#ifndef LIGHT_H
#define LIGHT_H

#include <QLightSensor>
#include <QObject>


class Light : public QObject
{
    Q_OBJECT

    Q_PROPERTY(qreal brightness READ brightness NOTIFY brightnessChanged)

    private:
        qreal m_brightness;
        QSensor *m_sensor;

    public:
        explicit Light(QObject *parent = NULL);
        ~Light();

        qreal brightness(void) const { return m_brightness; }

    public slots:
        void refresh(void);
        void deactivate(void);

    signals:
        void brightnessChanged(void);
};

#endif // LIGHT_H
