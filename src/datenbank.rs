// src/datenbank.rs
// ─────────────────────────────────────────────────────────────────────────────
// Alle Datenbankoperationen (SQLite via rusqlite).
// Strom (kWh), Wasser (m³), Gas (m³) werden in einer einzigen SQLite-Datei
// gespeichert. Jede Tabelle hat: id, datum (TEXT ISO-8601), wert (REAL),
// notiz (TEXT).
// ─────────────────────────────────────────────────────────────────────────────

use anyhow::{Context, Result};
use chrono::NaiveDate;
use rusqlite::{params, Connection};
use std::path::{Path, PathBuf};

// ── Datensatz ────────────────────────────────────────────────────────────────

#[derive(Debug, Clone)]
pub struct Verbrauchseintrag {
    pub id:    i64,
    pub datum: String,   // "YYYY-MM-DD"
    pub wert:  f64,
    pub notiz: String,
}

// ── Hilfs-Enum für die drei Verbrauchsarten ──────────────────────────────────

#[derive(Debug, Clone, Copy)]
pub enum Verbrauchsart {
    Strom,
    Wasser,
    Gas,
}

impl Verbrauchsart {
    pub fn tabelle(self) -> &'static str {
        match self {
            Verbrauchsart::Strom  => "strom",
            Verbrauchsart::Wasser => "wasser",
            Verbrauchsart::Gas    => "gas",
        }
    }
    pub fn einheit(self) -> &'static str {
        match self {
            Verbrauchsart::Strom  => "kWh",
            Verbrauchsart::Wasser => "m³",
            Verbrauchsart::Gas    => "m³",
        }
    }
}

// ── VerbrauchsDatenbank ──────────────────────────────────────────────────────

pub struct VerbrauchsDatenbank {
    pub pfad: PathBuf,
    conn:     Connection,
}

impl VerbrauchsDatenbank {
    /// Öffnet oder erstellt eine Datenbank am angegebenen Pfad.
    pub fn oeffnen(pfad: impl AsRef<Path>) -> Result<Self> {
        let pfad = pfad.as_ref().to_path_buf();

        // Übergeordnete Verzeichnisse anlegen, falls nötig
        if let Some(eltern) = pfad.parent() {
            std::fs::create_dir_all(eltern)
                .with_context(|| format!("Verzeichnis erstellen: {}", eltern.display()))?;
        }

        let conn = Connection::open(&pfad)
            .with_context(|| format!("Datenbank öffnen: {}", pfad.display()))?;

        // WAL-Modus für bessere Performance
        conn.execute_batch("PRAGMA journal_mode=WAL; PRAGMA foreign_keys=ON;")?;

        let db = Self { pfad, conn };
        db.tabellen_erstellen()?;
        Ok(db)
    }

    /// Standard-Pfad: {UserDaten}/verbrauchsmanager/verbrauch.db
    pub fn standard_pfad() -> PathBuf {
        dirs::data_local_dir()
            .unwrap_or_else(|| PathBuf::from("."))
            .join("verbrauchsmanager")
            .join("verbrauch.db")
    }

    // ── Schema ────────────────────────────────────────────────────────────────

