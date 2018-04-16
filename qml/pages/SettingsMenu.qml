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
    id: pageSettingsmenu

    onOrientationChanged:
    {
        console.log("onOrientationChanged: " + pageSettingsmenu.width.toString() + "," + pageSettingsmenu.height.toString());
    }

    ListModel
    {
        id: pagesModel

        ListElement
        {
            page: "SettingsPage.qml"
            title: qsTr("General")
            source: "../img/general.png"
        }
        ListElement
        {
            page: "VoiceSettingsPage.qml"
            title: qsTr("Voice coach")
            source: "../img/voicecoach.png"
        }
        ListElement
        {
            page: "MapSettingsPage.qml"
            title: qsTr("Map")
            source: "../img/map.png"
        }
        ListElement
        {
            page: "CoverSettingsPage.qml"
            title: qsTr("App cover")
            source: "../img/cover.png"
        }        
        ListElement
        {
            page: "BTConnectPage.qml"
            title: qsTr("Heart rate device")
            source: "../img/heart.png"
        }
        ListElement
        {
            page: "SocialMediaMenu.qml"
            title: qsTr("Share workout")
            source: "../img/socialmedia.png"
        }        
        ListElement
        {
            page: "PebbleSettingsPage.qml"
            title: qsTr("Pebble")
            source: "../img/pebble.png"
        }
    }
    SilicaListView
    {
        id: listView
        anchors.fill: parent
        model: pagesModel
        header: PageHeader { title: qsTr("Settings") }
        delegate: BackgroundItem
        {
            width: listView.width

            Image
            {
                source: model.source
                anchors.verticalCenter: parent.verticalCenter
                anchors.bottomMargin: Theme.paddingLarge
                x: Theme.paddingLarge
                width: parent.height - Theme.paddingSmall - Theme.paddingSmall //parent.height is the height of the listitem. It cannot be set manually )-:
                height: parent.height - Theme.paddingSmall - Theme.paddingSmall
            }
            Label
            {
                id: firstName
                text: model.title
                color: highlighted ? Theme.highlightColor : Theme.primaryColor
                anchors.verticalCenter: parent.verticalCenter
                //width: parent.width - parent.height - Theme.paddingSmall - Theme.paddingSmall
                x: (parent.height - Theme.paddingSmall - Theme.paddingSmall) + Theme.paddingLarge + Theme.paddingLarge
            }
            onClicked: pageStack.push(Qt.resolvedUrl(page))            
        }
        VerticalScrollDecorator {}
    }
}
