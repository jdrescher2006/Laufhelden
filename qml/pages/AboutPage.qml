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
            MouseArea
            {
                width : parent.width /1.8
                height: parent.width / 1.8
                anchors.horizontalCenter: parent.horizontalCenter
                Image
                {
                    anchors.fill: parent
                    source: "../laufhelden.png"
                }
                onClicked:
                {
                    if (iCountWhtRbbt == 1)
                        fncShowMessage(1,"The future's not set. There's no fate but what we make for ourselves.<br>John Connor", 8000);
                    else if (iCountWhtRbbt == 2)
                        fncShowMessage(1,"And it would die, to protect him. In an insane world, it was the sanest choice.<br>Sarah Connor", 8000);
                    else if (iCountWhtRbbt == 3)
                        fncShowMessage(1,"I know now why you cry but it's something that I can never do.<br>T-800", 8000);
                    else if (iCountWhtRbbt == 4)
                        fncShowMessage(3,"STOP NOW or system will crash!!!", 8000);
                    else if (iCountWhtRbbt == 5)
                        fncShowMessage(0,"Skynet is now searching for viruses on your system, please wait...", 3000);
                    else if (iCountWhtRbbt == 6)
                    {
                        fncShowMessage(4,"Developed by Cyberdyne Systems, 18144 El Camino Real, Sunnyvale, California<br>Project Supervisor: Miles Dyson<br>Chief Programmer: Jens Drescher<br>\u00A9 Cyberdyne Systems Inc. All Rights Reserved", 16000);

                        fncPlaySound("audio/hlvb.wav");
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
                text: qsTr("Sport tracker application for Sailfish OS")
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
                text: qsTr("Copyright") + " \u00A9 2017 Jens Drescher, " + qsTr("Germany")
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
                text: qsTr("Date: ") + "16.01.2018";
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
                text: qsTr("Credits for localization:")
            }
            Label
            {
                width: parent.width
                wrapMode: Text.WordWrap
                anchors.horizontalCenter: parent.horizontalCenter
                font.pixelSize: Theme.fontSizeExtraSmall
                color: Theme.secondaryColor
                text: qsTr("Spanish") + " - Caballlero<br>" + qsTr("Polish") + " - atlochowski<br>" + qsTr("Swedish") + " - eson57<br>" + qsTr("Finnish") + " - niemisenjussi<br>" + qsTr("Hungarian") + " - martonmiklos"
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
                text: qsTr("Credits for code contribution:")
            }
            Label
            {
                width: parent.width
                wrapMode: Text.WordWrap
                anchors.horizontalCenter: parent.horizontalCenter
                font.pixelSize: Theme.fontSizeExtraSmall
                color: Theme.secondaryColor
                text: "niemisenjussi<br>piggz"
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
                text: qsTr("If you like this app you can donate for it:")
            }
            Label
            {
                anchors.horizontalCenter: parent.horizontalCenter
                font.pixelSize: Theme.fontSizeExtraSmall
                property string urlstring: "https://www.paypal.me/JensDrescher"
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
                text: qsTr("Source code:")
            }
            Label
            {
                anchors.horizontalCenter: parent.horizontalCenter
                font.pixelSize: Theme.fontSizeExtraSmall
                property string urlstring: "https://github.com/jdrescher2006/Laufhelden"
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
                property string urlstring: "https://github.com/jdrescher2006/Laufhelden/issues"
                text: "<a href=\"" + urlstring + "\">" +  urlstring + "<\a>"
                onLinkActivated: Qt.openUrlExternally(link)
            }
        }
    }
}


