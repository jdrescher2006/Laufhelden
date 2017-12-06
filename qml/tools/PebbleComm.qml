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
import org.nemomobile.dbus 2.0

Item
{
    id: pebbleControl

    function fncLaunchPebbleApp(sAppID)
    {
        interfaceDBUSPebble.call('LaunchApp', sAppID);
    }

    function fncClosePebbleApp(sAppID)
    {
        interfaceDBUSPebble.call('CloseApp', sAppID);
    }

    function fncSendDataToPebbleApp(sAppID, oData)
    {
        interfaceDBUSPebble.call('SendAppData', [sAppID, oData]);
    }

    function bGetPebbleAddress()
    {
        return interfaceDBUSPebble.getProperty('Address');
    }

    function bGetPebbleName()
    {
        return interfaceDBUSPebble.getProperty('Name');
    }

    function bIsPebbleConnected()
    {      
        return interfaceDBUSPebble.getProperty('IsConnected');
    }


    DBusInterface
    {
        id:interfaceDBUSPebble
        service: 'org.rockwork'
        path: sPebblePath
        iface: 'org.rockwork.Pebble'
        signalsEnabled: true

        function connected()
        {
            console.log("Pebble connected");
            
            if (!bPebbleConnected)
                fncShowMessage(2,qsTr("Pebble connected"), 1200);

            //Pebble just got connected, check if sport app is required
            if (bPebbleSportAppRequired && !bPebbleConnected)
                pebbleComm.fncLaunchPebbleApp("4dab81a6-d2fc-458a-992c-7a1f3b96a970");

            bPebbleConnected = true;                       
        }
        function disconnected()
        {
            console.log("Pebble disconnected");

            if (bPebbleConnected)
                fncShowMessage(3,qsTr("Pebble disconnected"), 1200);

            bPebbleConnected = false;
        }
        function appButtonPressed(uuid, key)
        {
            console.log("appbuttonpressed, " + uuid + ": " + key.toString());

            //If the pause key was pressed within pebble sport app
            if (uuid.toString().indexOf("4dab81a6-d2fc-458a-992c-7a1f3b96a970") !== -1 && key.toString() === "4")
            {
                console.log("Pause button pressed!")

                //Only toggle pause if recorder is running
                if (recorder.running)
                    recorder.pause = !recorder.pause;

                //If recorder is not running, start workout
                if (!recorder.running && recorder.accuracy > 0 && recorder.accuracy < 30)
                {
                    recorder.pause = false;
                    recorder.running = true;
                }
            }
        }
    } 
}
