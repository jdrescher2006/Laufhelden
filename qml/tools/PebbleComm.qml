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
        interfaceDBUS.call('LaunchApp', sAppID);
    }

    function fncClosePebbleApp(sAppID)
    {
        interfaceDBUS.call('CloseApp', sAppID);
    }

    function fncSendDataToPebbleApp(sAppID, oData)
    {
        interfaceDBUS.call('SendAppData', [sAppID, oData]);
    }

    function bIsPebbleConnected()
    {
        var sTester = interfaceDBUS.getProperty('IsConnected');
        console.log("isConnected: " + sTester.toString());

        sTester = interfaceDBUS.getProperty('Name');
        console.log("Name: " + sTester.toString());

        sTester = interfaceDBUS.getProperty('Address');
        console.log("Address: " + sTester.toString());






        return interfaceDBUS.getProperty('IsConnected');
    }

    DBusInterface
    {
        id:interfaceDBUS
        service: 'org.rockwork'
        path: '/org/rockwork/B0_B4_48_62_63_F7'
        iface: 'org.rockwork.Pebble'
    }
}
