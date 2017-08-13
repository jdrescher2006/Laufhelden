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
import QtSensors 5.0 as Sensors
import HistoryModel 1.0
import Settings 1.0
import TrackRecorder 1.0
import bluetoothconnection 1.0
import bluetoothdata 1.0
import logwriter 1.0
import "pages"
import "tools"

ApplicationWindow
{
    id: appWindow

    //Define global variables

    //*** HRM Start ***
    property bool bHRMConnected: false          //the connection state to the HRM device
    property bool bHRMConnecting: false
    property bool bReconnectHRMDevice: false    //HRM device has lost connection, reconnect
    property bool bRecordDialogRequestHRM: false
    property string sHeartRate: ""
    property string sBatteryLevel: ""    
    property string sHRMAddress: ""
    property string sHRMDeviceName: ""
    property string sHeartRateHexString: ""
    //*** HRM End ***

    property var vMainPageObject    //this is used for back jumps (pop) to the MainPage
    property bool bLoadHistoryData: true  //this is set on record page after a workout, to have mainpage load GPX files


    //Init C++ classes, libraries
    HistoryModel{ id: id_HistoryModel }
    BluetoothConnection{ id: id_BluetoothConnection }
    BluetoothData{ id: id_BluetoothData }
    LogWriter{ id: id_LogWriter }
    Settings{ id: settings }
    TrackRecorder
    {
        id: recorder        
        //We want the app to continue recording the track even when in background!
        applicationActive: appWindow.applicationActive
        updateInterval: settings.updateInterval
    }

    //These are connections to c++ events
    Connections
    {
        target: id_BluetoothData        
        onSigReadDataReady:     //This is called from C++ if there is data via bluetooth
        {
            fncCheckHeartrate(sData);
        }
        onSigConnected:
        {
            fncShowMessage(2,"HRM Connected", 4000);
            bHRMConnected = true;
        }
        onSigDisconnected:
        {
            fncShowMessage(1,"HRM Disconnected", 4000);
            sHeartRate = "";
            sBatteryLevel = "";
            bHRMConnected = false;
            recorder.vSetCurrentHeartRate(-1);

            //if record dialog is opened, try to reconnect to HRM device
            if (bRecordDialogRequestHRM)
                bReconnectHRMDevice = true;

        }
        onSigError:
        {
            fncShowMessage(3,"HRM Error: " + sError, 10000);
        }
    }

    function fncCheckHeartrate(sData)
    {
        var sHeartRateTemp = 0;
        var sBatteryLevelTemp = 0;
        var iPacketLength = 0;

        //Save received data to packet string. This must be done because a packet is not always consistent.
        sHeartRateHexString = sHeartRateHexString + sData.toLowerCase();

        console.log("sHeartRateHexString: " + sHeartRateHexString);

        //Check for minimal length
        if (sHeartRateHexString.length < 8)
        {
            console.log("Packet is too small!");
            return;
        }

        //Search for vaid telegrams
        //Check for Zephyr control characters start and enddelimiter
        console.log("Header: " + sHeartRateHexString.substr(0,4));
        console.log("Enddelimiter: " + sHeartRateHexString.substr(sHeartRateHexString.length - 2));

        if (sHeartRateHexString.substr(0,4).indexOf("0226") !== -1 && sHeartRateHexString.substr(sHeartRateHexString.length-2).indexOf("03") !== -1)
        {
            //This should be a Zyphyr packet

            console.log("Valid Zepyhr HxM data packet found!");

            //Extract length
            iPacketLength = parseInt(sHeartRateHexString.substr(4,2),16);
            console.log("Length: " + iPacketLength.toString());

            //Extract CRC
            var sCRC = sHeartRateHexString.substr(-4);
            sCRC = sCRC.substr(0,2);
            console.log("CRC: " + sCRC);

            //Extract heart rate data
            sHeartRateHexString = sHeartRateHexString.substring(6,sHeartRateHexString.length - 4);

            console.log("HR data: " + sHeartRateHexString);
            console.log("HR data length: " + sHeartRateHexString.length);

            //Check if length match is given
            if (sHeartRateHexString.length !== (iPacketLength*2))
            {
                console.log("Length does not match, scrap packet!");
                sHeartRateHexString = "";
                return;
            }

            //Check if data is valid by CRC
            //Man the example is in C )-: do it later...

            //Extract battery level
            sBatteryLevelTemp = (parseInt(sHeartRateHexString.substr(16,2),16)).toString();
            console.log("Battery level: " + sBatteryLevelTemp);

            //Extract heart rate at byte 12
            sHeartRateTemp = (parseInt(sHeartRateHexString.substr(18,2),16)).toString();
            console.log("Heartrate: " + sHeartRateTemp);

            //If we found a valid packet, delete the packet memory string
            sHeartRateHexString = "";
        }
        else if (sHeartRateHexString.substr(0,2).indexOf("fe") !== -1)
        {
            //This should be a POLAR packet

            //Check if packet is at correct length
            iPacketLength = parseInt(sHeartRateHexString.substr(2,2), 16);
            console.log("iPacketLength: " + iPacketLength);
            if (sHeartRateHexString.length < (iPacketLength * 2))
            {
                sHeartRateHexString = "";
                return; //Packet is not big enough
            }
            //Check check byte, 255 - packet length
            var iCheckByte = parseInt(sHeartRateHexString.substr(4,2), 16);
            console.log("iCheckByte: " + iCheckByte);
            if (iCheckByte !== (255 - iPacketLength))
            {
                sHeartRateHexString = "";
                console.log("Check byte is not valid!");
                return; //Check byte is not valid
            }
            //Check sequence valid
            var iSequenceValid = parseInt(sHeartRateHexString.substr(6,2), 16);
            console.log("iSequenceValid: " + iSequenceValid);
            if (iSequenceValid >= 16)
            {
                sHeartRateHexString = "";
                return; //Sequence valid byte is not valid
            }

            //Check status byte
            var iStatus = parseInt(sHeartRateHexString.substr(8,2), 16);
            console.log("iStatus: " + iStatus);
            //Check battery state
            sBatteryLevelTemp = parseInt(sHeartRateHexString.substr(8,1), 16);
            console.log("iBattery: " + sBatteryLevelTemp);
            //Extract heart rate
            sHeartRateTemp = (parseInt(sHeartRateHexString.substr(10,2), 16)).toString();
            console.log("HeartRateTemp: " + sHeartRateTemp);

            var sTemp = ((100/15) * sBatteryLevelTemp).toString();
            if (sTemp.indexOf(".") != -1)
                sTemp = sTemp.substring(0, sTemp.indexOf("."));
            sBatteryLevelTemp = sTemp;

            //Extraction was successful here. Reset message text var.
            //Only kill the bytes for this packet. There might be more bytes after this packet.
            if (sHeartRateHexString.length > (iPacketLength * 2))
            {
                sHeartRateHexString = sHeartRateHexString.substring((iPacketLength * 2));
                console.log("Found additional data: " + sHeartRateHexString);
                fncCheckHeartrate("");
            }
            else
                sHeartRateHexString = "";
        }
        else
        {
            //We have a strange start delimiter. Kill data...
            console.log("Strange data found. Kill data.");
            sHeartRateHexString = "";
        }


        //Send heart rate to trackrecorderiHeartRate so that it can be included into the gpx file.
        recorder.vSetCurrentHeartRate(parseInt(sHeartRateTemp));

        sHeartRate = sHeartRateTemp;
        sBatteryLevel = sBatteryLevelTemp;
    }


    function fncShowMessage(iType ,sMessage, iTime)
    {
        messagebox.showMessage(iType, sMessage, iTime);
    }

    Sensors.OrientationSensor
    {
        id: rotationSensor
        active: true
        property int angle: reading.orientation ? _getOrientation(reading.orientation) : 0
        function _getOrientation(value)
        {
            switch (value)
            {
                case 2:
                    return 180
                case 3:
                    return -90
                case 4:
                    return 90
                default:
                    return 0
            }
        }
    }

    Messagebox
    {
        id: messagebox
        rotation: rotationSensor.angle
        width: Math.abs(rotationSensor.angle) == 90 ? parent.height : parent.width
        Behavior on rotation { SmoothedAnimation { duration: 500 } }
        Behavior on width { SmoothedAnimation { duration: 500 } }
    }

    Timer
    {
        //This is called if the connection to the HRM device is broken
        id: timReconnectHRMdevice
        interval: 2000
        running: bReconnectHRMDevice
        repeat: false
        onTriggered:
        {
            console.log("Timer for HRM reconnection is running.");

            id_BluetoothData.connect(sHRMAddress, 1);

            bReconnectHRMDevice = false;
        }
    }

    function fncEnableScreenBlank(bEnableScreenBlank)
    {
        screenblank.enabled = bEnableScreenBlank;
    }

    ScreenBlank
    {
        id: screenblank
    }


    initialPage: Component { MainPage { } }
    cover: Qt.resolvedUrl("cover/CoverPage.qml")
    allowedOrientations: Orientation.All
    _defaultPageOrientations: Orientation.All
}
