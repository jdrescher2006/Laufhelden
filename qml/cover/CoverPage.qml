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
    Timer
    {
        id: idTimerUpdateCycleCoverPage
        interval: 1000
        repeat: true
        running: recorder.running
        onTriggered:
        {
            id_LBL_Value1.text = (settings.measureSystem === 0) ? JSTools.arrayLookupCoverPageValueTypesByFieldID[1].value + JSTools.arrayLookupCoverPageValueTypesByFieldID[1].unit :
                                                                  JSTools.arrayLookupCoverPageValueTypesByFieldID[1].value + JSTools.arrayLookupCoverPageValueTypesByFieldID[1].imperialUnit;
            id_LBL_Value2.text = (settings.measureSystem === 0) ? JSTools.arrayLookupCoverPageValueTypesByFieldID[2].value + JSTools.arrayLookupCoverPageValueTypesByFieldID[2].unit :
                                                                  JSTools.arrayLookupCoverPageValueTypesByFieldID[2].value + JSTools.arrayLookupCoverPageValueTypesByFieldID[2].imperialUnit;
            id_LBL_Value3.text = (settings.measureSystem === 0) ? JSTools.arrayLookupCoverPageValueTypesByFieldID[3].value + JSTools.arrayLookupCoverPageValueTypesByFieldID[3].unit :
                                                                  JSTools.arrayLookupCoverPageValueTypesByFieldID[3].value + JSTools.arrayLookupCoverPageValueTypesByFieldID[3].imperialUnit;
        }
    }

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


    Item
    {
        anchors.top: parent.top
        width: parent.width
        height: parent.height * 0.2

        Label
        {
            anchors.verticalCenter: parent.verticalCenter
            anchors.horizontalCenter: parent.horizontalCenter
            text: !recorder.running ? qsTr("Stopped") : (recorder.pause ? qsTr("Paused") : qsTr("Recording"))
            fontSizeMode: Theme.fontSizeMedium
        }
    }

    Item
    {
        anchors.verticalCenter: parent.verticalCenter
        height: parent.height * 0.6
        width: parent.width

        Item
        {
            height: parent.height * 0.333
            width: parent.width
            anchors.top: parent.top

            Text
            {
                color: Theme.highlightColor
                id: id_LBL_Value1
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                anchors.centerIn: parent
                fontSizeMode: Text.Fit
                font.pointSize: 4000
            }
        }
        Item
        {
            height: parent.height * 0.333
            width: parent.width
            anchors.verticalCenter: parent.verticalCenter

            Text
            {
                color: Theme.highlightColor
                id: id_LBL_Value2
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                anchors.centerIn: parent
                fontSizeMode: Text.Fit
                font.pointSize: 4000
            }
        }
        Item
        {
            height: parent.height * 0.333
            width: parent.width
            anchors.bottom: parent.bottom

            Text
            {
                color: Theme.highlightColor
                id: id_LBL_Value3
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                anchors.centerIn: parent
                fontSizeMode: Text.Fit
                font.pointSize: 4000
            }
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
