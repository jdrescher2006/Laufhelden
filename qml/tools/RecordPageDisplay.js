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
    { index: 0, fieldID: 1, value: 0, header: qsTr("Distance"), footer: qsTr("km") },
    { index: 1, fieldID: 2, value: 0, header: qsTr("Heartrate"), footer: qsTr("bpm") },
    { index: 2, fieldID: 3, value: 0, header: qsTr("Heartrate ⌀"), footer: qsTr("bpm") },
    { index: 3, fieldID: 4, value: 0, header: qsTr("Pace"), footer: qsTr("min/km") },
    { index: 4, fieldID: 5, value: 0, header: qsTr("Pace ⌀"), footer: qsTr("min/km") },
    { index: 5, fieldID: 6, value: 0, header: qsTr("Speed"), footer: qsTr("km/h") },
    { index: 6, fieldID: 0, value: 0, header: qsTr("Speed ⌀"), footer: qsTr("km/h") },
    { index: 7, fieldID: 0, value: 0, header: qsTr("Altitude"), footer: qsTr("m") }
]



//Create lookup table for value types.
//This is a helper table to easier access the value types table.
var arrayLookupValueTypesByFieldID = {};
for (var i = 0; i < arrayValueTypes.length; i++)
{
    arrayLookupValueTypesByFieldID[arrayValueTypes[i].fieldID] = arrayValueTypes[i];
}


function fncConvertSaveStringToArray(sSaveString, iWorkoutType, iWorkoutTypesCount)
{
    //"5,3,4,1,2,0,0,6|5,3,4,0,0,1,2,6|5,3,4,0,0,1,2,6|5,3,4,1,2,0,0,6|5,3,4,0,0,1,2,6"

    var arValueTypesByWorkout = sSaveString.split("|");

    if (arValueTypesByWorkout.length !== iWorkoutTypesCount) //This is the amount of known workout types, currently 5
        return;

    //Pick the one for the selected workout
    var arValueTypes = arValueTypesByWorkout[iWorkoutType].split(",");

    if (arValueTypes.length !== arrayValueTypes.length)    //This is the amount of value types
        return;

    arrayValueTypes[0].fieldID = parseInt(arValueTypes[0]);
    arrayValueTypes[1].fieldID = parseInt(arValueTypes[1]);
    arrayValueTypes[2].fieldID = parseInt(arValueTypes[2]);
    arrayValueTypes[3].fieldID = parseInt(arValueTypes[3]);
    arrayValueTypes[4].fieldID = parseInt(arValueTypes[4]);
    arrayValueTypes[5].fieldID = parseInt(arValueTypes[5]);
    arrayValueTypes[6].fieldID = parseInt(arValueTypes[6]);
    arrayValueTypes[7].fieldID = parseInt(arValueTypes[7]);

    fncRefreshLookupArrayByFieldIDs();
}

function fncRefreshLookupArrayByFieldIDs()
{
    for (var i = 0; i < arrayValueTypes.length; i++)
    {
        arrayLookupValueTypesByFieldID[arrayValueTypes[i].fieldID] = arrayValueTypes[i];
    }
}

function fncConvertArrayToSaveString(sSaveString, iWorkoutType, iWorkoutTypesCount)
{
    //"5,3,4,1,2,0,0,6|5,3,4,0,0,1,2,6|5,3,4,0,0,1,2,6|5,3,4,1,2,0,0,6|5,3,4,0,0,1,2,6"
    var sReturnString = "";
    var sWorkoutString = "";

    var arValueTypesByWorkout = sSaveString.split("|");

    if (arValueTypesByWorkout.length !== iWorkoutTypesCount) //This is the amount of known workout types, currently 5
        return;

    //Go through profiles
    for (var i = 0; i < arrayValueTypes.length; i++)
    {
        //Generate part of the savestring for current workkout
        sWorkoutString = sWorkoutString + (arrayValueTypes[i]["fieldID"]).toString() + ",";
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
