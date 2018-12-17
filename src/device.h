/****************************************************************************
**
** Copyright (C) 2017 The Qt Company Ltd.
** Contact: https://www.qt.io/licensing/
**
** This file is part of the demonstration applications of the Qt Toolkit.
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

#ifndef DEVICE_H
#define DEVICE_H

#include <qbluetoothlocaldevice.h>
#include <QObject>
#include <QVariant>
#include <QList>
#include <QBluetoothServiceDiscoveryAgent>
#include <QBluetoothDeviceDiscoveryAgent>
#include <QLowEnergyController>
#include <QBluetoothServiceInfo>
#include <QBluetoothSocket>
#include <QTimer>
#include "deviceinfo.h"
#include "serviceinfo.h"

QT_FORWARD_DECLARE_CLASS (QBluetoothDeviceInfo)
QT_FORWARD_DECLARE_CLASS (QBluetoothServiceInfo)



class Device: public QObject
{
    Q_OBJECT
    Q_PROPERTY(QVariant devicesList READ getDevices NOTIFY devicesUpdated)
    Q_PROPERTY(QString update READ getUpdate WRITE setUpdate NOTIFY updateChanged)
    Q_PROPERTY(bool useRandomAddress READ isRandomAddress WRITE setRandomAddress NOTIFY randomAddressChanged)
    Q_PROPERTY(bool state READ state NOTIFY stateChanged)
    Q_PROPERTY(bool controllerError READ hasControllerError)
    Q_PROPERTY(int bluetoothType READ bluetoothType WRITE setBluetoothType NOTIFY bluetoothTypeChanged)



public:
    Device();
    ~Device();
    QVariant getDevices();
    QString getUpdate();
    bool state();
    bool hasControllerError() const;

    bool isRandomAddress() const;
    void setRandomAddress(bool newValue);
    int bluetoothType();
    enum bluetoothTypes {
        BLEPUBLIC = 0,
        BLERANDOM = 1,
        CLASSICBLUETOOTH = 2
    };
    Q_ENUM(bluetoothTypes)
    Q_INVOKABLE void sendHex(QString sString);


public slots:
    void startDeviceDiscovery();
    void stopDeviceDiscovery();
    void scanServices(const QString &address);
    void connectClassic(QString address,int port);
    void disconnectFromDevice();
    void setBluetoothType(int type);


private slots:
    // QBluetoothDeviceDiscoveryAgent related
    void addDevice(const QBluetoothDeviceInfo&);
    void deviceScanFinished();
    void deviceScanError(QBluetoothDeviceDiscoveryAgent::Error);

    // QLowEnergyController related
    void lowEnergyServiceDiscovered(const QBluetoothUuid &uuid);
    void deviceConnected();
    void errorReceived(QLowEnergyController::Error);
    void error(QBluetoothSocket::SocketError errorCode);

    void serviceScanDone();
    void deviceDisconnected();



    // QLowEnergyService related
    void hrmServiceStateChanged(QLowEnergyService::ServiceState s);
    void batServiceStateChanged(QLowEnergyService::ServiceState s);
    void subscribeToHRM();
    void updateValues(const QLowEnergyCharacteristic &c, const QByteArray &value);
    void updateBatteryData();

    //Classic Bluetooth
    void readData();

signals:
    void devicesUpdated();
    void servicesUpdated();
    void characteristicsUpdated();
    void updateChanged();
    void scanFinished();
    void stateChanged();
    void sigBTLEDataReady(int sData);
    void sigBTLEBatteryLevelReady(int sData);
    void sigBATDataReady(int sData);
    void sigHRMDataReady(int sData);
    void sigConnected();
    void sigConnecting();
    void sigDisconnected();
    void sigError(QString sError);
    void randomAddressChanged();
    void deviceFound(QString sName, QString sAddress);
    void bluetoothTypeChanged(int bluetoothType);
    void sigReadDataReady(QString sData);

private:
    void setUpdate(QString message);
    QBluetoothDeviceDiscoveryAgent *discoveryAgent;
    DeviceInfo currentDevice;
    QList<QObject*> devices;
    QString m_previousAddress;
    QString m_message;
    bool connected;
    QLowEnergyController *m_controller;
    QLowEnergyService *m_hrmService;
    QLowEnergyService *m_batService;
    QLowEnergyDescriptor m_notificationDesc;
    bool m_deviceScanState;
    bool randomAddress;
    bool m_heartRateFound;
    bool m_batteryStateFound;
    QTimer *m_batTimer;
    int m_bluetoothType;
    // This is for classic Bluetooth
    QBluetoothSocket *m_socket;
    int m_port;
    qint64 write(QByteArray data);
};

#endif // DEVICE_H
