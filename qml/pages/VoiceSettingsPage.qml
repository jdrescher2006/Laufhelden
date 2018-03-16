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
			TextSwitch
            {
                id: id_TextSwitch_IntervalDuration
                text: qsTr("Interval duration")
                onCheckedChanged:
                {
                    if (!bLockOnCompleted)
                    {

					}
                }
            }
			ComboBox
            {
                id: id_CMB_IntervalDuration
                label: qsTr("Every ")
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
                    if (bLockOnCompleted)
                        return;
                }
            }  	
			Label
			{
				text: qsTr("Every %1 km")
				color: Theme.secondaryColor
			}		
			TextSwitch
            {
                id: id_TextSwitch_IntervalDistance
                text: qsTr("Interval distance")
                onCheckedChanged:
                {
                    if (!bLockOnCompleted)
					{

					}
                }
            }   
			ComboBox
            {
                id: id_CMB_IntervalDistance
                label: qsTr("Every ")
                menu: ContextMenu
                {
                    MenuItem { text: qsTr("minute") }
                    MenuItem { text: qsTr("2 minutes") }
                    MenuItem { text: qsTr("5 minutes") }
                    MenuItem { text: qsTr("10 minutes") }
                    MenuItem { text: qsTr("20 minutes") }
                    MenuItem { text: qsTr("hour") }
                }                
                onCurrentIndexChanged:
                {
                    if (bLockOnCompleted)
                        return;
                }
            }  	    
			Label
			{
				text: qsTr("Every %1 minute")
				color: Theme.secondaryColor
			}		   
			Separator
            {
                color: Theme.highlightColor
                width: parent.width
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
                    arTemp.push("numbers/0_de_male.wav");
                    arTemp.push("units/m_de_male.wav");
                    arTemp.push("numbers/0_de_male.wav");
                    arTemp.push("units/minkm_de_male.wav");
                    arTemp.push("numbers/0_de_male.wav");
                    arTemp.push("units/bpm_de_male.wav");
                    arTemp.push("numbers/0_de_male.wav");
                    arTemp.push("units/km_de_male.wav");
					fncPlaySoundArray(arTemp);                    
                    */
                }
            }
        }
    }
}
