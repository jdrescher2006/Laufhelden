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
import "../tools/SharedResources.js" as SharedResources

Page {
    id: myStravaActivities
    property bool busy: false

    O2 {
        id: o2strava
        clientId: STRAVA_CLIENT_ID
        clientSecret: STRAVA_CLIENT_SECRET
        scope: "write"
        requestUrl: "https://www.strava.com/oauth/authorize"
        tokenUrl: "https://www.strava.com/oauth/token"
    }

    BusyIndicator {
        size: BusyIndicatorSize.Large
        anchors.centerIn: parent
        visible: parent.busy
        running: parent.busy
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
            contentHeight: distLabel.y + distLabel.height + Theme.paddingMedium

            Image
            {
                id: workoutImage
                anchors.top: parent.top
                anchors.topMargin: Theme.paddingMedium
                x: Theme.paddingMedium
                width: Theme.paddingMedium * 3
                height: Theme.paddingMedium * 3
                source: stravaList.model[index]["type"]==="" ? "" : SharedResources.arrayLookupWorkoutTableByName[SharedResources.fromStravaType(stravaList.model[index]["type"]).toLowerCase()].icon
            }
            Label
            {
                id: nameLabel
                width: parent.width - dateLabel.width - 2*Theme.paddingLarge
                anchors.top: parent.top
                anchors.topMargin: Theme.paddingMedium
                anchors.left: workoutImage.right
                anchors.leftMargin: Theme.paddingMedium
                truncationMode: TruncationMode.Fade
                text: stravaList.model[index]["name"]
                color: listItem.highlighted ? Theme.highlightColor : Theme.primaryColor
            }
            Label
            {
                id: dateLabel
                anchors.top: parent.top
                anchors.topMargin: Theme.paddingMedium
                anchors.right: parent.right
                anchors.rightMargin: Theme.paddingSmall
                text: (new Date(stravaList.model[index]["start_date"])).toDateString()
                color: listItem.highlighted ? Theme.highlightColor : Theme.primaryColor
            }
            Image {
                id: distangeImage
                anchors.top: nameLabel.bottom
                anchors.left: workoutImage.right
                anchors.leftMargin: Theme.paddingMedium
                source: "../img/pin.png"
                height: distLabel.height
                width: height
            }

            Label
            {
                id: distLabel
                anchors.top: distangeImage.top
                anchors.left: distangeImage.right
                anchors.leftMargin: Theme.paddingMedium
                color: listItem.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
                font.pixelSize: Theme.fontSizeSmall
                text: (settings.measureSystem === 0) ? (stravaList.model[index]["distance"]/1000).toFixed(2) + "km" : JSTools.fncConvertDistanceToImperial(stravaList.model[index]["distance"]/1000).toFixed(2) + "mi"
            }
            Image {
                id: timeImage
                anchors.top: timeLabel.top
                anchors.right: timeLabel.left
                anchors.rightMargin: Theme.paddingSmall
                source: "../img/time.png"
                height: timeLabel.height
                width: height
            }
            Label
            {
                id: timeLabel
                anchors.top: nameLabel.bottom
                x: (parent.width - width) / 2
                color: listItem.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
                font.pixelSize: Theme.fontSizeSmall
                text: Math.floor(stravaList.model[index]["elapsed_time"] / 60) + "min"
            }
            Image {
                id: elevationImage
                anchors.top: nameLabel.bottom
                anchors.right: elevationLabel.left
                anchors.rightMargin: Theme.paddingSmall
                source: "../img/elevation.png"
                height: elevationLabel.height
                width: height
            }

            Label
            {
                id: elevationLabel
                anchors.top: elevationImage.top
                anchors.right: parent.right
                anchors.rightMargin: Theme.paddingSmall
                color: listItem.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
                font.pixelSize: Theme.fontSizeSmall
                text: stravaList.model[index]["total_elevation_gain"] + "m"
            }
            onClicked: {
                var activityPage = pageStack.push(Qt.resolvedUrl("StravaActivityPage.qml"));
                activityPage.loadActivity(stravaList.model[index]["id"]);
            }
        }
    }




    Component.onCompleted: {
        loadActivities(0);
    }

    function loadActivities(page) {
        if (!o2strava.linked){
            console.log("Not linked to Strava");
            return;
        }

        busy = true;

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
            busy = true;
            //console.log("Ready state changed:", xmlhttp.readyState, xmlhttp.responseType, xmlhttp.responseText, xmlhttp.status, xmlhttp.statusText);
            if (xmlhttp.readyState==4 && xmlhttp.status==200){
                //console.log("Get Response:", xmlhttp.responseText);
                stravaList.model = JSON.parse(xmlhttp.responseText);
            }
            busy = false;
        };

        xmlhttp.send();
    }
}
