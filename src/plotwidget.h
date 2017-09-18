#ifndef PLOTWIDGET_H
#define PLOTWIDGET_H

#include <QQuickPaintedItem>

class PlotWidget : public QQuickPaintedItem
{
    Q_OBJECT

    Q_PROPERTY(QColor plotColor READ plotColor WRITE setplotColor)
    Q_PROPERTY(QColor scaleColor READ scaleColor WRITE setscaleColor)
    Q_PROPERTY(unsigned scrollStep READ scrollStep WRITE setscrollStep)

private:
    QColor m_plotColor;
    QColor m_scaleColor;

    QList<qreal> m_values;

    qreal m_minValue;
    qreal m_maxValue;

    unsigned m_scrollStep;

    typedef QList<qreal> ValueList;

public:
    static const unsigned NUM_SCALE_LINES = 5; // number of lines in the background indicating the plot scale

    explicit PlotWidget(QQuickItem *parent = 0);

    void paint(QPainter *painter);

    void setplotColor(const QColor &color) { m_plotColor = color; }
    void setscaleColor(const QColor &color) { m_scaleColor = color; }
    void setscrollStep(unsigned step) { m_scrollStep = step; }

    const QColor& plotColor() { return m_plotColor; }
    const QColor& scaleColor() { return m_scaleColor; }
    unsigned scrollStep() { return m_scrollStep; }

signals:

public slots:
    void addValue(qreal v);
    void reset(void);

};

#endif // PLOTWIDGET_H
