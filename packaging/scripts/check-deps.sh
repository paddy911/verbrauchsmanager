#!/bin/bash
# packaging/scripts/check-deps.sh
# ─────────────────────────────────────────────────────────────────────────────
# Prüft alle Build-Abhängigkeiten und installiert fehlende automatisch.
# Wird vom VS Code Task "⚙️ Voraussetzungen prüfen" aufgerufen.
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

# Farben
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'
CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

ok()   { echo -e "  ${GREEN}✔${NC}  $*"; }
warn() { echo -e "  ${YELLOW}⚠${NC}  $*"; }
info() { echo -e "  ${CYAN}→${NC}  $*"; }
fail() { echo -e "  ${RED}✘${NC}  $*"; }

echo ""
echo -e "${BOLD}╔══════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}║       Voraussetzungen prüfen                     ║${NC}"
echo -e "${BOLD}╚══════════════════════════════════════════════════╝${NC}"
echo ""

FEHLER=0
APT_PAKETE=()

# ── 1. Betriebssystem erkennen ────────────────────────────────────────────────
echo -e "${BOLD}System:${NC}"
if [[ -f /etc/os-release ]]; then
    . /etc/os-release
    ok "Betriebssystem: $PRETTY_NAME"
else
    warn "Betriebssystem nicht erkannt"
fi
echo ""

# ── 2. Rust / Cargo ───────────────────────────────────────────────────────────
echo -e "${BOLD}Rust:${NC}"
if command -v cargo &>/dev/null; then
    RUST_VER=$(rustc --version 2>/dev/null)
    ok "cargo gefunden: $RUST_VER"

    # Mindestversion 1.70 prüfen
    RUST_MINOR=$(rustc --version | grep -oP '\d+\.\K\d+' | head -1)
    if [[ "${RUST_MINOR:-0}" -lt 70 ]]; then
        warn "Rust-Version ist alt (< 1.70) – bitte aktualisieren:"
        info "rustup update stable"
    fi
else
    fail "cargo NICHT gefunden!"
    info "Rust installieren:"
    info "curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"
    info "source ~/.cargo/env"
    FEHLER=$((FEHLER + 1))
fi
echo ""

# ── 3. Build-Tools ────────────────────────────────────────────────────────────
echo -e "${BOLD}Build-Tools:${NC}"
for tool in gcc cmake ninja pkg-config; do
    if command -v "$tool" &>/dev/null; then
        ok "$tool: $(command -v "$tool")"
    else
        fail "$tool: FEHLT"
        case "$tool" in
            gcc)   APT_PAKETE+=("build-essential") ;;
            cmake) APT_PAKETE+=("cmake") ;;
            ninja) APT_PAKETE+=("ninja-build") ;;
            pkg-config) APT_PAKETE+=("pkg-config") ;;
        esac
    fi
done
echo ""

# ── 4. Qt6 ────────────────────────────────────────────────────────────────────
echo -e "${BOLD}Qt 6:${NC}"
QT6_PAKETE=(
    "libqt6core6:libqt6core6"
    "qt6-base-dev:qt6-base-dev"
    "qt6-declarative-dev:qt6-declarative-dev"
    "libqt6quick6:libqt6quick6"
    "libqt6quickcontrols2-6:libqt6quickcontrols2-6"
)
for eintrag in "${QT6_PAKETE[@]}"; do
    paket="${eintrag%%:*}"
    apt_name="${eintrag##*:}"
    if dpkg -l "$paket" &>/dev/null; then
        VER=$(dpkg -l "$paket" 2>/dev/null | awk '/^ii/{print $3}' | head -1)
        ok "$paket ($VER)"
    else
        fail "$paket: FEHLT"
        APT_PAKETE+=("$apt_name")
    fi
done

# QML-Module prüfen
for modul in qml6-module-qtquick-controls qml6-module-qtquick-layouts qml6-module-qtquick-dialogs; do
    if dpkg -l "$modul" &>/dev/null; then
        ok "$modul"
    else
        warn "$modul fehlt (optional, aber empfohlen)"
        APT_PAKETE+=("$modul")
    fi
done
echo ""

# ── 5. Paketierungs-Tools ─────────────────────────────────────────────────────
echo -e "${BOLD}Paketierungs-Tools:${NC}"
for tool_apt in "dpkg-deb:dpkg-dev" "fakeroot:fakeroot" "lintian:lintian"; do
    tool="${tool_apt%%:*}"
    apt="${tool_apt##*:}"
    if command -v "$tool" &>/dev/null; then
        ok "$tool: $(command -v "$tool")"
    else
        if [[ "$tool" == "lintian" ]]; then
            warn "$tool fehlt (optional – Qualitätsprüfung)"
        else
            fail "$tool: FEHLT"
        fi
        APT_PAKETE+=("$apt")
    fi
done
echo ""

# ── 6. Fehlende Pakete installieren ──────────────────────────────────────────
# Duplikate entfernen
mapfile -t APT_PAKETE < <(printf '%s\n' "${APT_PAKETE[@]}" | sort -u)

if [[ ${#APT_PAKETE[@]} -gt 0 ]]; then
    echo -e "${BOLD}${YELLOW}Fehlende Pakete werden installiert:${NC}"
    for p in "${APT_PAKETE[@]}"; do
        info "$p"
    done
    echo ""

    if [[ $EUID -eq 0 ]]; then
        apt-get update -qq
        apt-get install -y "${APT_PAKETE[@]}"
    else
        echo -e "${CYAN}→ sudo erforderlich:${NC}"
        sudo apt-get update -qq
        sudo apt-get install -y "${APT_PAKETE[@]}"
    fi
    echo ""
    ok "Alle Pakete installiert"
fi

# ── 7. Ergebnis ───────────────────────────────────────────────────────────────
echo ""
if [[ $FEHLER -eq 0 ]]; then
    echo -e "${BOLD}${GREEN}╔══════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${GREEN}║  ✅  Alle Voraussetzungen erfüllt – los geht's!  ║${NC}"
    echo -e "${BOLD}${GREEN}╚══════════════════════════════════════════════════╝${NC}"
    echo ""
    exit 0
else
    echo -e "${BOLD}${RED}╔══════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${RED}║  ❌  $FEHLER Voraussetzung(en) fehlen!             ║${NC}"
    echo -e "${BOLD}${RED}╚══════════════════════════════════════════════════╝${NC}"
    echo ""
    exit 1
fi
