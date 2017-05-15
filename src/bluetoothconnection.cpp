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

#include "bluetoothconnection.h"
#include <QtGui>

BluetoothConnection::BluetoothConnection(QObject *parent) : QObject(parent)
{
    this->discoveryAgent = new QBluetoothDeviceDiscoveryAgent(this);

    connect(this->discoveryAgent, SIGNAL(deviceDiscovered(QBluetoothDeviceInfo)),this, SLOT(vDeviceDiscovered(QBluetoothDeviceInfo)));
    connect(this->discoveryAgent, SIGNAL(finished()), this, SLOT(vDiscoveryFinished()));
    connect(this->discoveryAgent, SIGNAL(canceled()), this, SLOT(vDiscoveryFinished()));
}

BluetoothConnection::~BluetoothConnection()
{
    delete this->discoveryAgent;
}

void BluetoothConnection::vStartDeviceDiscovery()
{      
    qDebug() << "Scanning...";
    if (this->discoveryAgent->isActive())
        this->discoveryAgent->stop();

    //this->discoveryAgent->setUuidFilter(uuid);
    this->discoveryAgent->start();
}

void BluetoothConnection::vStopDeviceDiscovery()
{
    this->discoveryAgent->stop();
}

// In your local slot, read information about the found devices
void BluetoothConnection::vDeviceDiscovered(const QBluetoothDeviceInfo &device)
{
    qDebug() << "Found new device:" << device.name() << '(' << device.address().toString() << ')';

    emit deviceFound(device.name(), device.address().toString());

    //this->bluetoothSocket->connectToService(QBluetoothAddress(device.address()), 1);

    /*
    qDebug() << "Discovered service on" << serviceInfo.device().name() << serviceInfo.device().address().toString();
    qDebug() << "\tService name:" << serviceInfo.serviceName();
    qDebug() << "\tDescription:" << serviceInfo.attribute(QBluetoothServiceInfo::ServiceDescription).toString();
    qDebug() << "\tProvider:" << serviceInfo.attribute(QBluetoothServiceInfo::ServiceProvider).toString();
    qDebug() << "\tL2CAP protocol service multiplexer:" << serviceInfo.protocolServiceMultiplexer();
    qDebug() << "\tRFCOMM server channel:" << serviceInfo.serverChannel();
    */
}

void BluetoothConnection::vDiscoveryFinished()
{
    qDebug() << "Scanning finished";
}
