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

        Toolbar {
            id: toolbar
            Layout.fillWidth: true
            onSnoozeRequested: function(minutes) {
                answered({ confirmed: false, cancelled: false, response: null, comment: null, snoozed: true, snoozeMinutes: minutes, instruction: "Set a timer for " + minutes + " minute" + (minutes === 1 ? "" : "s") + " and re-ask this question when it fires." })
            }
            onFeedbackSubmitted: function(text) {
                answered({ confirmed: false, cancelled: false, response: null, comment: null, feedbackText: text })
            }
        }
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
