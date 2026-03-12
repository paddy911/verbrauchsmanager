# ⚡ Verbrauchsmanager – Komplettanleitung
## Von VS Code → GitHub → fertiges .deb Paket

---

## 📋 Übersicht

```
┌─────────────┐     ┌──────────────┐     ┌─────────────────┐
│   VS Code   │────▶│    GitHub    │────▶│  .deb Download  │
│  (Schritt 1)│     │  (Schritt 2) │     │   (Schritt 3)   │
└─────────────┘     └──────────────┘     └─────────────────┘
   Code hochladen    Build startet         Paket herunterladen
                     automatisch
```

---

# SCHRITT 1 — Code mit VS Code auf GitHub hochladen

## 1.1 — GitHub-Konto mit VS Code verbinden (einmalig)

**In VS Code:**
```
Strg + Shift + P  →  "GitHub: Sign in"  →  Enter
```
Ein Browser-Fenster öffnet sich → GitHub-Login → Bestätigen → zurück zu VS Code.

---

## 1.2 — Repository auf GitHub erstellen

**In VS Code:**
```
Strg + Shift + P  →  "Publish to GitHub"  →  Enter
```

VS Code fragt dich:
- **Name:** `verbrauchsmanager`
- **Sichtbarkeit:** `Public` oder `Private` (deine Wahl)
- Alle Dateien auswählen → **„OK"**

✅ Das Repository wird automatisch erstellt und der Code hochgeladen.

---

## 1.3 — Workflow-Datei korrekt platzieren

⚠️ **Wichtig:** Die GitHub Actions Datei muss im richtigen Ordner liegen!

**Überprüfe im VS Code Explorer (links):**
```
verbrauchsmanager/
├── .github/                    ← Muss so heißen (mit Punkt)
│   └── workflows/
│       └── build-deb.yml       ← Diese Datei muss hier liegen ✅
├── .vscode/
├── packaging/
├── src/
├── qml/
└── Cargo.toml
```

Falls `.github/workflows/build-deb.yml` **nicht** vorhanden ist:

**In VS Code Terminal** (`Strg + Ö`):
```bash
mkdir -p .github/workflows
cp packaging/.github/workflows/build-deb.yml .github/workflows/
git add .github/
git commit -m "CI: Workflow hinzugefügt"
git push
```

---

## 1.4 — Spätere Änderungen hochladen

Immer wenn du Code geändert hast:

**Methode A – Über die VS Code Seitenleiste (einfach):**
```
1. Links auf das Branch-Symbol klicken (Quellcodeverwaltung)
2. "+" neben geänderten Dateien klicken  →  Dateien werden "gestaged"
3. Oben eine Nachricht eintippen z.B. "Neue Funktion hinzugefügt"
4. Auf den "✓ Commit"-Button klicken
5. Auf "Änderungen synchronisieren" (↑↓) klicken  →  Hochladen
```

**Methode B – Über das Terminal:**
```bash
git add .
git commit -m "Beschreibung der Änderung"
git push
```

---
---

# SCHRITT 2 — .deb Paket auf GitHub bauen lassen

## 2.1 — Build manuell starten (im Browser)

Öffne deinen Browser und gehe zu:
```
https://github.com/DEIN-USERNAME/verbrauchsmanager
```

Dann:
```
① Klicke oben auf den Reiter "Actions"

② Klicke links in der Liste auf "📦 Build .deb Paket"

③ Klicke rechts auf den grünen Button "Run workflow"

④ Es öffnet sich ein Menü:
   ┌─────────────────────────────────────────────────┐
   │ Branch: main                                    │
   │ Version überschreiben: [leer lassen]            │
   │ GitHub Release erstellen?: [false ▼]            │
   └─────────────────────────────────────────────────┘

⑤ Klicke auf den grünen "Run workflow" Button
```

---

## 2.2 — Build beobachten

```
Actions → laufender Job (gelber Kreis dreht sich)
       → klicke darauf
       → klicke auf "📦 Debian Paket bauen (Ubuntu 22.04)"
```

