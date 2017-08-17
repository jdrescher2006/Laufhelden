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
    id: mediePlayerControl
    property var services:
    [
        "org.mpris.MediaPlayer2.jolla-mediaplayer",        
    ]

    function pause()
    {
        mediePlayerControl.services.forEach(function(el, i)
        {
            dbbusInterface.service = el;
            dbbusInterface.call('Pause', undefined);
        });
    }

    function resume()
    {
        mediePlayerControl.services.forEach(function(el, i)
        {
            dbbusInterface.service = el;
            dbbusInterface.call('Play', undefined);
        });
    }

    DBusInterface
    {
        id:dbbusInterface
        service: 'org.mpris.MediaPlayer2.jolla-mediaplayer'
        path: '/org/mpris/MediaPlayer2'
        iface: 'org.mpris.MediaPlayer2.Player'
    }
}
