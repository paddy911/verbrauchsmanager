#!/bin/bash
# packaging/scripts/build-deb.sh
set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

info()    { echo -e "  ${CYAN}[INFO]${NC}  $*"; }
success() { echo -e "  ${GREEN}[OK]${NC}    $*"; }
warn()    { echo -e "  ${YELLOW}[WARN]${NC}  $*"; }
error()   { echo -e "  ${RED}[ERROR]${NC} $*" >&2; exit 1; }
step()    { echo -e "\n${BOLD}${CYAN}▶ $*${NC}"; }

PAKET_NAME="verbrauchsmanager"
ARCHITEKTUR="amd64"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# ── Version automatisch aus Cargo.toml lesen ──────────────────────────────────
# Nur noch Cargo.toml ändern – build-deb.sh liest die Version automatisch!
VERSION=$(grep -m1 '^version' "${PROJECT_ROOT}/Cargo.toml" | sed 's/[^"]*"\([^"]*\)".*/\1/')
[[ -z "$VERSION" ]] && error "Version nicht in Cargo.toml gefunden!"

PAKET_DATEI="${PAKET_NAME}_${VERSION}_${ARCHITEKTUR}.deb"
PAKET_DIR="${PROJECT_ROOT}/packaging/debian"
DIST_DIR="${PROJECT_ROOT}/dist"
BINARY_SRC="${PROJECT_ROOT}/target/release/${PAKET_NAME}"
BINARY_DST="${PAKET_DIR}/usr/lib/${PAKET_NAME}/${PAKET_NAME}-bin"
WRAPPER="${PAKET_DIR}/usr/bin/${PAKET_NAME}"

SKIP_COMPILE=false
[[ "${1:-}" == "--skip-compile" ]] && SKIP_COMPILE=true

echo -e "${BOLD}"
echo "╔════════════════════════════════════════════════════╗"
echo "║     Verbrauchsmanager  –  .deb Build-Skript       ║"
echo "╚════════════════════════════════════════════════════╝"
echo -e "${NC}"
info "Version:  ${BOLD}${VERSION}${NC}  (aus Cargo.toml)"
info "Paket:    ${PAKET_DATEI}"

# ── 1. Voraussetzungen ────────────────────────────────────────────────────────
step "Voraussetzungen prüfen"
for cmd_pkg in "cargo:rustup" "dpkg-deb:dpkg-dev" "fakeroot:fakeroot"; do
    cmd="${cmd_pkg%%:*}"; pkg="${cmd_pkg##*:}"
    command -v "$cmd" &>/dev/null \
        && success "$cmd gefunden" \
        || error "$cmd nicht gefunden → sudo apt install $pkg"
done
command -v lintian &>/dev/null \
    && success "lintian gefunden" \
    || warn "lintian nicht gefunden (optional)"

# ── 2. Kompilieren ────────────────────────────────────────────────────────────
if [[ "$SKIP_COMPILE" == false ]]; then
    step "Rust Release-Binary kompilieren"
    cd "${PROJECT_ROOT}"
    cargo build --release
    success "Kompiliert: $(du -sh "$BINARY_SRC" | cut -f1)"
else
    step "Compilierung übersprungen (--skip-compile)"
    [[ -f "$BINARY_SRC" ]] || error "Binary fehlt: ${BINARY_SRC}"
    info "Vorhandenes Binary: $(du -sh "$BINARY_SRC" | cut -f1)"
fi

# ── 3. Paketstruktur zusammenstellen ─────────────────────────────────────────
step "Paketstruktur zusammenstellen"

mkdir -p "$(dirname "$BINARY_DST")"
cp "$BINARY_SRC" "$BINARY_DST"
success "Binary → ${BINARY_DST}"

mkdir -p "$(dirname "$WRAPPER")"
cat > "$WRAPPER" << 'WRAPPER_EOF'
#!/bin/bash
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/tmp/runtime-$(id -u)}"
exec /usr/lib/verbrauchsmanager/verbrauchsmanager-bin "$@"
WRAPPER_EOF
success "Wrapper-Skript erstellt"

