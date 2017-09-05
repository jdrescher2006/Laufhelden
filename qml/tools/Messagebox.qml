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

BackgroundItem
{
    id: messagebox
    z: 20
    visible: messageboxVisibility.running
    height: Theme.itemSizeSmall + Theme.paddingSmall + messageboxText.height
    anchors.centerIn: parent
    width: parent.width
    onClicked: messageboxVisibility.stop()

    Rectangle
    {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.6)
    }

    Image
    {
        id: idImageIcon
        anchors.top: parent.top
        anchors.left: parent.left
        source: "image://theme/icon-lock-warning"
    }

    Rectangle
    {
        id: idRectangleColor
        anchors.left: idImageIcon.right
        height: Theme.paddingSmall
        width: parent.width - idImageIcon.width
        color: Theme.highlightBackgroundColor
    }



    function showMessage(type, message, delay)
    {
        messageboxText.text = message;
        messageboxVisibility.interval = (delay>0) ? delay : 3000;
        messageboxVisibility.restart();

        if (type === 0)//WARNING
        {
            idRectangleColor.color = "#DEB954";
            idImageIcon.visible = true;
            idImageIcon.source = "../img/icon-lock-warning.png"
        }
        else if (type === 1)//INFO
        {
            idRectangleColor.color = "#7086FF";
            idImageIcon.visible = true;
            idImageIcon.source = "../img/icon-lock-info.png"
        }
        else if (type === 2)//SUCCESS
        {
            idRectangleColor.color = "#2FE629";
            idImageIcon.visible = true;
            idImageIcon.source = "../img/icon-lock-ok.png"
        }
        else if (type === 3)//ERROR
        {
            idRectangleColor.color = "#F23730";
            idImageIcon.visible = true;
            idImageIcon.source = "../img/icon-lock-error.png"
        }
        else if (type === 4)//SPECIAL IMAGE
        {
            idRectangleColor.color = "#F9D440";
            idImageIcon.visible = true;
            idImageIcon.source = "../img/cd_logo.jpg"
        }
    }

    Label
    {
        id: messageboxText
        width: parent.width
        wrapMode: Text.WordWrap
        color: Theme.primaryColor
        text: ""
        anchors.centerIn: parent

    }

    Timer
    {
        id: messageboxVisibility
        interval: 3000
    }
}
