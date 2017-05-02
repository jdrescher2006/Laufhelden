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

Page
{
    allowedOrientations: Orientation.All
    property int iCountWhtRbbt: 1;

    SilicaFlickable
    {
        anchors.fill: parent
        contentHeight: id_Column_Main.height

        VerticalScrollDecorator {}

        Column
        {
            id: id_Column_Main

            anchors.top: parent.top
            width: parent.width

            PageHeader
            {
                title: qsTr("About Laufhelden")
            }
            Button
            {
                anchors.horizontalCenter: parent.horizontalCenter
                height: 256
                Image
                {
                    anchors.fill: parent
                    fillMode: Image.PreserveAspectFit
                    source: "../obdfish.png"
                }
                onClicked:
                {
                    if (iCountWhtRbbt == 1)
                        fncShowMessage(1,"The whole thing goes: The future's not set. There's no fate but what we make for ourselves.<br>John Connor", 6000);
                    else if (iCountWhtRbbt == 2)
                        fncShowMessage(1,"And it would die, to protect him. In an insane world, it was the sanest choice.<br>Sarah Connor", 6000);
                    else if (iCountWhtRbbt == 3)
                        fncShowMessage(1,"I know now why you cry but it's something that I can never do.<br>T-800", 6000);
                    else if (iCountWhtRbbt == 4)
                        fncShowMessage(1,"Fourth iteration: Inevitably, underlying instabilities begin to appear.<br>Ian Malcolm", 6000);
                    else if (iCountWhtRbbt == 5)
                        fncShowMessage(1,"Fifth iteration: Flaws in the system will now become severe.<br>Ian Malcolm", 6000);
                    else if (iCountWhtRbbt == 6)
                        fncShowMessage(1,"Sixth iteration: System recovery may prove impossible.<br>Ian Malcolm", 6000);
                    else if (iCountWhtRbbt == 7)
                        fncShowMessage(1,"Seventh iteration: Increasingly, the mathematics will demand the courage to face its implications.<br>Ian Malcolm", 6000);
                    else if (iCountWhtRbbt == 8)
                        fncShowMessage(3,"STOP NOW or system will crash!!!", 6000);
                    else if (iCountWhtRbbt == 9)
                        fncShowMessage(0,"loading whte_rbt.obj to sailfish device, please wait...", 3000);
                    else if (iCountWhtRbbt == 10)
                    {
                        fncShowMessage(4,"Developed by Cyberdyne Systems, 18144 El Camino Real, Sunnyvale, California<br>Project Supervisor: Dennis Nedry<br>Chief Programmer: Mike Backes<br>\u00A9 Jurassic Parc Inc. All Rights Reserved", 16000);
                        iCountWhtRbbt = 0;
                    }

                    iCountWhtRbbt++;
                }
            }
            Item
            {
                width: parent.width
                height: Theme.paddingLarge
            }
            Label
            {
                width: parent.width
                anchors.horizontalCenter: parent.horizontalCenter
                font.pixelSize: Theme.fontSizeExtraSmall
                wrapMode: Text.WordWrap
                maximumLineCount: 2
                horizontalAlignment: Text.AlignHCenter
                text: qsTr("OBD ELM327 car diagnostic reader application for Sailfish OS")
            }
            Item
            {
                width: parent.width
                height: Theme.paddingLarge
            }
            Label
            {
                anchors.horizontalCenter: parent.horizontalCenter
                font.pixelSize: Theme.fontSizeExtraSmall
                color: Theme.secondaryColor
                text: "Copyright \u00A9 2017 Jens Drescher, Germany"
            }
            Label
            {
                anchors.horizontalCenter: parent.horizontalCenter
                font.pixelSize: Theme.fontSizeExtraSmall
                color: Theme.secondaryColor
                text: "Version: " + Qt.application.version
            }
            Label
            {
                anchors.horizontalCenter: parent.horizontalCenter
                font.pixelSize: Theme.fontSizeExtraSmall
                color: Theme.secondaryColor
                text: qsTr("Date: ") + "01.02.2017";
            }
            Label
            {
                anchors.horizontalCenter: parent.horizontalCenter
                font.pixelSize: Theme.fontSizeExtraSmall
                color: Theme.secondaryColor
                text: qsTr("License: GPLv3")
            }
            Item
            {
                width: parent.width
                height: Theme.paddingLarge
            }
            Label
            {
                anchors.horizontalCenter: parent.horizontalCenter
                font.pixelSize: Theme.fontSizeExtraSmall
                color: Theme.secondaryColor
                text: qsTr("Source code:")
            }
            Label
            {
                anchors.horizontalCenter: parent.horizontalCenter
                font.pixelSize: Theme.fontSizeExtraSmall
                property string urlstring: "https://github.com/jdrescher2006/OBDFish"
                text: "<a href=\"" + urlstring + "\">" +  urlstring + "<\a>"
                onLinkActivated: Qt.openUrlExternally(link)
            }
            Item
            {
                width: parent.width
                height: Theme.paddingLarge
            }
            Label
            {
                anchors.horizontalCenter: parent.horizontalCenter
                font.pixelSize: Theme.fontSizeExtraSmall
                color: Theme.secondaryColor
                text: qsTr("Feedback, bugs:")
            }
            Label
            {
                anchors.horizontalCenter: parent.horizontalCenter
                font.pixelSize: Theme.fontSizeExtraSmall
                property string urlstring: "https://github.com/jdrescher2006/OBDFish/issues"
                text: "<a href=\"" + urlstring + "\">" +  urlstring + "<\a>"
                onLinkActivated: Qt.openUrlExternally(link)
            }
        }
    }
}


