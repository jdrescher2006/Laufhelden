#include <QDebug>
#include "light.h"

Light::Light(QObject *parent) : QObject(parent)
{
    this->m_sensor = new QLightSensor(this);
    QObject::connect(this->m_sensor, SIGNAL(readingChanged()), this, SLOT(refresh()));
}

Light::~Light()
{
}

void Light::deactivate(void)
{
    Q_ASSERT(m_sensor);

    // stop the sensor if all parts are deactivated
    if(m_sensor->isActive()) {
        qDebug() << "Sensor stopped";
        m_sensor->stop();
    }
}

void Light::refresh(void)
{    
    Q_ASSERT(m_sensor);

    if(!this->m_sensor->isActive())
    {
        qDebug() << "Sensor started";
        m_sensor->setAlwaysOn(true);
        m_sensor->start();
    }

    QLightSensor *light = dynamic_cast<QLightSensor*>(this->m_sensor);
    QLightReading *reading = light->reading();

    m_brightness = reading->lux();

    emit brightnessChanged();   
}
