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

    property bool multi: payload.allowMultiple === undefined ? true : payload.allowMultiple
    property int selectedIndex: -1
    property var selectedSet: []

    function toggle(idx) {
        if (multi) {
            var copy = selectedSet.slice();
            var pos = copy.indexOf(idx);
            if (pos === -1) copy.push(idx); else copy.splice(pos, 1);
            selectedSet = copy;
        } else {
            selectedIndex = idx;
        }
    }

    Component.onCompleted: {
        if (!multi && payload.defaultSelection && payload.choices) {
            var idx = payload.choices.indexOf(payload.defaultSelection);
            if (idx >= 0) selectedIndex = idx;
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        Label {
            text: payload.prompt || "Choose"
            color: "white"
            wrapMode: Text.WordWrap
            font.pixelSize: 16
        }

        Toolbar {
            id: toolbar
            Layout.fillWidth: true
            onSnoozeRequested: function(minutes) {
                answered({ selected: null, cancelled: false, description: null, descriptions: null, comment: null, snoozed: true, snoozeMinutes: minutes, instruction: "Set a timer for " + minutes + " minute" + (minutes === 1 ? "" : "s") + " and re-ask this question when it fires." })
            }
            onFeedbackSubmitted: function(text) {
                answered({ selected: null, cancelled: false, description: null, descriptions: null, comment: null, feedbackText: text })
            }
        }
        ListView {
            id: listView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: payload.choices || []
            delegate: ItemDelegate {
                width: listView.width
                text: modelData
                font.pixelSize: 14
                checkable: multi
                checked: multi ? root.selectedSet.indexOf(index) !== -1 : root.selectedIndex === index
                onClicked: {
                    root.toggle(index)
                }
            }
        }

        RowLayout {
            spacing: 12
            Button {
                text: "Cancel"
                Layout.fillWidth: true
                onClicked: answered({ selected: null, cancelled: true, description: null, comment: null })
            }
            Button {
                text: "OK"
                Layout.fillWidth: true
                onClicked: {
                    if (multi) {
                        var arr = selectedSet.slice().sort(function(a,b){return a-b}).map(function(idx){ return payload.choices[idx]; });
                        answered({ selected: arr.length ? arr : null, cancelled: !arr.length, description: null, descriptions: null, comment: null })
                    } else {
                        if (selectedIndex === -1) {
                            answered({ selected: null, cancelled: true, description: null, comment: null })
                        } else {
                            var choice = payload.choices[selectedIndex]
                            var desc = payload.descriptions && payload.descriptions.length > selectedIndex ? payload.descriptions[selectedIndex] : null
                            answered({ selected: choice, cancelled: false, description: desc, comment: null })
                        }
                    }
                }
            }
        }
    }
}
