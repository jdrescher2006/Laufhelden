#ifndef TIMEFORMATTER_H
#define TIMEFORMATTER_H

#include <QString>

class TimeFormatter
{
public:
    static QString formatHMS(uint hours, uint minutes, uint seconds);
};

#endif // TIMEFORMATTER_H
