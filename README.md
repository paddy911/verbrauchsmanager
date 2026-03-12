# ⚡ Verbrauchsmanager

Ein modernes Desktop-Programm zum Erfassen und Auswerten von
**Strom (kWh)**, **Wasser (m³)** und **Gas (m³)** –
gebaut mit **Rust** und **Qt 6 (QML)**.

---

## 📦 Features

| Funktion | Beschreibung |
|---|---|
| Verbrauch erfassen | Datum, Wert und optionale Notiz pro Eintrag |
| Datenbank-Info | Vollständiger Pfad und Dateigröße werden angezeigt |
| Neue DB erstellen | Beliebigen Speicherort per Dateidialog wählen |
| DB öffnen | Vorhandene `.db`/`.sqlite`-Datei laden |
| CSV-Export | Alle drei Verbrauchsarten in einer Datei |
| XLSX-Export | Excel-Datei mit je einem Blatt pro Art + Summenzeile |
| Statistik | Gesamtverbrauch und Anzahl Einträge je Art |
| Löschen | Jeden Eintrag einzeln entfernen |

---

## 🛠 Voraussetzungen

### System-Pakete

**Ubuntu / Debian:**
```bash
sudo apt update
sudo apt install -y \
    build-essential cmake ninja-build pkg-config \
    qt6-base-dev qt6-declarative-dev qt6-tools-dev \
    libgl1-mesa-dev libsqlite3-dev
```

**Fedora / RHEL:**
```bash
sudo dnf install -y \
    gcc cmake ninja-build pkg-config \
    qt6-qtbase-devel qt6-qtdeclarative-devel qt6-qttools \
    mesa-libGL-devel sqlite-devel
```

**macOS (Homebrew):**
```bash
brew install qt6 cmake ninja
export PATH="/opt/homebrew/opt/qt/bin:$PATH"
```

**Windows (MSVC + vcpkg):**
```powershell
# Qt 6 via Installer: https://www.qt.io/download-qt-installer
# Dann:
set Qt6_DIR=C:\Qt\6.x.x\msvc2022_64\lib\cmake\Qt6
```

### Rust
```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
rustup update stable
```

---

## 🚀 Kompilieren und Starten

```bash
# 1. Repository klonen / Ordner entpacken
cd verbrauchsmanager

# 2. Debug-Build (schneller)
cargo run

# 3. Release-Build (optimiert)
cargo build --release
./target/release/verbrauchsmanager
```

---

## 📁 Datenbankpfad

Die SQLite-Datenbank wird standardmäßig hier gespeichert:

| Betriebssystem | Pfad |
|---|---|
| **Linux** | `~/.local/share/verbrauchsmanager/verbrauch.db` |
| **macOS** | `~/Library/Application Support/verbrauchsmanager/verbrauch.db` |
| **Windows** | `%APPDATA%\Local\verbrauchsmanager\verbrauch.db` |

Der Pfad wird in der Statusleiste unten und im **Datenbank-Tab** angezeigt.
Über *Neue Datenbank erstellen* kann ein beliebiger anderer Ort gewählt werden.

---

## 📊 Datenbankschema

```sql
-- Tabelle für Strom
CREATE TABLE strom (
    id    INTEGER PRIMARY KEY AUTOINCREMENT,
    datum TEXT    NOT NULL,          -- Format: "YYYY-MM-DD"
    wert  REAL    NOT NULL CHECK(wert >= 0),
    notiz TEXT    NOT NULL DEFAULT ''
);

-- Identisch für: wasser, gas
CREATE INDEX idx_strom_datum ON strom(datum DESC);
```

---

## 📄 CSV-Export (Beispiel)

```
Art,Datum,Wert,Einheit,Notiz
Strom,2024-01-15,312.5000,kWh,Hauptzähler
Strom,2024-02-15,287.2300,kWh,
Wasser,2024-01-15,4.8500,m³,Keller-Zähler
Gas,2024-01-15,123.4000,m³,
```

---

## 📊 XLSX-Export

Die Excel-Datei enthält **drei Tabellenblätter**:

- `Strom (kWh)` – alle Stromeinträge + Gesamtsumme
- `Wasser (m³)` – alle Wassereinträge + Gesamtsumme
- `Gas (m³)` – alle Gaseinträge + Gesamtsumme

---

## 🗂 Projektstruktur

```
verbrauchsmanager/
├── Cargo.toml          # Abhängigkeiten & Build-Konfiguration
├── build.rs            # Qt6-Build-Skript (cxx-qt-build)
├── src/
│   ├── main.rs         # Einstiegspunkt, Qt-App-Initialisierung
│   ├── bridge.rs       # cxx-qt-Bridge: Qt ↔ Rust Schnittstelle
│   └── datenbank.rs    # SQLite-Operationen, CSV/XLSX-Export
└── qml/
    ├── main.qml        # Hauptfenster, TabBar, Layout
    ├── EingabeSeite.qml   # Eingabeformular + Tabelle (3× verwendet)
    └── DatenbankSeite.qml # DB-Verwaltung, Statistik, Export
```

---

## 📦 Verwendete Bibliotheken

| Crate | Zweck |
|---|---|
| `cxx-qt` | Rust ↔ Qt6 QObject-Bindings |
| `cxx-qt-lib` | Qt-Typen (QString, QStringList …) |
| `rusqlite` | SQLite (statisch gelinkt, kein extra sqlite3 nötig) |
| `csv` | CSV-Export |
| `xlsxwriter` | Excel-XLSX-Export |
| `chrono` | Datum/Zeit-Validierung |
| `dirs` | Betriebssystem-spezifische Datenpfade |
| `anyhow` | Fehlerbehandlung |

---

## 🐛 Häufige Fehler

**`Qt6 not found`**
```bash
export CMAKE_PREFIX_PATH=/path/to/Qt/6.x.x/gcc_64
```

**`libGL not found`** (Linux)
```bash
sudo apt install libgl1-mesa-dev
```

**Fenster öffnet sich nicht / leer**
- Qt Quick Controls 2 Style setzen:
```bash
QT_QUICK_CONTROLS_STYLE=Fusion ./verbrauchsmanager
```

---

## 📜 Lizenz

MIT License – frei verwendbar und modifizierbar.
