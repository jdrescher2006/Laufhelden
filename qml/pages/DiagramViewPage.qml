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
import harbour.laufhelden 1.0
import "../tools/JSTools.js" as JSTools

Page
{
    id: page

    allowedOrientations: Orientation.All

    property bool bLockFirstPageLoad: true

    onStatusChanged:
    {
        if (status === PageStatus.Active && bLockFirstPageLoad)
        {
            bLockFirstPageLoad = false;

        }

        if (status === PageStatus.Active)
        {
            id_PlotWidgetHR.reset();
            id_PlotWidgetELE.reset();

            var iLastProperHeartRate = 0;

            for (var i = 0; i < JSTools.arrayDataPoints.length; i++)
            {
                if (JSTools.arrayDataPoints[i].heartrate > 0)
                {
                    id_PlotWidgetHR.addValue(JSTools.arrayDataPoints[i].heartrate);
                    iLastProperHeartRate = JSTools.arrayDataPoints[i].heartrate;
                }
                else
                    id_PlotWidgetHR.addValue(iLastProperHeartRate);

                id_PlotWidgetELE.addValue(JSTools.arrayDataPoints[i].elevation);



                //if (i > 100)
                  //  break;
            }

            id_PlotWidgetHR.update();
            id_PlotWidgetELE.update();
        }
    }

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
                title: qsTr("Diagrams")
            }

            PlotWidget
            {
                id: id_PlotWidgetHR
                width: page.width
                height: page.height / 3
                plotColor: "blue"
                scaleColor: "red"
            }
            Item
            {
                width: parent.width
                height: Theme.paddingLarge
            }

            PlotWidget
            {
                id: id_PlotWidgetELE
                width: page.width
                height: page.height / 3
                plotColor: Theme.highlightColor
                scaleColor: Theme.secondaryHighlightColor
            }

        }
    }
}


