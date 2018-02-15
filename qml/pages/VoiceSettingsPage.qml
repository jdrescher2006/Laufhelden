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

    onStatusChanged:
    {
        //This is loaded only the first time the page is displayed
        if (status === PageStatus.Active && bLockFirstPageLoad)
        {
            bLockOnCompleted = true;

            bLockFirstPageLoad = false;
            console.log("First Active SettingsPage");

            id_TextSwitch_StartEndWorkout.checked = settings.voiceStartEndWorkout;
            id_TextSwitch_PauseContinueWorkout.checked = settings.voicePauseContinueWorkout;
            id_TextSwitch_GPSConnectLost.checked = settings.voiceGPSConnectLost;

            id_CMB_VoiceLanguage.currentIndex = settings.voiceLanguage;

            bLockOnCompleted = false;
        }

        //This is loaded everytime the page is displayed
        if (status === PageStatus.Active)
        {
            console.log("Active SettingsPage");
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
                title: qsTr("Voice output settings")
            }
            SectionHeader
            {
                text: qsTr("Cyclic voice outputs")
            }
            Slider
            {
                id: id_Slider_CyclicVoiceOutputsAmount
                width: parent.width
                valueText: value.toFixed(0)
                label: qsTr("Voice outputs")
                minimumValue: 0
                maximumValue: 3
                onValueChanged:
                {
                    if (bLockOnCompleted)
                        return;

                }
            }
            ComboBox
            {
                visible: id_Slider_CyclicVoiceOutputsAmount.value.toFixed(0) > 0
                id: id_CMB_ValueField1
                label: qsTr("1 parameter:")
                menu: ContextMenu { Repeater { model: JSTools.arrayVoiceValueTypes; MenuItem { text: modelData.header } }}
                onCurrentItemChanged:
                {
                    if (!bLockOnCompleted && !bLockFirstPageLoad)
                    {
                        console.log("Combo changed: " + JSTools.arrayVoiceValueTypes[currentIndex].header);


                    }
                }
            }
            ComboBox
            {
                visible: id_Slider_CyclicVoiceOutputsAmount.value.toFixed(0) > 1
                id: id_CMB_ValueField2
                label: qsTr("2 parameter:")
                menu: ContextMenu { Repeater { model: JSTools.arrayVoiceValueTypes; MenuItem { text: modelData.header } }}
                onCurrentItemChanged:
                {
                    if (!bLockOnCompleted && !bLockFirstPageLoad)
                    {
                        console.log("Combo changed: " + JSTools.arrayVoiceValueTypes[currentIndex].header);


                    }
                }
            }
            ComboBox
            {
                visible: id_Slider_CyclicVoiceOutputsAmount.value.toFixed(0) > 2
                id: id_CMB_ValueField3
                label: qsTr("3 parameter:")
                menu: ContextMenu { Repeater { model: JSTools.arrayVoiceValueTypes; MenuItem { text: modelData.header } }}
                onCurrentItemChanged:
                {
                    if (!bLockOnCompleted && !bLockFirstPageLoad)
                    {
                        console.log("Combo changed: " + JSTools.arrayVoiceValueTypes[currentIndex].header);


                    }
                }
            }

            SectionHeader
            {
                text: qsTr("Voice outputs on events")
            }
            TextSwitch
            {
                id: id_TextSwitch_StartEndWorkout
                text: qsTr("Start/end workout")
                onCheckedChanged:
                {
                    if (!bLockOnCompleted)
                        settings.voiceStartEndWorkout = checked;
                }                
            }
            TextSwitch
            {
                id: id_TextSwitch_PauseContinueWorkout
                text: qsTr("Pause/continue workout")
                onCheckedChanged:
                {
                    if (!bLockOnCompleted)
                        settings.voicePauseContinueWorkout = checked;
                }
            }
            TextSwitch
            {
                id: id_TextSwitch_GPSConnectLost
                text: qsTr("Connect/disconnect GPS")
                onCheckedChanged:
                {
                    if (!bLockOnCompleted)
                        settings.voiceGPSConnectLost = checked;
                }
            }
            Separator
            {
                color: Theme.highlightColor
                width: parent.width
            }            
            ComboBox
            {
                id: id_CMB_VoiceLanguage
                label: qsTr("Voice language")
                menu: ContextMenu
                {
                    MenuItem
                    {
                        text: qsTr("English male")
                        onClicked:
                        {
                            if (bLockOnCompleted)
                                return;

                            settings.voiceLanguage = 0;
                        }
                    }
                    MenuItem
                    {
                        text: qsTr("German male")
                        onClicked:
                        {
                            if (bLockOnCompleted)
                                return;

                            settings.voiceLanguage = 1;
                        }
                    }
                }
            }
            Button
            {
                width: parent.width - Theme.paddingLarge
                anchors.horizontalCenter: parent.horizontalCenter
                text: qsTr("Test")
                onClicked:
                {
                    var sVoiceLanguage = "_en_male.wav";
                    //check voice language and generate last part of audio filename
                    if (settings.voiceLanguage === 0)        //english male
                        sVoiceLanguage = "_en_male.wav";
                    else if (settings.voiceLanguage === 1)   //german male
                        sVoiceLanguage = "_de_male.wav";

                    fncPlaySound("audio/hr_toohigh" + sVoiceLanguage);

                    /*
					var arTemp = [];
                    arTemp.push("audio/start_workout_en_male.wav");
                    arTemp.push("audio/hr_toohigh_en_male.wav");
                    arTemp.push("audio/pace_toohigh_en_male.wav");
                    arTemp.push("audio/end_workout_en_male.wav");
					fncPlaySoundArray(arTemp);
                    */
                }
            }
        }
    }
}
