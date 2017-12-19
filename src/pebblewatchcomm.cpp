#include <QDebug>
#include "pebblewatchcomm.h"

PebbleWatchComm::PebbleWatchComm(QObject *parent) : QObject(parent)
{
    this->dbusPebble = NULL;
}

PebbleWatchComm::~PebbleWatchComm()
{
    this->dbusPebble = NULL;
}

void PebbleWatchComm::setServicePath(QString sServicePath)
{
    this->dbusPebble = new QDBusInterface(SERVER_SERVICE, sServicePath, SERVER_INTERFACE, QDBusConnection::sessionBus(), this);
}

QString PebbleWatchComm::getAddress()
{
    if (this->dbusPebble == NULL)
        return "";

    QDBusReply<QString> reply = dbusPebble->call("Address");

    if (reply.isValid())
    {
        return reply.value();
    }
    else
    {
        qDebug()<<"DBus error: " << reply.error().message();
        return "";
    }
}

QString PebbleWatchComm::getName()
{
    if (this->dbusPebble == NULL)
        return "";

    QDBusReply<QString> reply = dbusPebble->call("Name");

    if (reply.isValid())
    {
        return reply.value();
    }
    else
    {
        qDebug()<<"DBus error: " << reply.error().message();
        return "";
    }
}

bool PebbleWatchComm::isConnected()
{
    if (this->dbusPebble == NULL)
        return false;

    QDBusReply<bool> reply = dbusPebble->call("IsConnected");

    if (reply.isValid())
    {
        return reply.value();
    }
    else
    {
        qDebug()<<"DBus error: " << reply.error().message();
        return false;
    }
}

