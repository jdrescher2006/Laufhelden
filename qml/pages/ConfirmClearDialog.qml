import QtQuick 2.0
import Sailfish.Silica 1.0

Dialog {
    allowedOrientations: Orientation.Portrait

    Column {
        anchors.fill: parent
        DialogHeader {
            title: "Start a new track"
            acceptText: "Start"
        }
    }

    Label {
        anchors.centerIn: parent
        width: parent.width - 2*Theme.paddingLarge
        text: qsTr("Clear unsaved track and start a new one?")
        wrapMode: Text.WordWrap
        horizontalAlignment: Text.AlignHCenter
        font.pixelSize: Theme.fontSizeHuge
        color: Theme.highlightColor
    }
}
