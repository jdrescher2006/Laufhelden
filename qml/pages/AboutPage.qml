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
    SilicaFlickable {
        anchors.fill: parent
        contentHeight: childrenRect.height
        Column {
            id: column
            width: page.width
            spacing: Theme.paddingLarge
            PageHeader {
                title: qsTr("About")
            }
            Label {
                anchors.horizontalCenter: column.horizontalCenter
                text: "Rena"
                font.pixelSize: Theme.fontSizeExtraLarge
            }
            Label {
                anchors.horizontalCenter: column.horizontalCenter
                text: "Track recorder"
                font.pixelSize: Theme.fontSizeExtraMedium
            }
            Label {
                anchors.horizontalCenter: column.horizontalCenter
                text: qsTr("Version") + " 0.0.5-dev"
                font.pixelSize: Theme.fontSizeExtraSmall
            }
            Label {
                anchors.horizontalCenter: column.horizontalCenter
                text: "Copyright 2014 Simo Mattila"
            }
            Label {
                anchors.horizontalCenter: column.horizontalCenter
                text: "<a href=\"https://github.com/Simoma/rena\">https://github.com/Simoma/rena</a>"
                font.pixelSize: Theme.fontSizeExtraSmall
                onLinkActivated: Qt.openUrlExternally(link)
            }
            Label {
                anchors.horizontalCenter: column.horizontalCenter
                text: "simo.h.mattila@gmail.com"
                font.pixelSize: Theme.fontSizeExtraSmall
            }
            Label {
                anchors.horizontalCenter: column.horizontalCenter
                horizontalAlignment: Text.AlignHCenter
                text: qsTr("Distributed under the terms of the<br>GNU General Public License")
                font.pixelSize: Theme.fontSizeExtraSmall
            }
        }
    }
}
