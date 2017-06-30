import QtQuick 2.0
import Sailfish.Silica 1.0
import "SharedResources.js" as SharedResources


Page {
    id: pageBTConnectPage

    property bool bFirstPage: true
    property bool bBluetoothScanning: false
    property int iScannedDevicesCount: 0
    property string sConnectingBTDevice: ""    

    onStatusChanged:
    {       
        if (status === PageStatus.Active && bFirstPage)
        {
            bFirstPage = false

            console.log("BTPage");

            //DEBUG START
            SharedResources.fncAddDevice("Polar iWL", "00:22:D0:02:2F:54");
            //DEBUG ENDE

            id_LV_Devices.model = iScannedDevicesCount = SharedResources.fncGetDevicesNumber();            
        }
        if (status === PageStatus.Inactive)
        {
            if (bHRMConnected) {id_BluetoothData.disconnect();}

            sHeartRate: ""
            sBatteryLevel: ""
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

            console.log(iScannedDevicesCount.toString());
        }
        onScanFinished:
        {
            //Scan is finished now
            bBluetoothScanning = false;
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
                visible: !bBluetoothScanning && !bHRMConnecting && !bHRMConnected
            }
            Button
            {
                width: parent.width
                text: qsTr("Start Scanning...")
                visible: !bBluetoothScanning && !bHRMConnecting && !bHRMConnected
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
                visible: bHRMConnected
                width: parent.width;
                id: id_LBL_HeartRate;
                text: qsTr("Heart Rate: ") + sHeartRate + qsTr(" bpm");
            }
            Label
            {
                visible: bHRMConnected
                width: parent.width;
                id: id_LBL_Battery;
                text: qsTr("Battery Level: ") + sBatteryLevel + " %";
            }

            SectionHeader
            {
                text: qsTr("Found BT devices (press to connect):")
                visible: (iScannedDevicesCount > 0 &&  !bHRMConnected && !bHRMConnecting)
            }
            SilicaListView
            {
                id: id_LV_Devices
                model: SharedResources.fncGetDevicesNumber();
                anchors.left: parent.left
                anchors.right: parent.right
                height: parent.height / 3
                visible: (iScannedDevicesCount > 0 &&  !bHRMConnected && !bHRMConnecting)

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
                        if (bBluetoothScanning)
                            return;
                        sConnectingBTDevice = SharedResources.fncGetDeviceBTName(index) + ", " + SharedResources.fncGetDeviceBTAddress(index);
                        id_BluetoothData.connect(SharedResources.fncGetDeviceBTAddress(index), 1);
                        sHRMAddress = SharedResources.fncGetDeviceBTAddress(index);
                    }
                }
                VerticalScrollDecorator {}
            }
        }
    }
}


