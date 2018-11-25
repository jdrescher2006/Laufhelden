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
    connected(false), controller(0), m_deviceScanState(false), randomAddress(false)
{
    //! [les-devicediscovery-1]
    discoveryAgent = new QBluetoothDeviceDiscoveryAgent();
    connect(discoveryAgent, &QBluetoothDeviceDiscoveryAgent::deviceDiscovered,
            this, &Device::addDevice);
    //connect(discoveryAgent, &QBluetoothDeviceDiscoveryAgent::error,
    //        this, &Device::deviceScanError);
    connect(discoveryAgent, &QBluetoothDeviceDiscoveryAgent::finished, this, &Device::deviceScanFinished);

    //startDeviceDiscovery();
}

Device::~Device()
{
    delete discoveryAgent;
    delete controller;
    qDeleteAll(devices);
    qDeleteAll(m_services);
    devices.clear();
}

void Device::startDeviceDiscovery()
{
    qDeleteAll(devices);
    devices.clear();
    emit devicesUpdated();

    qDebug() << "Scanning for devices ...";
    discoveryAgent->start();

    if (discoveryAgent->isActive()) {
        m_deviceScanState = true;
        Q_EMIT stateChanged();
    }
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

QVariant Device::getServices()
{
    return QVariant::fromValue(m_services);
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
        exit;
    }

    if (!currentDevice.getDevice().isValid()) {
        qWarning() << "Not a valid device";
        return;
    }

    qDeleteAll(m_services);
    m_services.clear();
    emit servicesUpdated();

    if (controller && m_previousAddress != currentDevice.getAddress()) {
        qDebug() << "Disconnecting from previous device...";
        controller->disconnectFromDevice();
        delete controller;
        controller = 0;
    }

    if (!controller) {
        qDebug() << "Trying to connect to " << currentDevice.getName();
        // Connecting signals and slots for connecting to LE services.
        controller = new QLowEnergyController(currentDevice.getDevice());
        connect(controller, &QLowEnergyController::connected,
                this, &Device::deviceConnected);
        connect(controller, &QLowEnergyController::disconnected,
                this, &Device::deviceDisconnected);
        connect(controller, &QLowEnergyController::serviceDiscovered,
                this, &Device::lowEnergyServiceDiscovered);
        connect(controller, &QLowEnergyController::discoveryFinished,
                this, &Device::serviceScanDone);
        connect(controller, static_cast<void (QLowEnergyController::*)(QLowEnergyController::Error)>(&QLowEnergyController::error),
                this, [this](QLowEnergyController::Error error) {
            Q_UNUSED(error);
            qDebug()<< "Cannot connect to remote device. " << error;
            // This would probably the moment to try to connect via non BTLE  Bluetooth
        });

    }

    if (isRandomAddress())
        controller->setRemoteAddressType(QLowEnergyController::RandomAddress);
    else
        controller->setRemoteAddressType(QLowEnergyController::PublicAddress);
    controller->connectToDevice();

    m_previousAddress = currentDevice.getAddress();
}

void Device::lowEnergyServiceDiscovered(const QBluetoothUuid &serviceUuid)
{

    if (serviceUuid == QBluetoothUuid(QBluetoothUuid::HeartRate)) {
        qDebug() << "Heart Rate Monitor Found";
        m_heartRateFound = true;
    }
    if (serviceUuid == QBluetoothUuid(QBluetoothUuid::BatteryService)) {
        qDebug() << "Battery Level Found";
        m_batteryStateFound = true;
    }

}
void Device::serviceScanDone()
{
    qDebug() << "Service scan done!)";
    emit servicesUpdated();
    // Now we connect to the HRM and Battery Status
    if (m_heartRateFound)
    {
         m_HRMservice = controller->createServiceObject(QBluetoothUuid(QBluetoothUuid::HeartRate),this);
         if (!m_HRMservice) {
             qWarning() << "Cannot create service for HRM";
             return;
         }
         if (m_HRMservice) {
             connect(m_HRMservice, &QLowEnergyService::stateChanged,
                     this, &Device::hrmServiceStateChanged);

             //connect(m_HRMservice, &QLowEnergyService::descriptorWritten,
             //        this, &Device::hrmConfirmedDescriptorWrite);

             m_HRMservice->discoverDetails();
         }
     }
    if (m_batteryStateFound)
    {
         m_BATservice = controller->createServiceObject(QBluetoothUuid(QBluetoothUuid::BatteryService),this);
         if (!m_BATservice) {
             qWarning() << "Cannot create service for Battery Level";
             return;
         }
         if (m_BATservice) {
             connect(m_BATservice, &QLowEnergyService::stateChanged,
                     this, &Device::batServiceStateChanged);

             //connect(m_HRMservice, &QLowEnergyService::descriptorWritten,
             //        this, &Device::hrmConfirmedDescriptorWrite);

             m_BATservice->discoverDetails();
         }
     }}

