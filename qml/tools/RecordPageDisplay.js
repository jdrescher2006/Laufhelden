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

var arrayValueTypes =
[
    { index: 0, fieldID: "0", value: 0, header: qsTr("Empty"), footer: "", footnote: false, footnoteText: "", footnoteValue: 0 },
    { index: 1, fieldID: "2", value: 0, header: qsTr("Heartrate"), footer: qsTr("bpm"), footnote: true, footnoteText: qsTr("Bat.:"), footnoteValue: 0 },
    { index: 2, fieldID: "3", value: 0, header: qsTr("Heartrate") + "∅", footer: qsTr("bpm"),footnote: false, footnoteText: "", footnoteValue: 0 },
    { index: 3, fieldID: "4", value: 0, header: qsTr("Pace"), footer: qsTr("min/km"), footnote: false, footnoteText: "", footnoteValue: 0 },
    { index: 4, fieldID: "5", value: 0, header: qsTr("Pace") + "∅", footer: qsTr("min/km"), footnote: false, footnoteText: "", footnoteValue: 0 },
    { index: 5, fieldID: "6", value: 0, header: qsTr("Speed"), footer: qsTr("km/h"), footnote: false, footnoteText: "", footnoteValue: 0 },
    { index: 6, fieldID: "0", value: 0, header: qsTr("Speed") + "∅", footer: qsTr("km/h"), footnote: false, footnoteText: "", footnoteValue: 0 },
    { index: 7, fieldID: "0", value: 0, header: qsTr("Altitude"), footer: qsTr("m"), footnote: false, footnoteText: "", footnoteValue: 0 },
    { index: 8, fieldID: "1", value: 0, header: qsTr("Distance"), footer: qsTr("km"), footnote: false, footnoteText: "", footnoteValue: 0 }
]

function fncAddFieldIDByIndex(iIndex, iFieldID)
{
    console.log("Old fieldID: " + arrayValueTypes[iIndex].fieldID);

    var arFieldIDString = arrayValueTypes[iIndex].fieldID.split(",");

    var sNewFieldIDString = "";

    if (arFieldIDString.length === 1 && arFieldIDString[0] === "0")
        sNewFieldIDString = iFieldID.toString();
    else
        sNewFieldIDString = arrayValueTypes[iIndex].fieldID + "," + iFieldID.toString();

    console.log("New fieldID: " + sNewFieldIDString);

    arrayValueTypes[iIndex].fieldID = sNewFieldIDString;
}

function fncRemoveFieldIDByIndex(iIndex, iFieldID)
{
    console.log("Old fieldID: " + arrayValueTypes[iIndex].fieldID);

    var arFieldIDString = arrayValueTypes[iIndex].fieldID.split(",");

    var sNewFieldIDString = "";

    //the fieldID string must hold at least one value, go through this array
    for (var j = 0; j < arFieldIDString.length; j++)
    {
        //If the current item fits the current value field
        if (parseInt(arFieldIDString[j]) === iFieldID)
        {
            //Do nothing here, the field must become empty
            //sNewFieldIDString = sNewFieldIDString + "0,";
        }
        else
            sNewFieldIDString = sNewFieldIDString + arFieldIDString[j] + ",";
    }

    //kill the last ,
    sNewFieldIDString = sNewFieldIDString.substr(0, (sNewFieldIDString.length - 1));

    if (sNewFieldIDString === "") sNewFieldIDString = "0";

    console.log("New fieldID: " + sNewFieldIDString);

    arrayValueTypes[iIndex].fieldID = sNewFieldIDString;
}


function fncGetIndexByFieldID(iFieldID)
{
    //Go through value types array
    for (var i = 0; i < arrayValueTypes.length; i++)
    {
        var arFieldIDString = arrayValueTypes[i].fieldID.split(",");

        //the fieldID string must hold at least one value, go through this array
        for (var j = 0; j < arFieldIDString.length; j++)
        {
            //If the current item fits the current value field
            if (parseInt(arFieldIDString[j]) === iFieldID)
            {
                return arrayValueTypes[i].index;
            }
        }
    }

    return 0;
}

function fncGetValueTextByFieldID(iFieldID)
{
    //Go through value types array
    for (var i = 0; i < arrayValueTypes.length; i++)
    {
        var arFieldIDString = arrayValueTypes[i].fieldID.split(",");

        //the fieldID string must hold at least one value, go through this array
        for (var j = 0; j < arFieldIDString.length; j++)
        {
            //If the current item fits the current value field
            if (parseInt(arFieldIDString[j]) === iFieldID)
            {
                //If this is the first index [0], this is empty field, return ""
                if (i === 0)
                    return "";
                else
                    return arrayValueTypes[i].value;
            }
        }
    }

    return 0;
}

function fncGetHeaderTextByFieldID(iFieldID)
{
    //Go through value types array
    for (var i = 0; i < arrayValueTypes.length; i++)
    {
        var arFieldIDString = arrayValueTypes[i].fieldID.split(",");

        //the fieldID string must hold at least one value, go through this array
        for (var j = 0; j < arFieldIDString.length; j++)
        {
            //If the current item fits the current value field
            if (parseInt(arFieldIDString[j]) === iFieldID)
            {
                //If this is the first index [0], this is empty field, return ""
                if (i === 0)
                    return "";
                else
                    return arrayValueTypes[i].header;
            }
        }
    }
    
    return "";
}

