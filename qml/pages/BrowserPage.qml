import QtQuick 2.0
import Sailfish.Silica 1.0

Page {
    id: browser
    visible: false
    //minimumHeight: 800
    //minimumWidth: 500
    //title: "Login"

    property url url: ""

    SilicaWebView {
        anchors.fill: parent
        url: browser.url
    }

    onStatusChanged: {
       // if (status == PageStatus.Deactivating) {
        //close.accepted = true
        //loginButton.enabled = true
    }
}
