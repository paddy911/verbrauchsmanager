// qml/main.qml
// ─────────────────────────────────────────────────────────────────────────────
// Hauptfenster des Verbrauchsmanagers.
// Enthält eine TabBar mit den Bereichen:
//   • Strom / Wasser / Gas (Eingabe + Tabelle)
//   • Datenbank (Pfad, Statistik, Export)
// ─────────────────────────────────────────────────────────────────────────────

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import com.verbrauchsmanager 1.0

ApplicationWindow {
    id:      fenster
    title:   "⚡ Verbrauchsmanager – Strom · Wasser · Gas"
    width:   1100
    height:  720
    minimumWidth:  900
    minimumHeight: 600
    visible: true

    // ── Farbpalette ───────────────────────────────────────────────────────────
    readonly property color blauDunkel:  "#1A2744"
    readonly property color blauMittel: "#2E86AB"
    readonly property color blauHell:   "#A8DADC"
    readonly property color gruenAkzent:"#52B788"
    readonly property color rotAkzent:  "#E63946"
    readonly property color hintergrund:"#F4F6F9"
    readonly property color weiss:      "#FFFFFF"
    readonly property color grauText:   "#6B7280"
    readonly property color stromFarbe: "#F4A261"   // Orange
    readonly property color wasserFarbe:"#457B9D"   // Blau
    readonly property color gasFarbe:   "#95D5B2"   // Grün

    // ── Backend-Objekt (Rust/Qt) ──────────────────────────────────────────────
    VerbrauchsManager {
        id: manager
        Component.onCompleted: manager.initialisieren()
    }

    // ── Hintergrund ───────────────────────────────────────────────────────────
    background: Rectangle { color: fenster.hintergrund }

    // ── Titelleiste ───────────────────────────────────────────────────────────
    header: Rectangle {
        height: 60
        color:  fenster.blauDunkel

        RowLayout {
            anchors { fill: parent; leftMargin: 20; rightMargin: 20 }

            Text {
                text:  "⚡ Verbrauchsmanager"
                font { pixelSize: 22; bold: true }
                color: fenster.weiss
            }
            Item { Layout.fillWidth: true }
            Text {
                text:  "v1.0"
                font.pixelSize: 13
                color: fenster.blauHell
            }
        }
    }

    // ── Hauptlayout ───────────────────────────────────────────────────────────
    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // ── Tab-Leiste ────────────────────────────────────────────────────────
        TabBar {
            id:          tabs
            Layout.fillWidth: true
            background:  Rectangle { color: fenster.blauDunkel }

            TabButton {
                text: "⚡  Strom"
                font.pixelSize: 14
                contentItem: Text {
                    text:  parent.text
                    font:  parent.font
                    color: parent.checked ? fenster.stromFarbe : "#AAAAAA"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment:   Text.AlignVCenter
                }
                background: Rectangle {
                    color: parent.checked ? Qt.rgba(1,1,1,0.1) : "transparent"
                    Rectangle {
                        anchors.bottom: parent.bottom
                        width: parent.width; height: 3
                        color:   fenster.stromFarbe
                        visible: parent.parent.checked
                    }
                }
            }
            TabButton {
                text: "💧  Wasser"
                font.pixelSize: 14
                contentItem: Text {
                    text:  parent.text
                    font:  parent.font
                    color: parent.checked ? fenster.wasserFarbe : "#AAAAAA"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment:   Text.AlignVCenter
                }
                background: Rectangle {
                    color: parent.checked ? Qt.rgba(1,1,1,0.1) : "transparent"
                    Rectangle {
                        anchors.bottom: parent.bottom
                        width: parent.width; height: 3
                        color:   fenster.wasserFarbe
                        visible: parent.parent.checked
                    }
                }
            }
            TabButton {
                text: "🔥  Gas"
                font.pixelSize: 14
                contentItem: Text {
                    text:  parent.text
                    font:  parent.font
                    color: parent.checked ? fenster.gasFarbe : "#AAAAAA"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment:   Text.AlignVCenter
                }
                background: Rectangle {
                    color: parent.checked ? Qt.rgba(1,1,1,0.1) : "transparent"
                    Rectangle {
                        anchors.bottom: parent.bottom
                        width: parent.width; height: 3
                        color:   fenster.gasFarbe
                        visible: parent.parent.checked
                    }
                }
            }
            TabButton {
                text: "🗄️  Datenbank"
                font.pixelSize: 14
                contentItem: Text {
                    text:  parent.text
                    font:  parent.font
                    color: parent.checked ? fenster.blauHell : "#AAAAAA"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment:   Text.AlignVCenter
                }
                background: Rectangle {
                    color: parent.checked ? Qt.rgba(1,1,1,0.1) : "transparent"
                    Rectangle {
                        anchors.bottom: parent.bottom
                        width: parent.width; height: 3
                        color:   fenster.blauHell
                        visible: parent.parent.checked
                    }
                }
            }
        }

        // ── Tab-Inhalte ───────────────────────────────────────────────────────
        StackLayout {
            Layout.fillWidth:  true
            Layout.fillHeight: true
            currentIndex:      tabs.currentIndex

            // Tab 0: Strom
            EingabeSeite {
                akzentFarbe:  fenster.stromFarbe
                symbol:       "⚡"
                label:        "Strom"
                einheit:      "kWh"
                tabellenDaten: manager.stromTabelle
                onEintragHinzufuegen: (datum, wert, notiz) =>
                    manager.stromHinzufuegen(datum, wert, notiz)
                onEintragLoeschen: (id) => manager.stromLoeschen(id)
                summenwert:   manager.stromSumme
                anzahlEintraege: manager.stromAnzahl
            }

            // Tab 1: Wasser
            EingabeSeite {
                akzentFarbe:  fenster.wasserFarbe
                symbol:       "💧"
                label:        "Wasser"
                einheit:      "m³"
                tabellenDaten: manager.wasserTabelle
                onEintragHinzufuegen: (datum, wert, notiz) =>
                    manager.wasserHinzufuegen(datum, wert, notiz)
                onEintragLoeschen: (id) => manager.wasserLoeschen(id)
                summenwert:   manager.wasserSumme
                anzahlEintraege: manager.wasserAnzahl
            }

            // Tab 2: Gas
            EingabeSeite {
                akzentFarbe:  fenster.gasFarbe
                symbol:       "🔥"
                label:        "Gas"
                einheit:      "m³"
                tabellenDaten: manager.gasTabelle
                onEintragHinzufuegen: (datum, wert, notiz) =>
                    manager.gasHinzufuegen(datum, wert, notiz)
                onEintragLoeschen: (id) => manager.gasLoeschen(id)
                summenwert:   manager.gasSumme
                anzahlEintraege: manager.gasAnzahl
            }

            // Tab 3: Datenbank
            DatenbankSeite {
                dbPfad:       manager.dbPfad
                dbGroesseKb:  manager.dbGroesseKb
                stromSumme:   manager.stromSumme
                wasserSumme:  manager.wasserSumme
                gasSumme:     manager.gasSumme
                stromAnzahl:  manager.stromAnzahl
                wasserAnzahl: manager.wasserAnzahl
                gasAnzahl:    manager.gasAnzahl
                onNeueDb:         (pfad) => manager.neueDatenbankErstellen(pfad)
                onDbOeffnen:      (pfad) => manager.datenbankOeffnen(pfad)
                onExportCsv:      (pfad) => manager.exportCsv(pfad)
                onExportXlsx:     (pfad) => manager.exportXlsx(pfad)
            }
        }

        // ── Statusleiste ──────────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            height: 32
            color:  manager.hatFehler ? "#FEECEC" : "#EDFDF4"
            border.color: manager.hatFehler ? fenster.rotAkzent : fenster.gruenAkzent
            border.width: 1

            RowLayout {
                anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
                Text {
                    text:  manager.statusMeldung
                    color: manager.hatFehler ? fenster.rotAkzent : "#1B6B3A"
                    font.pixelSize: 13
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }
                Text {
                    text:  "DB: " + manager.dbPfad
                    color: fenster.grauText
                    font.pixelSize: 11
                    elide: Text.ElideLeft
                    Layout.maximumWidth: 400
                }
            }
        }
    }
}