function fncGetFooterTextByFieldID(iFieldID)
{
    //Go through value types array
    for (var i = 0; i < arrayValueTypes.length; i++)
    {
        var arFieldIDString = arrayValueTypes[i].fieldID.split(",");

        //the fieldID string must hold at least one value, go through this array
        for (var j = 0; j < arFieldIDString.length; j++)
        {
            //If the current item fits the current value field
            if (parseInt(arFieldIDString[j]) === iFieldID)
            {
                return arrayValueTypes[i].footer;
            }
        }
    }

    return "";
}

function fncGetFootnoteTextByFieldID(iFieldID)
{
    //Go through value types array
    for (var i = 0; i < arrayValueTypes.length; i++)
    {
        var arFieldIDString = arrayValueTypes[i].fieldID.split(",");

        //the fieldID string must hold at least one value, go through this array
        for (var j = 0; j < arFieldIDString.length; j++)
        {
            //If the current item fits the current value field
            if (parseInt(arFieldIDString[j]) === iFieldID)
            {
                return arrayValueTypes[i].footnoteText;
            }
        }
    }

    return "";
}

function fncGetFootnoteVisibleByFieldID(iFieldID)
{
    //Go through value types array
    for (var i = 0; i < arrayValueTypes.length; i++)
    {
        var arFieldIDString = arrayValueTypes[i].fieldID.split(",");

        //the fieldID string must hold at least one value, go through this array
        for (var j = 0; j < arFieldIDString.length; j++)
        {
            //If the current item fits the current value field
            if (parseInt(arFieldIDString[j]) === iFieldID)
            {
                return arrayValueTypes[i].footnote;
            }
        }
    }

    return false;
}

function fncGetFootnoteValueByFieldID(iFieldID)
{
    //Go through value types array
    for (var i = 0; i < arrayValueTypes.length; i++)
    {
        var arFieldIDString = arrayValueTypes[i].fieldID.split(",");

        //the fieldID string must hold at least one value, go through this array
        for (var j = 0; j < arFieldIDString.length; j++)
        {
            //If the current item fits the current value field
            if (parseInt(arFieldIDString[j]) === iFieldID)
            {
                return arrayValueTypes[i].footnoteValue;
            }
        }
    }

    return 0;
}

function fncConvertSaveStringToArray(sSaveString, iWorkoutType, iWorkoutTypesCount)
{
    //"3,3,1,2,7,8|5,6,1,2,7,8|5,6,1,2,7,8|3,4,1,2,7,8|5,6,1,2,7,8"

    var arValueTypesByWorkout = sSaveString.split("|");

    if (arValueTypesByWorkout.length !== iWorkoutTypesCount) //This is the amount of known workout types, currently 5
        return;

    //Pick the one for the selected workout
    var arValueTypes = arValueTypesByWorkout[iWorkoutType].split(",");

    if (arValueTypes.length !== 6)    //This is the amount of value fields on record page, currently 6
        return;

    //Go through value types
    for (var i = 0; i < arrayValueTypes.length; i++)
    {
        var sFieldIDString = "";

        //Go through value fields
        for (var j = 0; j < arValueTypes.length; j++)
        {
            if (parseInt(arValueTypes[j]) === i)
                sFieldIDString = sFieldIDString + (j + 1).toString() + ",";
        }

        //If the current value (i) was not found in the save string, set fieldID to 0
        //0 means that this value will not be shown anywhere on the record dialog
        if (sFieldIDString === "")
            sFieldIDString = "0";
        else
        {
            //kill the last ,
            sFieldIDString = sFieldIDString.substr(0, (sFieldIDString.length - 1));
        }

        //write that to the array
        arrayValueTypes[i].fieldID = sFieldIDString;
    }
}

function fncConvertArrayToSaveString(sSaveString, iWorkoutType, iWorkoutTypesCount)
{
    //"3,3,1,2,7,8|5,6,1,2,7,8|5,6,1,2,7,8|3,4,1,2,7,8|5,6,1,2,7,8"
    var sReturnString = "";
    var sWorkoutString = "";

    var arValueTypesByWorkout = sSaveString.split("|");

    if (arValueTypesByWorkout.length !== iWorkoutTypesCount) //This is the amount of known workout types, currently 5
        return;

    //Go through value fields
    for (var i = 0; i < 6; i++)
    {
        //Go through value types array
        for (var j = 0; j < arrayValueTypes.length; j++)
        {
            var arFieldIDString = arrayValueTypes[j].fieldID.split(",");

            //the fieldID string must hold at least one value, go through this array
            for (var k = 0; k < arFieldIDString.length; k++)
            {
                //If the current item fits the current value field
                if (parseInt(arFieldIDString[k]) === (i + 1))
                {
                    sWorkoutString = sWorkoutString + arrayValueTypes[j].index.toString() + ",";
                }
            }
        }
    }

    //kill the last ,
    sWorkoutString = sWorkoutString.substr(0, (sWorkoutString.length - 1));


    //Rebuild savestring
    for (i = 0; i < arValueTypesByWorkout.length; i++)
    {
        if (i === iWorkoutType)
            sReturnString = sReturnString + sWorkoutString + "|";
        else
            sReturnString = sReturnString + arValueTypesByWorkout[i] + "|";
    }

    //kill the last | then return
    return sReturnString.substr(0, (sReturnString.length - 1));
}
