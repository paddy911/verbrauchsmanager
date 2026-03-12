// src/main.rs
// ─────────────────────────────────────────────────────────────────────────────
// Einstiegspunkt des Verbrauchsmanagers.
// Startet die Qt-Applikation und lädt die QML-Oberfläche.
// ─────────────────────────────────────────────────────────────────────────────

mod bridge;
mod datenbank;

use cxx_qt_lib::{QGuiApplication, QQmlApplicationEngine, QUrl};

fn main() {
    // Qt-Applikation initialisieren
    let mut app = QGuiApplication::new();

    // High-DPI-Skalierung aktivieren (Qt 6 macht das standardmäßig,
    // trotzdem zur Sicherheit explizit setzen)
    app.set_application_name(&cxx_qt_lib::QString::from("Verbrauchsmanager"));
    app.set_application_version(&cxx_qt_lib::QString::from("1.0.0"));
    app.set_organization_name(&cxx_qt_lib::QString::from("VerbrauchsManager GmbH"));

    // QML-Engine starten
    let mut engine = QQmlApplicationEngine::new();

    // Unsere QML-Datei laden (eingebettet via Qt Resource System)
    engine.load(&QUrl::from_str("qrc:/qt/qml/com/verbrauchsmanager/qml/main.qml"));

    if engine.root_objects().is_empty() {
        eprintln!("FEHLER: QML-Datei konnte nicht geladen werden!");
        std::process::exit(1);
    }

    // Event-Loop starten
    app.exec();
}
