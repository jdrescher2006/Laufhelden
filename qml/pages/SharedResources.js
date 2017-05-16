/*
 * Copyright (C) 2016 Jens Drescher, Germany
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
