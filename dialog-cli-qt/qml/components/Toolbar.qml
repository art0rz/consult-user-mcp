import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: toolbar
    color: "#2a2a2d"
    radius: 8
    border.color: "#3a3a3d"
    border.width: 1
    property int snoozeMinutes: 5
    property bool snoozeExpanded: false
    property bool feedbackExpanded: false
    property string feedbackText: ""
    signal snoozeRequested(int minutes)
    signal feedbackSubmitted(string text)

    implicitHeight: contentItem.implicitHeight + 12
    anchors.left: parent.left
    anchors.right: parent.right

    ColumnLayout {
        id: contentItem
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 8
        spacing: 8

        RowLayout {
            spacing: 8
            Button {
                text: snoozeExpanded ? "Close Snooze" : "Snooze"
                Layout.fillWidth: true
                onClicked: {
                    snoozeExpanded = !snoozeExpanded;
                    feedbackExpanded = false;
                }
            }
            Button {
                text: feedbackExpanded ? "Close Feedback" : "Feedback"
                Layout.fillWidth: true
                onClicked: {
                    feedbackExpanded = !feedbackExpanded;
                    snoozeExpanded = false;
                }
            }
        }

        Item {
            Layout.fillWidth: true
            visible: snoozeExpanded
            implicitHeight: visible ? 72 : 0

            ColumnLayout {
                anchors.fill: parent
                spacing: 6

                RowLayout {
                    spacing: 8
                    Label { text: "Minutes"; color: "white"; Layout.alignment: Qt.AlignVCenter }
                    Slider {
                        id: minutesSlider
                        Layout.fillWidth: true
                        from: 1; to: 60; stepSize: 1; value: toolbar.snoozeMinutes
                        onValueChanged: toolbar.snoozeMinutes = Math.round(value)
                    }
                    Label { text: toolbar.snoozeMinutes + "m"; color: "white"; Layout.alignment: Qt.AlignVCenter }
                }
                Button {
                    text: "Snooze"
                    Layout.alignment: Qt.AlignRight
                    onClicked: snoozeRequested(toolbar.snoozeMinutes)
                }
            }
        }

        Item {
            Layout.fillWidth: true
            visible: feedbackExpanded
            implicitHeight: visible ? 110 : 0

            ColumnLayout {
                anchors.fill: parent
                spacing: 6
                TextArea {
                    id: feedbackInput
                    Layout.fillWidth: true
                    Layout.preferredHeight: 70
                    color: "white"
                    placeholderText: "Feedback for the agent"
                    wrapMode: TextEdit.Wrap
                    text: toolbar.feedbackText
                    onTextChanged: toolbar.feedbackText = text
                }
                Button {
                    text: "Send Feedback"
                    Layout.alignment: Qt.AlignRight
                    enabled: feedbackInput.text.length > 0
                    onClicked: feedbackSubmitted(feedbackInput.text)
                }
            }
        }
    }
}
