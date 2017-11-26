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

    function fncGetRockworkVersion()
    {
        return interfaceDBUSManager.getProperty('Version');
    }

    function fncGetListOfWatches()
    {
        return interfaceDBUSManager.getProperty('ListWatches');       
    }

    DBusInterface
    {
        id:interfaceDBUSPebble
        service: 'org.rockwork'
        path: '/org/rockwork/' + sPebbleAddress
        iface: 'org.rockwork.Pebble'
        signalsEnabled: true

        function connected()
        {
            console.log("Pebble connected");
            
            if (!bPebbleConnected)
                fncShowMessage(2,qsTr("Pebble connected"), 1200);
                                
            bPebbleConnected = true;

            //TODO: if recorder is recording, we have to start the sport app here
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
        }
    }

    DBusInterface
    {
        id:interfaceDBUSManager
        service: 'org.rockwork'
        path: '/org/rockwork/Manager'
        iface: 'org.rockwork.Manager'
    }
}
