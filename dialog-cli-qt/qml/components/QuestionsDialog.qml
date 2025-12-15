import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "./"

Rectangle {
    id: root
    anchors.fill: parent
    color: "#1c1c1e"
    radius: 10
    property var payload
    signal answered(var result)

    property var questions: payload.questions || []
    property string mode: payload.mode || "wizard"
    property int currentIndex: 0
    property var answers: ({})

    function recordAnswer(idx, value) {
        if (!questions || idx >= questions.length || idx < 0) return;
        var q = questions[idx];
        answers[q.id] = value;
    }

    function completedCount() {
        var c = 0;
        for (var i = 0; i < questions.length; i++) {
            var q = questions[i];
            if (answers[q.id] !== undefined && answers[q.id] !== null) {
                c += 1;
            }
        }
        return c;
    }

    function finishCancelled() {
        answered({ answers: {}, cancelled: true, completedCount: completedCount(), dismissed: false });
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        Label {
            text: "Questions"
            color: "white"
            font.pixelSize: 18
        }

        Loader {
            id: modeLoader
            Layout.fillWidth: true
            Layout.fillHeight: true
            sourceComponent: mode === "accordion" ? accordionComponent : wizardComponent
        }

        Toolbar {
            id: toolbar
            Layout.fillWidth: true
            onSnoozeRequested: function(minutes) {
                answered({ answers: {}, cancelled: false, completedCount: completedCount(), snoozed: true, snoozeMinutes: minutes, instruction: "Set a timer for " + minutes + " minute" + (minutes === 1 ? "" : "s") + " and re-ask these questions when it fires." })
            }
            onFeedbackSubmitted: function(text) {
                answered({ answers: {}, cancelled: false, completedCount: completedCount(), feedbackText: text })
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 12
            Button {
                text: "Cancel"
                Layout.fillWidth: true
                onClicked: finishCancelled()
            }
            Button {
                text: mode === "wizard" ? (currentIndex < questions.length - 1 ? "Next" : "Submit") : "Submit"
                Layout.fillWidth: true
                onClicked: {
                    if (mode === "wizard") {
                        if (currentIndex < questions.length - 1) {
                            wizardItem.saveStep();
                            currentIndex += 1;
                        } else {
                            wizardItem.saveStep();
                            answered({ answers: answers, cancelled: false, completedCount: completedCount() });
                        }
                    } else {
                        answered({ answers: answers, cancelled: false, completedCount: completedCount() });
                    }
                }
            }
        }
    }

    Component {
        id: wizardComponent
        Item {
            id: wizardItem
            anchors.fill: parent

            function saveStep() {
                var q = questions[currentIndex];
                if (!q) return;
                if (q.type === "text" || (q.options && q.options.length === 0)) {
                    recordAnswer(currentIndex, textField.text);
                } else if (q.multiSelect) {
                    recordAnswer(currentIndex, choiceList.selectionLabels());
                } else {
                    recordAnswer(currentIndex, choiceList.selectionLabel());
                }
            }

            ColumnLayout {
                anchors.fill: parent
                spacing: 10

                Label {
                    text: questions[currentIndex] ? questions[currentIndex].question : ""
                    color: "white"
                    wrapMode: Text.WordWrap
                    font.pixelSize: 16
                }

                Loader {
                    id: questionLoader
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    sourceComponent: (questions[currentIndex] && (questions[currentIndex].type === "text" || (questions[currentIndex].options && questions[currentIndex].options.length === 0))) ? textComponent : choiceComponent
                }
            }

            Component {
                id: choiceComponent
                ChoiceList {
                    id: choiceList
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    model: questions[currentIndex] ? questions[currentIndex].options : []
                    multi: questions[currentIndex] ? !!questions[currentIndex].multiSelect : false
                    initialSelection: answers[questions[currentIndex] ? questions[currentIndex].id : ""] || []
                    onSelectionChanged: {
                        if (multi) {
                            recordAnswer(currentIndex, selectionLabels());
                        } else {
                            recordAnswer(currentIndex, selectionLabel());
                        }
                    }
                }
            }

            Component {
                id: textComponent
                TextArea {
                    id: textField
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    placeholderText: questions[currentIndex] && questions[currentIndex].placeholder ? questions[currentIndex].placeholder : ""
                    color: "white"
                    wrapMode: TextArea.Wrap
                    text: answers[questions[currentIndex] ? questions[currentIndex].id : ""] || ""
                    onTextChanged: recordAnswer(currentIndex, text)
                }
            }
        }
    }

    Component {
        id: accordionComponent
        Flickable {
            contentWidth: parent.width
            contentHeight: column.implicitHeight
            clip: true
            ColumnLayout {
                id: column
                width: parent.width
                spacing: 8
                Repeater {
                    model: questions
                    delegate: GroupBox {
                        title: modelData.question
                        Layout.fillWidth: true
                        ColumnLayout {
                            anchors.margins: 8
                            anchors.fill: parent
                            spacing: 8
                            Loader {
                                id: questionLoader
                                Layout.fillWidth: true
                                sourceComponent: (modelData.type === "text" || (modelData.options && modelData.options.length === 0)) ? textBlock : choiceBlock
                            }
                        }
                    }
                }
            }

            Component {
                id: choiceBlock
                ChoiceList {
                    model: modelData.options
                    multi: modelData.multiSelect
                    initialSelection: answers[modelData.id] || []
                    onSelectionChanged: {
                        if (modelData.multiSelect) {
                            recordAnswer(index, selectionLabels());
                        } else {
                            recordAnswer(index, selectionLabel());
                        }
                    }
                }
            }

            Component {
                id: textBlock
                TextArea {
                    Layout.fillWidth: true
                    wrapMode: TextArea.Wrap
                    color: "white"
                    placeholderText: modelData.placeholder || ""
                    text: answers[modelData.id] || ""
                    onTextChanged: recordAnswer(index, text)
                }
            }
        }
    }
}