Du siehst live was passiert:
```
✅ Quellcode auschecken          (~10 Sek.)
✅ Rust stable installieren      (~30 Sek.)
✅ Qt6 und Build-Tools           (~2 Min.)
✅ Release-Binary kompilieren    (~5 Min.)
✅ .deb Paket bauen              (~30 Sek.)
✅ Lintian Qualitätsprüfung      (~10 Sek.)
✅ .deb als Artefakt speichern   (~10 Sek.)
```
**Gesamtdauer: ca. 8–12 Minuten**

Grüner Haken = Erfolg ✅  |  Rotes X = Fehler ❌ (Log anklicken)

---

## 2.3 — Build automatisch mit Release-Tag auslösen

Wenn du eine fertige Version veröffentlichen möchtest:

**In VS Code Terminal:**
```bash
git tag v1.0.0
git push origin v1.0.0
```

→ GitHub Actions startet **automatisch** und erstellt einen Release mit dem fertigen `.deb`.

---
---

# SCHRITT 3 — Fertiges .deb herunterladen

## 3.1 — Als Artefakt (ohne Release)

```
github.com/DEIN-USERNAME/verbrauchsmanager
  → "Actions"
  → letzter erfolgreicher Build (grüner Haken ✅)
  → ganz nach unten scrollen
  → "Artifacts"
  → "verbrauchsmanager_1.0.0_amd64"  ← Klicken = Download
```

Die Datei wird als `.zip` heruntergeladen → entpacken → `.deb` liegt darin.

---

## 3.2 — Als Release (mit Tag)

```
github.com/DEIN-USERNAME/verbrauchsmanager
  → rechts: "Releases"
  → "Verbrauchsmanager v1.0.0"
  → "verbrauchsmanager_1.0.0_amd64.deb"  ← Klicken = Download
```

---
---

# SCHRITT 4 — .deb installieren

Auf dem Ziel-System (Ubuntu / Debian):

```bash
# Paket installieren
sudo dpkg -i verbrauchsmanager_1.0.0_amd64.deb

# Falls Abhängigkeiten fehlen – automatisch nachholen
sudo apt-get install -f

# Programm starten
verbrauchsmanager
```

Oder per Doppelklick auf die `.deb`-Datei im Dateimanager.

---
---

# 🔄 Kompletter Ablauf als Kurzübersicht

```
┌──────────────────────────────────────────────────────────────────┐
│                                                                  │
│  CODE ÄNDERN          GIT PUSH           GITHUB ACTIONS          │
│                                                                  │
│  VS Code          Strg+Shift+P        Actions → Run workflow     │
│  Code bearbeiten  "Publish to         ODER                       │
│  und speichern    GitHub"             git tag v1.0.0             │
│                   ODER                git push origin v1.0.0    │
│                   git add .                    │                 │
│                   git commit -m "..."          ▼                 │
│                   git push             Build läuft (~10 Min)     │
│                                               │                  │
│                                               ▼                  │
│                                    ✅ .deb fertig!               │
│                                               │                  │
│                                    Actions → Artifacts           │
│                                    ODER Releases                 │
│                                    → .deb herunterladen          │
│                                               │                  │
│                                               ▼                  │
│                                    sudo dpkg -i *.deb            │
│                                    sudo apt-get install -f       │
│                                    verbrauchsmanager             │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

---

# ❓ Häufige Probleme

| Problem | Lösung |
|---|---|
| „Publish to GitHub" fehlt | Erweiterung „GitHub Pull Requests" installieren |
| Push schlägt fehl | `Strg+Shift+P` → „GitHub: Sign in" |
| Actions-Tab nicht sichtbar | Workflow muss in `.github/workflows/` liegen |
| Build schlägt fehl (rotes X) | Auf den Job klicken → Log lesen → Zeile mit ❌ |
| Artefakt nicht sichtbar | Nur bei erfolgreichem Build (grüner Haken) |
| Tag bereits vorhanden | `git tag -d v1.0.0` dann neu setzen |
