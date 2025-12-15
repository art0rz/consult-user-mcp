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
        anchors.margins: 16
        spacing: 12

        Label {
            text: payload.title || "Input"
            color: "white"
            font.pixelSize: 18
        }

        Text {
            text: payload.prompt || ""
            color: "#dcdcdc"
            wrapMode: Text.WordWrap
            font.pixelSize: 14
        }

        TextField {
            id: inputField
            Layout.fillWidth: true
            text: payload.defaultValue || ""
            echoMode: payload.hidden ? TextInput.Password : TextInput.Normal
        }

        Item { Layout.fillHeight: true }

        RowLayout {
            spacing: 12
            Button {
                text: "Cancel"
                Layout.fillWidth: true
                onClicked: answered({ text: null, cancelled: true, comment: null })
            }
            Button {
                text: "OK"
                Layout.fillWidth: true
                onClicked: answered({ text: inputField.text, cancelled: false, comment: null })
            }
        }
    }
}
