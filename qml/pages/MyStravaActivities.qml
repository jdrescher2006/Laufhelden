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
import com.pipacs.o2 1.0
import "../tools"
import "../tools/SharedResources.js" as SharedResources

Page {
    id: myStravaActivities

    O2 {
        id: o2strava
        clientId: "13707"
        clientSecret: STRAVA_CLIENT_SECRET
        scope: "write"
        requestUrl: "https://www.strava.com/oauth/authorize"
        tokenUrl: "https://www.strava.com/oauth/token"
    }

    SilicaListView
    {
        anchors.fill: parent
        id: stravaList

        VerticalScrollDecorator {}

        header: PageHeader {
            title: qsTr("My Strava Activities")
        }

        delegate: ListItem {
            id: listItem
            menu: ContextMenu
            {
                MenuItem
                {
                    text: qsTr("Download Activity")
                }
            }

            Image
            {
                id: workoutImage
                anchors.top: parent.top
                anchors.topMargin: Theme.paddingMedium
                x: Theme.paddingSmall
                width: Theme.paddingMedium * 3
                height: Theme.paddingMedium * 3
                source: stravaList.model[index]["type"]==="" ? "" : SharedResources.arrayLookupWorkoutTableByName[stravaList.model[index]["type"].toLowerCase()].icon
            }
            Label
            {
                id: nameLabel
                x: Theme.paddingLarge * 2
                width: parent.width - dateLabel.width - 2*Theme.paddingLarge
                anchors.top: parent.top
                truncationMode: TruncationMode.Fade
                text: stravaList.model[index]["name"]
                color: listItem.highlighted ? Theme.highlightColor : Theme.primaryColor
            }
            Label
            {
                id: dateLabel
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.rightMargin: Theme.paddingSmall
                text: new Date(stravaList.model[index]["start_date"]).toLocaleDateString()
                color: listItem.highlighted ? Theme.highlightColor : Theme.primaryColor
            }
            Label
            {
                anchors.top: nameLabel.bottom
                x: Theme.paddingLarge * 2
                color: listItem.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
                font.pixelSize: Theme.fontSizeSmall
                text: (settings.measureSystem === 0) ? (stravaList.model[index]["distance"]/1000).toFixed(2) + "km" : JSTools.fncConvertDistanceToImperial(stravaList.model[index]["distance"]/1000).toFixed(2) + "mi"
            }
            Label
            {
                anchors.top: nameLabel.bottom
                x: (parent.width - width) / 2
                color: listItem.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
                font.pixelSize: Theme.fontSizeSmall
                text: Math.floor(stravaList.model[index]["elapsed_time"] / 60) + "min"
            }
            Label
            {
                anchors.top: nameLabel.bottom
                anchors.right: parent.right
                anchors.rightMargin: Theme.paddingSmall
                color: listItem.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
                font.pixelSize: Theme.fontSizeSmall
                text: stravaList.model[index]["total_elevation_gain"] + "m"
            }
            onClicked: pageStack.push(Qt.resolvedUrl("DetailedViewPage.qml"),
                                      {filename: filename, name: name})
        }
    }


    JSONListModel {
        id: jsonModel
    }

    Component.onCompleted: {
        loadActivities(0);
    }

    function loadActivities(page) {
        if (!o2strava.linked){
            console.log("Not linked to Strava");
            return;
        }

        var xmlhttp = new XMLHttpRequest();

        xmlhttp.open("GET", "https://www.strava.com/api/v3/athlete/activities");
        xmlhttp.setRequestHeader('Accept-Encoding', 'text');
        xmlhttp.setRequestHeader('Connection', 'keep-alive');
        xmlhttp.setRequestHeader('Pragma', 'no-cache');
        xmlhttp.setRequestHeader('Content-Type', 'application/json');
        xmlhttp.setRequestHeader('Accept', 'application/json, text/plain, */*');
        xmlhttp.setRequestHeader('Cache-Control', 'no-cache');
        xmlhttp.setRequestHeader('Authorization', "Bearer " + o2strava.token);

        xmlhttp.onreadystatechange=function(){
            console.log("Ready state changed:", xmlhttp.readyState, xmlhttp.responseType, xmlhttp.responseText, xmlhttp.status, xmlhttp.statusText);
            if (xmlhttp.readyState==4 && xmlhttp.status==200){
                console.log("Get Response:", xmlhttp.responseText);
                stravaList.model = JSON.parse(xmlhttp.responseText);
            }

        };

        xmlhttp.send();
    }
}
