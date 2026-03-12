// src/bridge.rs
// ─────────────────────────────────────────────────────────────────────────────
// cxx-qt Bridge: verbindet den Rust-Backend mit dem Qt/QML-Frontend.
//
// Das Makro #[cxx_qt::bridge] generiert automatisch ein QObject (C++/Qt),
// das von QML aus verwendet werden kann.  Alle Properties und Slots (Methoden)
// die hier definiert werden, sind in QML direkt nutzbar.
// ─────────────────────────────────────────────────────────────────────────────

#[cxx_qt::bridge(cxx_file_stem = "verbrauchsmanager")]
pub mod qobject {
    // ── Qt-seitige Includes (werden in den generierten C++-Code eingefügt) ────
    unsafe extern "C++" {
        include!("cxx-qt-lib/qstring.h");
        type QString = cxx_qt_lib::QString;

        include!("cxx-qt-lib/qstringlist.h");
        type QStringList = cxx_qt_lib::QStringList;
    }

    // ── Properties des QObjects ──────────────────────────────────────────────
    // Jede Property ist automatisch eine Qt-Property (NOTIFY-Signal inklusive)
    // und kann in QML mit `manager.eigenschaft` gelesen/geschrieben werden.
    #[cxx_qt::qobject(qml_uri = "com.verbrauchsmanager", qml_version = "1.0")]
    #[derive(Default)]
    pub struct VerbrauchsManager {
        /// Pfad zur aktuell geöffneten SQLite-Datenbank
        #[qproperty]
        db_pfad: QString,

        /// Statusmeldung für die Statusleiste
        #[qproperty]
        status_meldung: QString,

        /// Ob zuletzt ein Fehler aufgetreten ist (für rote/grüne Statusfarbe)
        #[qproperty]
        hat_fehler: bool,

        /// Anzahl Einträge Strom
        #[qproperty]
        strom_anzahl: i32,

        /// Anzahl Einträge Wasser
        #[qproperty]
        wasser_anzahl: i32,

        /// Anzahl Einträge Gas
        #[qproperty]
        gas_anzahl: i32,

        /// Gesamtverbrauch Strom (kWh)
        #[qproperty]
        strom_summe: f64,

        /// Gesamtverbrauch Wasser (m³)
        #[qproperty]
        wasser_summe: f64,

        /// Gesamtverbrauch Gas (m³)
        #[qproperty]
        gas_summe: f64,

        /// Dateigröße der DB in KB
        #[qproperty]
        db_groesse_kb: i64,

        // ── Interne Rust-Daten (nicht QML-sichtbar) ──────────────────────────
        #[qproperty(READ)]
        strom_tabelle: QStringList,

        #[qproperty(READ)]
        wasser_tabelle: QStringList,

        #[qproperty(READ)]
        gas_tabelle: QStringList,
    }

    // ── Slots (Methoden, die aus QML aufgerufen werden können) ────────────────
    impl qobject::VerbrauchsManager {
        // ── Initialisierung ───────────────────────────────────────────────────

        /// Beim Programmstart aufrufen: lädt die Standard-Datenbank.
        #[qinvokable]
        pub fn initialisieren(self: Pin<&mut Self>) {
            let pfad = crate::datenbank::VerbrauchsDatenbank::standard_pfad();
            let pfad_str = pfad.to_string_lossy().to_string();
            self.datenbank_laden_intern(&pfad_str);
        }

        // ── Datenbank-Operationen ─────────────────────────────────────────────

        /// Neue leere Datenbank an einem vom Benutzer gewählten Pfad erstellen.
        #[qinvokable]
        pub fn neue_datenbank_erstellen(self: Pin<&mut Self>, pfad: &QString) {
            let pfad_str = pfad.to_string();
            self.datenbank_laden_intern(&pfad_str);
        }

        /// Vorhandene Datenbank öffnen.
        #[qinvokable]
        pub fn datenbank_oeffnen(self: Pin<&mut Self>, pfad: &QString) {
            self.datenbank_laden_intern(&pfad.to_string());
        }

        // ── Einträge hinzufügen ───────────────────────────────────────────────

        /// Stromeintrag speichern (datum = "YYYY-MM-DD", kwh = Verbrauch in kWh).
        #[qinvokable]
        pub fn strom_hinzufuegen(
            self: Pin<&mut Self>,
            datum: &QString,
            kwh:   f64,
            notiz: &QString,
        ) {
            self.eintrag_speichern(
                crate::datenbank::Verbrauchsart::Strom,
                &datum.to_string(),
                kwh,
                &notiz.to_string(),
            );
        }

        /// Wassereintrag speichern (m³).
        #[qinvokable]
        pub fn wasser_hinzufuegen(
            self: Pin<&mut Self>,
            datum:      &QString,
            kubikmeter: f64,
            notiz:      &QString,
        ) {
            self.eintrag_speichern(
                crate::datenbank::Verbrauchsart::Wasser,
                &datum.to_string(),
                kubikmeter,
                &notiz.to_string(),
            );
        }

