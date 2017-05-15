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

#ifndef BLUETOOTHDATA
#define BLUETOOTHDATA

#include <QObject>
#include <QBluetoothSocket>
#include <QBluetoothAddress>

class BluetoothData : public QObject
{
    Q_OBJECT
public:
    explicit BluetoothData(QObject *parent = 0);
    ~BluetoothData();    
    Q_INVOKABLE void connect(QString address, int port);
    Q_INVOKABLE void sendHex(QString sString);
    Q_INVOKABLE void disconnect();
private slots:
    void readData();
    void connected();
    void disconnected();
    void error(QBluetoothSocket::SocketError errorCode);
private:
    QBluetoothSocket *_socket;
    int _port;
    qint64 write(QByteArray data);
signals:
    void sigReadDataReady(QString sData);
    void sigConnected();
    void sigDisconnected();
    void sigError(QString sError);
};


#endif // BLUETOOTHDATA
