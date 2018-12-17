/***************************************************************************
**
** Copyright (C) 2013 BlackBerry Limited. All rights reserved.
** Copyright (C) 2017 The Qt Company Ltd.
** Contact: https://www.qt.io/licensing/
**
** This file is part of the QtBluetooth module of the Qt Toolkit.
**
** $QT_BEGIN_LICENSE:BSD$
** Commercial License Usage
** Licensees holding valid commercial Qt licenses may use this file in
** accordance with the commercial license agreement provided with the
** Software or, alternatively, in accordance with the terms contained in
** a written agreement between you and The Qt Company. For licensing terms
** and conditions see https://www.qt.io/terms-conditions. For further
** information use the contact form at https://www.qt.io/contact-us.
**
** BSD License Usage
** Alternatively, you may use this file under the terms of the BSD license
** as follows:
**
** "Redistribution and use in source and binary forms, with or without
** modification, are permitted provided that the following conditions are
** met:
**   * Redistributions of source code must retain the above copyright
**     notice, this list of conditions and the following disclaimer.
**   * Redistributions in binary form must reproduce the above copyright
**     notice, this list of conditions and the following disclaimer in
**     the documentation and/or other materials provided with the
**     distribution.
**   * Neither the name of The Qt Company Ltd nor the names of its
**     contributors may be used to endorse or promote products derived
**     from this software without specific prior written permission.
**
**
** THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
** "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
** LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
** A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
** OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
** SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
** LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
** DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
** THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
** (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
** OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE."
**
** $QT_END_LICENSE$
**
****************************************************************************/

/***************************************************************************
 * This file contains bluetooth functions for Laufhelden, based on the QT
 * example files.
 * Some parts are also taken from the original Laufhelden bluetoothdata.cpp
 * by Jens Drescher
 * (c) 2018 Thomas Michel <tom@michel.ruhr>
 * *************************************************************************/


#include "device.h"

#include <qbluetoothaddress.h>
#include <qbluetoothdevicediscoveryagent.h>
#include <qbluetoothlocaldevice.h>
#include <qbluetoothdeviceinfo.h>
#include <qbluetoothservicediscoveryagent.h>
#include <QDebug>
#include <QList>
#include <QTimer>
#include <QtEndian>

Device::Device():
    connected(false), m_controller(0), m_deviceScanState(false),m_socket(0), m_batTimer(0)
{
    m_bluetoothType = Device::BLEPUBLIC;
    discoveryAgent = new QBluetoothDeviceDiscoveryAgent();
    connect(discoveryAgent, &QBluetoothDeviceDiscoveryAgent::deviceDiscovered,
            this, &Device::addDevice);
    //TODO: Error handling
    //connect(discoveryAgent, &QBluetoothDeviceDiscoveryAgent::error,
    //        this, &Device::deviceScanError);
    connect(discoveryAgent, &QBluetoothDeviceDiscoveryAgent::finished, this, &Device::deviceScanFinished);
    startDeviceDiscovery();
}

Device::~Device()
{
    delete discoveryAgent;
    m_controller->deleteLater();
    qDeleteAll(devices);
    devices.clear();
}

void Device::startDeviceDiscovery()
{
    if (m_deviceScanState) {
        m_deviceScanState = false;
        discoveryAgent->stop();
    }
    qDeleteAll(devices);
    devices.clear();
    emit devicesUpdated();

    qDebug() << "Scanning for devices ...";
    discoveryAgent->start();

    if (discoveryAgent->isActive()) {
        m_deviceScanState = true;
        emit stateChanged();
    }
}

void Device::stopDeviceDiscovery()
{
    qDebug() << "Scanning for devices stopped...";
    discoveryAgent->stop();

    m_deviceScanState = false;
    emit scanFinished();
    emit stateChanged();
}

void Device::addDevice(const QBluetoothDeviceInfo &info)
{
        DeviceInfo *d = new DeviceInfo(info);
        devices.append(d);
        qDebug() << "Last device added: " + d->getName();
        emit deviceFound(d->getName(), d->getAddress());
}

void Device::deviceScanFinished()
{
    emit devicesUpdated();
    m_deviceScanState = false;
    emit stateChanged();
    emit scanFinished();
    if (devices.isEmpty())
        qDebug() << "No Bluetooth devices found...";
    else
        qDebug() << "Scan finished!";
}

QVariant Device::getDevices()
{
    return QVariant::fromValue(devices);
}


QString Device::getUpdate()
{
    return m_message;
}

