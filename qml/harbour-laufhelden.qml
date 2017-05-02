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
import Settings 1.0
import TrackRecorder 1.0
import "pages"

ApplicationWindow {
    id: appWindow
    initialPage: Component { RecordPage { } }
    cover: Qt.resolvedUrl("cover/CoverPage.qml")

    Settings {
        id: settings
    }

    TrackRecorder {
        id: recorder
        applicationActive: appWindow.applicationActive
        updateInterval: settings.updateInterval
    }
}
