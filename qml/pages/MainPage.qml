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
import "SharedResources.js" as SharedResources

Page
{
    id: mainPage

    property bool bLockFirstPageLoad: true
    property int iLoadFileGPX: 0
    property int iGPXFiles: 100
    property bool bLoadingFiles: false

    onStatusChanged:
    {
        //This is loaded only the first time the page is displayed
        if (status === PageStatus.Active && bLockFirstPageLoad)
        {
            bLockFirstPageLoad = false;
            console.log("First Active MainPage");

            //Init log file. Save first string.
            //if (settings.enableLogFile) id_LogWriter.vWriteStart("Version: " + Qt.application.version + "\r\n" + "Date: " + Date() + "\r\n-------------------------------\r\n");
            //id_LogWriter.vWriteStart("Version: " + Qt.application.version + "\r\n" + "Date: " + Date() + "\r\n-------------------------------\r\n");
            //id_LogWriter.vWriteData("Test Eintrag..." + "\r\n");

            //Read settings to QML variables
            var sTemp = settings.hrmdevice;
            sTemp = sTemp.split(',');
            if (sTemp.length === 2)
            {
                sHRMAddress = sTemp[0];
                sHRMDeviceName = sTemp[1];
            }
            else
            {
                sHRMAddress = "";
                sHRMDeviceName = "";
            }
        }

        //This is loaded everytime the page is displayed
        if (status === PageStatus.Active)
        {
            console.log("Active MainPage");

            //Save the object of this page for back jumps
            vMainPageObject = pageStack.currentPage;
            console.log("vMainPageObject: " + vMainPageObject.toString());


            //Load history model.
            if (bLoadHistoryData)
            {
                bLoadingFiles = true;

                id_HistoryModel.readDirectory();
                bLoadHistoryData = false;
            }
        }
    }


    Connections
    {
        target: id_HistoryModel
        onSigLoadingFinished:     //This is called from C++ if the loading of the GPX files is ready
        {            
            historyList.model = undefined;
            historyList.model = id_HistoryModel;            

            bLoadingFiles = false;
        }
        onDataChanged:     //This is called from C++ if the loading of one GPX file is ready
        {
            console.log("Track loading finished!!!");
            iLoadFileGPX++;
        }
        onSigAmountGPXFiles:
        {
            console.log("Amount of tracks: " + iAmountGPXFiles.toString());
            iGPXFiles = iAmountGPXFiles;
        }
    }

    SilicaListView
    {
        anchors.fill: parent

        id: historyList
        model: id_HistoryModel

        PullDownMenu
        {
            id: menu
            MenuItem
            {
                text: qsTr("About")
                onClicked: pageStack.push(Qt.resolvedUrl("AboutPage.qml"))
            }
            MenuItem
            {
                text: qsTr("Settings")
                onClicked: pageStack.push(Qt.resolvedUrl("SettingsPage.qml"))
            }
            MenuItem
            {
                text: qsTr("Start new workout")
                onClicked: pageStack.push(Qt.resolvedUrl("PreRecordPage.qml"))
            }            
        }

        header: Column
        {
            spacing: Theme.paddingLarge;
            anchors {
                left: parent.left;
                right: parent.right;
            }

            PageHeader {
                title: qsTr("Welcome to Laufhelden")
            }

            Label
            {
                id: id_LBL_WorkoutCount
                x: Theme.paddingLarge
                truncationMode: TruncationMode.Fade
                text: historyList.count === 0 ? qsTr("No earlier workouts") : qsTr("Workouts: ") + (historyList.count).toString();
                color: Theme.highlightColor
                visible: !bLoadingFiles
            }
            ProgressBar
            {
                id: progressBarWaitLoadGPX
                width: parent.width
                maximumValue: iGPXFiles
                valueText: value + " " + qsTr("of") + " " + iGPXFiles
                label: qsTr("Loading GPX files...")
                value: iLoadFileGPX
                visible: bLoadingFiles
            }

            Separator
            {
                color: Theme.highlightColor;
                anchors {
                    left: parent.left;
                    right: parent.right;
                }
            }
        }

        delegate: ListItem
        {
            id: listItem
            width: parent.width
            ListView.onRemove: animateRemoval()
            menu: ContextMenu
            {
                MenuItem
                {
                    text: qsTr("Remove workout")
                    onClicked: remorseAction(qsTr("Removing workout..."), listItem.deleteTrack)
                }
            }

            function deleteTrack()
            {
                id_HistoryModel.removeTrack(index);
            }


            Image
            {
                id: workoutImage
                anchors.top: parent.top
                anchors.topMargin: Theme.paddingMedium
                x: Theme.paddingSmall
                width: Theme.paddingMedium * 3
                height: Theme.paddingMedium * 3
                source: workout==="" ? "" : SharedResources.arrayLookupWorkoutTableByName[workout].icon
            }
            Label
            {
                id: nameLabel
                x: Theme.paddingLarge * 2
                width: parent.width - dateLabel.width - 2*Theme.paddingLarge
                anchors.top: parent.top
                truncationMode: TruncationMode.Fade
                text: name==="" ? "(Unnamed track)" : name
                color: listItem.highlighted ? Theme.highlightColor : Theme.primaryColor
            }
            Label
            {
                id: dateLabel
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.rightMargin: Theme.paddingSmall
                text: date
                color: listItem.highlighted ? Theme.highlightColor : Theme.primaryColor
            }
            Label
            {
                anchors.top: nameLabel.bottom
                x: Theme.paddingLarge * 2
                color: listItem.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
                font.pixelSize: Theme.fontSizeSmall
                text: distance
            }
            Label
            {
                anchors.top: nameLabel.bottom
                x: (parent.width - width) / 2
                color: listItem.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
                font.pixelSize: Theme.fontSizeSmall
                text: duration
            }
            Label
            {
                anchors.top: nameLabel.bottom
                anchors.right: parent.right
                anchors.rightMargin: Theme.paddingSmall
                color: listItem.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
                font.pixelSize: Theme.fontSizeSmall
                text: speed
            }
            onClicked: pageStack.push(Qt.resolvedUrl("DetailedViewPage.qml"),
                                      {filename: filename, name: name})
        }
    }
}