void Device::scanServices(const QString &address)
{
    qDebug() << "Trying to connect to " << address;

    m_heartRateFound = false;
    m_batteryStateFound = false;

    // We need the current device for service discovery.

    bool deviceFound = false;

    for (int i = 0; i < devices.size(); i++) {
        if (((DeviceInfo*)devices.at(i))->getAddress() == address )
        {
            currentDevice.setDevice(((DeviceInfo*)devices.at(i))->getDevice());
            deviceFound  = true;
        }
    }

    if (!deviceFound)   {
        qDebug() << "Device to connect not found!";
        return;
    }

    if (!currentDevice.getDevice().isValid()) {
        qWarning() << "Not a valid device";
        return;
    }


    if (m_controller)  {
        qDebug() << "Trying Disconnect now";
        if (m_controller->state() == QLowEnergyController::ConnectedState)
        {
            qDebug() << "Disconnecting from previous BLE device...";
            m_controller->disconnectFromDevice();
            m_controller->deleteLater();
            m_controller = 0;
        }

    }


    if (m_bluetoothType==Device::BLEPUBLIC||m_bluetoothType==Device::BLERANDOM) {
        qDebug() << "Trying to connect to BLE address " << currentDevice.getName();
        // Connecting signals and slots for connecting to LE services.
        if (!m_controller)
            m_controller = new QLowEnergyController(currentDevice.getDevice());
        connect(m_controller, &QLowEnergyController::connected,
                this, &Device::deviceConnected);
        connect(m_controller, &QLowEnergyController::disconnected,
                this, &Device::deviceDisconnected);
        connect(m_controller, &QLowEnergyController::serviceDiscovered,
                this, &Device::lowEnergyServiceDiscovered);
        connect(m_controller, &QLowEnergyController::discoveryFinished,
                this, &Device::serviceScanDone);
        connect(m_controller, static_cast<void (QLowEnergyController::*)(QLowEnergyController::Error)>(&QLowEnergyController::error),
                this, &Device::errorReceived);
        if (m_bluetoothType==Device::BLEPUBLIC)
            m_controller->setRemoteAddressType(QLowEnergyController::PublicAddress);
        else
            m_controller->setRemoteAddressType(QLowEnergyController::RandomAddress);
        m_controller->connectToDevice();
        emit this->sigConnecting();

    }
    else {
        // Connect to classic device
        connectClassic(currentDevice.getAddress(),1);
    }
    m_previousAddress = currentDevice.getAddress();
}

void Device ::connectClassic(QString address, int port)
{
    this->m_port = port;
    qDebug() << "Trying to connect to " << address;
    qDebug("Trying to connect to: %s_%d", address.toUtf8().constData(), m_port);

    if(this->m_socket)
        delete this->m_socket;

    this->m_socket = new QBluetoothSocket(QBluetoothServiceInfo::RfcommProtocol);

    QObject::connect(this->m_socket, SIGNAL(connected()), this, SLOT(deviceConnected()));
    QObject::connect(this->m_socket, SIGNAL(disconnected()), this, SLOT(deviceDisconnected()));
    QObject::connect(this->m_socket, SIGNAL(error(QBluetoothSocket::SocketError)), this, SLOT(error(QBluetoothSocket::SocketError)));
    QObject::connect(this->m_socket, SIGNAL(readyRead()), this, SLOT(readData()));

    qDebug("Connecting...");
    this->m_socket->connectToService(QBluetoothAddress(address), this->m_port);
}
void Device::lowEnergyServiceDiscovered(const QBluetoothUuid &serviceUuid)
{

    if (serviceUuid == QBluetoothUuid(QBluetoothUuid::HeartRate)) {
        qDebug() << "Heart Rate Monitor Found";
        m_heartRateFound = true;
        return;
    }
    if (serviceUuid == QBluetoothUuid(QBluetoothUuid::BatteryService)) {
        qDebug() << "Battery Level Found";
        m_batteryStateFound = true;
        return;
    }
    // This is for debug purposes only:#
    /*
    QLowEnergyService *tmpService = controller->createServiceObject((serviceUuid));
    if (tmpService)
    {
        qDebug() << "Service found: " << tmpService->serviceName();
        delete tmpService;
    }
    */

}
void Device::serviceScanDone()
{
    qDebug() << "Service scan done!)";
    emit servicesUpdated();
    // Now we connect to the HRM and Battery Status
    if (m_heartRateFound)
    {
         m_hrmService = m_controller->createServiceObject(QBluetoothUuid(QBluetoothUuid::HeartRate),this);
         if (!m_hrmService) {
             qWarning() << "Cannot create service for HRM";
             return;
         }
         connect(m_hrmService, &QLowEnergyService::stateChanged,
                 this, &Device::hrmServiceStateChanged);

         m_hrmService->discoverDetails();
     }
    if (m_batteryStateFound)
    {
         m_batService = m_controller->createServiceObject(QBluetoothUuid(QBluetoothUuid::BatteryService),this);
         if (!m_batService) {
             qWarning() << "Cannot create service for Battery Level";
             return;
         }
         connect(m_batService, &QLowEnergyService::stateChanged,
                 this, &Device::batServiceStateChanged);
         m_batService->discoverDetails();
     }
}

