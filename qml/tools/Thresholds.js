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

.pragma library


var iLastHeartRateArea = -1;
var iHRAboveTopCounter = 0;
var iHRBelowTopCounter = 0;
var iHRAboveBottomCounter = 0;
var iHRBelowBottomCounter = 0;
var iHRUpperCounter = 3;    //these are the update cycles which are used as waiting time before triggering threshold
var iHRLowerCounter = 3;    //these are the update cycles which are used as waiting time before triggering threshold


var iLastPaceArea = -1;
var iPaceAboveTopCounter = 0;
var iPaceBelowTopCounter = 0;
var iPaceAboveBottomCounter = 0;
var iPaceBelowBottomCounter = 0 ;
var iPaceUpperCounter = 4;  //these are the update cycles which are used as waiting time before triggering threshold
var iPaceLowerCounter = 4;  //these are the update cycles which are used as waiting time before triggering threshold


var arrayThresholdProfiles =
[
    //{ name: "Test profile", active: true, bHRUpperThresholdEnable: false, iHRUpperThreshold: 165, bHRLowerThresholdEnable: false, iHRLowerThreshold: 135, bPaceUpperThresholdEnable: false, fPaceUpperThreshold: 6.5, bPaceLowerThresholdEnable: false, fPaceLowerThreshold: 4.5 },
    //{ name: "Race", active: false, bHRUpperThresholdEnable: true, iHRUpperThreshold: 183, bHRLowerThresholdEnable: false, iHRLowerThreshold: 135, bPaceUpperThresholdEnable: true, fPaceUpperThreshold: 5.0, bPaceLowerThresholdEnable: true, fPaceLowerThreshold: 4.3 },
    //{ name: "GA1", active: false, bHRUpperThresholdEnable: true, iHRUpperThreshold: 142, bHRLowerThresholdEnable: true, iHRLowerThreshold: 135, bPaceUpperThresholdEnable: false, fPaceUpperThreshold: 5.0, bPaceLowerThresholdEnable: false, fPaceLowerThreshold: 4.3 }
]

//Create lookup table for threshold profiles.
//This is a helper table to easier access the threshold profiles table.
var arrayLookupThresholdProfilesByName = {};
for (var i = 0; i < arrayThresholdProfiles.length; i++)
{
    arrayLookupThresholdProfilesByName[arrayThresholdProfiles[i].name] = arrayThresholdProfiles[i];
}

function fncConvertSaveStringToArray(sSaveString)
{
    //"Default profile,true,false,173,false,133,false,6.3,false,3.3|Second profile,true,172,true,132,true,6.2,true,3.2"

    //First delete array
    arrayThresholdProfiles = [];

    var arProfiles = sSaveString.split("|");

    //Go through profiles
    for (var i = 0; i < arProfiles.length; i++)
    {
        var arParameters = arProfiles[i].split(",");

        //Check length, you never know...
        if (arParameters.length !== 10)
            continue;

        //Go through parameters for this profile
        for (var j = 0; j < arParameters.length; j++)
        {
            arrayThresholdProfiles[i] = new Object();

            //First one is always off!
            if (i === 0)
                arrayThresholdProfiles[i]["name"] = qsTr("Thresholds off");
            else
                arrayThresholdProfiles[i]["name"] = arParameters[0];

            arrayThresholdProfiles[i]["active"] = (arParameters[1] === "true");
            arrayThresholdProfiles[i]["bHRUpperThresholdEnable"] = (arParameters[2] === "true");
            arrayThresholdProfiles[i]["iHRUpperThreshold"] = parseInt(arParameters[3]);
            arrayThresholdProfiles[i]["bHRLowerThresholdEnable"] = (arParameters[4] === "true");
            arrayThresholdProfiles[i]["iHRLowerThreshold"] = parseInt(arParameters[5]);
            arrayThresholdProfiles[i]["bPaceUpperThresholdEnable"] = (arParameters[6] === "true");
            arrayThresholdProfiles[i]["fPaceUpperThreshold"] = parseFloat(arParameters[7]);
            arrayThresholdProfiles[i]["bPaceLowerThresholdEnable"] = (arParameters[8] === "true");
            arrayThresholdProfiles[i]["fPaceLowerThreshold"] = parseFloat(arParameters[9]);
        }
    }
}

