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

    ListModel
    {
        id: pagesModel

        ListElement
        {
            page: "SettingsPage.qml"
            title: qsTr("General settings")
        }
        ListElement
        {
            page: "MapSettingsPage.qml"
            title: qsTr("Map settings")
        }
        ListElement
        {
            page: "ThresholdSettingsPage.qml"
            title: qsTr("Alarm thresholds")
        }
        ListElement
        {
            page: "BTConnectPage.qml"
            title: qsTr("Heart rate device")
        }
        ListElement
        {
            page: "SportsTrackerSettingsPage.qml"
            title: qsTr("Sports-Tracker.com")
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
            Label
            {
                id: firstName
                text: model.title
                color: highlighted ? Theme.highlightColor : Theme.primaryColor
                anchors.verticalCenter: parent.verticalCenter
                x: Theme.horizontalPageMargin
            }
            onClicked: pageStack.push(Qt.resolvedUrl(page))
        }
        VerticalScrollDecorator {}
    }
}