# ── 4. Versionsnummer in control eintragen ────────────────────────────────────
step "control-Datei aktualisieren"
sed -i "s/^Version:.*/Version: ${VERSION}/" "${PAKET_DIR}/DEBIAN/control"
success "Version ${VERSION} in control eingetragen"

# ── 5. Berechtigungen ─────────────────────────────────────────────────────────
step "Dateiberechtigungen setzen"
find "${PAKET_DIR}" -type f -exec chmod 0644 {} \;
find "${PAKET_DIR}" -type d -exec chmod 0755 {} \;
chmod 0755 "${BINARY_DST}"
chmod 0755 "${WRAPPER}"
for skript in postinst prerm postrm; do
    f="${PAKET_DIR}/DEBIAN/${skript}"
    [[ -f "$f" ]] && chmod 0755 "$f"
done
success "Berechtigungen gesetzt"

# ── 6. Installed-Size aktualisieren ──────────────────────────────────────────
step "Paketgröße berechnen"
INSTALLED_KB=$(du -sk "${PAKET_DIR}" --exclude="${PAKET_DIR}/DEBIAN" | cut -f1)
if grep -q "^Installed-Size:" "${PAKET_DIR}/DEBIAN/control"; then
    sed -i "s/^Installed-Size:.*/Installed-Size: ${INSTALLED_KB}/" "${PAKET_DIR}/DEBIAN/control"
else
    echo "Installed-Size: ${INSTALLED_KB}" >> "${PAKET_DIR}/DEBIAN/control"
fi
success "Installed-Size: ${INSTALLED_KB} KB"

# ── 7. MD5-Prüfsummen ────────────────────────────────────────────────────────
step "MD5-Prüfsummen generieren"
cd "${PAKET_DIR}"
find . -path ./DEBIAN -prune -o -type f -print | sort | \
    xargs -I{} md5sum {} 2>/dev/null > "${PAKET_DIR}/DEBIAN/md5sums" || true
chmod 0644 "${PAKET_DIR}/DEBIAN/md5sums"
success "$(wc -l < "${PAKET_DIR}/DEBIAN/md5sums") Prüfsummen generiert"

# ── 8. .deb bauen ────────────────────────────────────────────────────────────
step ".deb Paket bauen"
mkdir -p "${DIST_DIR}"
cd "${PROJECT_ROOT}"
fakeroot dpkg-deb --build --root-owner-group "${PAKET_DIR}" "${DIST_DIR}/${PAKET_DATEI}"
DEB_GROESSE=$(du -sh "${DIST_DIR}/${PAKET_DATEI}" | cut -f1)
success "Paket: ${DIST_DIR}/${PAKET_DATEI} (${DEB_GROESSE})"

# ── 9. Inhalt anzeigen ───────────────────────────────────────────────────────
echo ""
dpkg-deb --contents "${DIST_DIR}/${PAKET_DATEI}" | awk '{printf "  %-10s %s\n", $3, $6}'

# ── 10. Lintian (optional) ────────────────────────────────────────────────────
if command -v lintian &>/dev/null; then
    step "Lintian-Qualitätsprüfung"
    lintian --color always "${DIST_DIR}/${PAKET_DATEI}" 2>&1 || \
        warn "Lintian-Warnungen (bei eigenen Paketen normal)"
fi

# ── Fertig ────────────────────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}${GREEN}╔══════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${GREEN}║         ✅  Build erfolgreich!                  ║${NC}"
echo -e "${BOLD}${GREEN}╚══════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "  Paket:   ${BOLD}${DIST_DIR}/${PAKET_DATEI}${NC}  (${DEB_GROESSE})"
echo ""
echo -e "  ${BOLD}Installieren:${NC}"
echo -e "  sudo dpkg -i ${DIST_DIR}/${PAKET_DATEI}"
echo -e "  sudo apt-get install -f"
echo ""
