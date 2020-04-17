import QtQuick 2.0
import Sailfish.Silica 1.0

Item {
    property alias label: label.text
    property alias value: value.text
    property alias leftPadding: label.leftPadding
    anchors.left: parent.left
    anchors.right: parent.right
    height: value.height
    Label {
        id: label
        color: Theme.secondaryColor
        text: "Label"
        rightPadding: Theme.paddingSmall
    }
    Label {
        id: value
        anchors.left: label.right
        color: Theme.primaryColor
        text: "Value"
    }
}