void Device::deviceConnected()
{
    qDebug() << "Device connected - Discovering services...)";
    connected = true;
    //! [les-service-2]
    controller->discoverServices();
    emit this->sigConnected();
    //! [les-service-2]
}

void Device::errorReceived(QLowEnergyController::Error /*error*/)
{
    qWarning() << "Error: " << controller->errorString();
    setUpdate(QString("Back\n(%1)").arg(controller->errorString()));
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

    if (controller->state() != QLowEnergyController::UnconnectedState)
        controller->disconnectFromDevice();
    else
        deviceDisconnected();
}

void Device::deviceDisconnected()
{
    qWarning() << "Disconnect from device";
    emit sigDisconnected();
}


void Device::hrmServiceStateChanged(QLowEnergyService::ServiceState s)
{
    switch (s) {
    case QLowEnergyService::DiscoveringServices:
        qDebug() <<"Discovering services...";
        break;
    case QLowEnergyService::ServiceDiscovered:
    {
        qDebug() << "Service discovered.";
        // check for Heart Rate charactereistic available
        const QLowEnergyCharacteristic hrChar = m_HRMservice->characteristic(QBluetoothUuid(QBluetoothUuid::HeartRateMeasurement));
        if (!hrChar.isValid()) {
            qDebug() << "HR Data not found.";
            break;
        }
        // check for Heart Rate descriptor availabily
        m_notificationDesc = hrChar.descriptor(QBluetoothUuid::ClientCharacteristicConfiguration);
        if (m_notificationDesc.isValid())
        {
            // subscribe to Heart Rate service
            connect(m_HRMservice, &QLowEnergyService::characteristicChanged,
                    this, &Device::updateHeartRateValue);
            m_HRMservice->writeDescriptor(m_notificationDesc, QByteArray::fromHex("0100"));
        }

        break;
    }
    default:
        //nothing for now
        break;
    }

    //emit aliveChanged();
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
        const QLowEnergyCharacteristic hrChar = m_BATservice->characteristic(QBluetoothUuid(QBluetoothUuid::BatteryLevel));
        if (!hrChar.isValid()) {
            qDebug() << "Battery Data not found.";
            break;
        }
        // check for Battery descriptor availability
        QLowEnergyDescriptor notificationDesc = hrChar.descriptor(QBluetoothUuid::ClientCharacteristicConfiguration);
        if (notificationDesc.isValid())
        {
            // subscribe to Battery level service
            connect(m_BATservice, &QLowEnergyService::characteristicChanged,
                    this, &Device::updateBatteryLevelValue);
            m_BATservice->writeDescriptor(notificationDesc, QByteArray::fromHex("0100"));
        }

        break;
    }
    default:
        //nothing for now
        break;
    }

    //emit aliveChanged();
}

void Device::updateHeartRateValue(const QLowEnergyCharacteristic &c, const QByteArray &value)
{
    // ignore any other characteristic change -> shouldn't really happen though
    if (c.uuid() != QBluetoothUuid(QBluetoothUuid::HeartRateMeasurement))
        return;

    const quint8 *data = reinterpret_cast<const quint8 *>(value.constData());
    quint8 flags = data[0];

    //Heart Rate
    int hrvalue = 0;
    if (flags & 0x1) // HR 16 bit? otherwise 8 bit
        hrvalue = (int)qFromLittleEndian<quint16>(data[1]);
    else
        hrvalue = (int)data[1];

    qDebug() << "Current Heart Rate " << hrvalue;

    emit this->sigBTLEDataReady(hrvalue);
}

void Device::updateBatteryLevelValue(const QLowEnergyCharacteristic &c, const QByteArray &value)
{
    // ignore any other characteristic change -> shouldn't really happen though
    if (c.uuid() != QBluetoothUuid(QBluetoothUuid::BatteryService))
        return;

    const quint8 *data = reinterpret_cast<const quint8 *>(value.constData());
    quint8 flags = data[0];

    //Battery Level
    int batvalue = 0;
    if (flags & 0x1) //  16 bit? otherwise 8 bit
        batvalue = (int)qFromLittleEndian<quint16>(data[1]);
    else
        batvalue = (int)data[1];

    qDebug() << "Current battery Level " << batvalue;

    emit this->sigBTLEBatteryLevelReady(batvalue);
}
void Device::hrmConfirmedDescriptorWrite(const QLowEnergyDescriptor &d, const QByteArray &value)
{
    if (d.isValid() && d == m_notificationDesc && value == QByteArray::fromHex("0000")) {
        //disabled notifications -> assume disconnect intent
        controller->disconnectFromDevice();
        delete m_HRMservice;
        m_HRMservice = 0;
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
    if (controller && controller->error() != QLowEnergyController::NoError)
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
