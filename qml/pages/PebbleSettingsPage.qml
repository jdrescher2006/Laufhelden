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

    property bool bLockOnCompleted : false
    property bool bLockFirstPageLoad: true
    property int iCheckPebbleStep: 0

    onStatusChanged:
    {
        //This is loaded only the first time the page is displayed
        if (status === PageStatus.Active && bLockFirstPageLoad)
        {
            bLockOnCompleted = true;

            bLockFirstPageLoad = false;
            console.log("First Active PebbleSettingsPage");

            //Check if a Pebble watch was found in Rockpool manager
            var sPebbleList = id_PebbleManagerComm.getListWatches();
            console.log("sPebbleList: " + sPebbleList);

            if (sPebbleList !== undefined && sPebbleList.length > 0)
            {
                //A pebble was found, we have now a DBus path to it.
                //If there are more than one pebble, use the first one.
                sPebblePath = sPebbleList[0];

                //Read version of Rockpool and check if it is sufficient
                fncCheckVersion(id_PebbleManagerComm.getRockpoolVersion());
            }
            else
            {
                //Show error
                id_REC_PebbleAddress.visible = true;

                //Disable pebble support
                settings.enablePebble = false;

                //Disble this dialog
                id_TextSwitch_enablePebble.checked = false;
                id_TextSwitch_enablePebble.enabled = false;
            }


            //Set settings to dialog
            id_TextSwitch_enablePebble.checked = settings.enablePebble;

            var arValueTypes = settings.valuePebbleFields.split(",");
            if (arValueTypes === undefined || arValueTypes === "" || arValueTypes.length !== 3)    //This is the amount pebble fields
            {
                //Set defaults if save string is damaged or broken
                arValueTypes[0] = 10;
                arValueTypes[1] = 8;
                arValueTypes[2] = 3;
            }

            arValueTypes[0] = parseInt(arValueTypes[0]);
            arValueTypes[1] = parseInt(arValueTypes[1]);
            arValueTypes[2] = parseInt(arValueTypes[2]);

            id_CMB_ValueField1.currentIndex = arValueTypes[0];
            id_CMB_ValueField2.currentIndex = arValueTypes[1];
            id_CMB_ValueField3.currentIndex = arValueTypes[2];


            bLockOnCompleted = false;
        }

        //This is loaded everytime the page is displayed
        if (status === PageStatus.Active)
        {
            console.log("Active PebbleSettingsPage");

            //Check if pebble is connected
            if (settings.enablePebble && !bPebbleConnected)
                bPebbleConnected = pebbleComm.bIsPebbleConnected();
        }
    }

    function fncCheckVersion(sVersion)
    {
        //Check if version is valid
        if (sVersion === undefined || sVersion === "" || sVersion.indexOf(".") === -1 || sVersion.indexOf("-") === -1)
        {
            id_LBL_Rockpool.text = id_LBL_Rockpool.text + "-";
            id_REC_Rockpool.visible = true;

            //Disable pebble support
            settings.enablePebble = false;

            //Disble this dialog
            id_TextSwitch_enablePebble.checked = false;
            id_TextSwitch_enablePebble.enabled = false;
        }
        else
        {
            //Cut off the release number, we don't need that for comparing
            var sModVersion = sVersion.substring(0, sVersion.indexOf("-"));

            //Check if Rockpool verion is too old
            if (fncCompareVersions(sModVersion, "1.3") < 0)
            {
                id_LBL_Rockpool.text = id_LBL_Rockpool.text + sVersion;
                id_REC_Rockpool.visible = true;

                settings.enablePebble = false;
                id_TextSwitch_enablePebble.checked = false;
                id_TextSwitch_enablePebble.enabled = false;

            }
            else
            {
                id_REC_Rockpool.visible = false;
                id_TextSwitch_enablePebble.enabled = true;
            }
        }
    }

    function fncCompareVersions(a, b)
    {
        var i, diff;
        var regExStrip0 = /(\.0+)+$/;
        var segmentsA = a.replace(regExStrip0, '').split('.');
        var segmentsB = b.replace(regExStrip0, '').split('.');
        var l = Math.min(segmentsA.length, segmentsB.length);

        for (i = 0; i < l; i++) {
            diff = parseInt(segmentsA[i], 10) - parseInt(segmentsB[i], 10);
            if (diff) {
                return diff;
            }
        }
        return segmentsA.length - segmentsB.length;
    }

    Timer
    {
        id: timCheckPebbleTimer
        interval: 1600
        running: (iCheckPebbleStep > 0)
        repeat: true
        onTriggered:
        {
            iCheckPebbleStep++;

            if (iCheckPebbleStep === 2)
            {
                progressBarCheckPebble.label = qsTr("set metric units");
                pebbleComm.fncSendDataToPebbleApp("4dab81a6-d2fc-458a-992c-7a1f3b96a970", {'3': '1'});
                pebbleComm.fncSendDataToPebbleApp("4dab81a6-d2fc-458a-992c-7a1f3b96a970", {'4': '1'});
            }
            if (iCheckPebbleStep === 3)
            {
                progressBarCheckPebble.label = qsTr("sending data 1");
                pebbleComm.fncSendDataToPebbleApp("4dab81a6-d2fc-458a-992c-7a1f3b96a970", {'0': '02:30', '1': '10.12', '5': '0', '2': '2.4'});
            }
            if (iCheckPebbleStep === 4)
            {
                progressBarCheckPebble.label = qsTr("sending data 2");
                pebbleComm.fncSendDataToPebbleApp("4dab81a6-d2fc-458a-992c-7a1f3b96a970", {'0': '02:33', '1': '10.22', '5': '0', '2': '3.3'});
            }
            if (iCheckPebbleStep === 5)
            {
                progressBarCheckPebble.label = qsTr("sending data 3");
                pebbleComm.fncSendDataToPebbleApp("4dab81a6-d2fc-458a-992c-7a1f3b96a970", {'0': '02:45', '1': '11.34', '5': '0', '2': '14.4'});
            }
            if (iCheckPebbleStep === 6)
            {
                progressBarCheckPebble.label = qsTr("closing sport app");
                pebbleComm.fncClosePebbleApp("4dab81a6-d2fc-458a-992c-7a1f3b96a970");
            }
            if (iCheckPebbleStep === 7)
            {
                progressBarCheckPebble.label = "";
                iCheckPebbleStep = 0;
            }
        }
    }

    Rectangle
    {
        visible: false
        id: id_REC_Rockpool
        z: 2
        color: "black"
        anchors.fill: parent
        Label
        {
            id: id_LBL_Rockpool
            color: "red"
            text: qsTr("Rockpool must be installed<br>at least in version 1.4-4.<br>Installed version is: ")
            font.pixelSize: Theme.fontSizeSmall
            anchors.centerIn: parent
        }
        Label
        {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: id_LBL_Rockpool.bottom
            anchors.topMargin: Theme.paddingLarge
            font.pixelSize: Theme.fontSizeSmall
            property string urlstring: "https://openrepos.net/content/abranson/rockpool"
            text: "<a href=\"" + urlstring + "\">" +  urlstring + "<\a>"
            onLinkActivated: Qt.openUrlExternally(link)
        }
        Image
        {
            width: parent.width/10
            height: parent.width/10
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: id_LBL_Rockpool.top
            anchors.bottomMargin: Theme.paddingLarge
            source: "../img/icon-lock-error.png"
        }
    }

    Rectangle
    {
        visible: false
        id: id_REC_PebbleAddress
        z: 2
        color: "black"
        anchors.fill: parent
        Label
        {
            id: id_LBL_PebbleAddress
            color: "red"
            text: qsTr("No Pebble found.<br>Install Rockpool and<br>then connect Pebble!")
            font.pixelSize: Theme.fontSizeSmall
            anchors.centerIn: parent
        }
        Label
        {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: id_LBL_PebbleAddress.bottom
            anchors.topMargin: Theme.paddingLarge
            font.pixelSize: Theme.fontSizeSmall
            property string urlstring: "https://openrepos.net/content/abranson/rockpool"
            text: "<a href=\"" + urlstring + "\">" +  urlstring + "<\a>"
            onLinkActivated: Qt.openUrlExternally(link)
        }
        Image
        {
            width: parent.width/10
            height: parent.width/10
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: id_LBL_PebbleAddress.top
            anchors.bottomMargin: Theme.paddingLarge
            source: "../img/icon-lock-error.png"
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
                title: qsTr("Pebble settings")
            }                        
            TextSwitch
            {
                id: id_TextSwitch_enablePebble
                text: qsTr("Enable Pebble support")
                description: qsTr("View workout data on Pebble Smartwatch.")
                onCheckedChanged:
                {
                    console.log("Pressed...");
                    if (!bLockOnCompleted && !bLockFirstPageLoad)
                        settings.enablePebble = checked;
                }                
            }

            Separator
            {
                visible: id_TextSwitch_enablePebble.checked
                color: Theme.highlightColor
                width: parent.width
            }
            Item
            {
                visible: id_TextSwitch_enablePebble.checked
                width: parent.width
                height: id_BTN_TestPebble.height

                Label
                {
                    id: id_LBL_PebbleConnected
                    anchors.left: parent.left
                    anchors.leftMargin: Theme.paddingSmall
                    anchors.verticalCenter: parent.verticalCenter
                    text: qsTr("Connected:")
                }

                GlassItem
                {
                    id: id_GI_PebbleConnected
                    anchors.left: id_LBL_PebbleConnected.right
                    anchors.verticalCenter: parent.verticalCenter
                    color: bPebbleConnected ? "green" : "red"
                    falloffRadius: 0.15
                    radius: 1.0
                    cache: false
                }
                Button
                {
                    id: id_BTN_TestPebble
                    text: qsTr("Test Pebble")
                    width: parent.width/2
                    anchors.right: parent.right
                    anchors.rightMargin: Theme.paddingSmall
                    onClicked:
                    {
                        iCheckPebbleStep = 1;
                        progressBarCheckPebble.label = qsTr("starting sport app");
                        pebbleComm.fncLaunchPebbleApp("4dab81a6-d2fc-458a-992c-7a1f3b96a970");
                    }
                }
            }

            Separator
            {
                visible: id_TextSwitch_enablePebble.checked
                color: Theme.highlightColor
                width: parent.width
            }
            Item
            {
                width: parent.width
                height: parent.height / 5
                Image
                {
                    id: id_IMG_Pebble
                    visible: id_TextSwitch_enablePebble.checked
                    anchors.top: parent.top
                    anchors.left: parent.left
                    height: parent.height
                    width: parent.height / 1.167
                    fillMode: Image.Stretch
                    source: "../img/pebble.jpg"
                }
                Label
                {
                    anchors.left: id_IMG_Pebble.right
                    anchors.leftMargin: Theme.paddingSmall
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - id_IMG_Pebble.width
                    wrapMode: Text.WordWrap
                    color: Theme.primaryColor
                    visible: id_TextSwitch_enablePebble.checked
                    text: qsTr("Choose values for Pebble fields!")
                }
            }
            ComboBox
            {
                visible: id_TextSwitch_enablePebble.checked
                id: id_CMB_ValueField1
                label: qsTr("1 DURATION field:")
                menu: ContextMenu { Repeater { model: JSTools.arrayPebbleValueTypes; MenuItem { text: modelData.header } }}
                onCurrentItemChanged:
                {
                    if (!bLockOnCompleted && !bLockFirstPageLoad)
                    {
                        console.log("Combo changed: " + JSTools.arrayPebbleValueTypes[currentIndex].header);

                        //Check if an other combobox has this value
                        if (currentIndex === id_CMB_ValueField2.currentIndex || currentIndex === id_CMB_ValueField3.currentIndex)
                        {
                            fncShowMessage(3,qsTr("This value is already assigned!"), 3000);
                            return
                        }

                        //Check if the other comboboxes are OK
                        if (id_CMB_ValueField2.currentIndex === id_CMB_ValueField3.currentIndex)
                            return;

                        var arValueTypes = settings.valuePebbleFields.split(",");
                        if (arValueTypes === undefined || arValueTypes === "" || arValueTypes.length !== 3)    //This is the amount pebble fields
                        {
                            //Set defaults if save string is damaged or broken
                            arValueTypes[0] = 10;
                            arValueTypes[1] = 8;
                            arValueTypes[2] = 3;
                        }

                        arValueTypes[0] = id_CMB_ValueField1.currentIndex;
                        arValueTypes[1] = id_CMB_ValueField2.currentIndex;
                        arValueTypes[2] = id_CMB_ValueField3.currentIndex;

                        var sSaveString = arValueTypes[0].toString() + "," + arValueTypes[1].toString() + "," + arValueTypes[2].toString();

                        settings.valuePebbleFields = sSaveString;

                        JSTools.fncGenerateHelperArray();
                    }
                }
            }
            ComboBox
            {
                visible: id_TextSwitch_enablePebble.checked
                id: id_CMB_ValueField2
                label: qsTr("2 DISTANCE field:")
                menu: ContextMenu { Repeater { model: JSTools.arrayPebbleValueTypes; MenuItem { text: modelData.header } }}
                onCurrentItemChanged:
                {
                    if (!bLockOnCompleted && !bLockFirstPageLoad)
                    {
                        console.log("Combo changed: " + JSTools.arrayPebbleValueTypes[currentIndex].header);

                        //Check if an other combobox has this value
                        if (currentIndex === id_CMB_ValueField1.currentIndex || currentIndex === id_CMB_ValueField3.currentIndex)
                        {
                            fncShowMessage(3,qsTr("This value is already assigned!"), 3000);
                            return
                        }

                        //Check if the other comboboxes are OK
                        if (id_CMB_ValueField1.currentIndex === id_CMB_ValueField3.currentIndex)
                            return;

                        var arValueTypes = settings.valuePebbleFields.split(",");
                        if (arValueTypes === undefined || arValueTypes === "" || arValueTypes.length !== 3)    //This is the amount pebble fields
                        {
                            //Set defaults if save string is damaged or broken
                            arValueTypes[0] = 10;
                            arValueTypes[1] = 8;
                            arValueTypes[2] = 3;
                        }

                        arValueTypes[0] = id_CMB_ValueField1.currentIndex;
                        arValueTypes[1] = id_CMB_ValueField2.currentIndex;
                        arValueTypes[2] = id_CMB_ValueField3.currentIndex;

                        var sSaveString = arValueTypes[0].toString() + "," + arValueTypes[1].toString() + "," + arValueTypes[2].toString();

                        settings.valuePebbleFields = sSaveString;

                        JSTools.fncGenerateHelperArray();
                    }
                }
            }
            ComboBox
            {
                visible: id_TextSwitch_enablePebble.checked
                id: id_CMB_ValueField3
                label: qsTr("3 PACE/SPEED field:")
                menu: ContextMenu { Repeater { model: JSTools.arrayPebbleValueTypes; MenuItem { text: modelData.header } }}
                onCurrentItemChanged:
                {
                    if (!bLockOnCompleted && !bLockFirstPageLoad)
                    {
                        console.log("Combo changed: " + JSTools.arrayPebbleValueTypes[currentIndex].header);

                        //Check if an other combobox has this value
                        if (currentIndex === id_CMB_ValueField1.currentIndex || currentIndex === id_CMB_ValueField2.currentIndex)
                        {
                            fncShowMessage(3,qsTr("This value is already assigned!"), 3000);
                            return
                        }

                        //Check if the other comboboxes are OK
                        if (id_CMB_ValueField1.currentIndex === id_CMB_ValueField2.currentIndex)
                            return;

                        var arValueTypes = settings.valuePebbleFields.split(",");
                        if (arValueTypes === undefined || arValueTypes === "" || arValueTypes.length !== 3)    //This is the amount pebble fields
                        {
                            //Set defaults if save string is damaged or broken
                            arValueTypes[0] = 10;
                            arValueTypes[1] = 8;
                            arValueTypes[2] = 3;
                        }

                        arValueTypes[0] = id_CMB_ValueField1.currentIndex;
                        arValueTypes[1] = id_CMB_ValueField2.currentIndex;
                        arValueTypes[2] = id_CMB_ValueField3.currentIndex;

                        var sSaveString = arValueTypes[0].toString() + "," + arValueTypes[1].toString() + "," + arValueTypes[2].toString();

                        settings.valuePebbleFields = sSaveString;

                        JSTools.fncGenerateHelperArray();
                    }
                }
            }            
            ProgressBar
            {
                id: progressBarCheckPebble
                width: parent.width
                maximumValue: 6
                valueText: value.toString() + "/" + maximumValue.toString()
                label: ""
                visible: (iCheckPebbleStep > 0)
                value: iCheckPebbleStep
            }
        }
    }
}