void Device::deviceConnected()
{
    qDebug() << "BLE Device connected - Discovering services...)";
    connected = true;
    //! [les-service-2]
    if (m_bluetoothType!=Device::CLASSICBLUETOOTH)
    {
       m_controller->discoverServices();
    }

    emit this->sigConnected();
}

void Device::errorReceived(QLowEnergyController::Error /*error*/)
{
    //qWarning() << "Error connecting to BLE device: " << m_controller->errorString();
    //emit sigError(QString("(%1)").arg(m_controller->errorString()));
    emit this->sigError(QString("Could not connect to device. Ensure it is switched on or try different connection method."));
}

void Device::error(QBluetoothSocket::SocketError errorCode)
{
    qDebug() << "Error: " << this->m_socket->errorString();
    qDebug() << "Errorcode: " << errorCode;

    emit this->sigError(this->m_socket->errorString());
}



void Device::setUpdate(QString message)
{
    m_message = message;
    emit updateChanged();
}

void Device::disconnectFromDevice()
{
    // UI always expects disconnect() signal when calling this signal
    // TODO what is really needed is to extend state() to a multi value
    // and thus allowing UI to keep track of controller progress in addition to
    // device scan progress

    if (!m_controller)
        return;
    if (m_controller->state() != QLowEnergyController::UnconnectedState)
        m_controller->disconnectFromDevice();
    else
        deviceDisconnected();
}

void Device::deviceDisconnected()
{
    qWarning() << "Disconnect from device";
    if ((m_bluetoothType!=Device::CLASSICBLUETOOTH) && m_controller)  {
        if (m_controller->errorString()=="")
            //otherwise an error has been emitted and we would overwrite the message
            emit sigDisconnected();
    } else if (m_socket) {
        if (m_socket->errorString()=="")
            //otherwise an error has been emitted and we would overwrite the message
            emit sigDisconnected();
    }
}


void Device::hrmServiceStateChanged(QLowEnergyService::ServiceState s)
{
    switch (s) {
    case QLowEnergyService::DiscoveringServices:
        qDebug() <<"Discovering services...";
        break;
    case QLowEnergyService::ServiceDiscovered:
    {

        subscribeToHRM();
        break;
    }
    default:
        //nothing for now
        break;
    }

    //emit aliveChanged();
}

void Device::subscribeToHRM()
{
    if (!m_hrmService) {
        return;
    }
    // check for Heart Rate charactereistic available
    const QLowEnergyCharacteristic hrChar = m_hrmService->characteristic(QBluetoothUuid(QBluetoothUuid::HeartRateMeasurement));
    if (!hrChar.isValid()) {
        qDebug() << "HR Data not found.";
    }
    // check for Heart Rate descriptor availabily
    m_notificationDesc = hrChar.descriptor(QBluetoothUuid::ClientCharacteristicConfiguration);
    if (m_notificationDesc.isValid())
    {
        // subscribe to Heart Rate service
        qDebug() << "Subscribing to HRM Service";
        connect(m_hrmService, &QLowEnergyService::characteristicChanged,
                this, &Device::updateValues);
        m_hrmService->writeDescriptor(m_notificationDesc, QByteArray::fromHex("0100"));
    }

}

void Device::batServiceStateChanged(QLowEnergyService::ServiceState s)
{
    switch (s) {
    case QLowEnergyService::DiscoveringServices:
        qDebug() <<"Discovering services...";
        break;
    case QLowEnergyService::ServiceDiscovered:
    {
        qDebug() << "Service discovered.";
        // check for Battery charactereistic available
        const QLowEnergyCharacteristic hrChar = m_batService->characteristic(QBluetoothUuid(QBluetoothUuid::BatteryLevel));
        if (!hrChar.isValid()) {
            qDebug() << "Battery Data not found.";
            break;
        }
        // check for Battery descriptor availability
        QLowEnergyDescriptor notificationDesc = hrChar.descriptor(QBluetoothUuid::ClientCharacteristicConfiguration);
        if (notificationDesc.isValid())
        {
            qDebug() << "Subscribing to Battery Service";
            // subscribe to Battery level service
            connect(m_batService, &QLowEnergyService::characteristicChanged,
                    this, &Device::updateValues);
            connect(m_batService, &QLowEnergyService::characteristicRead,
                    this, &Device::updateValues );

            m_batService->writeDescriptor(notificationDesc, QByteArray::fromHex("0100"));
            // Try to read battery data periodically for device not sending a signal
            if (!m_batTimer)
                m_batTimer = new QTimer(this);
            connect(m_batTimer, SIGNAL(timeout()), this, SLOT(updateBatteryData()));
            m_batTimer->start(10000);

        }

        break;
    }
    default:
        //nothing for now
        break;
    }

    //emit aliveChanged();
}

