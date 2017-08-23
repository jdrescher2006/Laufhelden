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

/*----------------START used bluetooth adapters----------------*/

var arrayUsedAdapters = new Array();

function fncFillUsedAdaptersArray(sUsedAdaptersNames, sUsedAdaptersAddresses)
{
    arrayUsedAdapters = new Array();

    var arrayNames = sUsedAdaptersNames.split("#,#");
    var arrayAddresses = sUsedAdaptersAddresses.split("#,#");

    //If there is no data or amount of names and amount of addresses differ, exit.
    if (arrayNames.length === 0 || arrayNames.length !== arrayAddresses.length)
        return;

    for (var i = 0; i < arrayNames.length; i++)
    {        
        arrayUsedAdapters[i] = new Object();
        arrayUsedAdapters[i]["BTName"] = arrayNames[i];
        arrayUsedAdapters[i]["BTAddress"] = arrayAddresses[i];
    }        
}

function fncAddUsedDevice(sBTName, sBTAddress)
{      
    //Hier ist irgendwo ein Bug

    var iPosition = arrayUsedAdapters.length;

    //Check if the device address is already in the list.
    //DEBUG: this might not work here, because object arrays have no length in crazy JS!!!
    for (var i = 0; i < arrayUsedAdapters.length; i++)
    {
        if (arrayUsedAdapters[i]["BTAddress"] === sBTAddress)
        {
            //If the adapter is already in the list, break here.
            return false;
        }
    }

    arrayUsedAdapters[iPosition] = new Object();
    arrayUsedAdapters[iPosition]["BTName"] = sBTName;
    arrayUsedAdapters[iPosition]["BTAddress"] = sBTAddress;

    return true;
}

function fncGetUsedDeviceBTNamesSeparatedString()
{
    var sSeparatedString = "";

    for (var i = 0; i < arrayUsedAdapters.length; i++)
    {       
        //Check if this is the last iteration
        if ((i+1) >= arrayUsedAdapters.length)
            sSeparatedString = sSeparatedString + arrayUsedAdapters[i]["BTName"];
        else
            sSeparatedString = sSeparatedString + arrayUsedAdapters[i]["BTName"] + "#,#";
    }

    return sSeparatedString;
}

function fncGetUsedDeviceBTAddressesSeparatedString()
{
    var sSeparatedString = "";

    for (var i = 0; i < arrayUsedAdapters.length; i++)
    {
        //Check if this is the last iteration
        if ((i+1) >= arrayUsedAdapters.length)
            sSeparatedString = sSeparatedString + arrayUsedAdapters[i]["BTAddress"];
        else
            sSeparatedString = sSeparatedString + arrayUsedAdapters[i]["BTAddress"] + "#,#";
    }

    return sSeparatedString;
}

function fncGetUsedDevicesNumber()
{
    return arrayUsedAdapters.length;
}

function fncGetUsedDeviceBTName(iIndex)
{
    return arrayUsedAdapters[iIndex]["BTName"];
}

function fncGetUsedDeviceBTAddress(iIndex)
{
    return arrayUsedAdapters[iIndex]["BTAddress"];
}

/*----------------END used bluetooth adapters----------------*/


/*--------------START scanned bluetooth adapters--------------*/

var arrayMainDevicesArray = new Array();

function fncAddDevice(sBTName, sBTAddress)
{
    var iPosition = arrayMainDevicesArray.length;

    arrayMainDevicesArray[iPosition] = new Object();
    arrayMainDevicesArray[iPosition]["BTName"] = sBTName;
    arrayMainDevicesArray[iPosition]["BTAddress"] = sBTAddress;
}

function fncDeleteDevices()
{
    arrayMainDevicesArray = new Array();
}

function fncGetDevicesNumber()
{
    return arrayMainDevicesArray.length;
}

function fncGetDeviceBTName(iIndex)
{
    return arrayMainDevicesArray[iIndex]["BTName"];
}

