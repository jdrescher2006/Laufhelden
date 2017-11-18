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
import QtLocation 5.0
import Sailfish.Silica 1.0

MapQuickItem
{
    id: pause_marker
    anchorPoint.x: sourceItem.width/2
    anchorPoint.y: sourceItem.height/2
    height: sourceItem.height
    width: sourceItem.width
    z: 10 //the pause items should be placed on top of start/end icon
    sourceItem: Item
    {
        height: pause_marker.iSize
        width: pause_marker.iSize
        Image
        {
            id: image
            width: parent.width
            height: parent.height
            source: pause_marker.bPauseStart ? "../img/map_pause.png" : "../img/map_resume.png"
        }
    }

    property bool bPauseStart: true
    property int iSize: 0
}
