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
import "../tools/JSTools.js" as JSTools

Page
{
    id: page

    property bool bLockOnCompleted : false;
    property bool bLockFirstPageLoad: true

    function fncCheckBoxesOK()
    {
        //The comboboxes must be checked, because the values need to be different. Except index 0, this may be same for all boxes.
        if (id_CMB_ValueField1.currentIndex !== 0 && id_CMB_ValueField1.currentIndex === id_CMB_ValueField2.currentIndex)
            return false;
        if (id_CMB_ValueField1.currentIndex !== 0 && id_CMB_ValueField1.currentIndex === id_CMB_ValueField3.currentIndex)
            return false;
        if (id_CMB_ValueField1.currentIndex !== 0 && id_CMB_ValueField1.currentIndex === id_CMB_ValueField4.currentIndex)
            return false;
        if (id_CMB_ValueField2.currentIndex !== 0 && id_CMB_ValueField2.currentIndex === id_CMB_ValueField3.currentIndex)
            return false;
        if (id_CMB_ValueField2.currentIndex !== 0 && id_CMB_ValueField2.currentIndex === id_CMB_ValueField4.currentIndex)
            return false;
        if (id_CMB_ValueField3.currentIndex !== 0 && id_CMB_ValueField3.currentIndex === id_CMB_ValueField4.currentIndex)
            return false;

        return true;
    }

    onStatusChanged:
    {
        //This is loaded only the first time the page is displayed
        if (status === PageStatus.Active && bLockFirstPageLoad)
        {
            bLockOnCompleted = true;

            bLockFirstPageLoad = false;
            console.log("First Active VoiceCycleDistanceSettingsPage");

            id_TextSwitch_IntervalDistance.checked = settings.voiceCycDistanceEnable;

            id_TextSwitch_PlayHeadlineDistance.checked = settings.voiceCycDistanceHeadlineEnable;

            if (settings.voiceCycDistance === 0.5)
                id_CMB_IntervalDistance.currentIndex = 0;
            else if (settings.voiceCycDistance === 1.0)
                id_CMB_IntervalDistance.currentIndex = 1;
            else if (settings.voiceCycDistance === 2.0)
                id_CMB_IntervalDistance.currentIndex = 2;
            else if (settings.voiceCycDistance === 5.0)
                id_CMB_IntervalDistance.currentIndex = 3;
            else if (settings.voiceCycDistance === 10.0)
                id_CMB_IntervalDistance.currentIndex = 4;
            else if (settings.voiceCycDistance === 20.0)
                id_CMB_IntervalDistance.currentIndex = 5;
            else
                id_CMB_IntervalDistance.currentIndex = 1;

            var arValueTypes = settings.voiceCycDistanceFields.split(",");
            if (arValueTypes === undefined || arValueTypes === "" || arValueTypes.length !== 4)    //This is the amount
            {
                //Set defaults if save string is damaged or broken
                arValueTypes[0] = 9;
                arValueTypes[1] = 8;
                arValueTypes[2] = 3;
                arValueTypes[3] = 5;
            }

            arValueTypes[0] = parseInt(arValueTypes[0]);
            arValueTypes[1] = parseInt(arValueTypes[1]);
            arValueTypes[2] = parseInt(arValueTypes[2]);
            arValueTypes[3] = parseInt(arValueTypes[3]);

            id_CMB_ValueField1.currentIndex = arValueTypes[0];
            id_CMB_ValueField2.currentIndex = arValueTypes[1];
            id_CMB_ValueField3.currentIndex = arValueTypes[2];
            id_CMB_ValueField4.currentIndex = arValueTypes[3];


            bLockOnCompleted = false;
        }

        //This is loaded everytime the page is displayed
        if (status === PageStatus.Active)
        {
            console.log("Active VoiceCycleDistanceSettingsPage");
        }        
    }


    SilicaFlickable
    {
        anchors.fill: parent
        contentHeight: column.height + Theme.paddingLarge;
        VerticalScrollDecorator {}
        Column
        {
            id: column
            width: page.width
            spacing: Theme.paddingLarge
            PageHeader
            {
                title: qsTr("Regular announcements by distance")
            }          
			TextSwitch
            {
                id: id_TextSwitch_IntervalDistance
                text: qsTr("Enabled")
                onCheckedChanged:
                {
                    if (bLockOnCompleted || bLockFirstPageLoad)
                        return;

                    settings.voiceCycDistanceEnable = checked;
                }
            }
			ComboBox
            {
                id: id_CMB_IntervalDistance
                label: qsTr("Every ")
                visible: id_TextSwitch_IntervalDistance.checked
                menu: ContextMenu
                {
                    MenuItem { text: (settings.measureSystem === 0) ? qsTr("500 meters") : qsTr("0.5 mi") }
                    MenuItem { text: (settings.measureSystem === 0) ? qsTr("1 km") : qsTr("1 mi") }
                    MenuItem { text: (settings.measureSystem === 0) ? qsTr("2 km") : qsTr("2 mi") }
                    MenuItem { text: (settings.measureSystem === 0) ? qsTr("5 km") : qsTr("5 mi") }
                    MenuItem { text: (settings.measureSystem === 0) ? qsTr("10 km") : qsTr("10 mi") }
                    MenuItem { text: (settings.measureSystem === 0) ? qsTr("20 km") : qsTr("20 mi") }
                }
                onCurrentIndexChanged:
                {
                    if (bLockOnCompleted || bLockFirstPageLoad)
                        return;

                    if (currentIndex === 0)
                        settings.voiceCycDistance = 0.5;
                    else if (currentIndex === 1)
                        settings.voiceCycDistance = 1.0;
                    else if (currentIndex === 2)
                        settings.voiceCycDistance = 2.0;
                    else if (currentIndex === 3)
                        settings.voiceCycDistance = 5.0;
                    else if (currentIndex === 4)
                        settings.voiceCycDistance = 10.0;
                    else if (currentIndex === 5)
                        settings.voiceCycDistance = 20.0;
                    else
                        settings.voiceCycDistance = 1.0
                }
            }
            Separator
            {
                visible: id_TextSwitch_IntervalDistance.checked
                color: Theme.highlightColor
                width: parent.width
            }
            TextSwitch
            {
                id: id_TextSwitch_PlayHeadlineDistance
                visible: id_TextSwitch_IntervalDistance.checked
                text: qsTr("Play value announcement")
                description: qsTr("Before a value is played, the type of value is announced e.g \"Distance:\". This makes the voice announcement last longer.")
                onCheckedChanged:
                {
                    if (bLockOnCompleted || bLockFirstPageLoad)
                        return;

                    settings.voiceCycDistanceHeadlineEnable = checked;
                }
            }
            Separator
            {
                visible: id_TextSwitch_IntervalDistance.checked
                color: Theme.highlightColor
                width: parent.width
            }
            ComboBox
            {
                visible: id_TextSwitch_IntervalDistance.checked
                id: id_CMB_ValueField1
                label: qsTr("1 announcement:")
                menu: ContextMenu { Repeater { model: JSTools.arrayVoiceValueTypes; MenuItem { text: modelData.header } }}
                onCurrentItemChanged:
                {
                    if (bLockOnCompleted || bLockFirstPageLoad)
                        return;

                    console.log("Combo changed: " + JSTools.arrayVoiceValueTypes[currentIndex].header);

                    //Check if an other combobox has this value
                    if (currentIndex !== 0 && (currentIndex === id_CMB_ValueField2.currentIndex || currentIndex === id_CMB_ValueField3.currentIndex || currentIndex === id_CMB_ValueField4.currentIndex))
                    {
                        fncShowMessage(3,qsTr("This value is already assigned!"), 3000);
                        return;
                    }

                    //Check if the other comboboxes are OK
                    if (fncCheckBoxesOK() === false)
                    {
                        console.log("fncCheckBoxesOK: false");
                        return;
                    }

                    var arValueTypes = settings.voiceCycDistanceFields.split(",");
                    if (arValueTypes === undefined || arValueTypes === "" || arValueTypes.length !== 4)    //This is the amount voice fields
                    {
                        //Set defaults if save string is damaged or broken
                        arValueTypes[0] = 9;
                        arValueTypes[1] = 8;
                        arValueTypes[2] = 3;
                        arValueTypes[3] = 5;
                    }

                    arValueTypes[0] = id_CMB_ValueField1.currentIndex;
                    arValueTypes[1] = id_CMB_ValueField2.currentIndex;
                    arValueTypes[2] = id_CMB_ValueField3.currentIndex;
                    arValueTypes[3] = id_CMB_ValueField4.currentIndex;

                    var sSaveString = arValueTypes[0].toString() + "," + arValueTypes[1].toString() + "," + arValueTypes[2].toString() + "," + arValueTypes[3].toString();

                    settings.voiceCycDistanceFields = sSaveString;

                    JSTools.fncGenerateHelperArrayFieldIDDistance();
                }
            }
            ComboBox
            {
                visible: id_TextSwitch_IntervalDistance.checked
                id: id_CMB_ValueField2
                label: qsTr("2 announcement:")
                menu: ContextMenu { Repeater { model: JSTools.arrayVoiceValueTypes; MenuItem { text: modelData.header } }}
                onCurrentItemChanged:
                {
                    if (bLockOnCompleted || bLockFirstPageLoad)
                        return;

                    console.log("Combo changed: " + JSTools.arrayVoiceValueTypes[currentIndex].header);

                    //Check if an other combobox has this value
                    if (currentIndex !== 0 && (currentIndex === id_CMB_ValueField1.currentIndex || currentIndex === id_CMB_ValueField3.currentIndex || currentIndex === id_CMB_ValueField4.currentIndex))
                    {
                        fncShowMessage(3,qsTr("This value is already assigned!"), 3000);
                        return;
                    }

                    //Check if the other comboboxes are OK
                    if (fncCheckBoxesOK() === false)
                    {
                        console.log("fncCheckBoxesOK: false");
                        return;
                    }

                    var arValueTypes = settings.voiceCycDistanceFields.split(",");
                    if (arValueTypes === undefined || arValueTypes === "" || arValueTypes.length !== 4)    //This is the amount voice fields
                    {
                        //Set defaults if save string is damaged or broken
                        arValueTypes[0] = 9;
                        arValueTypes[1] = 8;
                        arValueTypes[2] = 3;
                        arValueTypes[3] = 5;
                    }

                    arValueTypes[0] = id_CMB_ValueField1.currentIndex;
                    arValueTypes[1] = id_CMB_ValueField2.currentIndex;
                    arValueTypes[2] = id_CMB_ValueField3.currentIndex;
                    arValueTypes[3] = id_CMB_ValueField4.currentIndex;

                    var sSaveString = arValueTypes[0].toString() + "," + arValueTypes[1].toString() + "," + arValueTypes[2].toString() + "," + arValueTypes[3].toString();

                    settings.voiceCycDistanceFields = sSaveString;

                    JSTools.fncGenerateHelperArrayFieldIDDistance();
                }
            }
            ComboBox
            {
                visible: id_TextSwitch_IntervalDistance.checked
                id: id_CMB_ValueField3
                label: qsTr("3 announcement:")
                menu: ContextMenu { Repeater { model: JSTools.arrayVoiceValueTypes; MenuItem { text: modelData.header } }}
                onCurrentItemChanged:
                {
                    if (bLockOnCompleted || bLockFirstPageLoad)
                        return;

                    console.log("Combo changed: " + JSTools.arrayVoiceValueTypes[currentIndex].header);

                    //Check if an other combobox has this value
                    if (currentIndex !== 0 && (currentIndex === id_CMB_ValueField1.currentIndex || currentIndex === id_CMB_ValueField2.currentIndex || currentIndex === id_CMB_ValueField4.currentIndex))
                    {
                        fncShowMessage(3,qsTr("This value is already assigned!"), 3000);
                        return;
                    }

                    //Check if the other comboboxes are OK
                    if (fncCheckBoxesOK() === false)
                    {
                        console.log("fncCheckBoxesOK: false");
                        return;
                    }

                    var arValueTypes = settings.voiceCycDistanceFields.split(",");
                    if (arValueTypes === undefined || arValueTypes === "" || arValueTypes.length !== 4)    //This is the amount voice fields
                    {
                        //Set defaults if save string is damaged or broken
                        arValueTypes[0] = 9;
                        arValueTypes[1] = 8;
                        arValueTypes[2] = 3;
                        arValueTypes[3] = 5;
                    }

                    arValueTypes[0] = id_CMB_ValueField1.currentIndex;
                    arValueTypes[1] = id_CMB_ValueField2.currentIndex;
                    arValueTypes[2] = id_CMB_ValueField3.currentIndex;
                    arValueTypes[3] = id_CMB_ValueField4.currentIndex;

                    var sSaveString = arValueTypes[0].toString() + "," + arValueTypes[1].toString() + "," + arValueTypes[2].toString() + "," + arValueTypes[3].toString();

                    settings.voiceCycDistanceFields = sSaveString;

                    JSTools.fncGenerateHelperArrayFieldIDDistance();
                }
            }
            ComboBox
            {
                visible: id_TextSwitch_IntervalDistance.checked
                id: id_CMB_ValueField4
                label: qsTr("4 announcement:")
                menu: ContextMenu { Repeater { model: JSTools.arrayVoiceValueTypes; MenuItem { text: modelData.header } }}
                onCurrentItemChanged:
                {
                    if (bLockOnCompleted || bLockFirstPageLoad)
                        return;

                    console.log("Combo changed: " + JSTools.arrayVoiceValueTypes[currentIndex].header);

                    //Check if an other combobox has this value
                    if (currentIndex !== 0 && (currentIndex === id_CMB_ValueField1.currentIndex || currentIndex === id_CMB_ValueField2.currentIndex || currentIndex === id_CMB_ValueField3.currentIndex))
                    {
                        fncShowMessage(3,qsTr("This value is already assigned!"), 3000);
                        return;
                    }

                    //Check if the other comboboxes are OK
                    if (fncCheckBoxesOK() === false)
                    {
                        console.log("fncCheckBoxesOK: false");
                        return;
                    }

                    var arValueTypes = settings.voiceCycDistanceFields.split(",");
                    if (arValueTypes === undefined || arValueTypes === "" || arValueTypes.length !== 4)    //This is the amount voice fields
                    {
                        //Set defaults if save string is damaged or broken
                        arValueTypes[0] = 9;
                        arValueTypes[1] = 8;
                        arValueTypes[2] = 3;
                        arValueTypes[3] = 5;
                    }

                    arValueTypes[0] = id_CMB_ValueField1.currentIndex;
                    arValueTypes[1] = id_CMB_ValueField2.currentIndex;
                    arValueTypes[2] = id_CMB_ValueField3.currentIndex;
                    arValueTypes[3] = id_CMB_ValueField4.currentIndex;

                    var sSaveString = arValueTypes[0].toString() + "," + arValueTypes[1].toString() + "," + arValueTypes[2].toString() + "," + arValueTypes[3].toString();

                    settings.voiceCycDistanceFields = sSaveString;

                    JSTools.fncGenerateHelperArrayFieldIDDistance();
                }
            }
        }
    }
}
