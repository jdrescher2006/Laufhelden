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


Page {
    id: page

    property bool bLockOnCompleted : false;
    property bool bLockFirstPageLoad: true

    onStatusChanged:
    {
        //This is loaded only the first time the page is displayed
        if (status === PageStatus.Active && bLockFirstPageLoad)
        {
            bLockOnCompleted = true;

            bLockFirstPageLoad = false;
            console.log("First Active MapSettingsPage");

            id_TextSwitch_mapShowOnly4Fields.checked = settings.mapShowOnly4Fields;

            id_CMB_MapCenterMode.currentIndex = settings.mapMode;

            bLockOnCompleted = false;
        }

        //This is loaded everytime the page is displayed
        if (status === PageStatus.Active)
        {
            console.log("Active MapSettingsPage");

        }
    }


    SilicaFlickable
    {
        anchors.fill: parent
        contentHeight: column.height + Theme.paddingLarge;
        VerticalScrollDecorator {}
        Column
        {
            id: column
            width: page.width
            spacing: Theme.paddingLarge
            PageHeader
            {
                title: qsTr("Map settings")
            }                        
            TextSwitch
            {
                id: id_TextSwitch_mapShowOnly4Fields
                text: qsTr("Optimize screen in map mode")
                description: qsTr("Show only 4 value fields (instead of 6) when map is shown")
                onCheckedChanged:
                {
                    if (!bLockOnCompleted)
                        settings.mapShowOnly4Fields = checked;
                }                
            }                   
            Separator
            {
                color: Theme.highlightColor
                width: parent.width
            }
            ComboBox
            {
                id: id_CMB_MapCenterMode
                label: qsTr("Map center mode")
                menu: ContextMenu
                {
                    MenuItem
                    {
                        text: qsTr("Center current position on map")
                        onClicked:
                        {
                            if (bLockOnCompleted)
                                return;

                            settings.mapMode = 0;
                        }
                    }
                    MenuItem
                    {
                        text: qsTr("Center track on map")
                        onClicked:
                        {
                            if (bLockOnCompleted)
                                return;

                            settings.mapMode = 1;
                        }
                    }
                }
            }            
        }
    }
}
