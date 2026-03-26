# ⚡ Verbrauchsmanager – Komplettanleitung
## Von VS Code → GitHub → fertiges Flatpak

---

## 📋 Übersicht

```
┌─────────────┐     ┌──────────────┐     ┌──────────────────┐
│   VS Code   │────▶│    GitHub    │────▶│  Flatpak-Paket   │
│  (Schritt 1)│     │  (Schritt 2) │     │   (Schritt 3)    │
└─────────────┘     └──────────────┘     └──────────────────┘
   Code hochladen    Build startet         Paket installieren
                     automatisch
```

---

# SCHRITT 1 — Einmalige Vorbereitung (lokal)

## 1.1 — Flatpak-Werkzeuge installieren (CachyOS)

```bash
sudo pacman -S flatpak flatpak-builder
yay -S flatpak-cargo-generator

flatpak remote-add --user --if-not-exists flathub \
    https://flathub.org/repo/flathub.flatpakrepo

flatpak install --user flathub \
    org.freedesktop.Platform//23.08 \
    org.freedesktop.Sdk//23.08 \
    org.freedesktop.Sdk.Extension.rust-stable//23.08
```

## 1.2 — Cargo-Abhängigkeiten als Offline-Cache erzeugen

Flatpak baut ohne Internetzugang – dieser Schritt muss nach jedem
`Cargo.lock`-Update wiederholt werden:

```bash
cd ~/verbrauchsmanager
flatpak-cargo-generator Cargo.lock -o packaging/cargo-sources.json
git add packaging/cargo-sources.json
git commit -m "chore: Flatpak cargo-sources aktualisiert"
git push
```

---

# SCHRITT 2 — Code hochladen (wie bisher)

## 2.1 — GitHub-Konto verbinden (einmalig)

```
Strg + Shift + P  →  "GitHub: Sign in"  →  Enter
```

## 2.2 — Änderungen hochladen

**Über VS Code:**
```
1. Quellcodeverwaltung (Branch-Symbol links)
2. "+" neben geänderten Dateien
3. Commit-Nachricht eingeben
4. "Commit" → "Synchronisieren"
```

**Über Terminal:**
```bash
git add .
git commit -m "Beschreibung"
git push
```

---

# SCHRITT 3 — Flatpak lokal bauen und testen

## 3.1 — Bauen & installieren

```bash
cd ~/verbrauchsmanager/packaging

flatpak-builder \
    --user \
    --install \
    --force-clean \
    build-dir \
    de.paddy911.Verbrauchsmanager.yml
```

Dauer: ca. 5–10 Minuten beim ersten Mal.

## 3.2 — Testen

```bash
flatpak run de.paddy911.Verbrauchsmanager
```

---

# SCHRITT 4 — Als .flatpak Datei exportieren (zum Weitergeben)

```bash
cd ~/verbrauchsmanager/packaging

# Lokales Repository erzeugen
flatpak-builder --repo=repo --force-clean build-dir \
    de.paddy911.Verbrauchsmanager.yml

# Bundle erstellen
flatpak build-bundle repo \
    ../Verbrauchsmanager.flatpak \
    de.paddy911.Verbrauchsmanager
```

**Installation auf einem anderen Linux-System:**
```bash
flatpak install Verbrauchsmanager.flatpak
flatpak run de.paddy911.Verbrauchsmanager
```

---

# 🔄 Kurzübersicht Alltag

```
Coden          →  cargo run                    (schnell, direkt)
Cargo.lock neu →  flatpak-cargo-generator ...  (Quellen aktualisieren)
Release        →  flatpak-builder ...          (Flatpak bauen)
Weitergeben    →  flatpak build-bundle ...     (Bundle exportieren)
```

---

# ❓ Häufige Probleme

| Problem | Lösung |
|---|---|
| Build schlägt fehl: "offline" | `flatpak-cargo-generator` neu ausführen |
| Fenster leer / schwarz | `WAYLAND_DISPLAY="" flatpak run de.paddy911.Verbrauchsmanager` |
| Dateidialog öffnet sich nicht | `sudo pacman -S xdg-desktop-portal xdg-desktop-portal-kde` |
| `cargo-sources.json` fehlt | Schritt 1.2 ausführen |
| Tag bereits vorhanden | `git tag -d v0.1.2` dann neu setzen |
