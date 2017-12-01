#include <QDebug>
#include "pebblemanagercomm.h"

PebbleManagerComm::PebbleManagerComm(QObject *parent) : QObject(parent)
{
    //Initialize DBus interface
    this->dbusPebbleManager = new QDBusInterface(SERVER_SERVICE, SERVER_PATH, SERVER_INTERFACE, QDBusConnection::sessionBus(), this);
}

PebbleManagerComm::~PebbleManagerComm()
{

}

QList<QString> PebbleManagerComm::getListWatches()
{
    QList<QString> sPebbleList;

    QDBusReply<QList<QDBusObjectPath>> reply = dbusPebbleManager->call("ListWatches");

    if (reply.isValid())
    {
        QList<QDBusObjectPath> devices = reply.value();

        for (int i = 0; i < devices.count(); i++)
        {
            sPebbleList.append(devices.at(i).path());
        }

        //sPebbleList.append("Tester Gerät 2");
        //qDebug()<<"1 Pebble: " <<sPebbleList.at(0);
    }
    else
    {
        qDebug()<<"DBus error: " << reply.error().message();
    }

    return sPebbleList;
}

QString PebbleManagerComm::getRockpoolVersion()
{      
    QDBusReply<QString> reply = dbusPebbleManager->call("Version");

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