    fn tabellen_erstellen(&self) -> Result<()> {
        for tabelle in &["strom", "wasser", "gas"] {
            self.conn.execute_batch(&format!(
                "CREATE TABLE IF NOT EXISTS {tabelle} (
                    id    INTEGER PRIMARY KEY AUTOINCREMENT,
                    datum TEXT    NOT NULL,
                    wert  REAL    NOT NULL CHECK(wert >= 0),
                    notiz TEXT    NOT NULL DEFAULT ''
                );
                CREATE INDEX IF NOT EXISTS idx_{tabelle}_datum
                    ON {tabelle}(datum DESC);"
            ))?;
        }
        Ok(())
    }

    // ── Einfügen ──────────────────────────────────────────────────────────────

    pub fn eintrag_hinzufuegen(
        &self,
        art:   Verbrauchsart,
        datum: &str,
        wert:  f64,
        notiz: &str,
    ) -> Result<i64> {
        // Datum validieren
        NaiveDate::parse_from_str(datum, "%Y-%m-%d")
            .with_context(|| format!("Ungültiges Datum: {datum}"))?;

        let sql = format!(
            "INSERT INTO {} (datum, wert, notiz) VALUES (?1, ?2, ?3)",
            art.tabelle()
        );
        self.conn
            .execute(&sql, params![datum, wert, notiz])
            .with_context(|| "Eintrag einfügen")?;

        Ok(self.conn.last_insert_rowid())
    }

    // ── Löschen ───────────────────────────────────────────────────────────────

    pub fn eintrag_loeschen(&self, art: Verbrauchsart, id: i64) -> Result<()> {
        let sql = format!("DELETE FROM {} WHERE id = ?1", art.tabelle());
        self.conn
            .execute(&sql, params![id])
            .with_context(|| format!("Eintrag {id} löschen"))?;
        Ok(())
    }

    // ── Abfragen ──────────────────────────────────────────────────────────────

    pub fn eintraege_laden(&self, art: Verbrauchsart) -> Result<Vec<Verbrauchseintrag>> {
        let sql = format!(
            "SELECT id, datum, wert, notiz FROM {} ORDER BY datum DESC",
            art.tabelle()
        );
        let mut stmt = self.conn.prepare(&sql)?;
        let zeilen = stmt.query_map([], |row| {
            Ok(Verbrauchseintrag {
                id:    row.get(0)?,
                datum: row.get(1)?,
                wert:  row.get(2)?,
                notiz: row.get(3)?,
            })
        })?;

        let mut ergebnis = Vec::new();
        for z in zeilen {
            ergebnis.push(z?);
        }
        Ok(ergebnis)
    }

    /// Summe aller Einträge einer Art
    pub fn summe(&self, art: Verbrauchsart) -> Result<f64> {
        let sql = format!("SELECT COALESCE(SUM(wert), 0.0) FROM {}", art.tabelle());
        let summe: f64 = self.conn.query_row(&sql, [], |r| r.get(0))?;
        Ok(summe)
    }

    // ── Export: CSV ───────────────────────────────────────────────────────────

    pub fn export_csv(&self, ziel_pfad: impl AsRef<Path>) -> Result<()> {
        let mut writer = csv::Writer::from_path(&ziel_pfad)
            .with_context(|| "CSV-Datei öffnen")?;

        // Kopfzeile
        writer.write_record(["Art", "Datum", "Wert", "Einheit", "Notiz"])?;

        for (art, label) in &[
            (Verbrauchsart::Strom,  "Strom"),
            (Verbrauchsart::Wasser, "Wasser"),
            (Verbrauchsart::Gas,    "Gas"),
        ] {
            for e in self.eintraege_laden(*art)? {
                writer.write_record([
                    label,
                    &e.datum,
                    &format!("{:.4}", e.wert),
                    art.einheit(),
                    &e.notiz,
                ])?;
            }
        }

        writer.flush()?;
        Ok(())
    }

    // ── Export: XLSX ──────────────────────────────────────────────────────────

    pub fn export_xlsx(&self, ziel_pfad: impl AsRef<Path>) -> Result<()> {
        use rust_xlsxwriter::{Format, FormatAlign, Color, Workbook};

        let mut wb = Workbook::new();

        // Formate definieren
        let kopf_format = Format::new()
            .set_bold()
            .set_background_color(Color::RGB(0x2E86AB))
            .set_font_color(Color::White)
            .set_align(FormatAlign::Center);

        let zahl_format = Format::new()
            .set_num_format("0.000");

        let summen_format = Format::new()
            .set_bold()
            .set_num_format("0.000");

        for (art, blatt_name) in &[
            (Verbrauchsart::Strom,  "Strom (kWh)"),
            (Verbrauchsart::Wasser, "Wasser (m3)"),
            (Verbrauchsart::Gas,    "Gas (m3)"),
        ] {
            let sheet = wb.add_worksheet();
            sheet.set_name(blatt_name)?;

            // Spaltenbreiten
            sheet.set_column_width(0, 14)?;
            sheet.set_column_width(1, 14)?;
            sheet.set_column_width(2, 30)?;

            // Kopfzeile
            sheet.write_with_format(0, 0, "Datum",       &kopf_format)?;
            sheet.write_with_format(0, 1, art.einheit(), &kopf_format)?;
            sheet.write_with_format(0, 2, "Notiz",       &kopf_format)?;

            let eintraege = self.eintraege_laden(*art)?;
            for (zeile, e) in eintraege.iter().enumerate() {
                let z = (zeile + 1) as u32;
                sheet.write(z, 0, e.datum.as_str())?;
                sheet.write_with_format(z, 1, e.wert, &zahl_format)?;
                sheet.write(z, 2, e.notiz.as_str())?;
            }

            // Summen-Zeile
            let summen_zeile = (eintraege.len() + 2) as u32;
            sheet.write_with_format(summen_zeile, 0, "Gesamt:", &summen_format)?;
            sheet.write_with_format(summen_zeile, 1, self.summe(*art)?, &summen_format)?;
        }

        wb.save(ziel_pfad.as_ref())
            .with_context(|| "XLSX speichern")?;
        Ok(())
    }

    // ── Statistik ─────────────────────────────────────────────────────────────

    pub fn statistik(&self) -> Result<Statistik> {
        Ok(Statistik {
            strom_summe:  self.summe(Verbrauchsart::Strom)?,
            wasser_summe: self.summe(Verbrauchsart::Wasser)?,
            gas_summe:    self.summe(Verbrauchsart::Gas)?,
            strom_anz:    self.anzahl(Verbrauchsart::Strom)?,
            wasser_anz:   self.anzahl(Verbrauchsart::Wasser)?,
            gas_anz:      self.anzahl(Verbrauchsart::Gas)?,
        })
    }

    fn anzahl(&self, art: Verbrauchsart) -> Result<i64> {
        let sql = format!("SELECT COUNT(*) FROM {}", art.tabelle());
        let n: i64 = self.conn.query_row(&sql, [], |r| r.get(0))?;
        Ok(n)
    }

    /// Gibt Dateigröße in Kilobyte zurück
    pub fn dateigroesse_kb(&self) -> u64 {
        std::fs::metadata(&self.pfad)
            .map(|m| m.len() / 1024)
            .unwrap_or(0)
    }
}

// ── Statistik-Struct ─────────────────────────────────────────────────────────

#[derive(Debug, Default)]
pub struct Statistik {
    pub strom_summe:  f64,
    pub wasser_summe: f64,
    pub gas_summe:    f64,
    pub strom_anz:    i64,
    pub wasser_anz:   i64,
    pub gas_anz:      i64,
}
