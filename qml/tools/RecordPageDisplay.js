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
    { id: 1, name: qsTr("Distance"), field: 1, value: 0, header: qsTr("Distance"), footer: qsTr("km") },
    { id: 2, name: qsTr("Distance"), field: 2, value: 0, header: qsTr("Heartrate"), footer: qsTr("bpm") },
    { id: 3, name: qsTr("Distance"), field: 3, value: 0, header: qsTr("Heartrate ⌀"), footer: qsTr("bpm") },
    { id: 4, name: qsTr("Distance"), field: 4, value: 0, header: qsTr("Pace"), footer: qsTr("min/km") },
    { id: 5, name: qsTr("Distance"), field: 5, value: 0, header: qsTr("Pace ⌀"), footer: qsTr("min/km") },
    { id: 6, name: qsTr("Distance"), field: 6, value: 0, header: qsTr("Speed"), footer: qsTr("km/h") },
    { id: 7, name: qsTr("Distance"), field: 0, value: 0, header: qsTr("Speed ⌀"), footer: qsTr("km/h") },
    { id: 8, name: qsTr("Distance"), field: 0, value: 0, header: qsTr("Elevation"), footer: qsTr("m") }
]
