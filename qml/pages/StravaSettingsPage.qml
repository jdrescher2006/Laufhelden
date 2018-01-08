/*
 * Copyright (C) 2017 Adam Pigg <adam@piggz.co.uk>
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
import com.pipacs.o2 1.0

Page {
    id: page

    property bool downloadingGPX: false
    property variant athlete
    property string username: ""
    property string email: ""
    property string country: ""

    onStatusChanged:
    {
        if (status === PageStatus.Active) {
            console.log("Active StravaSettingsPage");
        }
        else if (status === PageStatus.Activating){
            if (o2strava.linked) {
                var tokens = o2strava.extraTokens;
                athlete = tokens["athlete"];
                username = athlete["username"];
                email = athlete["email"];
                country = athlete["country"];
            } else {
                username = "not logged in";
                email = "";
                country = "";
            }
        }
    }

    O2 {
        id: o2strava
        clientId: "13707"
        clientSecret: STRAVA_CLIENT_SECRET
        scope: "write"
        requestUrl: "https://www.strava.com/oauth/authorize"
        tokenUrl: "https://www.strava.com/oauth/token"

        onOpenBrowser: {
            var browser = pageStack.push(Qt.resolvedUrl("BrowserPage.qml"));
            browser.url = url;
        }

        onCloseBrowser: {

            pageStack.pop();
        }

        onLinkedChanged: {
            btnAuth.enabled = true;
            if (linked) {
                var tokens = o2strava.extraTokens;
                athlete = tokens["athlete"];
                page.username = athlete["username"];
                page.email = athlete["email"];
                page.country = athlete["country"];
            } else {
                page.username = "not logged in";
                page.email = "";
                page.country = "";
            }
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
                title: qsTr("Strava settings")
            }

            Column {
                width: parent.width
                spacing: Theme.paddingLarge


                Button{
                    id: btnAuth
                    width: parent.width/2
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: o2strava.linked? "Logout": "Login"
                    onClicked: {
                        enabled = false
                        if (o2strava.linked) {
                            o2strava.unlink();
                        } else {
                            o2strava.link();
                        }
                    }
                }
                Separator
                {
                    anchors.topMargin: 50
                    color: Theme.highlightColor
                    width: parent.width
                }
                Label{
                    id: lblUser
                    horizontalAlignment: Text.AlignHCenter
                    width: parent.width
                    text: "User Name: " + username
                }
                Label{
                    id: lblEmail
                    horizontalAlignment: Text.AlignHCenter
                    width: parent.width
                    text: "Email: " + email
                }
                Label{
                    id: lblCountry
                    horizontalAlignment: Text.AlignHCenter
                    width: parent.width
                    text: "Country: " + country
                }
            }
        }
    }
}
