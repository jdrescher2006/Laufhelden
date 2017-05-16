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
import HistoryModel 1.0

Page
{
    id: id_page_mainpage

    property bool bMainPage: true


    onStatusChanged:
    {       
        if (status === PageStatus.Active && bMainPage)
        {
            bMainPage = false;

        }
    }

    HistoryModel
    {
        id: historyModel
    }

    SilicaFlickable
    {
        anchors.fill: parent
        contentHeight: id_Column_FirstCol.height + Theme.paddingLarge;

        PullDownMenu
        {
            id: menu
            MenuItem
            {
                text: qsTr("About")
                onClicked: pageStack.push(Qt.resolvedUrl("AboutPage.qml"))
            }
            MenuItem
            {
                text: qsTr("Settings")
                onClicked: pageStack.push(Qt.resolvedUrl("SettingsPage.qml"))
            }
            MenuItem
            {
                text: qsTr("Heart rate device")
                onClicked: pageStack.push(Qt.resolvedUrl("BTConnectPage.qml"))
            }
            MenuItem
            {
                text: qsTr("Start new workout")
                onClicked: pageStack.push(Qt.resolvedUrl("RecordPage.qml"))
            }
        }

        Column
        {
            id: id_Column_FirstCol

            width: parent.width
            spacing: Theme.paddingLarge
            PageHeader
            {
                title: qsTr("Welcome to Laufhelden")
            }

            Label
            {
                id: id_LBL_WorkoutCount
                x: Theme.paddingLarge
                truncationMode: TruncationMode.Fade
                text: historyList.count === 0 ? qsTr("No earlier workouts") : qsTr("Workouts: ") + (historyList.count).toString();
                color: Theme.highlightColor
            }
            Separator {color: Theme.highlightColor; width: parent.width;}

            SilicaListView
            {
                id: historyList
                model: historyModel
                anchors.left: parent.left
                anchors.right: parent.right
                height: parent.height / 2

                delegate: ListItem
                {
                    id: listItem
                    width: parent.width
                    ListView.onRemove: animateRemoval()
                    menu: ContextMenu
                    {
                        MenuItem
                        {
                            text: qsTr("Remove workout")
                            onClicked: remorseAction(qsTr("Removing workout..."), listItem.deleteTrack)
                        }
                    }

                    function deleteTrack()
                    {
                        historyModel.removeTrack(index);
                    }

                    Label
                    {
                        id: nameLabel
                        x: Theme.paddingLarge
                        width: parent.width - dateLabel.width - 2*Theme.paddingLarge
                        anchors.top: parent.top
                        truncationMode: TruncationMode.Fade
                        text: name==="" ? "(Unnamed track)" : name
                        color: listItem.highlighted ? Theme.highlightColor : Theme.primaryColor
                    }
                    Label
                    {
                        id: dateLabel
                        anchors.top: parent.top
                        anchors.right: parent.right
                        anchors.rightMargin: Theme.paddingLarge
                        text: date
                        color: listItem.highlighted ? Theme.highlightColor : Theme.primaryColor
                    }
                    Label
                    {
                        anchors.top: nameLabel.bottom
                        x: Theme.paddingLarge
                        color: listItem.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
                        font.pixelSize: Theme.fontSizeSmall
                        text: distance
                    }
                    Label
                    {
                        anchors.top: nameLabel.bottom
                        x: (parent.width - width) / 2
                        color: listItem.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
                        font.pixelSize: Theme.fontSizeSmall
                        text: duration
                    }
                    Label
                    {
                        anchors.top: nameLabel.bottom
                        anchors.right: parent.right
                        anchors.rightMargin: Theme.paddingLarge
                        color: listItem.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
                        font.pixelSize: Theme.fontSizeSmall
                        text: speed
                    }
                    onClicked: pageStack.push(Qt.resolvedUrl("DetailedViewPage.qml"),
                                              {filename: filename, name: name})
                }
            }
        }
    }
}
