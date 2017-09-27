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
    { fieldID: 1, value: 0, header: qsTr("Distance"), footer: qsTr("km") },
    { fieldID: 2, value: 0, header: qsTr("Heartrate"), footer: qsTr("bpm") },
    { fieldID: 3, value: 0, header: qsTr("Heartrate ⌀"), footer: qsTr("bpm") },
    { fieldID: 4, value: 0, header: qsTr("Pace"), footer: qsTr("min/km") },
    { fieldID: 5, value: 0, header: qsTr("Pace ⌀"), footer: qsTr("min/km") },
    { fieldID: 6, value: 0, header: qsTr("Speed"), footer: qsTr("km/h") },
    { fieldID: 0, value: 0, header: qsTr("Speed ⌀"), footer: qsTr("km/h") },
    { fieldID: 0, value: 0, header: qsTr("Elevation"), footer: qsTr("m") }
]



//Create lookup table for value types.
//This is a helper table to easier access the value types table.
var arrayLookupValueTypesByFieldID = {};
for (var i = 0; i < arrayValueTypes.length; i++)
{
    arrayLookupValueTypesByFieldID[arrayValueTypes[i].fieldID] = arrayValueTypes[i];
}


function fncConvertSaveStringToArray(sSaveString, iWorkoutType)
{
    //3,4,1,2,0,7|5,6,1,2,0,7|5,6,1,2,0,7|5,6,1,2,0,7|5,6,1,2,0,7
    //

    var arValueTypesByWorkout = sSaveString.split("|");

    if (arValueTypesByWorkout.length !== 5) //This is the amount of known workout types, currently 5
        return;

    //Pick the one for the selected workout
    var arValueTypes = arValueTypesByWorkout[iWorkoutType].split(",");

    if (arValueTypes.length !== 6)    //This is the amount of value fields on record page, currently 6
        return;

    arrayValueTypes[parseInt(arValueTypes[0])].fieldID = 1;
    arrayValueTypes[parseInt(arValueTypes[1])].fieldID = 2;
    arrayValueTypes[parseInt(arValueTypes[2])].fieldID = 3;
    arrayValueTypes[parseInt(arValueTypes[3])].fieldID = 4;
    arrayValueTypes[parseInt(arValueTypes[4])].fieldID = 5;
    arrayValueTypes[parseInt(arValueTypes[5])].fieldID = 6;

    console.log(arrayValueTypes[0].fieldID.toString());
    console.log(arrayValueTypes[1].fieldID.toString());
    console.log(arrayValueTypes[2].fieldID.toString());
    console.log(arrayValueTypes[3].fieldID.toString());
    console.log(arrayValueTypes[4].fieldID.toString());
    console.log(arrayValueTypes[5].fieldID.toString());
    console.log(arrayValueTypes[6].fieldID.toString());
    console.log(arrayValueTypes[7].fieldID.toString());
}
