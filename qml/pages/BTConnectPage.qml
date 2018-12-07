import QtQuick 2.0
import Sailfish.Silica 1.0
import "../tools/SharedResources.js" as SharedResources


Page {
    id: pageBTConnectPage

    property bool bLockFirstPageLoad: true
    property bool bBluetoothScanning: false
    property int iScannedDevicesCount: 0
    property int iBluetoothType: 0

    Component.onCompleted:                 {
        bBluetoothScanning = true;
        SharedResources.fncDeleteDevices();
        id_LV_Devices.model = iScannedDevicesCount = SharedResources.fncGetDevicesNumber();
        id_Device.startDeviceDiscovery();
    }

    onStatusChanged:
    {       
        if (status === PageStatus.Active && bLockFirstPageLoad)
        {
            bLockFirstPageLoad = false;

            console.log("BTPage");

            //DEBUG START
            //SharedResources.fncAddDevice("Polar iWL", "00:22:D0:02:2F:54");
            //DEBUG ENDE

            id_LV_Devices.model = iScannedDevicesCount = SharedResources.fncGetDevicesNumber();            
        }
        if (status === PageStatus.Inactive)
        {
            if (bHRMConnected) {id_Device.disconnect();}

            sHeartRate: ""
            sBatteryLevel: ""
        }
        id_CMB_BluetoothType.currentIndex = settings.bluetoothType;
    }


    Connections
    {
        target: id_Device
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
        onConnecting:
        {
            btnConnect.enabled = false;
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
                title: qsTr("Heart rate device")
            }

            SectionHeader
            {
                text: qsTr("Scan for Bluetooth devices")
                visible: !bHRMConnected
            }
            Button
            {
                width: parent.width
                text: qsTr("Start scanning...")
                visible: !bBluetoothScanning &&!bHRMConnected
                enabled:  !bHRMConnecting
                onClicked:
                {
                    bBluetoothScanning = true;
                    SharedResources.fncDeleteDevices();
                    id_LV_Devices.model = iScannedDevicesCount = SharedResources.fncGetDevicesNumber();
                    id_Device.startDeviceDiscovery();
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
                text: qsTr("Cancel scanning")
                visible: bBluetoothScanning
                onClicked:
                {
                    id_Device.stopDeviceDiscovery();
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

            Separator {
                color: Theme.highlightColor
                width: parent.width
                visible:    !bHRMConnected

            }

            SectionHeader
            {
                text: qsTr("Current BT device")
            }
            Label
            {
                width: parent.width;
                text: sHRMAddress === "" ? qsTr("None") : sHRMDeviceName + ", " + sHRMAddress
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
            ComboBox
            {
                id: id_CMB_BluetoothType
                label: qsTr("Connection Type")
                menu: ContextMenu
                {
                    MenuItem
                    {
                        text: qsTr("BLE Public Address")
                        onClicked:
                        {
                            settings.bluetoothType = 0;//id_Device.BLEPUBLIC;
                            id_Device.setBluetoothType(0);//id_Device.BLEPUBLIC);
                        }
                    }
                    MenuItem
                    {
                        text: qsTr("BLE Random Address")
                        onClicked:
                        {
                           settings.bluetoothType = 1;// id_Device.BLERANDOM;
                           id_Device.setBluetoothType(1);//id_Device.BLERANDOM);
                        }
                    }
                    MenuItem
                    {
                        text: qsTr("Classic Bluetooth")
                        onClicked:
                        {
                            settings.bluetoothType = 2; //id_Device.CLASSICBLUETOOTH;
                            id_Device.setBluetoothType(2); //id_Device.CLASSICBLUETOOTH);
                        }
                    }
                }
            }

            Button
            {
                id: btnConnect
                text: qsTr("Connect")
                width: parent.width
                visible: !bHRMConnected && sHRMAddress !== ""  && !bHRMConnecting
                onClicked:
                {
                    id_Device.scanServices(sHRMAddress);
                }
            }
            Button
            {
                width: parent.width
                text: qsTr("Cancel Connect")
                visible: bHRMConnecting
                onClicked:
                {
                    // We could stop the connection attempt herer
                    id_Device.disconnectFromDevice();
                }
                Image
                {
                    source: "image://theme/icon-m-sync"
                    anchors.verticalCenter: parent.verticalCenter
                    smooth: true
                    NumberAnimation on rotation
                    {
                      running: bHRMConnecting
                      from: 0
                      to: 360
                      loops: Animation.Infinite
                      duration: 2000
                    }
                }
            }
            Button
            {
                text: qsTr("Disconnect")
                width: parent.width
                visible: bHRMConnected && !bHRMConnecting && sHRMAddress !== ""
                onClicked:
                {
                    id_Device.disconnectFromDevice();
                }
            }

            Separator { color: Theme.highlightColor; width: parent.width; }

            SectionHeader
            {
                text: qsTr("Found BT devices (press to connect):")
                visible: (iScannedDevicesCount > 0 &&  !bHRMConnected )//&& !bHRMConnecting)
            }
            SilicaListView
            {
                id: id_LV_Devices
                model: SharedResources.fncGetDevicesNumber();
                anchors.left: parent.left
                anchors.right: parent.right
                height: parent.height / 3
                visible: (iScannedDevicesCount > 0 &&  !bHRMConnected )//&& !bHRMConnecting)

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
                        if (bBluetoothScanning)
                            return;
                        sHRMAddress = SharedResources.fncGetDeviceBTAddress(index);
                        sHRMDeviceName = SharedResources.fncGetDeviceBTName(index);

                        //Save the new device to settings
                        settings.hrmdevice = sHRMAddress + "," + sHRMDeviceName;

                        id_BluetoothData.connect(SharedResources.fncGetDeviceBTAddress(index), 1);                        
                    }
                }
                VerticalScrollDecorator {}
            }
        }
    }
}


