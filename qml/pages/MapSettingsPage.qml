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


            if (settings.mapStyle === "mapbox://styles/mapbox/streets-v10")
                id_CMB_MapStyle.currentIndex = 0;
            else if (settings.mapStyle === "mapbox://styles/mapbox/outdoors-v10")
                id_CMB_MapStyle.currentIndex = 1;
            else if (settings.mapStyle === "mapbox://styles/mapbox/light-v9")
                id_CMB_MapStyle.currentIndex = 2;
            else if (settings.mapStyle === "mapbox://styles/mapbox/dark-v9")
                id_CMB_MapStyle.currentIndex = 3;
            else if (settings.mapStyle === "mapbox://styles/mapbox/satellite-v9")
                id_CMB_MapStyle.currentIndex = 4;
            else if (settings.mapStyle === "mapbox://styles/mapbox/satellite-streets-v10")
                id_CMB_MapStyle.currentIndex = 5;
            else if (settings.mapStyle === "http://localhost:8553/v1/mbgl/style?style=osmbright")
                id_CMB_MapStyle.currentIndex = 6;
            else
                id_CMB_MapStyle.currentIndex = 1;


            if (settings.mapCache === 25)
                id_CMB_MapCache.currentIndex = 0;
            else if (settings.mapCache === 50)
                id_CMB_MapCache.currentIndex = 1;
            else if (settings.mapCache === 100)
                id_CMB_MapCache.currentIndex = 2;
            else if (settings.mapCache === 250)
                id_CMB_MapCache.currentIndex = 3;
            else
                id_CMB_MapCache.currentIndex = 1;

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
            Separator
            {
                color: Theme.highlightColor
                width: parent.width
            }
            ComboBox
            {
                id: id_CMB_MapStyle
                description: qsTr("Choose map style.")
                label: qsTr("Map")
                menu: ContextMenu
                {
                    MenuItem { text: qsTr("Streets") }
                    MenuItem { text: qsTr("Outdoors") }
                    MenuItem { text: qsTr("Light") }
                    MenuItem { text: qsTr("Dark") }
                    MenuItem { text: qsTr("Satellite") }
                    MenuItem { text: qsTr("Satellite Streets") }
                    MenuItem { text: qsTr("OSM Scout Server") }
                }                
                onCurrentIndexChanged:
                {
                    if (bLockOnCompleted)
                        return;

                    if (currentIndex === 0)
                        settings.mapStyle = "mapbox://styles/mapbox/streets-v10";
                    else if (currentIndex === 1)
                        settings.mapStyle = "mapbox://styles/mapbox/outdoors-v10";
                    else if (currentIndex === 2)
                        settings.mapStyle = "mapbox://styles/mapbox/light-v9";
                    else if (currentIndex === 3)
                        settings.mapStyle = "mapbox://styles/mapbox/dark-v9";
                    else if (currentIndex === 4)
                        settings.mapStyle = "mapbox://styles/mapbox/satellite-v9";
                    else if (currentIndex === 5)
                        settings.mapStyle = "mapbox://styles/mapbox/satellite-streets-v10";
                    else if (currentIndex === 6)
                        settings.mapStyle = "http://localhost:8553/v1/mbgl/style?style=osmbright";
                    else
                        settings.mapStyle = "mapbox://styles/mapbox/outdoors-v10";
                }
            }
            Separator
            {
                color: Theme.highlightColor
                width: parent.width
            }
            ComboBox
            {
                id: id_CMB_MapCache
                description: qsTr("Limiting tile caching ensures up-to-date maps and keeps disk use under control, but loads maps slower and causes more data traffic. " +
                                    "Note that the cache size settings will be applied after restart of the application.")
                label: qsTr("Cache size")
                menu: ContextMenu
                {
                    MenuItem { text: "25 MB" }
                    MenuItem { text: "50 MB" }
                    MenuItem { text: "100 MB" }
                    MenuItem { text: "250 MB" }
                }                
                onCurrentIndexChanged:
                {
                    if (bLockOnCompleted)
                        return;

                    if (currentIndex === 0)
                        settings.mapCache = 25;
                    else if (currentIndex === 1)
                        settings.mapCache = 50;
                    else if (currentIndex === 2)
                        settings.mapCache = 100;
                    else if (currentIndex === 3)
                        settings.mapCache = 250;
                    else
                        settings.mapCache = 50;
                }
            }
        }
    }
}
