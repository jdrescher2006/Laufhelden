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
import HistoryModel 1.0

Page {
    id: historyPage

    HistoryModel {
        id: historyModel
    }

    SilicaListView {
        id: historyList
        VerticalScrollDecorator {}
        ViewPlaceholder {
            enabled: historyList.count === 0
            text: qsTr("No earlier tracks")
        }
        anchors.fill: parent
        model: historyModel
        header: PageHeader {
            title: qsTr("History")
        }
        delegate: ListItem {
            id: listItem
            width: parent.width
            height: Theme.itemSizeMedium
            Label {
                id: nameLabel
                x: Theme.paddingLarge
                width: parent.width - dateLabel.width - 2*Theme.paddingLarge
                anchors.top: parent.top
                truncationMode: TruncationMode.Fade
                text: name==="" ? "(Unnamed track)" : name
                color: listItem.highlighted ? Theme.highlightColor : Theme.primaryColor
            }
            Label {
                id: dateLabel
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.rightMargin: Theme.paddingLarge
                text: date
                color: listItem.highlighted ? Theme.highlightColor : Theme.primaryColor
            }
            Label {
                anchors.top: nameLabel.bottom
                x: Theme.paddingLarge
                color: listItem.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
                font.pixelSize: Theme.fontSizeSmall
                text: distance
            }
            Label {
                anchors.top: nameLabel.bottom
                x: (parent.width - width) / 2
                color: listItem.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
                font.pixelSize: Theme.fontSizeSmall
                text: duration
            }
            Label {
                anchors.top: nameLabel.bottom
                anchors.right: parent.right
                anchors.rightMargin: Theme.paddingLarge
                color: listItem.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
                font.pixelSize: Theme.fontSizeSmall
                text: speed
            }
            onClicked: pageStack.push(Qt.resolvedUrl("DetailedViewPage.qml"), {filename: filename})
        }
    }
}
