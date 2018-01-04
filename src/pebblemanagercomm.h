#ifndef PEBBLEMANAGERCOMM_H
#define PEBBLEMANAGERCOMM_H

#include <QtDBus/QtDBus>
#include <QObject>

#define SERVER_INTERFACE_MANAGER "org.rockwork.Manager"
#define SERVER_SERVICE "org.rockwork"
#define SERVER_PATH "/org/rockwork/Manager"

class PebbleManagerComm : public QObject
{
    Q_OBJECT

public:
    PebbleManagerComm(QObject * parent = NULL);
    ~PebbleManagerComm();

    Q_INVOKABLE QString	getRockpoolVersion();
    Q_INVOKABLE QList<QString> getListWatches();   

private:    
    QDBusInterface *dbusPebbleManager;    
};

#endif // PEBBLEMANAGERCOMM_H