        /// Gaseintrag speichern (m³).
        #[qinvokable]
        pub fn gas_hinzufuegen(
            self: Pin<&mut Self>,
            datum:      &QString,
            kubikmeter: f64,
            notiz:      &QString,
        ) {
            self.eintrag_speichern(
                crate::datenbank::Verbrauchsart::Gas,
                &datum.to_string(),
                kubikmeter,
                &notiz.to_string(),
            );
        }

        // ── Einträge löschen ──────────────────────────────────────────────────

        #[qinvokable]
        pub fn strom_loeschen(self: Pin<&mut Self>, id: i64) {
            self.eintrag_entfernen(crate::datenbank::Verbrauchsart::Strom, id);
        }

        #[qinvokable]
        pub fn wasser_loeschen(self: Pin<&mut Self>, id: i64) {
            self.eintrag_entfernen(crate::datenbank::Verbrauchsart::Wasser, id);
        }

        #[qinvokable]
        pub fn gas_loeschen(self: Pin<&mut Self>, id: i64) {
            self.eintrag_entfernen(crate::datenbank::Verbrauchsart::Gas, id);
        }

        // ── Export ────────────────────────────────────────────────────────────

        /// Alle Daten als CSV exportieren.
        #[qinvokable]
        pub fn export_csv(self: Pin<&mut Self>, ziel_pfad: &QString) {
            self.export_intern_csv(&ziel_pfad.to_string());
        }

        /// Alle Daten als XLSX exportieren.
        #[qinvokable]
        pub fn export_xlsx(self: Pin<&mut Self>, ziel_pfad: &QString) {
            self.export_intern_xlsx(&ziel_pfad.to_string());
        }

        // ── Statistik aktualisieren ───────────────────────────────────────────

        #[qinvokable]
        pub fn statistik_aktualisieren(self: Pin<&mut Self>) {
            self.statistik_laden();
        }
    }
}

// ── Rust-Implementierungen (Logik, nicht Qt-sichtbar) ────────────────────────

use crate::datenbank::{VerbrauchsDatenbank, Verbrauchsart};
use cxx_qt_lib::{QString, QStringList};
use std::pin::Pin;
use std::sync::{Mutex, OnceLock};

// Globale Datenbankinstanz (thread-safe)
static DB: OnceLock<Mutex<Option<VerbrauchsDatenbank>>> = OnceLock::new();

fn db_lock() -> std::sync::MutexGuard<'static, Option<VerbrauchsDatenbank>> {
    DB.get_or_init(|| Mutex::new(None)).lock().unwrap()
}

impl qobject::VerbrauchsManagerQt {
    // ── Interne Hilfsmethoden ─────────────────────────────────────────────────

    fn datenbank_laden_intern(mut self: Pin<&mut Self>, pfad: &str) {
        match VerbrauchsDatenbank::oeffnen(pfad) {
            Ok(db) => {
                *db_lock() = Some(db);
                self.as_mut().set_db_pfad(QString::from(pfad));
                self.as_mut().set_hat_fehler(false);
                self.as_mut().set_status_meldung(QString::from(
                    &format!("✅ Datenbank geöffnet: {pfad}"),
                ));
                self.statistik_laden();
                self.tabellen_laden();
            }
            Err(e) => {
                self.as_mut().set_hat_fehler(true);
                self.as_mut().set_status_meldung(QString::from(
                    &format!("❌ Fehler: {e}"),
                ));
            }
        }
    }

    fn eintrag_speichern(
        mut self: Pin<&mut Self>,
        art:   Verbrauchsart,
        datum: &str,
        wert:  f64,
        notiz: &str,
    ) {
        let guard = db_lock();
        match guard.as_ref() {
            None => {
                self.as_mut().set_hat_fehler(true);
                self.as_mut().set_status_meldung(QString::from(
                    "❌ Keine Datenbank geöffnet!",
                ));
            }
            Some(db) => match db.eintrag_hinzufuegen(art, datum, wert, notiz) {
                Ok(id) => {
                    drop(guard);
                    self.as_mut().set_hat_fehler(false);
                    let label = art_label(art);
                    self.as_mut().set_status_meldung(QString::from(
                        &format!("✅ {label} gespeichert (ID {id})"),
                    ));
                    self.statistik_laden();
                    self.tabellen_laden();
                }
                Err(e) => {
                    drop(guard);
                    self.as_mut().set_hat_fehler(true);
                    self.as_mut().set_status_meldung(QString::from(
                        &format!("❌ Fehler beim Speichern: {e}"),
                    ));
                }
            },
        }
    }

