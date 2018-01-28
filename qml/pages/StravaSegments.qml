/*
 * Copyright (C) 2017 Jussi Nieminen, Finland
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

import QtQuick 2.2
import Sailfish.Silica 1.0
import harbour.laufhelden 1.0
import com.pipacs.o2 1.0
import "../tools"
import "../tools/JSTools.js" as JSTools

Page {
    id: stravaSegments
    property bool busy: false
    property var segments

    BusyIndicator {
        size: BusyIndicatorSize.Large
        anchors.centerIn: parent
        visible: parent.busy
        running: parent.busy
    }

    SilicaListView
    {
        anchors.fill: parent
        id: segmentList
        model: segments

        VerticalScrollDecorator {}

        header: PageHeader {
            title: qsTr("Segments")
        }

        delegate: ListItem {
            id: listItem
            contentHeight: image.y + image.height + Theme.paddingMedium

            Image
            {
                id: image
                anchors.top: parent.top
                anchors.topMargin: Theme.paddingMedium
                x: Theme.paddingLarge
                width: Theme.paddingLarge * 3
                height: width
                source: segmentList.model[index]["pr_rank"] === null ? "" : "../img/strava_pr_" + segmentList.model[index]["pr_rank"] + ".png"
            }
            Label
            {
                id: nameLabel
                width: parent.width - image.width - 2*Theme.paddingLarge
                verticalAlignment: Text.AlignTop
                anchors.top: parent.top
                anchors.topMargin: Theme.paddingMedium
                anchors.left: image.right
                anchors.leftMargin: Theme.paddingMedium
                truncationMode: TruncationMode.Fade
                text: segments[index].name
            }
        }
    }
}