function fncConvertArrayToSaveString()
{
    var sReturnString = "";

    //Go through profiles
    for (var i = 0; i < arrayThresholdProfiles.length; i++)
    {
        sReturnString = sReturnString + arrayThresholdProfiles[i]["name"] + ",";
        sReturnString = sReturnString + arrayThresholdProfiles[i]["active"].toString() + ",";
        sReturnString = sReturnString + arrayThresholdProfiles[i]["bHRUpperThresholdEnable"].toString() + ",";
        sReturnString = sReturnString + arrayThresholdProfiles[i]["iHRUpperThreshold"].toString() + ",";
        sReturnString = sReturnString + arrayThresholdProfiles[i]["bHRLowerThresholdEnable"].toString() + ",";
        sReturnString = sReturnString + arrayThresholdProfiles[i]["iHRLowerThreshold"].toString() + ",";
        sReturnString = sReturnString + arrayThresholdProfiles[i]["bPaceUpperThresholdEnable"].toString() + ",";
        sReturnString = sReturnString + arrayThresholdProfiles[i]["fPaceUpperThreshold"].toString() + ",";
        sReturnString = sReturnString + arrayThresholdProfiles[i]["bPaceLowerThresholdEnable"].toString() + ",";
        sReturnString = sReturnString + arrayThresholdProfiles[i]["fPaceLowerThreshold"].toString()

        sReturnString = sReturnString + "|";
    }

    //kill the last | and then return
    return sReturnString.substr(0, (sReturnString.length - 1));
}

function fncGetActiveProfileObject()
{
    //Go through profiles
    for (var i = 0; i < arrayThresholdProfiles.length; i++)
    {
        if (arrayThresholdProfiles[i].active === true)
            return arrayThresholdProfiles[i];
    }
    return arrayThresholdProfiles[0];
}

function fncGetProfileObjectByIndex(iIndex)
{
    //Go through profiles
    for (var i = 0; i < arrayThresholdProfiles.length; i++)
    {
        //Set profile with matching index to active. All other ones inactiv!!!
        if (i === iIndex)
            return arrayThresholdProfiles[i];
    }
    return arrayThresholdProfiles[0];
}

function fncSetCurrentProfileByIndex(iIndex)
{
    //Go through profiles
    for (var i = 0; i < arrayThresholdProfiles.length; i++)
    {
        //Set profile with matching index to active. All other ones inactiv!!!
        if (i === iIndex)
            arrayThresholdProfiles[i].active = true;
        else
            arrayThresholdProfiles[i].active = false;
    }
}

function fncGetCurrentProfileIndex()
{
    //Go through profiles
    for (var i = 0; i < arrayThresholdProfiles.length; i++)
    {
        if (arrayThresholdProfiles[i].active === true)
            return i;
    }
    return 0;
}

function fncCheckHRThresholds(sHeartRate)
{
    //Check if heartrate has correct value. sHeartrate comes from --> harbour-laufhelden.qml
    if (sHeartRate === "" || sHeartRate === "-1")
    {
        return;
    }
    //Parse pulse value to int
    var iHeartrate = parseInt(sHeartRate);

    if (iHeartrate === 0)
        return;

    //Heart rate areas:
    //-1 not defined, start value
    // 0 below lower threshold
    // 1 between lower and upper threshold (good area)
    // 2 above upper threshold

    var oActiveProfileObject = fncGetActiveProfileObject();

    if (oActiveProfileObject.bHRUpperThresholdEnable)
    {
        //First condition: detect a break from below through the upper threshold
        if (iLastHeartRateArea != 2 && iHeartrate >= oActiveProfileObject.iHRUpperThreshold)
        {
            //Ok the threshold was triggered. Check how often in a row that was the case.
            if (iHRAboveTopCounter >= iHRUpperCounter)
            {
                iHRAboveTopCounter = 0;
                iLastHeartRateArea = 2;

                return 3;   //too high
                //fncPlaySound("audio/hr_toohigh.wav");
            }
            else
                iHRAboveTopCounter+=1;
        }
        //Second condition: detect a break from above through the upper threshold
        else if(iLastHeartRateArea == 2 && iHeartrate < oActiveProfileObject.iHRUpperThreshold)
        {
            //Ok the threshold was triggered. Check how often in a row that was the case.
            if (iHRBelowTopCounter >= iHRUpperCounter)
            {
                iHRBelowTopCounter = 0;
                iLastHeartRateArea = 1;

                return 1;   //normal
                //fncPlaySound("audio/hr_normal.wav");
            }
            else
                iHRBelowTopCounter+=1;
        }
        else
        {
            //OK, the threshold was not triggered. Reset the trigger counters.
            iHRAboveTopCounter = 0;
            iHRBelowTopCounter = 0;
        }
    }

    if (oActiveProfileObject.bHRLowerThresholdEnable)
    {
        //First condition: detect a break from above through the bottom threshold
        if (iLastHeartRateArea != 0 && iHeartrate <= oActiveProfileObject.iHRLowerThreshold)
        {
            //Ok the threshold was triggered. Check how often in a row that was the case.
            if (iHRBelowBottomCounter >= iHRLowerCounter)
            {
                iHRBelowBottomCounter = 0;
                iLastHeartRateArea = 0;

                return 2;   //too low
                //fncPlaySound("audio/hr_toolow.wav");
            }
            else
                iHRBelowBottomCounter+=1;
        }
        //Second condition: detect a break from below through the bottom threshold
        else if(iLastHeartRateArea == 0 && iHeartrate > oActiveProfileObject.iHRLowerThreshold)
        {
            //Ok the threshold was triggered. Check how often in a row that was the case.
            if (iHRAboveBottomCounter >= iHRLowerCounter)
            {
                iHRAboveBottomCounter = 0;
                iLastHeartRateArea = 1;

                return 1;   //normal
                //fncPlaySound("audio/hr_normal.wav");
            }
            else
                iHRAboveBottomCounter+=1;
        }
        else
        {
            //OK, the threshold was not triggered. Reset the trigger counters.
            iHRAboveBottomCounter = 0;
            iHRBelowBottomCounter = 0;
        }
    }
}