    fn eintrag_entfernen(mut self: Pin<&mut Self>, art: Verbrauchsart, id: i64) {
        let guard = db_lock();
        match guard.as_ref() {
            None => {
                self.as_mut().set_hat_fehler(true);
                self.as_mut().set_status_meldung(QString::from("❌ Keine Datenbank!"));
            }
            Some(db) => match db.eintrag_loeschen(art, id) {
                Ok(_) => {
                    drop(guard);
                    self.as_mut().set_hat_fehler(false);
                    self.as_mut().set_status_meldung(QString::from(
                        &format!("✅ Eintrag {} gelöscht", id),
                    ));
                    self.statistik_laden();
                    self.tabellen_laden();
                }
                Err(e) => {
                    drop(guard);
                    self.as_mut().set_hat_fehler(true);
                    self.as_mut().set_status_meldung(QString::from(
                        &format!("❌ Fehler beim Löschen: {e}"),
                    ));
                }
            },
        }
    }

    fn statistik_laden(mut self: Pin<&mut Self>) {
        let guard = db_lock();
        if let Some(db) = guard.as_ref() {
            if let Ok(stat) = db.statistik() {
                let kb = db.dateigroesse_kb() as i64;
                drop(guard);
                self.as_mut().set_strom_summe(stat.strom_summe);
                self.as_mut().set_wasser_summe(stat.wasser_summe);
                self.as_mut().set_gas_summe(stat.gas_summe);
                self.as_mut().set_strom_anzahl(stat.strom_anz as i32);
                self.as_mut().set_wasser_anzahl(stat.wasser_anz as i32);
                self.as_mut().set_gas_anzahl(stat.gas_anz as i32);
                self.as_mut().set_db_groesse_kb(kb);
            }
        }
    }

    fn tabellen_laden(mut self: Pin<&mut Self>) {
        let guard = db_lock();
        if let Some(db) = guard.as_ref() {
            let strom  = eintraege_zu_stringlist(db, Verbrauchsart::Strom,  "kWh");
            let wasser = eintraege_zu_stringlist(db, Verbrauchsart::Wasser, "m³");
            let gas    = eintraege_zu_stringlist(db, Verbrauchsart::Gas,    "m³");
            drop(guard);
            self.as_mut().set_strom_tabelle(strom);
            self.as_mut().set_wasser_tabelle(wasser);
            self.as_mut().set_gas_tabelle(gas);
        }
    }

    fn export_intern_csv(mut self: Pin<&mut Self>, pfad: &str) {
        let guard = db_lock();
        match guard.as_ref() {
            None => {
                drop(guard);
                self.as_mut().set_hat_fehler(true);
                self.as_mut().set_status_meldung(QString::from("❌ Keine Datenbank geöffnet!"));
            }
            Some(db) => match db.export_csv(pfad) {
                Ok(_) => {
                    drop(guard);
                    self.as_mut().set_hat_fehler(false);
                    self.as_mut().set_status_meldung(QString::from(
                        &format!("✅ CSV exportiert: {pfad}"),
                    ));
                }
                Err(e) => {
                    drop(guard);
                    self.as_mut().set_hat_fehler(true);
                    self.as_mut().set_status_meldung(QString::from(
                        &format!("❌ CSV-Export fehlgeschlagen: {e}"),
                    ));
                }
            },
        }
    }

    fn export_intern_xlsx(mut self: Pin<&mut Self>, pfad: &str) {
        let guard = db_lock();
        match guard.as_ref() {
            None => {
                drop(guard);
                self.as_mut().set_hat_fehler(true);
                self.as_mut().set_status_meldung(QString::from("❌ Keine Datenbank geöffnet!"));
            }
            Some(db) => match db.export_xlsx(pfad) {
                Ok(_) => {
                    drop(guard);
                    self.as_mut().set_hat_fehler(false);
                    self.as_mut().set_status_meldung(QString::from(
                        &format!("✅ Excel exportiert: {pfad}"),
                    ));
                }
                Err(e) => {
                    drop(guard);
                    self.as_mut().set_hat_fehler(true);
                    self.as_mut().set_status_meldung(QString::from(
                        &format!("❌ XLSX-Export fehlgeschlagen: {e}"),
                    ));
                }
            },
        }
    }
}

// ── Hilfsfunktionen ───────────────────────────────────────────────────────────

fn art_label(art: Verbrauchsart) -> &'static str {
    match art {
        Verbrauchsart::Strom  => "Strom",
        Verbrauchsart::Wasser => "Wasser",
        Verbrauchsart::Gas    => "Gas",
    }
}

/// Konvertiert Datenbankeinträge in eine QStringList mit dem Format:
/// "<id>|<datum>|<wert> <einheit>|<notiz>"
fn eintraege_zu_stringlist(
    db:     &VerbrauchsDatenbank,
    art:    Verbrauchsart,
    einheit: &str,
) -> QStringList {
    let mut liste = QStringList::default();
    if let Ok(eintraege) = db.eintraege_laden(art) {
        for e in eintraege {
            let zeile = format!(
                "{}|{}|{:.3} {}|{}",
                e.id, e.datum, e.wert, einheit, e.notiz
            );
            liste.append(QString::from(&zeile));
        }
    }
    liste
}
