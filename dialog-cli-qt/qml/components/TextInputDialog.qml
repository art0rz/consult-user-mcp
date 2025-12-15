import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "./"

Rectangle {
    id: root
    focus: true
    Keys.onPressed: {
        if (event.key === Qt.Key_S) {
            toolbar.snoozeExpanded = !toolbar.snoozeExpanded;
            toolbar.feedbackExpanded = false;
            event.accepted = true;
        } else if (event.key === Qt.Key_F) {
            toolbar.feedbackExpanded = !toolbar.feedbackExpanded;
            toolbar.snoozeExpanded = false;
            event.accepted = true;
        }
    }
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

        Toolbar {
            id: toolbar
            Layout.fillWidth: true
            onSnoozeRequested: function(minutes) {
                answered({ text: null, cancelled: false, comment: null, snoozed: true, snoozeMinutes: minutes, instruction: "Set a timer for " + minutes + " minute" + (minutes === 1 ? "" : "s") + " and re-ask this question when it fires." })
            }
            onFeedbackSubmitted: function(text) {
                answered({ text: null, cancelled: false, comment: null, feedbackText: text })
            }
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
