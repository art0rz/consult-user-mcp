import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "components"
import QtQuick.Window 2.15

Window {
    id: root
    width: 520
    height: 460
    visible: true
    title: cliPayload.title ? cliPayload.title : "Consult MCP"
    flags: Qt.Window | Qt.WindowStaysOnTopHint
    color: "#1c1c1e"

    property string command: cliCommand
    property var payload: cliPayload
    property int timeoutMs: 600000 // 10 minutes

    Component.onCompleted: {
        positionWindow();
        if (command === "notify") {
            finish({ success: true });
        } else if (command === "tts") {
            finish({ success: true });
        } else if (command === "questions") {
            finish({ answers: {}, cancelled: true, completedCount: 0 });
        }
    }

    Timer {
        interval: root.timeoutMs
        running: true
        repeat: false
        onTriggered: finish({ cancelled: true, dismissed: true })
    }

    onClosing: function() {
        finish({ cancelled: true, dismissed: true })
    }

    function finish(obj) {
        var payload = obj || {};
        if (payload.cancelled === undefined) payload.cancelled = false;
        resultEmitter.emitJson(JSON.stringify(payload));
    }

    function positionWindow() {
        var pos = payload.position ? payload.position : "center";
        var geom = root.screen ? root.screen.availableGeometry : Qt.application.screens[0].availableGeometry;
        var x = geom.x + (geom.width - width) / 2;
        if (pos === "left") {
            x = geom.x + 40;
        } else if (pos === "right") {
            x = geom.x + geom.width - width - 40;
        }
        var y = geom.y + 80;
        root.x = x;
        root.y = y;
    }

    Loader {
        id: loader
        anchors.fill: parent
        sourceComponent: {
            switch (command) {
            case "confirm":
                return confirmComponent
            case "choose":
                return chooseComponent
            case "textInput":
                return textInputComponent
            case "questions":
                return questionsComponent
            default:
                return fallbackComponent
            }
        }
    }

    Component {
        id: confirmComponent
        ConfirmDialog {
            payload: root.payload
            onAnswered: function(obj) { finish(obj) }
        }
    }

    Component {
        id: chooseComponent
        ChooseDialog {
            payload: root.payload
            onAnswered: function(obj) { finish(obj) }
        }
    }

    Component {
        id: textInputComponent
        TextInputDialog {
            payload: root.payload
            onAnswered: function(obj) { finish(obj) }
        }
    }

    Component {
        id: questionsComponent
        QuestionsDialog {
            payload: root.payload
            onAnswered: function(obj) { finish(obj) }
        }
    }

    Component {
        id: fallbackComponent
        Rectangle {
            color: "#1c1c1e"
            Text {
                anchors.centerIn: parent
                color: "white"
                text: "Unsupported command: " + command
            }
        }
    }
}
