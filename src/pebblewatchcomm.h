#ifndef PEBBLEWATCHCOMM_H
#define PEBBLEWATCHCOMM_H

#include <QtDBus/QtDBus>
#include <QObject>

#define SERVER_INTERFACE_PEBBLE "org.rockwork.Pebble"
#define SERVER_SERVICE "org.rockwork"

class PebbleWatchComm : public QObject
{
    Q_OBJECT

public:
    PebbleWatchComm(QObject * parent = NULL);
    ~PebbleWatchComm();

    Q_INVOKABLE void setServicePath(QString sServicePath);
    Q_INVOKABLE QString	getAddress();
    Q_INVOKABLE QString	getName();
    Q_INVOKABLE bool isConnected();

private:
    QDBusInterface *dbusPebble;
};

#endif // PEBBLEWATCHCOMM_H
