// build.rs – Qt 6 Build-Skript
// Registriert QML-Dateien und den cxx-qt-Bridge-Code beim Qt-Build-System.

use cxx_qt_build::{CxxQtBuilder, QmlModule};

fn main() {
    CxxQtBuilder::new()
        // Qt-Module die benötigt werden
        .qt_module("Quick")
        .qt_module("QuickControls2")
        .qt_module("Sql")
        // QML-Modul registrieren
        .qml_module(QmlModule {
            uri: "com.verbrauchsmanager",
            version_major: 1,
            version_minor: 0,
            qml_files: &[
                "qml/main.qml",
                "qml/EingabeSeite.qml",
                "qml/TabelleSeite.qml",
                "qml/DatenbankSeite.qml",
            ],
            ..Default::default()
        })
        // Bridge-Datei: enthält #[cxx_qt::bridge]
        .file("src/bridge.rs")
        .build();
}