function fncGetDeviceBTAddress(iIndex)
{
    return arrayMainDevicesArray[iIndex]["BTAddress"];
}

/*--------------END scanned bluetooth adapters--------------*/



/*--------------START workout table --------------*/

var arrayWorkoutTypes =
[
    { name: "running", labeltext: qsTr("Running"), icon: "../workouticons/running.png" },
    { name: "biking", labeltext: qsTr("Roadbike"), icon: "../workouticons/biking.png" },
    { name: "mountainBiking", labeltext: qsTr("Mountainbike"), icon: "../workouticons/mountainBiking.png" },
    { name: "walking", labeltext: qsTr("Walking"), icon: "../workouticons/walking.png" }
]

//Create lookup table for workout types.
//This is a helper table to easier access the workout type table.
var arrayLookupWorkoutTableByName = {};
for (var i = 0; i < arrayWorkoutTypes.length; i++)
{
    arrayLookupWorkoutTableByName[arrayWorkoutTypes[i].name] = arrayWorkoutTypes[i];
}

/*--------------END workout table --------------*/


/*--------------START thresholds  --------------*/

var arrayThresholdProfiles =
[
    { name: "Default profile", bHRUpperThresholdEnable: false, iHRUpperThreshold: 165, bHRLowerThresholdEnable: false, iHRLowerThreshold: 135, bPaceUpperThresholdEnable: false, fPaceUpperThreshold: 6.5, bPaceLowerThresholdEnable: false, fPaceLowerThreshold: 4.5 },
    { name: "Race", bHRUpperThresholdEnable: true, iHRUpperThreshold: 183, bHRLowerThresholdEnable: false, iHRLowerThreshold: 135, bPaceUpperThresholdEnable: true, fPaceUpperThreshold: 5.0, bPaceLowerThresholdEnable: true, fPaceLowerThreshold: 4.3 },
    { name: "GA1", bHRUpperThresholdEnable: true, iHRUpperThreshold: 142, bHRLowerThresholdEnable: true, iHRLowerThreshold: 135, bPaceUpperThresholdEnable: false, fPaceUpperThreshold: 5.0, bPaceLowerThresholdEnable: false, fPaceLowerThreshold: 4.3 }
]

function fncConvertSaveStringToArray(sSaveString)
{
    //"Default profile,false,173,false,133,false,6.3,false,3.3|Second profile,true,172,true,132,true,6.2,true,3.2"

    //First delete array
    arrayThresholdProfiles = [];

    var arProfiles = sSaveString.split("|");

    //Go through profiles
    for (var i = 0; i < arProfiles.length; i++)
    {
        var arParameters = arProfiles[i].split(",");

        //Check length, you never know...
        if (arParameters.length !== 9)
            continue;

        //Go through parameters for this profile
        for (var j = 0; j < arParameters.length; j++)
        {
            arrayThresholdProfiles[i] = new Object();
            arrayThresholdProfiles[i]["name"] = arParameters[0];
            arrayThresholdProfiles[i]["bHRUpperThresholdEnable"] = (arParameters[1] === "true");
            arrayThresholdProfiles[i]["iHRUpperThreshold"] = parseInt(arParameters[2]);
            arrayThresholdProfiles[i]["bHRLowerThresholdEnable"] = (arParameters[3] === "true");
            arrayThresholdProfiles[i]["iHRLowerThreshold"] = parseInt(arParameters[4]);
            arrayThresholdProfiles[i]["bPaceUpperThresholdEnable"] = (arParameters[5] === "true");
            arrayThresholdProfiles[i]["fPaceUpperThreshold"] = parseFloat(arParameters[6]);
            arrayThresholdProfiles[i]["bPaceLowerThresholdEnable"] = (arParameters[7] === "true");
            arrayThresholdProfiles[i]["fPaceLowerThreshold"] = parseFloat(arParameters[8]);
        }
    }
}

function fncConvertArrayToSaveString()
{

}

/*--------------END thresholds  --------------*/





