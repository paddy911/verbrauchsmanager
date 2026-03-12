// qml/EingabeSeite.qml
// ─────────────────────────────────────────────────────────────────────────────
// Wiederverwendbare Eingabe-Seite für Strom, Wasser und Gas.
// Enthält:  - Eingabeformular (Datum, Wert, Notiz)
//           - Statistik-Kachel (Summe, Anzahl Einträge)
//           - Tabelle aller vorhandenen Einträge
//           - Löschen-Funktion pro Zeile
// ─────────────────────────────────────────────────────────────────────────────

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: seite

    // ── Öffentliche Properties ────────────────────────────────────────────────
    required property color  akzentFarbe
    required property string symbol
    required property string label
    required property string einheit
    required property var    tabellenDaten    // QStringList
    required property double summenwert
    required property int    anzahlEintraege

    // ── Signale ───────────────────────────────────────────────────────────────
    signal eintragHinzufuegen(string datum, double wert, string notiz)
    signal eintragLoeschen(int id)

    // ── Farben ────────────────────────────────────────────────────────────────
    readonly property color hintergrund: "#F4F6F9"
    readonly property color karteHg:    "#FFFFFF"
    readonly property color grauBorder: "#E2E8F0"
    readonly property color textDunkel: "#1E293B"
    readonly property color textGrau:   "#64748B"

    // ── Layout ────────────────────────────────────────────────────────────────
    RowLayout {
        anchors { fill: parent; margins: 20 }
        spacing: 20

        // ── Linke Spalte: Eingabe + Statistik ─────────────────────────────────
        ColumnLayout {
            Layout.preferredWidth: 320
            Layout.fillHeight: true
            spacing: 16

            // Eingabe-Karte
            Rectangle {
                Layout.fillWidth: true
                height: eingabeLayout.implicitHeight + 32
                color:  seite.karteHg
                radius: 12
                border.color: seite.grauBorder

                // Farbstreifen oben
                Rectangle {
                    anchors { top: parent.top; left: parent.left; right: parent.right }
                    height: 4
                    radius: 12
                    color:  seite.akzentFarbe
                }

                ColumnLayout {
                    id: eingabeLayout
                    anchors { fill: parent; margins: 16; topMargin: 20 }
                    spacing: 12

                    // Überschrift
                    RowLayout {
                        Text {
                            text: seite.symbol
                            font.pixelSize: 28
                        }
                        Text {
                            text:  seite.label + " erfassen"
                            font { pixelSize: 18; bold: true }
                            color: seite.textDunkel
                        }
                    }

                    // Datum
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4
                        Text {
                            text: "Datum (JJJJ-MM-TT)"
                            font.pixelSize: 12
                            color: seite.textGrau
                        }
                        TextField {
                            id: datumFeld
                            Layout.fillWidth: true
                            placeholderText: Qt.formatDate(new Date(), "yyyy-MM-dd")
                            text: Qt.formatDate(new Date(), "yyyy-MM-dd")
                            font.pixelSize: 14
                            leftPadding: 10
                            background: Rectangle {
                                radius: 6
                                color:  datumFeld.activeFocus ? "#F0F9FF" : "#F8FAFC"
                                border.color: datumFeld.activeFocus
                                    ? seite.akzentFarbe : seite.grauBorder
                            }
                        }
                    }

                    // Wert
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4
                        Text {
                            text: "Verbrauch (" + seite.einheit + ")"
                            font.pixelSize: 12
                            color: seite.textGrau
                        }
                        TextField {
                            id: wertFeld
                            Layout.fillWidth: true
                            placeholderText: "0.000"
                            inputMethodHints: Qt.ImhFormattedNumbersOnly
                            validator: DoubleValidator { bottom: 0; decimals: 4 }
                            font.pixelSize: 14
                            leftPadding: 10
                            background: Rectangle {
                                radius: 6
                                color:  wertFeld.activeFocus ? "#F0F9FF" : "#F8FAFC"
                                border.color: wertFeld.activeFocus
                                    ? seite.akzentFarbe : seite.grauBorder
                            }
                        }
                    }

                    // Notiz
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4
                        Text {
                            text: "Notiz (optional)"
                            font.pixelSize: 12
                            color: seite.textGrau
                        }
                        TextField {
                            id: notizFeld
                            Layout.fillWidth: true
                            placeholderText: "z.B. Ablesung Keller"
                            font.pixelSize: 14
                            leftPadding: 10
                            background: Rectangle {
                                radius: 6
                                color:  notizFeld.activeFocus ? "#F0F9FF" : "#F8FAFC"
                                border.color: notizFeld.activeFocus
                                    ? seite.akzentFarbe : seite.grauBorder
                            }
                        }
                    }

                    // Speichern-Button
                    Button {
                        Layout.fillWidth: true
                        height: 44
                        enabled: wertFeld.text.length > 0 && datumFeld.text.length === 10

                        contentItem: Text {
                            text:  "💾  " + seite.label + " speichern"
                            color: "white"
                            font { pixelSize: 14; bold: true }
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment:   Text.AlignVCenter
                        }
                        background: Rectangle {
                            radius: 8
                            color: parent.enabled
                                ? (parent.pressed ? Qt.darker(seite.akzentFarbe, 1.2)
                                    : seite.akzentFarbe)
                                : "#CBD5E1"
                            Behavior on color { ColorAnimation { duration: 100 } }
                        }

                        onClicked: {
                            let w = parseFloat(wertFeld.text.replace(",", "."))
                            if (isNaN(w) || w < 0) return
                            seite.eintragHinzufuegen(datumFeld.text, w, notizFeld.text)
                            wertFeld.text  = ""
                            notizFeld.text = ""
                        }
                    }
                }
            }

            // Statistik-Karte
            Rectangle {
                Layout.fillWidth: true
                height: statLayout.implicitHeight + 24
                color:  seite.karteHg
                radius: 12
                border.color: seite.grauBorder

                ColumnLayout {
                    id: statLayout
                    anchors { fill: parent; margins: 16 }
                    spacing: 10

                    Text {
                        text: "📊 Statistik"
                        font { pixelSize: 15; bold: true }
                        color: seite.textDunkel
                    }

                    // Gesamtverbrauch
                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text:  "Gesamt:"
                            font.pixelSize: 13
                            color: seite.textGrau
                            Layout.fillWidth: true
                        }
                        Text {
                            text:  seite.summenwert.toFixed(3) + " " + seite.einheit
                            font { pixelSize: 16; bold: true }
                            color: seite.akzentFarbe
                        }
                    }

                    // Anzahl
                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text:  "Einträge:"
                            font.pixelSize: 13
                            color: seite.textGrau
                            Layout.fillWidth: true
                        }
                        Text {
                            text:  seite.anzahlEintraege
                            font { pixelSize: 15; bold: true }
                            color: seite.textDunkel
                        }
                    }
                }
            }

            Item { Layout.fillHeight: true }
        }

        // ── Rechte Spalte: Tabelle ─────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth:  true
            Layout.fillHeight: true
            color:  seite.karteHg
            radius: 12
            border.color: seite.grauBorder
            clip: true

            ColumnLayout {
                anchors { fill: parent; margins: 0 }
                spacing: 0

                // Tabellen-Kopf
                Rectangle {
                    Layout.fillWidth: true
                    height: 44
                    color:  seite.akzentFarbe
                    radius: 12

                    // Nur oben abgerundet
                    Rectangle {
                        anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
                        height: 12
                        color:  seite.akzentFarbe
                    }

                    RowLayout {
                        anchors { fill: parent; leftMargin: 16; rightMargin: 16 }
                        spacing: 0

                        Repeater {
                            model: [
                                { text: "Datum",                        breite: 120 },
                                { text: "Verbrauch (" + seite.einheit + ")", breite: 130 },
                                { text: "Notiz",                        breite: -1 },
                                { text: "Aktion",                       breite: 80 },
                            ]
                            delegate: Text {
                                Layout.preferredWidth:  modelData.breite > 0 ? modelData.breite : -1
                                Layout.fillWidth:       modelData.breite < 0
                                text:  modelData.text
                                font { pixelSize: 13; bold: true }
                                color: "white"
                                elide: Text.ElideRight
                            }
                        }
                    }
                }

                // Tabellen-Inhalt
                ListView {
                    id: tabelle
                    Layout.fillWidth:  true
                    Layout.fillHeight: true
                    clip: true
                    model: seite.tabellenDaten

                    ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                    // Leer-Zustand
                    Text {
                        anchors.centerIn: parent
                        text: "Noch keine Einträge vorhanden.\nFügen Sie oben einen neuen Eintrag hinzu."
                        horizontalAlignment: Text.AlignHCenter
                        color: seite.textGrau
                        font.pixelSize: 14
                        visible: tabelle.count === 0
                        lineHeight: 1.6
                    }

                    delegate: Rectangle {
                        width:  tabelle.width
                        height: 42
                        color:  index % 2 === 0 ? "white" : "#F8FAFC"

                        // Trennlinie
                        Rectangle {
                            anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
                            height: 1
                            color:  seite.grauBorder
                        }

                        // Hover-Effekt
                        Rectangle {
                            anchors.fill: parent
                            color: "#EFF6FF"
                            opacity: maArea.containsMouse ? 1 : 0
                            Behavior on opacity { NumberAnimation { duration: 100 } }
                        }
                        MouseArea { id: maArea; anchors.fill: parent; hoverEnabled: true }

                        // Daten parsen: "id|datum|wert einheit|notiz"
                        property var teile: modelData.split("|")
                        property string eintragsId:    teile.length > 0 ? teile[0] : "0"
                        property string eintagsDatum:  teile.length > 1 ? teile[1] : ""
                        property string eintragsWert:  teile.length > 2 ? teile[2] : ""
                        property string eintragsNotiz: teile.length > 3 ? teile[3] : ""

                        RowLayout {
                            anchors { fill: parent; leftMargin: 16; rightMargin: 16 }
                            spacing: 0

                            Text {
                                Layout.preferredWidth: 120
                                text:  eintagsDatum
                                font.pixelSize: 13
                                color: seite.textDunkel
                                elide: Text.ElideRight
                            }
                            Text {
                                Layout.preferredWidth: 130
                                text:  eintragsWert
                                font { pixelSize: 13; bold: true }
                                color: seite.akzentFarbe
                                elide: Text.ElideRight
                            }
                            Text {
                                Layout.fillWidth: true
                                text:  eintragsNotiz
                                font.pixelSize: 13
                                color: seite.textGrau
                                elide: Text.ElideRight
                            }
                            // Löschen-Button
                            Button {
                                Layout.preferredWidth: 72
                                height: 28
                                contentItem: Text {
                                    text:  "🗑 Löschen"
                                    font.pixelSize: 11
                                    color: "white"
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment:   Text.AlignVCenter
                                }
                                background: Rectangle {
                                    radius: 6
                                    color: parent.pressed ? "#B91C1C" : "#EF4444"
                                    Behavior on color { ColorAnimation { duration: 100 } }
                                }
                                onClicked: {
                                    seite.eintragLoeschen(parseInt(eintragsId))
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
