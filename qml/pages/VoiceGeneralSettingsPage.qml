/*
 * Copyright (C) 2017-2018 Jens Drescher, Germany
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
            console.log("First Active VoiceGeneralSettingsPage");

            id_CMB_VoiceLanguage.currentIndex = settings.voiceLanguage;

            bLockOnCompleted = false;
        }

        //This is loaded everytime the page is displayed
        if (status === PageStatus.Active)
        {
            console.log("Active VoiceGeneralSettingsPage");
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
                title: qsTr("Voice coach general settings")
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

