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

    onStatusChanged:
    {
        //This is loaded only the first time the page is displayed
        if (status === PageStatus.Active && bLockFirstPageLoad)
        {
            bLockOnCompleted = true;

            bLockFirstPageLoad = false;
            console.log("First Active CoverSettingsPage");

            var arValueTypes = settings.valueCoverFields.split(",");
            if (arValueTypes === undefined || arValueTypes === "" || arValueTypes.length !== 3)    //This is the amount cover page fields
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
            console.log("Active CoverSettingsPage");

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
                title: qsTr("Cover page settings")
            }
            Label
            {
                text: qsTr("Select values to be shown on the Cover Page.")
                font.pixelSize: Theme.fontSizeSmall
            }
            ComboBox
            {
                id: id_CMB_ValueField1
                label: qsTr("First field:")
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

                        var arValueTypes = settings.valueCoverFields.split(",");
                        if (arValueTypes === undefined || arValueTypes === "" || arValueTypes.length !== 3)    //This is the of amount cover page fields
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

                        settings.valueCoverFields = sSaveString;

                        JSTools.fncGenerateHelperArrayCoverPage();
                    }
                }
            }
            ComboBox
            {
                id: id_CMB_ValueField2
                label: qsTr("Second field:")
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

                        var arValueTypes = settings.valueCoverFields.split(",");
                        if (arValueTypes === undefined || arValueTypes === "" || arValueTypes.length !== 3)    //This is the of amount cover page fields
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

                        settings.valueCoverFields = sSaveString;

                        JSTools.fncGenerateHelperArrayCoverPage();
                    }
                }
            }
            ComboBox
            {
                id: id_CMB_ValueField3
                label: qsTr("Third field:")
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

                        var arValueTypes = settings.valueCoverFields.split(",");
                        if (arValueTypes === undefined || arValueTypes === "" || arValueTypes.length !== 3)    //This is the of amount cover page fields
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

                        settings.valueCoverFields = sSaveString;

                        JSTools.fncGenerateHelperArrayCoverPage();
                    }
                }
            }
        }
    }
}
