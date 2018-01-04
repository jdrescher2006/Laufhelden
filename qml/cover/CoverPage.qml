/*
 * Copyright (C) 2017 Jens Drescher, Germany
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

import QtQuick 2.0
import Sailfish.Silica 1.0
import "../tools/JSTools.js" as JSTools

CoverBackground
{   
    Image
    {
        anchors.margins: Theme.paddingMedium
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.right: parent.right
        fillMode: Image.PreserveAspectFit
        opacity: 0.2
        source: "../laufhelden.png"
    }

    Column
    {
        anchors.top: parent.top
        width: parent.width
        Label
        {
            anchors.horizontalCenter: parent.horizontalCenter
            text: !recorder.running ? qsTr("Stopped") : (recorder.pause ? qsTr("Paused") : qsTr("Recording"))
            font.pixelSize: Theme.fontSizeLarge
        }
        Label
        {
            anchors.horizontalCenter: parent.horizontalCenter
            text: (settings.measureSystem === 0) ? (recorder.distance/1000).toFixed(2) + " km" : JSTools.fncConvertDistanceToImperial(recorder.distance/1000).toFixed(2) + " mi";
            font.pixelSize: Theme.fontSizeMedium
        }
        Label
        {
            anchors.horizontalCenter: parent.horizontalCenter
            text: recorder.time
            font.pixelSize: Theme.fontSizeMedium
        }
        Label
        {
            anchors.horizontalCenter: parent.horizontalCenter
            text: sHeartRate + qsTr(" bpm")
            //visible: sHRMAddress !== "" && settings.useHRMdevice
            font.pixelSize: Theme.fontSizeMedium
        }
    }

    CoverActionList
    {
        id: coverAction
        enabled: recorder.running
        CoverAction
        {
            iconSource: !recorder.pause ? "image://theme/icon-cover-pause" : "image://theme/icon-cover-play"
            onTriggered: recorder.pause = !recorder.pause
        }
    }
}
