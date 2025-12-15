import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: root
    anchors.fill: parent
    color: "#1c1c1e"
    radius: 10
    property var payload
    signal answered(var result)

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 24
        spacing: 16

        Label {
            text: payload.title || "Confirmation"
            font.pixelSize: 18
            color: "white"
            wrapMode: Text.WordWrap
        }

        Text {
            text: payload.message || ""
            color: "#dcdcdc"
            wrapMode: Text.WordWrap
            font.pixelSize: 14
        }

        Item { Layout.fillHeight: true }

        RowLayout {
            spacing: 12
            Button {
                text: payload.cancelLabel || "Cancel"
                Layout.fillWidth: true
                onClicked: answered({ confirmed: false, cancelled: false, response: payload.cancelLabel || "Cancel", comment: null })
            }
            Button {
                text: payload.confirmLabel || "OK"
                Layout.fillWidth: true
                onClicked: answered({ confirmed: true, cancelled: false, response: payload.confirmLabel || "OK", comment: null })
            }
        }
    }
}
