import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

ColumnLayout {
    id: root
    property var model: []
    property bool multi: false
    property var initialSelection: []
    property var checkedLabels: []
    signal selectionChanged()

    function selectionLabels() {
        return checkedLabels.slice();
    }

    function selectionLabel() {
        return checkedLabels.length ? checkedLabels[0] : "";
    }

    Component.onCompleted: {
        if (!initialSelection || initialSelection.length === undefined) {
            if (initialSelection) {
                checkedLabels = [initialSelection];
            }
        } else if (initialSelection.length > 0) {
            checkedLabels = initialSelection;
        }
        if (!multi && checkedLabels.length === 0 && model && model.length > 0) {
            var first = model[0];
            var label = first.label !== undefined ? first.label : first;
            checkedLabels = [label];
        }
    }

    Repeater {
        model: root.model
        delegate: multi ? CheckBox {
            text: modelData.label
            checked: root.checkedLabels.indexOf(modelData.label) !== -1
            onClicked: {
                var copy = root.checkedLabels.slice();
                var pos = copy.indexOf(modelData.label);
                if (checked) {
                    if (pos === -1) copy.push(modelData.label);
                } else {
                    if (pos !== -1) copy.splice(pos, 1);
                }
                root.checkedLabels = copy;
                root.selectionChanged();
            }
        } : RadioButton {
            text: modelData.label
            checked: root.checkedLabels.length === 0 ? (index === 0) : root.checkedLabels[0] === modelData.label
            onClicked: {
                root.checkedLabels = [modelData.label];
                root.selectionChanged();
            }
        }
    }
}