void Device::updateValues(const QLowEnergyCharacteristic &c, const QByteArray &value)
{
    const quint8 *data = reinterpret_cast<const quint8 *>(value.constData());

    // Heart Rate Update
    if (c.uuid() == QBluetoothUuid(QBluetoothUuid::HeartRateMeasurement))
    {
        const quint8 *data = reinterpret_cast<const quint8 *>(value.constData());
        quint8 flags = data[0];

        //Heart Rate
        int hrvalue = 0;
        if (flags & 0x1) // HR 16 bit? otherwise 8 bit
            hrvalue = (int)qFromLittleEndian<quint16>(data[1]);
        else
            hrvalue = (int)data[1];

        //qDebug() << "Current Heart Rate " << hrvalue;
        emit this->sigHRMDataReady(hrvalue);
    }

    // Battery Level Update
    if (c.uuid() == QBluetoothUuid(QBluetoothUuid::BatteryLevel))
    {
        quint8 batvalue = data[0];
        qDebug() << "Current battery Level " << (int)batvalue;
        emit this->sigBATDataReady(batvalue);
    }
}

void Device::updateBatteryData()
{
    if (m_batService)
    {
        qDebug() << "Polling battery status";
        const QLowEnergyCharacteristic batChar = m_batService->characteristic(QBluetoothUuid(QBluetoothUuid::BatteryLevel));
        m_batService->readCharacteristic(batChar);
        if (m_batTimer) m_batTimer->start(10000);
    }
}

void Device::deviceScanError(QBluetoothDeviceDiscoveryAgent::Error error)
{
    if (error == QBluetoothDeviceDiscoveryAgent::PoweredOffError)
        qDebug() <<"The Bluetooth adaptor is powered off, power it on before doing discovery.";
    else if (error == QBluetoothDeviceDiscoveryAgent::InputOutputError)
        qDebug() << "Writing or reading from the device resulted in an error.";
    else
        qDebug() << "An unknown error has occurred.";

    m_deviceScanState = false;
    emit devicesUpdated();
    emit stateChanged();
}

bool Device::state()
{
    return m_deviceScanState;
}

bool Device::hasControllerError() const
{
    if (m_controller && m_controller->error() != QLowEnergyController::NoError)
        return true;
    return false;
}

bool Device::isRandomAddress() const
{
    return randomAddress;
}

void Device::setRandomAddress(bool newValue)
{
    randomAddress = newValue;
    emit randomAddressChanged();
}

int Device::bluetoothType()
{
    return m_bluetoothType;
}
void Device::setBluetoothType(int type)
{
    m_bluetoothType = type;
    qDebug() << "Set Bluetooth type to " << type;
    emit bluetoothTypeChanged(m_bluetoothType);
}



void Device::readData()
{
    //reads data from a classic Bluetooth Device
    qDebug("Entering readData...");

    QByteArray data = m_socket->readAll();

    QString s_data = data.trimmed();

    //s_data = s_data.replace("\r", " ");
    //s_data = s_data.replace("\n", " ");

    //qDebug() << "Data size:" << data.size();
    //qDebug() << "Data Hex[" + QString::number(_port) + "]:" << data.toHex();
    //qDebug() << "Data[" + QString::number(_port) + "]:" << data;

    //qDebug() << "Text: " << s_data;

    emit this->sigReadDataReady(data.toHex());
}

void Device::sendHex(QString sString)
{
    //This is for classic bluetooth devices
    //qDebug() << "sString: " << sString;

    QByteArray data = sString.toUtf8();

    //qDebug() << "data1: " << data.toHex();

    data.append("\r");

    //qDebug() << "data2: " << data.toHex();

    this->write(data);
}

qint64 Device::write(QByteArray data)
{
    // This is for classic bluettoth devices
    qDebug() << "Writing:" << data.toHex();


    qint64 ret = this->m_socket->write(data);


    //qint64 ret = this->_socket->write("ATZ\r");
    //ret = this->_socket->write("AT RV\r");
    //qint64 ret = this->_socket->write("AT L0\r");

    qDebug() << "Write returned:" << ret;



    return ret;
}
