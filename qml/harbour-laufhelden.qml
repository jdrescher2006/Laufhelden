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
import Settings 1.0
import TrackRecorder 1.0
import bluetoothconnection 1.0
import bluetoothdata 1.0
import "pages"
import "tools"

ApplicationWindow
{
    id: appWindow

    //Define global variables
    property bool bHRMConnected: false;
    property bool bHRMConnecting: false;    
    property bool bHRMuseDevice: true;
    property string sHeartRate: ""
    property string sBatteryLevel: ""
    property string sHRMAddress: ""
    property string sActiveBTDevice: ""

    //These are private variables
    property string sHeartRateHexString: ""


    //Init C++ classes, libraries
    BluetoothConnection{ id: id_BluetoothConnection }
    BluetoothData{ id: id_BluetoothData }
    Settings{ id: settings }
    TrackRecorder
    {
        id: recorder
        applicationActive: appWindow.applicationActive
        updateInterval: settings.updateInterval
    }

    //These are connections to c++ events
    Connections
    {
        target: id_BluetoothData        
        onSigReadDataReady:     //This is called from C++ if there is data via bluetooth
        {            
            //Check received data
              sHeartRateHexString = sHeartRateHexString + sData.toLowerCase();

            console.log("sHeartRateHexString: " + sHeartRateHexString);

            //Minimum length Polar packets is 8 bytes
            if (sHeartRateHexString.length < 16)
                return;

            //Search for header byte, must always be 0xfe
            if (sHeartRateHexString.indexOf("fe") !== -1)
            {
                //Cut off everything left of fe
              sHeartRateHexString = sHeartRateHexString.substr((sHeartRateHexString.indexOf("fe")));
            }
            else
                return; //No header byte found
            //Check if packet is at correct length
            var iPacketLength = parseInt(sHeartRateHexString.substr(2,2), 16);
            console.log("iPacketLength: " + iPacketLength);
            if (sHeartRateHexString.length < (iPacketLength * 2))
                return; //Packet has is not big enough
            //Check check byte, 255 - packet length
            var iCheckByte = parseInt(sHeartRateHexString.substr(4,2), 16);
            console.log("iCheckByte: " + iCheckByte);
            if (iCheckByte !== (255 - iPacketLength))
            {
                console.log("Check byte is not valid!");
                return; //Check byte is not valid
            }
            //Check sequence valid
            var iSequenceValid = parseInt(sHeartRateHexString.substr(6,2), 16);
            console.log("iSequenceValid: " + iSequenceValid);
            if (iSequenceValid >= 16)
                return; //Sequence valid byte is not valid

            //Check status byte
            var iStatus = parseInt(sHeartRateHexString.substr(8,2), 16);
            console.log("iStatus: " + iStatus);
            //Check battery state
            var iBattery = parseInt(sHeartRateHexString.substr(8,1), 16);
            console.log("iBattery: " + iBattery);
            //Extract heart rate
            var iHeartRate = parseInt(sHeartRateHexString.substr(10,2), 16);
            console.log("iHeartRate: " + iHeartRate);

            var sTemp = ((100/15) * iBattery).toString();
            if (sTemp.indexOf(".") != -1)
                sTemp = sTemp.substring(0, sTemp.indexOf("."));

            //Extraction was successful here. Reset message text var.
            sHeartRateHexString = "";

            //Send heart rate to trackrecorderiHeartRate so that it can be included into the gpx file.
            if (recorder.applicationActive)
                recorder.vSetCurrentHeartRate(iHeartRate);

            sHeartRate = iHeartRate.toString();
            sBatteryLevel = sTemp;
        }
        onSigConnected:
        {
            fncShowMessage(2,"Connected", 4000);
            bHRMConnected = true;
            //sActiveBTDevice = sConnectingBTDevice;      //PROBLEM HIER!!!
        }
        onSigDisconnected:
        {
            fncShowMessage(1,"Disconnected", 4000);
            //sHeartRate = "";
           // sBatteryLevel = "";
            //sActiveBTDevice = "";
            bHRMConnected = false;
            recorder.vSetCurrentHeartRate(-1);
        }
        onSigError:
        {
            fncShowMessage(3,"Error: " + sError, 10000);
        }
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


    initialPage: Component { MainPage { } }
    cover: Qt.resolvedUrl("cover/CoverPage.qml")
    allowedOrientations: Orientation.All
    _defaultPageOrientations: Orientation.All
}
