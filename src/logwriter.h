#ifndef LOGWRITER
#define LOGWRITER

#include <QGuiApplication>
#include <QQuickView>
#include <QtQml>
#include <QObject>

class LogWriter : public QObject
{
    Q_OBJECT
    public:
        explicit LogWriter(QObject *parent = 0);
        Q_INVOKABLE void vWriteData(const QString &msg);
        Q_INVOKABLE void vWriteStart(const QString &msg);
};

#endif // LOGWRITER