function fncCheckPaceThresholds(fPace)
{
    //Pace areas:
    //-1 not defined, start value
    // 0 below lower threshold
    // 1 between lower and upper threshold (good area)
    // 2 above upper threshold

    var oActiveProfileObject = fncGetActiveProfileObject();

    if (oActiveProfileObject.bPaceUpperThresholdEnable)      //Speed is too slow
    {
        //First condition: detect a break from below through the upper threshold
        if (iLastPaceArea != 2 && fPace >= oActiveProfileObject.fPaceUpperThreshold)
        {
            //Ok the threshold was triggered. Check how often in a row that was the case.
            if (iPaceAboveTopCounter >= iPaceUpperCounter)
            {
                iPaceAboveTopCounter = 0;
                iLastPaceArea = 2;

                return 2;   //too low

                //fncPlaySound("audio/pace_toolow.wav");
                //fncVibrate(3, 500);
            }
            else
                iPaceAboveTopCounter+=1;
        }
        //Second condition: detect a break from above through the upper threshold
        else if(iLastPaceArea == 2 && fPace < oActiveProfileObject.fPaceUpperThreshold)
        {
            //Ok the threshold was triggered. Check how often in a row that was the case.
            if (iPaceBelowTopCounter >= iPaceUpperCounter)
            {
                iPaceBelowTopCounter = 0;
                iLastPaceArea = 1;

                return 1;   //normal

                //fncPlaySound("audio/pace_normal.wav");
            }
            else
                iPaceBelowTopCounter+=1;
        }
        else
        {
            //OK, the threshold was not triggered. Reset the trigger counters.
            iPaceAboveTopCounter = 0;
            iPaceBelowTopCounter = 0;
        }
    }

    if (oActiveProfileObject.bPaceLowerThresholdEnable)    //Speed is too fast
    {
        //First condition: detect a break from above through the bottom threshold
        if (iLastPaceArea != 0 && fPace <= oActiveProfileObject.fPaceLowerThreshold)
        {
            //Ok the threshold was triggered. Check how often in a row that was the case.
            if (iPaceBelowBottomCounter >= iPaceLowerCounter)
            {
                iPaceBelowBottomCounter = 0;
                iLastPaceArea = 0;

                return 3;   //too high

                //fncPlaySound("audio/pace_toohigh.wav");

                //fncVibrate(3, 200);
            }
            else
                iPaceBelowBottomCounter+=1;
        }
        //Second condition: detect a break from below through the bottom threshold
        else if(iLastPaceArea == 0 && fPace > oActiveProfileObject.fPaceLowerThreshold)
        {
            //Ok the threshold was triggered. Check how often in a row that was the case.
            if (iPaceAboveBottomCounter >= iPaceLowerCounter)
            {
                iPaceAboveBottomCounter = 0;
                iLastPaceArea = 1;

                return 1;   //normal

                //fncPlaySound("audio/pace_normal.wav");
            }
            else
                iPaceAboveBottomCounter+=1;
        }
        else
        {
            //OK, the threshold was not triggered. Reset the trigger counters.
            iPaceAboveBottomCounter = 0;
            iPaceBelowBottomCounter = 0;
        }
    }
}
