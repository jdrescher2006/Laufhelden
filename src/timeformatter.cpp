#include "timeformatter.h"

#include <QObject>

/**
 * @brief TimeFormatter::formatHMS
 * Returns with a formatted string displaying the given time separated with ':'-s.
 * The return format depends on the time interval length, if not necessary it will
 * not display the hours (below 1 hour interval) and minutes (under 1 minute interval)
 *
 * @param hours
 * @param minutes
 * @param seconds
 * @return
 */
QString TimeFormatter::formatHMS(uint hours, uint minutes, uint seconds)
{
    if(hours == 0) {
        if(minutes == 0) {
            return QObject::tr("%1s").arg(seconds);
        }
        return QObject::tr("%1m %2s")
                .arg(minutes)
                .arg(seconds, 2, 10, QLatin1Char('0'));
    }
    return QString("%1:%2:%3")
            .arg(hours)
            .arg(minutes, 2, 10, QLatin1Char('0'))
            .arg(seconds, 2, 10, QLatin1Char('0'));
}
