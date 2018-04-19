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
//import QtLocation 5.0
import QtPositioning 5.3
import MapboxMap 1.0
import "../tools/SharedResources.js" as SharedResources
import "../tools/Thresholds.js" as Thresholds
import "../tools/JSTools.js" as JSTools
import "../tools/RecordPageDisplay.js" as RecordPageDisplay

Page
{
    id: page

    allowedOrientations: settings.recordPagePortrait ? Orientation.Portrait : Orientation.All

    //If pause and we have no data and the map is not big, going back is possible
    backNavigation: (!recorder.running && recorder.isEmpty && !bMapMaximized)

    property bool bShowMap: false

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

    property bool bRestoreWorkout: false

    property bool bShowLockScreen: false

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

    //Map
    property bool bMapMaximized: false
    property var vTrackLinePoints
    property string sTrackLine
    property string sCurrentPosition: ""
    property int iPausePositionsIndex: 0
    property var vTempTrackLinePoints
    property var vTempTrackLinePointsIndex
    property bool bDisableMap: settings.mapDisableRecordPage

    //Map buttons
    property bool showSettingsButton: true
    property bool showMinMaxButton: true
    property bool showCenterButton: true

    //Cyclic voice output
    property double iTriggerDistanceVoiceOutput: -1
    property double iTriggerDurationVoiceOutput: -1


    Connections
    {
        target: map
        onMetersPerPixelChanged:
        {
            //Map interaction is only done when map is really shown
            if (!bDisableMap && visible && bShowMap && appWindow.applicationActive)
            {
                fncSetMapUncertainty();
            }
        }
    }

    onStatusChanged:
    {
        console.log("Record onStatusChanged: " + status);
        //console.log("Record page: " + pageStack.currentPage.toString());

        //This is loaded only the first time the page is displayed
        if (status === PageStatus.Active && bLockFirstPageLoad)
        {
            console.log("---RecordPage first active enter---");

            bLockFirstPageLoad = false;                        

            //This setting determines if the map should be completely disabled.
            bDisableMap = settings.mapDisableRecordPage;
            if (bDisableMap)
                bShowMap = false;
            else
                bShowMap = settings.showMapRecordPage;

            //start positioning
            recorder.vStartGPS();            

            console.log("Is track empty: " + recorder.isEmpty.toString())

            //Check if recorder is empty. If this is not the case, there is data from an autoload.
            if (recorder.isEmpty === false)
            {                
                //Now we have to view this data
                bRestoreWorkout = true;

                console.log("Autosave: " + recorder.points.toString());

                for(var i=0;i<recorder.points;i++)
                {
                    fncSetMapPoint(recorder.trackPointAt(i), i);
                }

                //We need to set the last track to the map.
                map.updateSourceLine(sTrackLine, vTrackLinePoints);

                bRestoreWorkout = false;


                //We need to set parameters to the dialog/pebble/cyclic voice
                RecordPageDisplay.arrayValueTypes[8].value = (settings.measureSystem === 0) ? (recorder.distance/1000).toFixed(1) : JSTools.fncConvertDistanceToImperial(recorder.distance/1000).toFixed(1);
                JSTools.arrayPebbleValueTypes[8].value = (settings.measureSystem === 0) ? (recorder.distance/1000).toFixed(1) : JSTools.fncConvertDistanceToImperial(recorder.distance/1000).toFixed(1);
                JSTools.arrayVoiceValueTypes[8].value = (settings.measureSystem === 0) ? (recorder.distance/1000).toFixed(1) : JSTools.fncConvertDistanceToImperial(recorder.distance/1000).toFixed(1);
            }            

            console.log("---RecordPage first active leave---");
        }

        //This is loaded everytime the page is displayed
        if (status === PageStatus.Active)
        {
            console.log("---RecordPage active enter---");            

            //Set map style
            map.styleUrl = settings.mapStyle;

            recorder.newTrackPoint.connect(newTrackPoint);
            recorder.currentPositionChanged.connect(fncCurrentPositionChanged);

            //Set value types for fields in JS array
            RecordPageDisplay.fncConvertSaveStringToArray(settings.valueFields, SharedResources.arrayWorkoutTypes.map(function(e) { return e.name; }).indexOf(settings.workoutType), SharedResources.arrayWorkoutTypes.length);
            JSTools.fncConvertSaveStringToArray(settings.valuePebbleFields);
            JSTools.fncConvertSaveStringToArrayCoverPage(settings.valueCoverFields);
            JSTools.fncConvertSaveStringToArrayCyclicVoiceDistance(settings.voiceCycDistanceFields);
            JSTools.fncConvertSaveStringToArrayCyclicVoiceDuration(settings.voiceCycDurationFields);


            //Set header and footer to text fields
            fncSetHeaderFooterTexts();

            //Set display mode to dialog
            fncSetDisplayMode();            

            //If this page is shown, prevent screen from going blank
            if (settings.disableScreenBlanking)
                fncEnableScreenBlank(true);

            if (sPebblePath !== "" && settings.enablePebble && bPebbleConnected)
            {
                if (settings.measureSystem === 0)
                {
                    //Set metric unit
                    pebbleComm.fncSendDataToPebbleApp("4dab81a6-d2fc-458a-992c-7a1f3b96a970", {'3': 1});
                }
                else
                {
                    //Set imperial unit
                    pebbleComm.fncSendDataToPebbleApp("4dab81a6-d2fc-458a-992c-7a1f3b96a970", {'3': 0});
                }
            }

            if (sHRMAddress !== "" && settings.useHRMdevice && bRecordDialogRequestHRM === false)
            {
                id_BluetoothData.connect(sHRMAddress, 1);
                bRecordDialogRequestHRM = true;
            }

            //Check if pebble is connected
            if (sPebblePath !== "" && settings.enablePebble && !bPebbleConnected)
                bPebbleConnected = id_PebbleWatchComm.isConnected();

            //Load threshold settings and convert them to JS array
            Thresholds.fncConvertSaveStringToArray(settings.thresholds);            

            console.log("---RecordPage active leave---");
        }

        if (status === PageStatus.Inactive)
        {            
            console.log("RecordPage inactive");                        

            if (settings.disableScreenBlanking)
                fncEnableScreenBlank(false);                    

            recorder.newTrackPoint.disconnect(newTrackPoint);
            recorder.currentPositionChanged.disconnect(fncCurrentPositionChanged);
        }
    }

    function fncUpdateBrightness()
    {
        if (id_Light === undefined)
            return;

        //console.log("Brightness: " + id_Light.brightness.toString());

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
            //Really strange thing: this timer is called even when the page is NOT opened!
            //If the prerecord page is open, the timer is called!
            //So we need to find out wether this page is opened anf if not return here.
            if (page.status === 0)
                return;


            //We might be in a state when there are coordinates saved to the temp array because the map was invisible before.
            //If this is the case we can now draw the coordinates to the map.
            //We only need to do this if the accuracy is bad because otherwise this will be triggered by a new coordinate event.
            if (vTempTrackLinePoints !== undefined && vTempTrackLinePoints.length > 0 && !bDisableMap && visible && bShowMap && appWindow.applicationActive && recorder.accuracy >= 30)
            {
                var vLineArray = [];
                var vIndexArray =  [];

                console.log("vTempTrackLinePoints length: " + vTempTrackLinePoints.length.toString());

                vLineArray = vTempTrackLinePoints;
                vIndexArray = vTempTrackLinePointsIndex;

                //The global arrays now will be processed so clear them both.
                var vCleanArray = [];
                vTempTrackLinePoints = vCleanArray;
                vTempTrackLinePointsIndex = vCleanArray;

                bRestoreWorkout = true;

                console.log("Temp points: " + vLineArray.length.toString());

                //Go through the temp array
                for (var i = 0; i < vLineArray.length; i++)
                {
                    //Draw the coordinate points from the temp array on the map
                    fncSetMapPointToMap(vLineArray[i], vIndexArray[i]);
                }

                //We need to set the last track to the map.
                map.updateSourceLine(sTrackLine, vTrackLinePoints);

                bRestoreWorkout = false;
            }


            //Get current light in LUX
            if (settings.autoNightMode)
            {
                //Read from light sensor of smartphone
                id_Light.refresh();

                //console.log("Brightness: " + id_Light.brightness.toString());

                iAutoNightModeValue = iAutoNightModeValue + id_Light.brightness;


                iAutoNightModeLoop++;

                //After wait time, check light value
                if (iAutoNightModeLoop >= 10)
                {
                    //console.log("iAutoNightModeLoop: " + iAutoNightModeLoop.toString());
                    //console.log("iDisplayMode: " + iDisplayMode.toString());
                    //console.log("iOldDisplayMode: " + iOldDisplayMode.toString());
                    //console.log("iAutoNightModeValue: " + iAutoNightModeValue.toString());


                    iAutoNightModeLoop = 0;

                    //If we are currently in night mode, and original mode was something else than night mode, check if light is bright enough to leave night mode
                    if (iDisplayMode === 2 && iOldDisplayMode !== 2 && (iAutoNightModeValue / 3) > 20)
                    {
                        //Set mode to original mode.
                        iDisplayMode = iOldDisplayMode;
                        //Change mode
                        fncSetDisplayMode();
                    }

                    //If we are currently NOT in night mode, check if it is dark enough to enter night mode
                    if (iDisplayMode !== 2 && (iAutoNightModeValue / 3) <= 20)
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

                JSTools.arrayPebbleValueTypes[1].value = sHeartRate;
                JSTools.arrayVoiceValueTypes[1].value = sHeartRate;
            }
            //Set values to JS array if recorder is running
            if (recorder.running && !recorder.pause)
            {
                //0 is empty and 1 is heartrate!
                RecordPageDisplay.arrayValueTypes[2].value = recorder.heartrateaverage.toFixed(1);
                RecordPageDisplay.arrayValueTypes[3].value = (settings.measureSystem === 0) ? recorder.paceStr : recorder.paceImperialStr;
                RecordPageDisplay.arrayValueTypes[4].value = (settings.measureSystem === 0) ? recorder.paceaverageStr : recorder.paceaverageImperialStr;
                RecordPageDisplay.arrayValueTypes[5].value = (settings.measureSystem === 0) ? recorder.speed.toFixed(1) : JSTools.fncConvertSpeedToImperial(recorder.speed).toFixed(1);
                RecordPageDisplay.arrayValueTypes[6].value = (settings.measureSystem === 0) ? recorder.speedaverage.toFixed(1) : JSTools.fncConvertSpeedToImperial(recorder.speedaverage).toFixed(1);
                RecordPageDisplay.arrayValueTypes[7].value = (settings.measureSystem === 0) ? recorder.altitude : JSTools.fncConvertelevationToImperial(recorder.altitude).toFixed(2);
                RecordPageDisplay.arrayValueTypes[8].value = (settings.measureSystem === 0) ? (recorder.distance/1000).toFixed(1) : JSTools.fncConvertDistanceToImperial(recorder.distance/1000).toFixed(1);

                JSTools.arrayPebbleValueTypes[2].value = recorder.heartrateaverage.toFixed(1);
                JSTools.arrayPebbleValueTypes[3].value = (settings.measureSystem === 0) ? recorder.paceStr : recorder.paceImperialStr;
                JSTools.arrayPebbleValueTypes[4].value = (settings.measureSystem === 0) ? recorder.paceaverageStr : recorder.paceaverageImperialStr;
                JSTools.arrayPebbleValueTypes[5].value = (settings.measureSystem === 0) ? recorder.speed.toFixed(1) : JSTools.fncConvertSpeedToImperial(recorder.speed).toFixed(1);
                JSTools.arrayPebbleValueTypes[6].value = (settings.measureSystem === 0) ? recorder.speedaverage.toFixed(1) : JSTools.fncConvertSpeedToImperial(recorder.speedaverage).toFixed(1);
                JSTools.arrayPebbleValueTypes[7].value = (settings.measureSystem === 0) ? recorder.altitude : JSTools.fncConvertelevationToImperial(recorder.altitude).toFixed(1);
                JSTools.arrayPebbleValueTypes[8].value = (settings.measureSystem === 0) ? (recorder.distance/1000).toFixed(1) : JSTools.fncConvertDistanceToImperial(recorder.distance/1000).toFixed(1);

                JSTools.arrayVoiceValueTypes[2].value = recorder.heartrateaverage.toFixed(1);
                JSTools.arrayVoiceValueTypes[3].value = (settings.measureSystem === 0) ? recorder.paceStr : recorder.paceImperialStr;
                JSTools.arrayVoiceValueTypes[4].value = (settings.measureSystem === 0) ? recorder.paceaverageStr : recorder.paceaverageImperialStr;
                JSTools.arrayVoiceValueTypes[5].value = (settings.measureSystem === 0) ? recorder.speed.toFixed(1) : JSTools.fncConvertSpeedToImperial(recorder.speed).toFixed(1);
                JSTools.arrayVoiceValueTypes[6].value = (settings.measureSystem === 0) ? recorder.speedaverage.toFixed(1) : JSTools.fncConvertSpeedToImperia
                JSTools.arrayVoiceValueTypes[7].value = (settings.measureSystem === 0) ? recorder.altitude : JSTools.fncConvertelevationToImperial(recorder.altitude).toFixed(1);
                JSTools.arrayVoiceValueTypes[8].value = (settings.measureSystem === 0) ? (recorder.distance/1000).toFixed(1) : JSTools.fncConvertDistanceToImperial(recorder.distance/1000).toFixed(1);
            }
            if (recorder.running)
            {
                //This is the pause duration
                RecordPageDisplay.arrayValueTypes[9].value = recorder.pauseTime;
                JSTools.arrayPebbleValueTypes[9].value = recorder.pebblePauseTime;
                JSTools.arrayPebbleValueTypes[9].valueCoverPage = recorder.pauseTime;

                //This is the duration
                JSTools.arrayPebbleValueTypes[10].value = recorder.pebbleTime;
                JSTools.arrayPebbleValueTypes[10].valueCoverPage = recorder.time;
                JSTools.arrayVoiceValueTypes[9].value = recorder.time;
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

            if (sPebblePath !== "" && settings.enablePebble)
            {
                pebbleComm.fncSendDataToPebbleApp("4dab81a6-d2fc-458a-992c-7a1f3b96a970", {'0': JSTools.arrayLookupPebbleValueTypesByFieldID[1].value, '1': JSTools.arrayLookupPebbleValueTypesByFieldID[2].value, '2': JSTools.arrayLookupPebbleValueTypesByFieldID[3].value});
            }

            //Set values for LockScreen
            var sValue1, sValue2, sValue3;

            if ("valueCoverPage" in JSTools.arrayLookupCoverPageValueTypesByFieldID[1])
                sValue1 = JSTools.arrayLookupCoverPageValueTypesByFieldID[1].valueCoverPage;
            else
                sValue1 = JSTools.arrayLookupCoverPageValueTypesByFieldID[1].value;

            if ("valueCoverPage" in JSTools.arrayLookupCoverPageValueTypesByFieldID[2])
                sValue2 = JSTools.arrayLookupCoverPageValueTypesByFieldID[2].valueCoverPage;
            else
                sValue2 = JSTools.arrayLookupCoverPageValueTypesByFieldID[2].value;

            if ("valueCoverPage" in JSTools.arrayLookupCoverPageValueTypesByFieldID[3])
                sValue3 = JSTools.arrayLookupCoverPageValueTypesByFieldID[3].valueCoverPage;
            else
                sValue3 = JSTools.arrayLookupCoverPageValueTypesByFieldID[3].value;


            id_LBL_Value1.text = (settings.measureSystem === 0) ? sValue1 + JSTools.arrayLookupCoverPageValueTypesByFieldID[1].unit :
                                                                  sValue1 + JSTools.arrayLookupCoverPageValueTypesByFieldID[1].imperialUnit;
            id_LBL_Value2.text = (settings.measureSystem === 0) ? sValue2 + JSTools.arrayLookupCoverPageValueTypesByFieldID[2].unit :
                                                                  sValue2 + JSTools.arrayLookupCoverPageValueTypesByFieldID[2].imperialUnit;
            id_LBL_Value3.text = (settings.measureSystem === 0) ? sValue3 + JSTools.arrayLookupCoverPageValueTypesByFieldID[3].unit :
                                                                  sValue3 + JSTools.arrayLookupCoverPageValueTypesByFieldID[3].imperialUnit;


            //************functions for cyclic voice output**************
            //Initialize trigger distance
            if (iTriggerDistanceVoiceOutput === -1)
                iTriggerDistanceVoiceOutput = settings.voiceCycDistance;

            if (iTriggerDurationVoiceOutput === -1)
                iTriggerDurationVoiceOutput = settings.voiceCycDuration;


            //If recorder is running and not paused
            if (recorder.running && !recorder.pause)
            {                               
                //Check if we have to play a cyclic voice announcement

                //Check if distance is active
                if (settings.voiceCycDistanceEnable)
                {
                    //Get distance from recorder. This is float with 1 decimal place.
                    var iDistance = (settings.measureSystem === 0) ? parseFloat((recorder.distance/1000).toFixed(1)) : parseFloat(JSTools.fncConvertDistanceToImperial(recorder.distance/1000).toFixed(1));

                    //Check if current distance is same or higher than trigger distance
                    if (iDistance >= iTriggerDistanceVoiceOutput)
                    {
                        //Play voice announcement
                        var arSoundArray = JSTools.fncPlayCyclicVoiceAnnouncement((settings.measureSystem === 0), settings.voiceLanguage, true);

                        //console.log("arSoundArray.length: " + arSoundArray.length.toString());
                        //for (var i = 0; i < arSoundArray.length; i++)
                        //{
                          //  console.log("arSoundArray[" + i.toString() + "]: " + arSoundArray[i]);
                        //}

                        fncPlaySoundArray(arSoundArray);

                        //Set value for next trigger distance
                        iTriggerDistanceVoiceOutput = settings.voiceCycDistance + iDistance;
                    }
                }
                //Check if duration is active
                if (settings.voiceCycDurationEnable)
                {
                    var iTimeSeconds = recorder.timeSeconds;
                    //Check if cuurent duration is same or higher than trigger duration
                    if (iTimeSeconds >= iTriggerDurationVoiceOutput)
                    {
                        //Play voice announcement
                        var arSoundArray = JSTools.fncPlayCyclicVoiceAnnouncement((settings.measureSystem === 0), settings.voiceLanguage, false);

                        //console.log("arSoundArray.length: " + arSoundArray.length.toString());
                        //for (var i = 0; i < arSoundArray.length; i++)
                        //{
                            //console.log("arSoundArray[" + i.toString() + "]: " + arSoundArray[i]);
                        //}

                        fncPlaySoundArray(arSoundArray);

                        //Set value for next trigger distance
                        iTriggerDurationVoiceOutput = settings.voiceCycDuration + iTimeSeconds;
                    }
                }
            }
        }
    }

    Timer
    {
        id: idTimerLockScreenPadding
        interval: 30000
        repeat: true
        running: bShowLockScreen
        onTriggered:
        {
            var iAvailableHeight = page.height - id_ITM_LockScreen.height;

            var iTopMarginRandom = JSTools.fncGetRandomInt(0, iAvailableHeight);

            id_ITM_LockScreen.anchors.topMargin = iTopMarginRandom;
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

                recorder.running = false;
                if(!recorder.isEmpty)
                {
                    showSaveDialog();
                }
            }
        }
    }

    function fncSetMapUncertainty()
    {
        if (map.metersPerPixel > 0)
        {
            map.setPaintProperty("location-uncertainty", "circle-radius", (recorder.accuracy / map.metersPerPixel));
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
        idTXT_1_Footer.text = RecordPageDisplay.fncGetFooterTextByFieldID(1, settings.measureSystem) + " ";
        idTXT_1_Footnote.visible = RecordPageDisplay.fncGetFootnoteVisibleByFieldID(1);
        idTXT_1_Footnote.text = " " + RecordPageDisplay.fncGetFootnoteTextByFieldID(1) + " " + RecordPageDisplay.fncGetFootnoteValueByFieldID(1);

        idTXT_2_Header.text = RecordPageDisplay.fncGetHeaderTextByFieldID(2);
        idTXT_2_Footer.text = RecordPageDisplay.fncGetFooterTextByFieldID(2, settings.measureSystem);
        idTXT_2_Footnote.visible = RecordPageDisplay.fncGetFootnoteVisibleByFieldID(2);
        idTXT_2_Footnote.text = " " + RecordPageDisplay.fncGetFootnoteTextByFieldID(2) + " " + RecordPageDisplay.fncGetFootnoteValueByFieldID(2);

        idTXT_3_Header.text = RecordPageDisplay.fncGetHeaderTextByFieldID(3);
        idTXT_3_Footer.text = RecordPageDisplay.fncGetFooterTextByFieldID(3, settings.measureSystem) + " ";
        idTXT_3_Footnote.visible = RecordPageDisplay.fncGetFootnoteVisibleByFieldID(3);
        idTXT_3_Footnote.text = " " + RecordPageDisplay.fncGetFootnoteTextByFieldID(3) + " " + RecordPageDisplay.fncGetFootnoteValueByFieldID(3);

        idTXT_4_Header.text = RecordPageDisplay.fncGetHeaderTextByFieldID(4);
        idTXT_4_Footer.text = RecordPageDisplay.fncGetFooterTextByFieldID(4, settings.measureSystem);
        idTXT_4_Footnote.visible = RecordPageDisplay.fncGetFootnoteVisibleByFieldID(4);
        idTXT_4_Footnote.text = " " + RecordPageDisplay.fncGetFootnoteTextByFieldID(4) + " " + RecordPageDisplay.fncGetFootnoteValueByFieldID(4);

        idTXT_5_Header.text = RecordPageDisplay.fncGetHeaderTextByFieldID(5);
        idTXT_5_Footer.text = RecordPageDisplay.fncGetFooterTextByFieldID(5, settings.measureSystem) + " ";
        idTXT_5_Footnote.visible = RecordPageDisplay.fncGetFootnoteVisibleByFieldID(5);
        idTXT_5_Footnote.text = " " + RecordPageDisplay.fncGetFootnoteTextByFieldID(5) + " " + RecordPageDisplay.fncGetFootnoteValueByFieldID(5);

        idTXT_6_Header.text = RecordPageDisplay.fncGetHeaderTextByFieldID(6);
        idTXT_6_Footer.text = RecordPageDisplay.fncGetFooterTextByFieldID(6, settings.measureSystem);
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

                //Mainpage must load history data to get this new workout in the list
                bLoadHistoryData = true;

                //We must return here to the mainpage.
                pageStack.pop(vMainPageObject, PageStackAction.Immediate);
            })
            dialog.rejected.connect(function()
            {
                console.log("Cancel workout");
                recorder.clearTrack();

                //We must return here to the mainpage.
                pageStack.pop(vMainPageObject, PageStackAction.Immediate);
            })
        }
    }   

    function fncSetMapPoint(coordinate, iPointIndex)
    {                       
        var vLineArray = [];
        var vIndexArray =  [];

        //Map interaction is only done when map is really shown
        if (bDisableMap || !visible || !bShowMap || !appWindow.applicationActive)
        {
            //console.log("Map invisible. Point: " + iPointIndex.toString());

            //Now the map is not shown at the moment. Save current coordinate to a temp array. Also save the current index to a temp array.
            if (vTempTrackLinePoints !== undefined && vTempTrackLinePoints.length > 0)
            {
               vLineArray = vTempTrackLinePoints;
               vIndexArray = vTempTrackLinePointsIndex;
            }
            vLineArray.push(coordinate);
            vIndexArray.push(iPointIndex);
            //Save that to global array
            vTempTrackLinePoints = vLineArray;
            vTempTrackLinePointsIndex = vIndexArray;

            //Break here.
            return;
        }

        //console.log("Map visible. Point: " + iPointIndex.toString());

        //If we are here, the map is shown and we can do things with it.
        //First check if there is something in the temp array
        if (vTempTrackLinePoints !== undefined && vTempTrackLinePoints.length > 0)
        {
            //console.log("vTempTrackLinePoints length: " + vTempTrackLinePoints.length.toString());

            vLineArray = vTempTrackLinePoints;
            vIndexArray = vTempTrackLinePointsIndex;

            //Save the current coordinate also the temp array
            vLineArray.push(coordinate);
            vIndexArray.push(iPointIndex);

            //The global arrays now will be processed so clear them both.
            var vCleanArray = [];
            vTempTrackLinePoints = vCleanArray;
            vTempTrackLinePointsIndex = vCleanArray;

            bRestoreWorkout = true;

            //console.log("Temp points: " + vLineArray.length.toString());

            //Go through the temp array
            for (var i = 0; i < vLineArray.length; i++)
            {
                //Draw the coordinate points from the temp array on the map
                fncSetMapPointToMap(vLineArray[i], vIndexArray[i]);
            }

            //We need to set the last track to the map.
            map.updateSourceLine(sTrackLine, vTrackLinePoints);

            bRestoreWorkout = false;
        }
        else
        {
            //Here we are if the map is currently shown and there are no temporary saved coordinate points.
            //Show the current point directly to the map.
            fncSetMapPointToMap(coordinate, iPointIndex);
        }
    }

    function fncSetMapPointToMap(coordinate, iPointIndex)
    {
        var vLineArray = [];
        //console.log("Index: " + iPointIndex.toString());               

        //Recognize the start of a workout
        if (iPointIndex === 0 && recorder.running && !recorder.isEmpty)
        {
            //This is the first data point, draw the start icon
            map.addSourcePoint("pointStartImage",  coordinate);
            map.addImagePath("imageStartImage", Qt.resolvedUrl("../img/map_play.png"));
            map.addLayer("layerStartLayer", {"type": "symbol", "source": "pointStartImage"});
            map.setLayoutProperty("layerStartLayer", "icon-image", "imageStartImage");
            map.setLayoutProperty("layerStartLayer", "icon-size", 1.0 / map.pixelRatio);
			map.setLayoutProperty("layerStartLayer", "icon-allow-overlap", true);

            //Create temp line array
            vLineArray = [];
            //Write first coordinate to line array
            vLineArray.push(coordinate);
            //Save that to global array
            vTrackLinePoints = vLineArray;

            sTrackLine = "lineEndTrack";

            //We have to create a track line here.
            map.addSourceLine(sTrackLine, vTrackLinePoints)
            map.addLayer("layerEndTrack", { "type": "line", "source": sTrackLine })
            map.setLayoutProperty("layerEndTrack", "line-join", "round");
            map.setLayoutProperty("layerEndTrack", "line-cap", "round");
            map.setPaintProperty("layerEndTrack", "line-color", "red");
            map.setPaintProperty("layerEndTrack", "line-width", 2.0);            
        }        

        //Recognize the start of a pause
        if (recorder.running && !recorder.isEmpty && iPointIndex > 0 && recorder.pausePointAt(iPointIndex - 1) === false && recorder.pausePointAt(iPointIndex) === true)
        {
            //Draw the pause start icon
            map.addSourcePoint("pointPauseStartImage" + iPausePositionsIndex.toString(),  coordinate);
            map.addImagePath("imagePauseStartImage" + iPausePositionsIndex.toString(), Qt.resolvedUrl("../img/map_pause.png"));
            map.addLayer("layerPauseStartLayer" + iPausePositionsIndex.toString(), {"type": "symbol", "source": "pointPauseStartImage" + iPausePositionsIndex.toString()});
            map.setLayoutProperty("layerPauseStartLayer" + iPausePositionsIndex.toString(), "icon-image", "imagePauseStartImage" + iPausePositionsIndex.toString());
            map.setLayoutProperty("layerPauseStartLayer" + iPausePositionsIndex.toString(), "icon-size", 1.0 / map.pixelRatio);
			map.setLayoutProperty("layerPauseStartLayer" + iPausePositionsIndex.toString(), "icon-allow-overlap", true);        

            //set indexer to next pause position.
            iPausePositionsIndex++;
        }

        //Recognize the end of a pause
        if (recorder.running && !recorder.isEmpty && iPointIndex > 0 && recorder.pausePointAt(iPointIndex - 1) === true && recorder.pausePointAt(iPointIndex) === false)
        {
            //So this is a track point where a pause starts. The next one is the pause end!
            //Draw the pause end icon
            map.addSourcePoint("pointPauseEndImage" + iPausePositionsIndex.toString(), coordinate);
            map.addImagePath("imagePauseEndImage" + iPausePositionsIndex.toString(), Qt.resolvedUrl("../img/map_resume.png"));
            map.addLayer("layerPauseEndLayer" + iPausePositionsIndex.toString(), {"type": "symbol", "source": "pointPauseEndImage" + iPausePositionsIndex.toString()});
            map.setLayoutProperty("layerPauseEndLayer" + iPausePositionsIndex.toString(), "icon-image", "imagePauseEndImage" + iPausePositionsIndex.toString());
            map.setLayoutProperty("layerPauseEndLayer" + iPausePositionsIndex.toString(), "icon-size", 1.0 / map.pixelRatio);
			map.setLayoutProperty("layerPauseEndLayer" + iPausePositionsIndex.toString(), "icon-allow-overlap", true); 

            //Doing the update here is OK because there should not be too many pauses.
            map.updateSourceLine(sTrackLine, vTrackLinePoints);

            //Start new trackline here
            //Create fresh temp line array
            vLineArray = [];
            //Write first coordinate of new track segment to line array
            vLineArray.push(coordinate);
            //Save that to global array
            vTrackLinePoints = vLineArray;

            sTrackLine = "lineTrack" + iPausePositionsIndex.toString();

            //We have to create a track line here.
            map.addSourceLine(sTrackLine, vTrackLinePoints)
            map.addLayer("layerTrack" + iPausePositionsIndex.toString(), { "type": "line", "source": sTrackLine })
            map.setLayoutProperty("layerTrack" + iPausePositionsIndex.toString(), "line-join", "round");
            map.setLayoutProperty("layerTrack" + iPausePositionsIndex.toString(), "line-cap", "round");
            map.setPaintProperty("layerTrack" + iPausePositionsIndex.toString(), "line-color", "red");
            map.setPaintProperty("layerTrack" + iPausePositionsIndex.toString(), "line-width", 2.0);
        }

        //If the current point is not the first one and not a pause point, add it to the current track
        if (recorder.running && !recorder.isEmpty && iPointIndex !== 0 && recorder.pausePointAt(iPointIndex) === false)
        {
            //Create temp line array and set current points array to it. Must use a JS array here because QML arrays don't allow for push!
            vLineArray = vTrackLinePoints;
            //Write first coordinate to line array
            vLineArray.push(coordinate);
            //Save that to global array
            vTrackLinePoints = vLineArray;

            //If we are restoring a workout e.g. from autosave, we must avoid calling updateSourceLine too often.
            //Normally this call adds each position to the track individually. This is way too often for restoring a workout.
            if (!bRestoreWorkout)
                map.updateSourceLine(sTrackLine, vTrackLinePoints);

            if (settings.mapMode === 1 && !bMapMaximized) //center track on map
                map.fitView(vTrackLinePoints);
        }
    }

    function fncCurrentPositionChanged(coordinate)
    {
        //console.log("CurrentPositionChanged");

        //console.log("Record page 2: " + pageStack.currentPage.toString());

        //console.log("bDisableMap: " + bDisableMap.toString());
        //console.log("visible: " + visible.toString());
        //console.log("bShowMap: " + bShowMap.toString());
        //console.log("ApplicationWindow.applicationActive: " + appWindow.applicationActive.toString());

        //Map interaction is only done when map is really shown
        if (bDisableMap || !visible || !bShowMap || !appWindow.applicationActive)
        {
            return;
        }

        if (sCurrentPosition === undefined || sCurrentPosition === "")
        {
            sCurrentPosition = "currentPosition";

            //Create current position point on map
            map.addSourcePoint(sCurrentPosition,  coordinate);

            map.addLayer("location-uncertainty", {"type": "circle", "source": sCurrentPosition});
            map.setPaintProperty("location-uncertainty", "circle-radius", (300 / map.metersPerPixel));
            map.setPaintProperty("location-uncertainty", "circle-color", "#87cefa");
            map.setPaintProperty("location-uncertainty", "circle-opacity", 0.25);

            map.addLayer("location-case", {"type": "circle", "source": sCurrentPosition});
            map.setPaintProperty("location-case", "circle-radius", 10);
            map.setPaintProperty("location-case", "circle-color", "white");

            map.addLayer("location", {"type": "circle", "source": sCurrentPosition});
            map.setPaintProperty("location", "circle-radius", 6);
            map.setPaintProperty("location", "circle-color", "#98CCFD");
        }
        else
        {
            map.updateSourcePoint(sCurrentPosition, coordinate);
            fncSetMapUncertainty();
        }

        if (settings.mapMode === 0  && !bMapMaximized)
            map.center = coordinate;
    }

    function newTrackPoint(coordinate, iPointIndex)
    {
        //console.log("Position: " + recorder.currentPosition);
        //console.log("newTrackPoint");

        fncSetMapPoint(coordinate, iPointIndex);

        //Thresholds processing needs to be disabled if recording is paused
        if (recorder.pause)
            return;

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
            visible: !bShowLockScreen

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
                visible: !bDisableMap
                onClicked:
                {
                    bShowMap = !bShowMap;
                    settings.showMapRecordPage = bShowMap;
                }
            }
            MenuItem
            {
                text: "Test voice output distance"
                onClicked:
                {                                                                               
                    var arSoundArray = JSTools.fncPlayCyclicVoiceAnnouncement((settings.measureSystem === 0), settings.voiceLanguage, true);
                    console.log("arSoundArray.length: " + arSoundArray.length.toString());

                    for (var i = 0; i < arSoundArray.length; i++)
                    {
                        console.log("arSoundArray[" + i.toString() + "]: " + arSoundArray[i]);
                    }

                    fncPlaySoundArray(arSoundArray);
                }
            }
            MenuItem
            {
                text: "Test voice output duration"
                onClicked:
                {
                    var arSoundArray = JSTools.fncPlayCyclicVoiceAnnouncement((settings.measureSystem === 0), settings.voiceLanguage, false);
                    console.log("arSoundArray.length: " + arSoundArray.length.toString());

                    for (var i = 0; i < arSoundArray.length; i++)
                    {
                        console.log("arSoundArray[" + i.toString() + "]: " + arSoundArray[i]);
                    }

                    fncPlaySoundArray(arSoundArray);
                }
            }
        }
        PushUpMenu
        {
            id: menuUP
            visible: !bShowLockScreen

            MenuItem
            {
                text: qsTr("Lock screen")
                onClicked:
                {
                    if (!bShowLockScreen)
                    {
                        var iAvailableHeight = page.height - id_ITM_LockScreen.height;

                        var iTopMarginRandom = JSTools.fncGetRandomInt(0, iAvailableHeight);

                        id_ITM_LockScreen.anchors.topMargin = iTopMarginRandom;

                        bShowMap = false;
                        bShowLockScreen = true;
                    }
                    else
                        bShowLockScreen = false;
                }
            }

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
            MenuItem
            {
                text: qsTr("Restart Pebble App")
                visible: settings.enablePebble
                onClicked:
                {
                    //Launch pebble sport app
                    pebbleComm.fncLaunchPebbleApp("4dab81a6-d2fc-458a-992c-7a1f3b96a970");
                }
            }
        }

        //contentHeight: column.height + Theme.paddingLarge


        Rectangle
        {
            visible: bShowLockScreen
            color: (iDisplayMode !== 3) ? cBackColor : "black"
            anchors.fill: parent
            z: 2

            MouseArea
            {
                anchors.fill: parent
                onClicked:
                {
                    if (!bShowLockScreen)
                        return;

                    //Check if an other value field was pressed before.
                    //Use 99 for LockScreen
                    if (iValueFieldPressed !== 99)
                    {
                        iValueFieldPressed = 99;
                        iKeepPressingButton = 3;
                    }
                    else
                        iKeepPressingButton--;

                    if (iKeepPressingButton === 0)
                    {
                        idTimerKeepTappingReset.stop();
                        iKeepPressingButton = 4;

                        bShowLockScreen = false;
                    }
                    else
                        idTimerKeepTappingReset.restart();
                }
            }

            Item
            {
                id: id_ITM_LockScreen
                anchors.top: parent.top
                anchors.topMargin: 0
                width: parent.width
                height: parent.height / 4

                Text
                {
                    color: cPrimaryTextColor
                    id: id_LBL_Value1
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    fontSizeMode: Text.Fit
                    font.pointSize: Theme.fontSizeLarge
                }
                Text
                {
                    color: cPrimaryTextColor
                    id: id_LBL_Value2
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    fontSizeMode: Text.Fit
                    font.pointSize: Theme.fontSizeLarge
                }
                Text
                {
                    color: cPrimaryTextColor
                    id: id_LBL_Value3
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    fontSizeMode: Text.Fit
                    font.pointSize: Theme.fontSizeLarge
                }
            }
        }


        Rectangle
        {
            visible: (iKeepPressingButton !== 4)
            z: 3
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
            z: 3
            color: "steelblue"
            width: parent.width
            height: parent.height/10
            anchors.centerIn: parent
            Label
            {
                color: "white"
                text: qsTr("hold button for: %1 s").arg(iButtonLoop.toString());
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
                color: !recorder.running ? "green" : (recorder.pause ? "orange" : "red")
                falloffRadius: 0.15
                radius: 1.0
                cache: false
            }
            Text
            {
                text: !recorder.running ? qsTr("Stopped") : (recorder.pause ? qsTr("Paused") : qsTr("Recording"))
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
                    if (bShowLockScreen)
                        return;

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
                    if (bShowLockScreen)
                        return;

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
                    if (bShowLockScreen)
                        return;

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
                    if (bShowLockScreen)
                        return;

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
                    if (bShowLockScreen)
                        return;

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
                    if (bShowLockScreen)
                        return;

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
                color: recorder.isEmpty ? "dimgrey" : (recorder.pause ? "mediumseagreen" : "lightsalmon")
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
                        if (bShowLockScreen)
                            return;

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
                color: (recorder.isEmpty && (recorder.accuracy >= 30 || recorder.accuracy < 0)) ? "dimgrey" : (!recorder.running && recorder.isEmpty ? "#389632" : "indianred")
                border.color: (recorder.isEmpty && (recorder.accuracy >= 30 || recorder.accuracy < 0)) ? "grey" : "white"
                border.width: 2
                radius: 10
                Image
                {
                    height: parent.height
                    anchors.left: parent.left
                    fillMode: Image.PreserveAspectFit
                    source: !recorder.running && recorder.isEmpty ? "image://theme/icon-l-add" :  "image://theme/icon-l-clear"
                }
                Label
                {
                    anchors.right: parent.right
                    anchors.rightMargin: Theme.paddingMedium
                    anchors.verticalCenter: parent.verticalCenter
                    font.pixelSize: Theme.fontSizeLarge
                    color: (recorder.isEmpty && (recorder.accuracy >= 30 || recorder.accuracy < 0)) ? "grey" : "white"
                    text: !recorder.running && recorder.isEmpty ? qsTr("Start") : qsTr("End")
                }
                MouseArea
                {
                    anchors.fill: parent
                    onPressed:
                    {
                        if (bShowLockScreen)
                            return;

                        if (!recorder.running && recorder.isEmpty)
                        {
                            //Check accuracy
                            if (recorder.accuracy > 0 && recorder.accuracy < 30)
                            {
                                //Start workout
                                recorder.running = true;
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
                        if (bShowLockScreen)
                            return;

                        bEndLoop = true;
                    }
                }
            }
        }
    }
    MapboxMap
    {
        id: map

        width: parent.width
        height: bMapMaximized ? page.height : page.height / 3
        anchors.bottom: parent.bottom

        center: QtPositioning.coordinate(51.9854, 9.2743)
        zoomLevel: 8.0
        minimumZoomLevel: 0
        maximumZoomLevel: 20
        pixelRatio: 3.0

        accessToken: "pk.eyJ1IjoiamRyZXNjaGVyIiwiYSI6ImNqYmVta256YTJsdjUzMm1yOXU0cmxibGoifQ.JiMiONJkWdr0mVIjajIFZQ"
        cacheDatabaseMaximalSize: (settings.mapCache)*1024*1024
        cacheDatabaseDefaultPath: true

        styleUrl: settings.mapStyle

        visible: bShowMap

        Item
        {
            id: centerButton
            anchors.left: parent.left
            anchors.leftMargin: Theme.paddingSmall
            anchors.top: parent.top
            anchors.topMargin: Theme.paddingSmall
            width: parent.width / 10
            height: parent.width / 10
            visible: showCenterButton && bMapMaximized
            z: 200

            MouseArea
            {
                anchors.fill: parent
                onReleased:
                {
                    if (bShowLockScreen)
                        return;

                    console.log("centerButton pressed");
                    map.center = recorder.currentPosition;
                }
            }
            Image
            {
                anchors.fill: parent
                source: "../img/map_btn_center.png"
            }
        }
        Item
        {
            id: minmaxButton
            anchors.right: parent.right
            anchors.rightMargin: Theme.paddingSmall
            anchors.top: parent.top
            anchors.topMargin: Theme.paddingSmall
            width: parent.width / 10
            height: parent.width / 10
            visible: showMinMaxButton
            z: 200

            MouseArea
            {
                anchors.fill: parent
                onReleased:
                {
                    if (bShowLockScreen)
                        return;

                    console.log("minmaxButton pressed");
                    bMapMaximized = !bMapMaximized;
                }
            }
            Image
            {
                anchors.fill: parent
                source: (map.height === page.height) ? "../img/map_btn_min.png" : "../img/map_btn_max.png"
            }
        }
        Item
        {
            id: settingsButton
            anchors.right: parent.right
            anchors.rightMargin: Theme.paddingSmall
            anchors.bottom: parent.bottom
            anchors.bottomMargin: Theme.paddingSmall
            width: parent.width / 10
            height: parent.width / 10
            visible: showSettingsButton
            z: 200

            MouseArea
            {
                anchors.fill: parent
                onReleased:
                {
                    if (bShowLockScreen)
                        return;

                    console.log("settingsButton pressed");
                    pageStack.push(Qt.resolvedUrl("MapSettingsPage.qml"));
                }
            }
            Image
            {
                anchors.fill: parent
                source: "../img/map_btn_settings.png"
            }
        }

        MapboxMapGestureArea
        {
            id: mouseArea
            map: map
            activeClickedGeo: true
            activeDoubleClickedGeo: true
            activePressAndHoldGeo: false

            onDoubleClicked:
            {
                if (bShowLockScreen)
                    return;

                //console.log("onDoubleClicked: " + mouse)
                map.setZoomLevel(map.zoomLevel + 1, Qt.point(mouse.x, mouse.y) );
            }
            onDoubleClickedGeo:
            {
                if (bShowLockScreen)
                    return;

                //console.log("onDoubleClickedGeo: " + geocoordinate);
                map.center = geocoordinate;
            }
        }
    }

    Component
    {
        id: id_Dialog_ChooseValue

        Dialog
        {
            id: diagDialog
            width: parent.width
            height: parent.height
            canAccept: true
            acceptDestination: page
            acceptDestinationAction: PageStackAction.Pop            

            DialogHeader
            {
                id: diagTitle
                title: qsTr("Select value!")
                defaultAcceptText: qsTr("Accept")
                defaultCancelText: qsTr("Cancel")
            }

            SilicaListView
            {
                id: listView
                anchors.top: diagTitle.bottom
                anchors.bottom: diagDialog.bottom
                anchors.left: parent.left
                anchors.right: parent.right

                //header: PageHeader {}
                model: RecordPageDisplay.arrayValueTypes;

                //TODO: scrappy thing does not work, no idea :-((
                VerticalScrollDecorator {}

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
