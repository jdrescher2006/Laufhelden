import QtQuick 2.0
import Sailfish.Silica 1.0
import "SharedResources.js" as SharedResources


Page {
    id: pageBTConnectPage

    property bool bFirstPage: true
    property bool bBluetoothScanning: false
    property int iScannedDevicesCount: 0
    property string sConnectingBTDevice: ""
    property string sActiveBTDevice: ""
    property string sHeartRateHexString: ""
    property string sHeartRate: ""
    property string sBatteryLevel: ""

    onStatusChanged:
    {       
        if (status === PageStatus.Active && bFirstPage)
        {
            bFirstPage = false

            //DEBUG START
            //SharedResources.fncAddDevice("Polar iWL", "00:22:D0:02:2F:54");
            //DEBUG ENDE


            id_LV_Devices.model = SharedResources.fncGetDevicesNumber();
        }
    }

    Connections
    {
        target: id_BluetoothConnection
        onDeviceFound:
        {
            //Add device to data array
            SharedResources.fncAddDevice(sName, sAddress);            
            id_LV_Devices.model = iScannedDevicesCount = SharedResources.fncGetDevicesNumber();
        }
        onScanFinished:
        {
            //Scan is finished now
            bBluetoothScanning = false;
        }
    }
    Connections
    {
        target: id_BluetoothData
        onSigReadDataReady:
        {
            //id_LBL_ReadText.text = sData;

            sHeartRateHexString = sHeartRateHexString + sData.toLowerCase();

            console.log("sHeartRateHexString: " + sHeartRateHexString);

            //Minimum length Polar packets is 8 bytes
            if (sHeartRateHexString.length < 16)
                return;

            //Search for header byte, must always be 0xfe
            if (sHeartRateHexString.indexOf("fe") !== -1)
            {
                //Cut off everything left of fe
              sHeartRateHexString = sHeartRateHexString.substr((sHeartRateHexString.indexOf("fe")));
            }
            else
                return; //No header byte found
            //Check if packet is at correct length
            var iPacketLength = parseInt(sHeartRateHexString.substr(2,2), 16);
            console.log("iPacketLength: " + iPacketLength);
            if (sHeartRateHexString.length < (iPacketLength * 2))
                return; //Packet has is not big enough
            //Check check byte, 255 - packet length
            var iCheckByte = parseInt(sHeartRateHexString.substr(4,2), 16);
            console.log("iCheckByte: " + iCheckByte);
            if (iCheckByte !== (255 - iPacketLength))
            {
                console.log("Check byte is not valid!");
                return; //Check byte is not valid
            }
            //Check sequence valid
            var iSequenceValid = parseInt(sHeartRateHexString.substr(6,2), 16);
            console.log("iSequenceValid: " + iSequenceValid);
            if (iSequenceValid >= 16)
                return; //Sequence valid byte is not valid

            //Check status byte
            var iStatus = parseInt(sHeartRateHexString.substr(8,2), 16);
            console.log("iStatus: " + iStatus);
            //Check battery state
            var iBattery = parseInt(sHeartRateHexString.substr(8,1), 16);
            console.log("iBattery: " + iBattery);
            //Extract heart rate
            var iHeartRate = parseInt(sHeartRateHexString.substr(10,2), 16);
            console.log("iHeartRate: " + iHeartRate);

            sHeartRate = iHeartRate.toString();

            var sTemp = ((100/15) * iBattery).toString();
            if (sTemp.indexOf(".") != -1)
                sTemp = sTemp.substring(0, sTemp.indexOf("."));
            sBatteryLevel = sTemp + "%";

            //Extraction was successful here. Reset message text var.
            sHeartRateHexString = "";

        }
        onSigConnected:
        {            
            fncShowMessage(2,"Connected", 4000);
            bConnected = true;            
            sActiveBTDevice = sConnectingBTDevice;
        }
        onSigDisconnected:
        {
            fncShowMessage(1,"Disconnected", 4000);
            sHeartRate = "";
            sBatteryLevel = "";
            sActiveBTDevice = "";
            bConnected = false;
        }
        onSigError:
        {
            fncShowMessage(3,"Error: " + sError, 10000);
        }
    }


    // To enable PullDownMenu, place our content in a SilicaFlickable
    SilicaFlickable
    {
        anchors.fill: parent


        contentHeight: column.height

        Column
        {
            id: column

            width: pageBTConnectPage.width
            spacing: Theme.paddingLarge
            PageHeader
            {
                title: qsTr("Connect heart rate device")
            }

            SectionHeader
            {
                text: qsTr("Scan for Bluetooth devices...")
                visible: !bBluetoothScanning && !bConnecting && !bConnected
            }
            Button
            {
                width: parent.width
                text: qsTr("Start Scanning...")
                visible: !bBluetoothScanning && !bConnecting && !bConnected
                onClicked:
                {
                    bBluetoothScanning = true;
                    SharedResources.fncDeleteDevices();
                    id_LV_Devices.model = iScannedDevicesCount = SharedResources.fncGetDevicesNumber();
                    id_BluetoothConnection.vStartDeviceDiscovery();
                }
                Image
                {
                    anchors.verticalCenter: parent.verticalCenter
                    source: "image://theme/icon-m-bluetooth"
                }
            }
            Button
            {
                width: parent.width
                text: qsTr("Cancel")
                visible: bBluetoothScanning
                onClicked:
                {
                    id_BluetoothConnection.vStopDeviceDiscovery();
                }
                Image
                {
                    source: "image://theme/icon-m-sync"
                    anchors.verticalCenter: parent.verticalCenter
                    smooth: true
                    NumberAnimation on rotation
                    {
                      running: bBluetoothScanning
                      from: 0
                      to: 360
                      loops: Animation.Infinite
                      duration: 2000
                    }
                }
            }


            Button
            {
                text: "Disconnect"
                onClicked:
                {
                    id_BluetoothData.disconnect();                    
                }
            }

            SectionHeader
            {
                text: qsTr("Active BT device")
            }
            Label
            {
                width: parent.width;
                text: sActiveBTDevice;
            }
            Label
            {
                width: parent.width;
                id: id_LBL_HeartRate;
                text: qsTr("Heart Rate: ") + sHeartRate;
            }
            Label
            {
                width: parent.width;
                id: id_LBL_Battery;
                text: qsTr("Battery Level: ") + sBatteryLevel;
            }

            SectionHeader
            {
                text: qsTr("Found BT devices (press to connect):")
                visible: (iScannedDevicesCount > 0 &&  !bConnected && !bConnecting)
            }
            SilicaListView
            {
                id: id_LV_Devices
                model: SharedResources.fncGetDevicesNumber();
                anchors.left: parent.left
                anchors.right: parent.right
                height: parent.height / 3
                visible: (iScannedDevicesCount > 0 &&  !bConnected && !bConnecting)

                delegate: BackgroundItem
                {
                    id: delegate

                    Label
                    {
                        x: Theme.paddingLarge
                        text: SharedResources.fncGetDeviceBTName(index) + ", " + SharedResources.fncGetDeviceBTAddress(index);
                        anchors.verticalCenter: parent.verticalCenter
                        color: delegate.highlighted ? Theme.highlightColor : Theme.primaryColor
                    }
                    onClicked:
                    {
                        console.log("Clicked " + index);
                        sConnectingBTDevice = SharedResources.fncGetDeviceBTName(index) + ", " + SharedResources.fncGetDeviceBTAddress(index);
                        id_BluetoothData.connect(SharedResources.fncGetDeviceBTAddress(index), 1);
                    }
                }
                VerticalScrollDecorator {}
            }
        }
    }
}


