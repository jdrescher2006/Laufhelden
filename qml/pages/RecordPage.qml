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
import QtLocation 5.0
import "../tools/SharedResources.js" as SharedResources
import "../tools/Thresholds.js" as Thresholds
import "../tools/JSTools.js" as JSTools
import "../tools/RecordPageDisplay.js" as RecordPageDisplay

Page
{
    id: page

    allowedOrientations: settings.recordPagePortrait ? Orientation.Portrait : Orientation.All

    //If pause and we have no data and the map is not big, going back is possible
    backNavigation: (recorder.pause && recorder.isEmpty && !map.gesture.enabled)

    property bool bShowMap: settings.showMapRecordPage  

    property bool bLockFirstPageLoad: true
    property int iButtonLoop : 3
    property bool bEndLoop: false;
    property int iValueFieldPressed: -1

    property int iKeepPressingButton: 4

    property int iDisplayMode: settings.displayMode
    property bool bShowBorderLines: settings.showBorderLines
    property color cBackColor: "black"
    property color cPrimaryTextColor: "white"
    property color cSecondaryTextColor: "#D5D5D5"
    property color cBorderColor: "steelblue"

    property int iSelectedValue: -1
    property int iOldValue: -1

    //Automatic night mode
    property int iAutoNightModeLoop: 0
    property int iAutoNightModeValue: 0
    property int iOldDisplayMode: settings.displayMode

    //Scaling
    property int iHeaderLineWidthFactor: (settings.mapShowOnly4Fields && bShowMap) ? 8 : 10
    property int iMiddleLineWidthFactor: (settings.mapShowOnly4Fields && bShowMap) ? 4 : 5
    property int iFooterLineWidthFactor: (settings.mapShowOnly4Fields && bShowMap) ? 8 : 10
    property int iBorderWidth: height / 400
    property double iPrimaryTextHeightFactor: 1.8
    property double iSecondaryTextHeightFactor: 3.6

    onStatusChanged:
    {
        //This is loaded only the first time the page is displayed
        if (status === PageStatus.Active && bLockFirstPageLoad)
        {
            console.log("---RecordPage first active enter---");

            bLockFirstPageLoad = false;                        

            recorder.newTrackPoint.connect(newTrackPoint);
            map.addMapItem(positionMarker);
            console.log("RecordPage: Plotting track line");
            for(var i=0;i<recorder.points;i++)
            {
                trackLine.addCoordinate(recorder.trackPointAt(i));
            }
            console.log("RecordPage: Appending track line to map");
            map.addMapItem(trackLine);
            console.log("RecordPage: Setting map viewport");
            setMapViewport();

            console.log("---RecordPage first active leave---");
        }

        //This is loaded everytime the page is displayed
        if (status === PageStatus.Active)
        {
            console.log("---RecordPage active enter---");            

            //Set value types for fields in JS array
            RecordPageDisplay.fncConvertSaveStringToArray(settings.valueFields, SharedResources.arrayWorkoutTypes.map(function(e) { return e.name; }).indexOf(settings.workoutType), SharedResources.arrayWorkoutTypes.length);

            //Set header and footer to text fields
            fncSetHeaderFooterTexts();

            //Set display mode to dialog
            fncSetDisplayMode();            

            //If this page is shown, prevent screen from going blank
            if (settings.disableScreenBlanking)
                fncEnableScreenBlank(true);

            if (sHRMAddress !== "" && settings.useHRMdevice && bRecordDialogRequestHRM === false)
            {
                id_BluetoothData.connect(sHRMAddress, 1);
                bRecordDialogRequestHRM = true;
            }

            //Load threshold settings and convert them to JS array
            Thresholds.fncConvertSaveStringToArray(settings.thresholds);

            console.log("---RecordPage active leave---");
        }

        if (status === PageStatus.Inactive)
        {            
            console.log("RecordPage inactive");            

            if (settings.disableScreenBlanking)
                fncEnableScreenBlank(false);                    
        }
    }

    function fncUpdateBrightness()
    {
        if (id_Light === undefined)
            return;

        console.log("Brightness: " + id_Light.brightness.toString());

        iAutoNightModeValue = iAutoNightModeValue + id_Light.brightness;
    }


    Timer
    {
        id: idTimerUpdateCycle
        interval: 1000
        repeat: true
        running: true
        onTriggered:
        {
            //This timer is called every update cycle. Should be every second.            

            //Really strange thing: this timer is called even when the page is NOT opened!
            //If the prerecord page is open, the timer is called!
            //So we need to find out wether this page is opened anf if not return here.
            if (page.status === 0)
                return;

            //Get current light in LUX
            if (settings.autoNightMode)
            {
                //Read from light sensor of smartphone
                id_Light.refresh();

                //console.log("Brightness: " + id_Light.brightness.toString());

                iAutoNightModeValue = iAutoNightModeValue + id_Light.brightness;


                iAutoNightModeLoop++;

                //After 3 seconds, check value
                if (iAutoNightModeLoop >= 4)
                {
                    //console.log("iAutoNightModeLoop: " + iAutoNightModeLoop.toString());
                    //console.log("iDisplayMode: " + iDisplayMode.toString());
                    //console.log("iOldDisplayMode: " + iOldDisplayMode.toString());
                    //console.log("iAutoNightModeValue: " + iAutoNightModeValue.toString());


                    iAutoNightModeLoop = 0;

                    //If we are currently in night mode, and original mode was something else than night mode, check if light is bright enough to leave night mode
                    if (iDisplayMode === 2 && iOldDisplayMode !== 2 && (iAutoNightModeValue / 3) > 30)
                    {
                        //Set mode to original mode.
                        iDisplayMode = iOldDisplayMode;
                        //Change mode
                        fncSetDisplayMode();
                    }

                    //If we are currently NOT in night mode, check if it is dark enough to enter night mode
                    if (iDisplayMode !== 2 && (iAutoNightModeValue / 3) <= 30)
                    {
                        //Save current display mode
                        iOldDisplayMode = iDisplayMode

                        //Switch on night mode
                        iDisplayMode = 2;

                        //Change mode
                        fncSetDisplayMode();
                    }

                    iAutoNightModeValue = 0;
                }
            }

            //set heartrate to JS array if HR device is used
            if (sHRMAddress !== "" && settings.useHRMdevice)
            {
                RecordPageDisplay.arrayValueTypes[1].value = sHeartRate;
                RecordPageDisplay.arrayValueTypes[1].footnoteValue = sBatteryLevel + "%";
            }
            //Set values to JS array if recorder is running
            if (!recorder.pause)
            {
                //0 is empty and 1 is heartrate!
                RecordPageDisplay.arrayValueTypes[2].value = recorder.heartrateaverage.toFixed(1);
                RecordPageDisplay.arrayValueTypes[3].value = recorder.paceStr;
                RecordPageDisplay.arrayValueTypes[4].value = recorder.paceaverageStr;
                RecordPageDisplay.arrayValueTypes[5].value = recorder.speed.toFixed(1);
                RecordPageDisplay.arrayValueTypes[6].value = recorder.speedaverage.toFixed(1);
                RecordPageDisplay.arrayValueTypes[7].value = recorder.altitude;
                RecordPageDisplay.arrayValueTypes[8].value = (recorder.distance/1000).toFixed(1);
            }

            //Set values from JS array to dialog text fields
            idTXT_1_Value.text = RecordPageDisplay.fncGetValueTextByFieldID(1);
            if (RecordPageDisplay.fncGetFootnoteVisibleByFieldID(1)) idTXT_1_Footnote.text = " " + RecordPageDisplay.fncGetFootnoteTextByFieldID(1) + " " + RecordPageDisplay.fncGetFootnoteValueByFieldID(1);

            idTXT_2_Value.text = RecordPageDisplay.fncGetValueTextByFieldID(2);
            if (RecordPageDisplay.fncGetFootnoteVisibleByFieldID(2)) idTXT_2_Footnote.text = " " + RecordPageDisplay.fncGetFootnoteTextByFieldID(2) + " " + RecordPageDisplay.fncGetFootnoteValueByFieldID(2);

            idTXT_3_Value.text = RecordPageDisplay.fncGetValueTextByFieldID(3);
            if (RecordPageDisplay.fncGetFootnoteVisibleByFieldID(3)) idTXT_3_Footnote.text = " " + RecordPageDisplay.fncGetFootnoteTextByFieldID(3) + " " + RecordPageDisplay.fncGetFootnoteValueByFieldID(3);

            idTXT_4_Value.text = RecordPageDisplay.fncGetValueTextByFieldID(4);
            if (RecordPageDisplay.fncGetFootnoteVisibleByFieldID(4)) idTXT_4_Footnote.text = " " + RecordPageDisplay.fncGetFootnoteTextByFieldID(4) + " " + RecordPageDisplay.fncGetFootnoteValueByFieldID(4);

            idTXT_5_Value.text = RecordPageDisplay.fncGetValueTextByFieldID(5);
            if (RecordPageDisplay.fncGetFootnoteVisibleByFieldID(5)) idTXT_5_Footnote.text = " " + RecordPageDisplay.fncGetFootnoteTextByFieldID(5) + " " + RecordPageDisplay.fncGetFootnoteValueByFieldID(5);

            idTXT_6_Value.text = RecordPageDisplay.fncGetValueTextByFieldID(6);
            if (RecordPageDisplay.fncGetFootnoteVisibleByFieldID(6)) idTXT_6_Footnote.text = " " + RecordPageDisplay.fncGetFootnoteTextByFieldID(6) + " " + RecordPageDisplay.fncGetFootnoteValueByFieldID(6);

            //Set current daytime to dialog.
            var newDate = new Date();
            idCurrentDayTime.text = JSTools.fncPadZeros(newDate.getHours(),2) + ":" + JSTools.fncPadZeros(newDate.getMinutes(),2) + ":" + JSTools.fncPadZeros(newDate.getSeconds(),2) + " ";
        }
    }

    Timer
    {
        id: idTimerKeepTappingReset
        interval: 1000
        repeat: false
        running: (iKeepPressingButton !== 4)
        onTriggered:
        {
            //This timer is called if the user does not tap on the button repeately
            iKeepPressingButton = 4;
            iValueFieldPressed = -1;
        }
    }

    Timer
    {
        id: idTimerButtonLoop
        interval: 1000;
        repeat: (iButtonLoop<3 && iButtonLoop>0)
        running: (iButtonLoop<3 && iButtonLoop>0)
        onTriggered:
        {
            //Cancel end operation
            if (bEndLoop)
            {                
                iButtonLoop = 3;
                return;
            }

            iButtonLoop-=1;

            if (iButtonLoop===0)
            {
                iButtonLoop = 3;

                //These operation belong to "end workout" button pressed
                bRecordDialogRequestHRM = false;

                if (bHRMConnected) {id_BluetoothData.disconnect();}

                sHeartRate: ""
                sBatteryLevel: ""

                recorder.pause = true;
                if(!recorder.isEmpty)
                {
                    showSaveDialog();
                }
            }
        }
    }        

    function fncChangeValueField()
    {
        iSelectedValue = -1;
        iOldValue = RecordPageDisplay.fncGetIndexByFieldID(iValueFieldPressed);

        var dialog = pageStack.push(id_Dialog_ChooseValue)
        dialog.accepted.connect(function()
        {
            console.log("Accepted");

            if (iSelectedValue !== -1 && iOldValue !== -1)
            {
                console.log("iValueFieldPressed: " + iValueFieldPressed.toString());
                console.log("iSelectedValueIndex: " + iSelectedValue.toString());
                console.log("iOldValueIndex: " + iOldValue.toString());

                RecordPageDisplay.fncRemoveFieldIDByIndex(iOldValue, iValueFieldPressed);
                RecordPageDisplay.fncAddFieldIDByIndex(iSelectedValue, iValueFieldPressed);

                //Save the new value field arrangement to settings
                settings.valueFields = RecordPageDisplay.fncConvertArrayToSaveString(settings.valueFields, SharedResources.arrayWorkoutTypes.map(function(e) { return e.name; }).indexOf(settings.workoutType), SharedResources.arrayWorkoutTypes.length);
            }
        })
        dialog.rejected.connect(function()
        {
            console.log("Canceled");
            iSelectedValue = -1;
            iOldValue = -1;
        })
    }

    function fncSetHeaderFooterTexts()
    {                      
        idTXT_1_Header.text = RecordPageDisplay.fncGetHeaderTextByFieldID(1);
        idTXT_1_Footer.text = RecordPageDisplay.fncGetFooterTextByFieldID(1) + " ";
        idTXT_1_Footnote.visible = RecordPageDisplay.fncGetFootnoteVisibleByFieldID(1);
        idTXT_1_Footnote.text = " " + RecordPageDisplay.fncGetFootnoteTextByFieldID(1) + " " + RecordPageDisplay.fncGetFootnoteValueByFieldID(1);

        idTXT_2_Header.text = RecordPageDisplay.fncGetHeaderTextByFieldID(2);
        idTXT_2_Footer.text = RecordPageDisplay.fncGetFooterTextByFieldID(2);
        idTXT_2_Footnote.visible = RecordPageDisplay.fncGetFootnoteVisibleByFieldID(2);
        idTXT_2_Footnote.text = " " + RecordPageDisplay.fncGetFootnoteTextByFieldID(2) + " " + RecordPageDisplay.fncGetFootnoteValueByFieldID(2);

        idTXT_3_Header.text = RecordPageDisplay.fncGetHeaderTextByFieldID(3);
        idTXT_3_Footer.text = RecordPageDisplay.fncGetFooterTextByFieldID(3) + " ";
        idTXT_3_Footnote.visible = RecordPageDisplay.fncGetFootnoteVisibleByFieldID(3);
        idTXT_3_Footnote.text = " " + RecordPageDisplay.fncGetFootnoteTextByFieldID(3) + " " + RecordPageDisplay.fncGetFootnoteValueByFieldID(3);

        idTXT_4_Header.text = RecordPageDisplay.fncGetHeaderTextByFieldID(4);
        idTXT_4_Footer.text = RecordPageDisplay.fncGetFooterTextByFieldID(4);
        idTXT_4_Footnote.visible = RecordPageDisplay.fncGetFootnoteVisibleByFieldID(4);
        idTXT_4_Footnote.text = " " + RecordPageDisplay.fncGetFootnoteTextByFieldID(4) + " " + RecordPageDisplay.fncGetFootnoteValueByFieldID(4);

        idTXT_5_Header.text = RecordPageDisplay.fncGetHeaderTextByFieldID(5);
        idTXT_5_Footer.text = RecordPageDisplay.fncGetFooterTextByFieldID(5) + " ";
        idTXT_5_Footnote.visible = RecordPageDisplay.fncGetFootnoteVisibleByFieldID(5);
        idTXT_5_Footnote.text = " " + RecordPageDisplay.fncGetFootnoteTextByFieldID(5) + " " + RecordPageDisplay.fncGetFootnoteValueByFieldID(5);

        idTXT_6_Header.text = RecordPageDisplay.fncGetHeaderTextByFieldID(6);
        idTXT_6_Footer.text = RecordPageDisplay.fncGetFooterTextByFieldID(6);
        idTXT_6_Footnote.visible = RecordPageDisplay.fncGetFootnoteVisibleByFieldID(6);
        idTXT_6_Footnote.text = " " + RecordPageDisplay.fncGetFootnoteTextByFieldID(6) + " " + RecordPageDisplay.fncGetFootnoteValueByFieldID(6);
    }

    function showSaveDialog()
    {
        //If autosave is active...
        if (settings.enableAutosave)
        {
            console.log("Autosaving workout");
            recorder.exportGpx(SharedResources.arrayLookupWorkoutTableByName[settings.workoutType].labeltext + " - " + recorder.startingDateTime + " - " + (recorder.distance/1000).toFixed(1) + "km", "");
            recorder.clearTrack();  // TODO: Make sure save was successful?
            trackLine.path = [];

            //Mainpage must load history data to get this new workout in the list
            bLoadHistoryData = true;

            //We must return here to the mainpage.
            pageStack.pop(vMainPageObject, PageStackAction.Immediate);
        }
        else
        {
            var dialog = pageStack.push(Qt.resolvedUrl("SaveDialog.qml"));
            dialog.accepted.connect(function()
            {
                console.log("Saving workout");
                recorder.exportGpx(dialog.name, dialog.description);
                recorder.clearTrack();  // TODO: Make sure save was successful?
                trackLine.path = [];

                //Mainpage must load history data to get this new workout in the list
                bLoadHistoryData = true;

                //We must return here to the mainpage.
                pageStack.pop(vMainPageObject, PageStackAction.Immediate);
            })
            dialog.rejected.connect(function()
            {
                console.log("Cancel workout");
                recorder.clearTrack();
                trackLine.path = [];

                //We must return here to the mainpage.
                pageStack.pop(vMainPageObject, PageStackAction.Immediate);
            })
        }
    }   

    function setMapViewport()
    {
        if(recorder.accuracy < 0 && recorder.points < 1)
        {
            return;
        }

        var accuracyZoom;
        if(recorder.accuracy > 0) {
            var windowPixels;
            if(map.width < map.height) {
                windowPixels = map.width;
            } else {
                windowPixels = map.height;
            }
            var latCor = Math.cos(recorder.currentPosition.latitude*Math.PI/180);
            // Earth equator length in WGS-84: 40075.016686 km
            // Tile size: 256 pixels
            var innerFunction = windowPixels/256.0 * 40075016.686/(2*recorder.accuracy) * latCor
            // 2 base logarithm is ln(x)/ln(2)
            accuracyZoom = Math.min(map.maximumZoomLevel, Math.floor(Math.log(innerFunction) / Math.log(2)));
        } else {
            accuracyZoom = map.maximumZoomLevel;
        }

        var trackZoom = Math.min(map.maximumZoomLevel, recorder.fitZoomLevel(map.width, map.height));

        if(accuracyZoom <= trackZoom && recorder.accuracy > 0) {
            map.zoomLevel = accuracyZoom;
        } else {
            map.zoomLevel = trackZoom;
        }
        if(recorder.isEmpty)
        {
            map.center = recorder.currentPosition;
        }
        else
        {
            //center current position on map
            if (settings.mapMode === 0)
                map.center = recorder.currentPosition;
            else if (settings.mapMode === 1)
                map.center = recorder.trackCenter();
            else
                map.center = recorder.currentPosition;
        }
    }

    function newTrackPoint(coordinate)
    {
        //console.log("Position: " + recorder.currentPosition);
        console.log("newTrackPoint");               

        trackLine.addCoordinate(coordinate);
        if(!map.gesture.enabled)
        {
            // Set viewport only when not browsing
            setMapViewport();
        }

        var iThresholdTriggered = Thresholds.fncCheckHRThresholds(sHeartRate);

        var sVoiceLanguage = "_en_male.wav";
        //check voice language and generate last part of audio filename
        if (settings.voiceLanguage === 0)        //english male
            sVoiceLanguage = "_en_male.wav";
        else if (settings.voiceLanguage === 1)   //german male
            sVoiceLanguage = "_de_male.wav";


        if (iThresholdTriggered === 1)   //normal
        {            
            fncPlaySound("audio/hr_normal" + sVoiceLanguage);
        }
        else if (iThresholdTriggered === 2)   //low
        {
            fncPlaySound("audio/hr_toolow" + sVoiceLanguage);
        }
        else if (iThresholdTriggered === 3)   //high
        {
            fncPlaySound("audio/hr_toohigh" + sVoiceLanguage);
        }

        iThresholdTriggered = Thresholds.fncCheckPaceThresholds(recorder.pace.toFixed(1));

        if (iThresholdTriggered === 1)   //normal
        {
            fncPlaySound("audio/pace_normal" + sVoiceLanguage);
        }
        else if (iThresholdTriggered === 2)   //low
        {
            fncPlaySound("audio/pace_toolow" + sVoiceLanguage);
        }
        else if (iThresholdTriggered === 3)   //high
        {
            fncPlaySound("audio/pace_toohigh" + sVoiceLanguage);
        }
    }

    function fncSetDisplayMode()
    {
        if (iDisplayMode == 0)
        {
            //AMOLED mode
            cBackColor = "black";
            cPrimaryTextColor = "white";
            cSecondaryTextColor = "#D5D5D5";
            cBorderColor = "steelblue";

            //Show mode
            fncShowMessage(1,qsTr("AMOLED mode"), 1000);
        }
        else if (iDisplayMode == 1)
        {
            //LCD mode
            cBackColor = "white";
            cPrimaryTextColor = "black";
            cSecondaryTextColor = "#5B5B5B";
            cBorderColor = "steelblue";

            //Show mode
            fncShowMessage(1,qsTr("LCD mode"), 1000);
        }
        else if (iDisplayMode == 2)
        {
            //Night mode
            cBackColor = "black";
            cPrimaryTextColor = "#F50103";
            cSecondaryTextColor = "#FF1937";
            cBorderColor = "#F50103";

            //Show mode
            fncShowMessage(1,qsTr("Night mode"), 1000);
        }
        else
        {
            //Silica mode
            cBackColor = "transparent";
            cPrimaryTextColor = Theme.primaryColor;
            cSecondaryTextColor = Theme.secondaryColor;
            cBorderColor = Theme.secondaryColor;

            //Show mode
            fncShowMessage(1,qsTr("Silica mode"), 1000);
        }
    }

    MapCircle
    {
        id: positionMarker
        center: recorder.currentPosition
        radius: recorder.accuracy
        color: "blue"
        border.color: "white"
        border.width: 6
        opacity: 0.3        
        onRadiusChanged:
        {
            if(!map.gesture.enabled) {  // When not browsing the map
                setMapViewport()
            }
        }
        onCenterChanged:
        {
            if(!map.gesture.enabled) {  // When not browsing the map
                setMapViewport()
            }
        }        
        /* this stuff comes from Rena but was not working there either
        Behavior on radius
        {
            NumberAnimation { duration: 200 }
        }
        Behavior on center.latitude
        {
            NumberAnimation { duration: 200 }
        }
        Behavior on center.longitude
        {
            NumberAnimation { duration: 200 }
        }*/
    }

    MapPolyline
    {
        id: trackLine
        visible: path.length > 1
        line.color: "red"
        line.width: 5
        smooth: true
    }

    SilicaFlickable
    {
        id: flickable
        anchors.top: page.top
        anchors.bottom: bShowMap ? map.top : page.bottom
        anchors.left: page.left
        anchors.right: page.right

        PullDownMenu
        {
            id: menu

            MenuItem
            {
                text: qsTr("Settings")
                onClicked: pageStack.push(Qt.resolvedUrl("SettingsMenu.qml"))
            }
            MenuItem
            {
                text: qsTr("Switch display mode")
                onClicked:
                {
                    iDisplayMode++;

                    if (iDisplayMode > 3)
                        iDisplayMode = 0;

                    //Save current display mode to settings
                    settings.displayMode = iDisplayMode;

                    //Save current display mode to variable which is used for auto night mode
                    iOldDisplayMode = iDisplayMode;

                    //Set display mode to dialog
                    fncSetDisplayMode();
                }
            }
            MenuItem
            {
                text: bShowMap ? qsTr("Hide Map") : qsTr("Show Map")
                onClicked:
                {
                    bShowMap = !bShowMap;
                    settings.showMapRecordPage = bShowMap;
                }
            }
        }
        PushUpMenu
        {
            id: menuUP            

            MenuItem
            {
                text: qsTr("Disconnect HRM")
                visible: (sHRMAddress !== "" && settings.useHRMdevice)
                onClicked:
                {
                    bRecordDialogRequestHRM = false;
                    id_BluetoothData.disconnect();
                }
            }
            MenuItem
            {
                text: qsTr("Reconnect HRM")
                visible: (sHRMAddress !== "" && settings.useHRMdevice)
                onClicked:
                {
                    id_BluetoothData.connect(sHRMAddress, 1);
                    bRecordDialogRequestHRM = true;
                }
            }

        }

        //contentHeight: column.height + Theme.paddingLarge


        Rectangle
        {
            visible: (iKeepPressingButton !== 4)
            z: 2
            color: "steelblue"
            width: parent.width
            height: parent.height/10
            anchors.top: parent.top
            Label
            {
                color: "white"
                text: qsTr("keep tapping button: ") + iKeepPressingButton.toString();
                font.pixelSize: Theme.fontSizeMedium
                anchors.centerIn: parent
            }
        }


        Rectangle
        {
            visible: iButtonLoop < 3
            z: 2
            color: "steelblue"
            width: parent.width
            height: parent.height/10
            anchors.centerIn: parent
            Label
            {
                color: "white"
                text: qsTr("hold button for: ") + iButtonLoop.toString() + "s";
                font.pixelSize: Theme.fontSizeMedium
                anchors.centerIn: parent
            }
        }


        Item   //Header Line Left
        {
            id: idItemHeaderLine
            anchors.top: parent.top
            anchors.left: parent.left
            width: parent.width / 2
            height: parent.height / iHeaderLineWidthFactor                        

            Rectangle
            {
                anchors.fill: parent
                color: cBackColor
                visible: iDisplayMode !== 3 //invisible in silica mode because we need system background
            }
            GlassItem
            {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                color: recorder.accuracy < 0 ? "red" : (recorder.accuracy < 30 ? "green" : "orange")
                falloffRadius: 0.15
                radius: 1.0
                cache: false
            }
            Text
            {
                text: qsTr("GPS accuracy:")
                anchors.centerIn: parent
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignTop
                height: parent.height
                width: parent.width
                color: cSecondaryTextColor
                font.pixelSize: Theme.fontSizeSmall
            }
            Text
            {
                text: recorder.accuracy < 0 ? qsTr("No position") :
                                              (recorder.accuracy < 30
                                               ? recorder.accuracy.toFixed(1) + "m"
                                               : qsTr("too low: ") + recorder.accuracy.toFixed(1) + "m")
                anchors.centerIn: parent
                height: parent.height
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: bShowMap ? Text.AlignBottom : Text.AlignVCenter
                color: cPrimaryTextColor
                font.pixelSize: Theme.fontSizeSmall
            }
            Rectangle
            {
                width: parent.width
                height: iBorderWidth
                anchors.bottom: parent.bottom
                color: cBorderColor
                visible: bShowBorderLines
            }
            Rectangle
            {
                width: iBorderWidth
                height: parent.height
                anchors.right: parent.right
                color: cBorderColor
                visible: bShowBorderLines
            }
        }
        Item   //Header Line Right
        {
            anchors.top: parent.top
            anchors.right: parent.right
            width: parent.width / 2
            height: parent.height / iHeaderLineWidthFactor

            Rectangle
            {
                anchors.fill: parent
                color: cBackColor
                visible: iDisplayMode !== 3 //invisible in silica mode because we need system background
            }

            GlassItem
            {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                color: !recorder.pause ? "red" : (recorder.isEmpty ? "green" : "orange")
                falloffRadius: 0.15
                radius: 1.0
                cache: false
            }
            Text
            {
                text: !recorder.pause ? qsTr("Recording") : (recorder.isEmpty ? qsTr("Stopped") : qsTr("Paused"))
                anchors.centerIn: parent
                height: parent.height
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                color: cPrimaryTextColor
                font.pixelSize: Theme.fontSizeSmall
            }
            Rectangle
            {
                width: parent.width
                height: iBorderWidth
                anchors.bottom: parent.bottom
                color: cBorderColor
                visible: bShowBorderLines
            }
        }

        Item   //First Line Left
        {
            id: idItemFirstLine
            anchors.top: idItemHeaderLine.bottom
            anchors.left: parent.left
            width: parent.width / 2
            height: parent.height / iMiddleLineWidthFactor

            MouseArea
            {
                anchors.fill: parent
                onReleased:
                {
                    //Check if an other value field was pressed before.
                    if (iValueFieldPressed !== 1)
                    {
                        iValueFieldPressed = 1;
                        iKeepPressingButton = 3;
                    }
                    else
                        iKeepPressingButton--;

                    if (iKeepPressingButton === 0)
                    {
                        idTimerKeepTappingReset.stop();
                        iKeepPressingButton = 4;

                        fncChangeValueField();
                    }
                    else
                        idTimerKeepTappingReset.restart();
                }
            }

            Rectangle
            {
                anchors.fill: parent
                color: cBackColor
                visible: iDisplayMode !== 3 //invisible in silica mode because we need system background
            }

            Text
            {
                id: idTXT_1_Header
                anchors.top: parent.top
                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignVCenter
                height: parent.height / iSecondaryTextHeightFactor
                width: parent.width
                fontSizeMode: Text.Fit
                color: cSecondaryTextColor
                font.pointSize: 4000
            }
            Text
            {
                id: idTXT_1_Value
                text: "0"
                anchors.centerIn: parent
                height: parent.height / iPrimaryTextHeightFactor
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                fontSizeMode: Text.Fit
                color: cPrimaryTextColor
                font.pointSize: 4000
            }
            Text
            {
                id: idTXT_1_Footer
                anchors.bottom: parent.bottom
                height: parent.height / iSecondaryTextHeightFactor
                width: parent.width
                horizontalAlignment: Text.AlignRight
                verticalAlignment: Text.AlignVCenter
                fontSizeMode: Text.Fit
                color: cSecondaryTextColor
                font.pointSize: 4000
            }
            Text
            {
                id: idTXT_1_Footnote
                anchors.bottom: parent.bottom
                height: parent.height / 6
                width: parent.width
                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignVCenter
                fontSizeMode: Text.Fit
                color: cSecondaryTextColor
                font.pointSize: 4000
            }
            Rectangle
            {
                width: parent.width
                height: iBorderWidth
                anchors.bottom: parent.bottom
                color: cBorderColor
                visible: bShowBorderLines
            }
            Rectangle
            {
                width: iBorderWidth
                height: parent.height
                anchors.right: parent.right
                color: cBorderColor
                visible: bShowBorderLines
            }
        }

        Item   //First Line Right
        {
            anchors.top: idItemHeaderLine.bottom
            anchors.right: parent.right
            width: parent.width / 2
            height: parent.height / iMiddleLineWidthFactor

            MouseArea
            {
                anchors.fill: parent
                onReleased:
                {
                    //Check if an other value field was pressed before.
                    if (iValueFieldPressed !== 2)
                    {
                        iValueFieldPressed = 2;
                        iKeepPressingButton = 3;                                       
                    }
                    else
                        iKeepPressingButton--;

                    if (iKeepPressingButton === 0)
                    {
                        idTimerKeepTappingReset.stop();
                        iKeepPressingButton = 4;

                        fncChangeValueField();
                    }
                    else
                        idTimerKeepTappingReset.restart();
                }
            }

            Rectangle
            {
                anchors.fill: parent
                color: cBackColor
                visible: iDisplayMode !== 3 //invisible in silica mode because we need system background
            }

            Text
            {
                id: idTXT_2_Header
                anchors.top: parent.top
                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignVCenter
                height: parent.height / iSecondaryTextHeightFactor
                width: parent.width
                fontSizeMode: Text.Fit
                color: cSecondaryTextColor
                font.pointSize: 4000
            }
            Text
            {
                id: idTXT_2_Value
                text: "0"
                anchors.centerIn: parent
                height: parent.height / iPrimaryTextHeightFactor
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                fontSizeMode: Text.Fit
                color: cPrimaryTextColor
                font.pointSize: 4000
            }
            Text
            {
                id: idTXT_2_Footer
                anchors.bottom: parent.bottom
                height: parent.height / iSecondaryTextHeightFactor
                width: parent.width
                horizontalAlignment: Text.AlignRight
                verticalAlignment: Text.AlignVCenter
                fontSizeMode: Text.Fit
                color: cSecondaryTextColor
                font.pointSize: 4000
            }
            Text
            {
                id: idTXT_2_Footnote
                anchors.bottom: parent.bottom
                height: parent.height / 6
                width: parent.width
                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignVCenter
                fontSizeMode: Text.Fit
                color: cSecondaryTextColor
                font.pointSize: 4000
            }
            Rectangle
            {
                width: parent.width
                height: iBorderWidth
                anchors.bottom: parent.bottom
                color: cBorderColor
                visible: bShowBorderLines
            }
        }

        Item   //Second Line Left
        {
            id: idItemSecondLine
            anchors.top: idItemFirstLine.bottom
            anchors.left: parent.left
            width: parent.width / 2
            height: parent.height / iMiddleLineWidthFactor

            MouseArea
            {
                anchors.fill: parent
                onReleased:
                {
                    //Check if an other value field was pressed before.
                    if (iValueFieldPressed !== 3)
                    {
                        iValueFieldPressed = 3;
                        iKeepPressingButton = 3;
                    }
                    else
                        iKeepPressingButton--;

                    if (iKeepPressingButton === 0)
                    {
                        idTimerKeepTappingReset.stop();
                        iKeepPressingButton = 4;

                        fncChangeValueField();
                    }
                    else
                        idTimerKeepTappingReset.restart();
                }
            }

            Rectangle
            {
                anchors.fill: parent
                color: cBackColor
                visible: iDisplayMode !== 3 //invisible in silica mode because we need system background
            }

            Text
            {
                id: idTXT_3_Header
                anchors.top: parent.top
                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignVCenter
                height: parent.height / iSecondaryTextHeightFactor
                width: parent.width
                fontSizeMode: Text.Fit
                color: cSecondaryTextColor
                font.pointSize: 4000
            }
            Text
            {
                id: idTXT_3_Value
                text: "0"
                anchors.centerIn: parent
                height: parent.height / iPrimaryTextHeightFactor
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                fontSizeMode: Text.Fit
                color: cPrimaryTextColor
                font.pointSize: 4000
            }
            Text
            {
                id: idTXT_3_Footer
                anchors.bottom: parent.bottom
                height: parent.height / iSecondaryTextHeightFactor
                width: parent.width
                horizontalAlignment: Text.AlignRight
                verticalAlignment: Text.AlignVCenter
                fontSizeMode: Text.Fit
                color: cSecondaryTextColor
                font.pointSize: 4000
            }
            Text
            {
                id: idTXT_3_Footnote
                anchors.bottom: parent.bottom
                height: parent.height / 6
                width: parent.width
                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignVCenter
                fontSizeMode: Text.Fit
                color: cSecondaryTextColor
                font.pointSize: 4000
            }
            Rectangle
            {
                width: parent.width
                height: iBorderWidth
                anchors.bottom: parent.bottom
                color: cBorderColor
                visible: bShowBorderLines
            }
            Rectangle
            {
                width: iBorderWidth
                height: parent.height
                anchors.right: parent.right
                color: cBorderColor
                visible: bShowBorderLines
            }
        }

        Item   //Second Line Right
        {
            anchors.top: idItemFirstLine.bottom
            anchors.right: parent.right
            width: parent.width / 2
            height: parent.height / iMiddleLineWidthFactor

            MouseArea
            {
                anchors.fill: parent
                onReleased:
                {
                    //Check if an other value field was pressed before.
                    if (iValueFieldPressed !== 4)
                    {
                        iValueFieldPressed = 4;
                        iKeepPressingButton = 3;
                    }
                    else
                        iKeepPressingButton--;

                    if (iKeepPressingButton === 0)
                    {
                        idTimerKeepTappingReset.stop();
                        iKeepPressingButton = 4;

                        fncChangeValueField();
                    }
                    else
                        idTimerKeepTappingReset.restart();
                }
            }

            Rectangle
            {
                anchors.fill: parent
                color: cBackColor
                visible: iDisplayMode !== 3 //invisible in silica mode because we need system background
            }

            Text
            {
                id: idTXT_4_Header
                anchors.top: parent.top
                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignVCenter
                height: parent.height / iSecondaryTextHeightFactor
                width: parent.width
                fontSizeMode: Text.Fit
                color: cSecondaryTextColor
                font.pointSize: 4000
            }
            Text
            {
                id: idTXT_4_Value
                text: "0"
                anchors.centerIn: parent
                height: parent.height / iPrimaryTextHeightFactor
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                fontSizeMode: Text.Fit
                color: cPrimaryTextColor
                font.pointSize: 4000
            }
            Text
            {
                id: idTXT_4_Footer
                anchors.bottom: parent.bottom
                height: parent.height / iSecondaryTextHeightFactor
                width: parent.width
                horizontalAlignment: Text.AlignRight
                verticalAlignment: Text.AlignVCenter
                fontSizeMode: Text.Fit
                color: cSecondaryTextColor
                font.pointSize: 4000
            }
            Text
            {
                id: idTXT_4_Footnote
                //text: " " + qsTr("Bat:") + " " +  sBatteryLevel + "%"
                anchors.bottom: parent.bottom
                height: parent.height / 6
                width: parent.width
                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignVCenter
                fontSizeMode: Text.Fit
                color: cSecondaryTextColor
                font.pointSize: 4000
            }
            Rectangle
            {
                width: parent.width
                height: iBorderWidth
                anchors.bottom: parent.bottom
                color: cBorderColor
                visible: bShowBorderLines
            }
        }

        Item   //Third Line Left
        {
            id: idItemThirdLine
            anchors.top: idItemSecondLine.bottom
            anchors.left: parent.left
            width: parent.width / 2
            height: parent.height / iMiddleLineWidthFactor
            visible: !(settings.mapShowOnly4Fields && bShowMap)

            MouseArea
            {
                anchors.fill: parent
                onReleased:
                {
                    //Check if an other value field was pressed before.
                    if (iValueFieldPressed !== 5)
                    {
                        iValueFieldPressed = 5;
                        iKeepPressingButton = 3;
                    }
                    else
                        iKeepPressingButton--;

                    if (iKeepPressingButton === 0)
                    {
                        idTimerKeepTappingReset.stop();
                        iKeepPressingButton = 4;

                        fncChangeValueField();
                    }
                    else
                        idTimerKeepTappingReset.restart();
                }
            }

            Rectangle
            {
                anchors.fill: parent
                color: cBackColor
                visible: iDisplayMode !== 3 //invisible in silica mode because we need system background
            }

            Text
            {
                id: idTXT_5_Header
                anchors.top: parent.top
                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignVCenter
                height: parent.height / iSecondaryTextHeightFactor
                width: parent.width
                fontSizeMode: Text.Fit
                color: cSecondaryTextColor
                font.pointSize: 4000
            }
            Text
            {
                id: idTXT_5_Value
                text: "0"
                anchors.centerIn: parent
                height: parent.height / iPrimaryTextHeightFactor
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                fontSizeMode: Text.Fit
                color: cPrimaryTextColor
                font.pointSize: 4000
            }
            Text
            {
                id: idTXT_5_Footer
                anchors.bottom: parent.bottom
                height: parent.height / iSecondaryTextHeightFactor
                width: parent.width
                horizontalAlignment: Text.AlignRight
                verticalAlignment: Text.AlignVCenter
                fontSizeMode: Text.Fit
                color: cSecondaryTextColor
                font.pointSize: 4000
            }
            Text
            {
                id: idTXT_5_Footnote
                anchors.bottom: parent.bottom
                height: parent.height / 6
                width: parent.width
                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignVCenter
                fontSizeMode: Text.Fit
                color: cSecondaryTextColor
                font.pointSize: 4000
            }
            Rectangle
            {
                width: parent.width
                height: iBorderWidth
                anchors.bottom: parent.bottom
                color: cBorderColor
                visible: bShowBorderLines
            }
            Rectangle
            {
                width: iBorderWidth
                height: parent.height
                anchors.right: parent.right
                color: cBorderColor
                visible: bShowBorderLines
            }
        }

        Item   //Third Line Right
        {
            anchors.top: idItemSecondLine.bottom
            anchors.right: parent.right
            width: parent.width / 2
            height: parent.height / iMiddleLineWidthFactor
            visible: !(settings.mapShowOnly4Fields && bShowMap)

            MouseArea
            {
                anchors.fill: parent
                onReleased:
                {
                    //Check if an other value field was pressed before.
                    if (iValueFieldPressed !== 6)
                    {
                        iValueFieldPressed = 6;
                        iKeepPressingButton = 3;
                    }
                    else
                        iKeepPressingButton--;

                    if (iKeepPressingButton === 0)
                    {
                        idTimerKeepTappingReset.stop();
                        iKeepPressingButton = 4;

                        fncChangeValueField();
                    }
                    else
                        idTimerKeepTappingReset.restart();
                }
            }

            Rectangle
            {
                anchors.fill: parent
                color: cBackColor
                visible: iDisplayMode !== 3 //invisible in silica mode because we need system background
            }

            Text
            {
                id: idTXT_6_Header
                anchors.top: parent.top
                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignVCenter
                height: parent.height / iSecondaryTextHeightFactor
                width: parent.width
                fontSizeMode: Text.Fit
                color: cSecondaryTextColor
                font.pointSize: 4000
            }
            Text
            {
                id: idTXT_6_Value
                text: "0"
                anchors.centerIn: parent
                height: parent.height / iPrimaryTextHeightFactor
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                fontSizeMode: Text.Fit
                color: cPrimaryTextColor
                font.pointSize: 4000
            }
            Text
            {
                id: idTXT_6_Footer
                anchors.bottom: parent.bottom
                height: parent.height / iSecondaryTextHeightFactor
                width: parent.width
                horizontalAlignment: Text.AlignRight
                verticalAlignment: Text.AlignVCenter
                fontSizeMode: Text.Fit
                color: cSecondaryTextColor
                font.pointSize: 4000
            }
            Text
            {
                id: idTXT_6_Footnote
                anchors.bottom: parent.bottom
                height: parent.height / 6
                width: parent.width
                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignVCenter
                fontSizeMode: Text.Fit
                color: cSecondaryTextColor
                font.pointSize: 4000
            }
            Rectangle
            {
                width: parent.width
                height: iBorderWidth
                anchors.bottom: parent.bottom
                color: cBorderColor
                visible: bShowBorderLines
            }
        }

        Item   //Fourth Line
        {
            id: idItemFourthLine
            anchors.top: (settings.mapShowOnly4Fields && bShowMap) ? idItemSecondLine.bottom : idItemThirdLine.bottom
            anchors.left: parent.left
            width: parent.width
            height: parent.height / iMiddleLineWidthFactor           

            Rectangle
            {
                anchors.fill: parent
                color: cBackColor
                visible: iDisplayMode !== 3 //invisible in silica mode because we need system background
            }

            Text
            {
                text: qsTr("Duration:")
                anchors.top: parent.top
                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignVCenter
                height: parent.height / iSecondaryTextHeightFactor
                width: parent.width
                fontSizeMode: Text.Fit
                color: cSecondaryTextColor
                font.pointSize: 4000
            }
            Text
            {
                text: recorder.time
                anchors.centerIn: parent
                height: parent.height / iPrimaryTextHeightFactor
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                fontSizeMode: Text.Fit
                color: cPrimaryTextColor
                font.pointSize: 4000
            }
            Text
            {
                id: idCurrentDayTime
                anchors.bottom: parent.bottom
                height: parent.height / iSecondaryTextHeightFactor
                width: parent.width
                horizontalAlignment: Text.AlignRight
                verticalAlignment: Text.AlignVCenter
                fontSizeMode: Text.Fit
                color: cSecondaryTextColor
                font.pointSize: 4000
            }
            Rectangle
            {
                width: parent.width
                height: iBorderWidth
                anchors.bottom: parent.bottom
                color: cBorderColor
                visible: bShowBorderLines
            }
        }

        Item    //Footer line
        {
            id: idItemFooterLine
            anchors.top: idItemFourthLine.bottom
            width: parent.width
            height: (parent.height / iFooterLineWidthFactor) - Theme.paddingSmall

            Rectangle
            {
                anchors.fill: parent
                color: cBackColor
                visible: iDisplayMode !== 3 //invisible in silica mode because we need system background
            }

            Rectangle
            {
                anchors.left: parent.left
                anchors.leftMargin: Theme.paddingSmall
                width: ((parent.width/2) - (Theme.paddingLarge/2))
                height: parent.height
                color: recorder.isEmpty ? "dimgrey" : "lightsalmon"
                border.color: recorder.isEmpty ? "grey" : "white"
                border.width: 2
                radius: 10
                Image
                {
                    height: parent.height
                    anchors.left: parent.left
                    fillMode: Image.PreserveAspectFit
                    source: !recorder.pause ? "image://theme/icon-l-pause" : "image://theme/icon-l-play"
                }
                Label
                {
                    anchors.right: parent.right
                    anchors.rightMargin: Theme.paddingMedium
                    anchors.verticalCenter: parent.verticalCenter
                    font.pixelSize: Theme.fontSizeLarge
                    color: recorder.isEmpty ? "grey" : "white"
                    text: !recorder.pause ? qsTr("Pause") : qsTr("Continue")
                }
                MouseArea
                {
                    anchors.fill: parent
                    enabled: !recorder.isEmpty //pause or continue only if workout was really started
                    onClicked:
                    {
                        recorder.pause = !recorder.pause;
                    }
                }
            }
            Rectangle
            {
                width: ((parent.width/2) - (Theme.paddingLarge/2))
                height: parent.height
                anchors.right: parent.right
                anchors.rightMargin: Theme.paddingSmall
                color: (recorder.isEmpty && (recorder.accuracy >= 30 || recorder.accuracy < 0)) ? "dimgrey" : (recorder.pause && recorder.isEmpty ? "#389632" : "salmon")
                border.color: (recorder.isEmpty && (recorder.accuracy >= 30 || recorder.accuracy < 0)) ? "grey" : "white"
                border.width: 2
                radius: 10
                Image
                {
                    height: parent.height
                    anchors.left: parent.left
                    fillMode: Image.PreserveAspectFit
                    source: recorder.pause && recorder.isEmpty ? "image://theme/icon-l-add" :  "image://theme/icon-l-clear"
                }
                Label
                {
                    anchors.right: parent.right
                    anchors.rightMargin: Theme.paddingMedium
                    anchors.verticalCenter: parent.verticalCenter
                    font.pixelSize: Theme.fontSizeLarge
                    color: (recorder.isEmpty && (recorder.accuracy >= 30 || recorder.accuracy < 0)) ? "grey" : "white"
                    text: recorder.pause && recorder.isEmpty ? qsTr("Start") : qsTr("End")
                }
                MouseArea
                {
                    anchors.fill: parent
                    onPressed:
                    {
                        if (recorder.pause && recorder.isEmpty)
                        {
                            //Check accuracy
                            if (recorder.accuracy > 0 && recorder.accuracy < 30)
                            {
                                //Start workout
                                recorder.pause = false;
                            }
                        }
                        else
                        {
                            bEndLoop = false;
                            iButtonLoop = 2;
                        }
                    }
                    onReleased:
                    {
                        bEndLoop = true;
                    }
                }
            }
        }
    }
    Map
    {
        id: map
        width: parent.width
        //height: map.gesture.enabled ? page.height : width * 3/4
        height: map.gesture.enabled ? page.height : parent.height / 2.5
        anchors.bottom: parent.bottom
        clip: true
        gesture.enabled: false
        visible: bShowMap
        plugin: Plugin
        {
            name: "osm"
            PluginParameter
            {
                name: "useragent"                
                value: "Laufhelden(SailfishOS)"
            }
            //PluginParameter { name: "osm.mapping.host"; value: "http://localhost:8553/v1/tile/" }
        }
        center {
            latitude: 0.0
            longitude: 0.0
        }
        zoomLevel: minimumZoomLevel
        onHeightChanged: setMapViewport()
        onWidthChanged: setMapViewport()
        Behavior on height {
            NumberAnimation { duration: 200 }
        }
        Behavior on zoomLevel {
            NumberAnimation { duration: 200 }
        }
        Behavior on center.latitude {
            NumberAnimation { duration: 200 }
        }
        Behavior on center.longitude {
            NumberAnimation { duration: 200 }
        }       

        MapQuickItem {
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            sourceItem: Rectangle {
                color: "white"
                opacity: 0.6
                width: contributionLabel.width
                height: contributionLabel.height
                Label {
                    id: contributionLabel
                    font.pixelSize: Theme.fontSizeTiny
                    color: "black"
                    text: "(C) OpenStreetMap contributors"
                }
            }
        }
        MouseArea {
            anchors.fill: parent
            onClicked: {
                map.gesture.enabled = !map.gesture.enabled;
                if(map.gesture.enabled)
                {
                    //distanceLabel.opacity = 0.0;
                    //timeLabel.opacity = 0.0;
                    //accuracyLabel.opacity = 0.0;
                    //page.allowedOrientations = Orientation.All;
                }
                else
                {
                    //distanceLabel.opacity = 1.0;
                    //timeLabel.opacity = 1.0;
                    //accuracyLabel.opacity = 1.0;
                    //page.allowedOrientations = Orientation.All;
                }
                //page.forwardNavigation = !map.gesture.enabled;
                flickable.interactive = !map.gesture.enabled;
                menu.visible = !map.gesture.enabled;
            }
        }
    }
    Component
    {
        id: id_Dialog_ChooseValue


        Dialog
        {
            width: parent.width
            canAccept: true
            acceptDestination: page
            acceptDestinationAction: PageStackAction.Pop

            Column
            {
                width: parent.width

                DialogHeader
                {
                    title: qsTr("Select value!")
                    defaultAcceptText: qsTr("Accept")
                    defaultCancelText: qsTr("Cancel")
                }

                SilicaListView
                {
                    id: listView
                    width: parent.width
                    height: contentItem.childrenRect.height
                    //header: PageHeader {}
                    model: RecordPageDisplay.arrayValueTypes;

                    delegate: ListItem
                    {
                        width: listView.width                        
                        Label
                        {
                            id: idLBLValueName
                            text: modelData.header
                            //color: (iValueFieldPressed === modelData.fieldID || iSelectedValue === modelData.index) ? Theme.highlightColor : Theme.primaryColor
                            anchors.verticalCenter: parent.verticalCenter
                            x: Theme.paddingLarge
                        }
                        GlassItem //this is the item for the old value field
                        {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            color: (iSelectedValue === -1 || iSelectedValue === modelData.index) ? "green" : "grey"
                            falloffRadius: 0.15
                            radius: 1.0
                            cache: false
                            visible: (iSelectedValue !== modelData.index && (RecordPageDisplay.fncGetIndexByFieldID(iValueFieldPressed) === modelData.index))
                        }
                        GlassItem //this is the item for the currently selected value field
                        {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            color: "green"
                            falloffRadius: 0.15
                            radius: 1.0
                            cache: false
                            visible: (iSelectedValue !== -1 && iSelectedValue === modelData.index)
                        }                        

                        onClicked:
                        {
                            console.log("Clicked index: " + modelData.index.toString());
                            iSelectedValue = modelData.index;
                        }
                    }

                }
            }
        }
    }
}
