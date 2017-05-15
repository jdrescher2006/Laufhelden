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

#include "bluetoothdata.h"
#include <qbluetoothsocket.h>

BluetoothData::BluetoothData (QObject *parent):QObject(parent)
{

}

BluetoothData::~BluetoothData ()
{
    if(this->_socket)
        delete this->_socket;
}

void BluetoothData::connect(QString address, int port)
{
    this->_port = port;
    qDebug("Trying to connect to: %s_%d", address.toUtf8().constData(), _port);

    if(this->_socket)
        delete this->_socket;

    this->_socket = new QBluetoothSocket(QBluetoothServiceInfo::RfcommProtocol);

    QObject::connect(this->_socket, SIGNAL(connected()), this, SLOT(connected()));
    QObject::connect(this->_socket, SIGNAL(disconnected()), this, SLOT(disconnected()));
    QObject::connect(this->_socket, SIGNAL(error(QBluetoothSocket::SocketError)), this, SLOT(error(QBluetoothSocket::SocketError)));
    QObject::connect(this->_socket, SIGNAL(readyRead()), this, SLOT(readData()));

    qDebug("Connecting...");
    this->_socket->connectToService(QBluetoothAddress(address), this->_port);
}

void BluetoothData::connected()
{
    qDebug() << "Connected";

    emit this->sigConnected();
}
void BluetoothData::disconnected()
{
    qDebug() << "Disconnected!";

    emit this->sigDisconnected();
}
void BluetoothData::error(QBluetoothSocket::SocketError errorCode)
{
    qDebug() << "Error: " << this->_socket->errorString();
    qDebug() << "Errorcode: " << errorCode;

    emit this->sigError(this->_socket->errorString());
}


void BluetoothData::disconnect()
{
    qDebug("Disconnecting...");

    if(!this->_socket)
        return;

    if(this->_socket->isOpen())
        this->_socket->close();

    delete this->_socket;
    this->_socket = 0;

    qDebug("Disconnected.");
}

void BluetoothData::readData()
{
    qDebug("Entering readData...");

    QByteArray data = _socket->readAll();

    QString s_data = data.trimmed();

    //s_data = s_data.replace("\r", " ");
    //s_data = s_data.replace("\n", " ");

    //qDebug() << "Data size:" << data.size();
    //qDebug() << "Data Hex[" + QString::number(_port) + "]:" << data.toHex();
    //qDebug() << "Data[" + QString::number(_port) + "]:" << data;

    //qDebug() << "Text: " << s_data;

    emit this->sigReadDataReady(data.toHex());
}

void BluetoothData::sendHex(QString sString)
{
    //qDebug() << "sString: " << sString;

    QByteArray data = sString.toUtf8();

    //qDebug() << "data1: " << data.toHex();

    data.append("\r");

    //qDebug() << "data2: " << data.toHex();

    this->write(data);
}

qint64 BluetoothData::write(QByteArray data)
{
    qDebug() << "Writing:" << data.toHex();


    qint64 ret = this->_socket->write(data);


    //qint64 ret = this->_socket->write("ATZ\r");
    //ret = this->_socket->write("AT RV\r");
    //qint64 ret = this->_socket->write("AT L0\r");

    qDebug() << "Write returned:" << ret;



    return ret;
}
