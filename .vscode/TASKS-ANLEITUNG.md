# ⚡ VS Code – .deb Paket bauen: Kurzanleitung

## 🚀 In 3 Schritten zum fertigen .deb

---

### Schritt 1 — Projekt in VS Code öffnen

```
Datei → Öffnen → verbrauchsmanager.code-workspace
```
*(oder: `code verbrauchsmanager.code-workspace` im Terminal)*

---

### Schritt 2 — Task-Menü öffnen

```
Strg + Shift + P  →  "Tasks: Run Task"  →  Enter
```

Oder über das Menü:
```
Terminal  →  Aufgabe ausführen...
```

---

### Schritt 3 — Task auswählen

```
📦 DEB: Paket bauen (Vollständig)
```

➡️ VS Code öffnet ein dediziertes Terminal-Panel und führt aus:
1. `⚙️  Voraussetzungen prüfen`  — installiert fehlende Pakete automatisch
2. `cargo build --release`       — kompiliert das Rust-Binary
3. `dpkg-deb --build`            — packt das .deb zusammen
4. `lintian`                     — prüft die Paket-Qualität

**Ergebnis:** `dist/verbrauchsmanager_1.0.0_amd64.deb`

---

## 📋 Alle verfügbaren Tasks

| Task | Tastenkürzel | Beschreibung |
|---|---|---|
| 🔨 Rust: Debug-Build | `Strg+Shift+B` | Schneller Build zum Testen |
| ▶️  Starten (Debug) | — | Direkt starten ohne .deb |
| **📦 DEB: Paket bauen** | — | **Vollständiger .deb Build** |
| 📦 DEB: Nur packen | — | Ohne neuen Compile |
| ⚙️  Voraussetzungen prüfen | — | Qt6, fakeroot, dpkg-dev |
| 🔎 DEB: Paketinhalt anzeigen | — | Was ist im .deb? |
| ✅ DEB: Lintian-Prüfung | — | Qualitätskontrolle |
| 💾 DEB: Installieren | — | `sudo dpkg -i` lokal |
| 🗑️  DEB: Deinstallieren | — | `sudo apt remove` |
| 🔍 Clippy: Code prüfen | — | Rust-Linter |
| ✨ Rustfmt: formatieren | — | Code-Formatierung |
| 🏷️  Git: Release-Tag | — | Push → GitHub Actions |
| 🧹 Alles aufräumen | — | target/ + dist/ löschen |

---

## 🪟 Windows-Nutzer: WSL einrichten (einmalig)

```powershell
# 1. PowerShell als Administrator öffnen
wsl --install -d Ubuntu

# 2. Ubuntu starten und einrichten (Benutzername + Passwort)
# 3. VS Code öffnen → Erweiterung "WSL" installieren
# 4. Unten links auf ">" klicken → "Connect to WSL"
# 5. Im WSL-Terminal: Projekt-Ordner öffnen
```

Alle Tasks erkennen Windows **automatisch** und leiten an WSL weiter.

---

## 🐧 Linux-Nutzer

Alle Tasks laufen direkt — kein WSL nötig.

Beim ersten Mal einmalig ausführen:
```
⚙️  Voraussetzungen prüfen
```
Das installiert Qt6, dpkg-dev und fakeroot automatisch per `sudo apt`.
