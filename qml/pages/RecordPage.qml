/*
    Copyright 2014 Simo Mattila
    simo.h.mattila@gmail.com

    This file is part of Rena.

    Rena is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    any later version.

    Rena is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with Rena.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.0
import Sailfish.Silica 1.0


Page {
    id: page

    onStatusChanged: {
        if (status === PageStatus.Active) {
            pageStack.pushAttached(Qt.resolvedUrl("HistoryPage.qml"), {})
        }
    }

    function showSaveDialog() {
        var dialog = pageStack.push(Qt.resolvedUrl("SaveDialog.qml"));
        dialog.accepted.connect(function() {
            console.log("Saving track");
            recorder.exportGpx(dialog.name, dialog.description);
            recorder.clearTrack();  // TODO: Make sure save was successful?
        })
    }

    SilicaFlickable {
        anchors.fill: parent

        PullDownMenu {
            MenuItem {
                text: qsTr("About Rena")
                onClicked: pageStack.push(Qt.resolvedUrl("AboutPage.qml"))
            }
            MenuItem {
                text: qsTr("Start new recording")
                visible: !recorder.tracking
                onClicked: {
                    recorder.clearTrack();
                    recorder.tracking = true;
                }
            }
            MenuItem {
                text: qsTr("Continue recording")
                visible: !recorder.tracking && !recorder.isEmpty
                onClicked: recorder.tracking = true
            }
            MenuItem {
                text: qsTr("Save track")
                visible: !recorder.tracking && !recorder.isEmpty
                onClicked: showSaveDialog()
            }
            MenuItem {
                text: qsTr("Stop recording")
                visible: recorder.tracking
                onClicked: {
                    recorder.tracking = false;
                    if(!recorder.isEmpty) {
                        showSaveDialog();
                    }
                }
            }
        }

        contentHeight: column.height

        Column {
            id: column
            width: page.width
            spacing: Theme.paddingLarge
            PageHeader {
                title: "Rena"
            }
            Label {
                anchors.horizontalCenter: parent.horizontalCenter
                text: recorder.tracking ? qsTr("Recording") : qsTr("Stopped")
                font.pixelSize: Theme.fontSizeLarge
            }
            Label {
                anchors.horizontalCenter: parent.horizontalCenter
                text: (recorder.distance/1000).toFixed(3) + " km"
                font.pixelSize: Theme.fontSizeHuge
            }
            Label {
                anchors.horizontalCenter: parent.horizontalCenter
                text: recorder.time
                font.pixelSize: Theme.fontSizeHuge
            }
            Label {
                anchors.horizontalCenter: parent.horizontalCenter
                text: recorder.accuracy < 0 ? "No position" :
                                              (recorder.accuracy < 30
                                               ? qsTr("Accuracy: ") + recorder.accuracy.toFixed(1) + "m"
                                               : qsTr("Accuracy too low: ") + recorder.accuracy.toFixed(1) + "m")
            }
        }
    }
}
