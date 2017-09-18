#include <QPainter>

#include "plotwidget.h"

PlotWidget::PlotWidget(QQuickItem *parent) :
    QQuickPaintedItem(parent), m_scrollStep(3)
{
}

void PlotWidget::paint(QPainter *painter)
{
    int minX = 0;

    QPen scalePen(m_scaleColor);
    scalePen.setWidth(1);

    QPen plotPen(m_plotColor);
    plotPen.setWidth(2);


    // draw NUM_SCALE_LINES lines for scale indication
    QFont font = painter->font();
    font.setPixelSize(font.pixelSize() * 0.7);
    font.setBold(true);
    painter->setFont(font);

    painter->setRenderHint(QPainter::Antialiasing, true);

    QFontMetrics fontMetrics(font);

    qreal step = (m_maxValue - m_minValue) / NUM_SCALE_LINES;

    for(unsigned i = 0; i < NUM_SCALE_LINES; i++) {
        qreal v = m_minValue + (i + 0.5) * step;

        int ypos = (1.0 - (i + 0.5) / NUM_SCALE_LINES) * this->height() - 1;

        QString text = QLocale::system().toString(v, 'g', 3);
        int startX = fontMetrics.width(text) + 5;

        if(startX > minX) {
            minX = startX;
        }

        painter->setPen(scalePen);
        painter->drawLine(startX, ypos, this->width(), ypos);

        painter->setPen(plotPen);
        painter->drawText(QRect(1, ypos, 0, 0), Qt::AlignVCenter | Qt::AlignLeft | Qt::TextDontClip, text);
    }

    // draw the plot

    // if there are no values, just return here
    if(m_values.isEmpty()) {
        return;
    }

    painter->setPen(plotPen);

    QPoint prevPoint, curPoint(this->width(), 0);

    bool firstPoint = true;
    ValueList::Iterator iter = m_values.end() - 1;

    while((iter != m_values.begin()) && (curPoint.x() > minX)) {
        qreal v = *iter;

        // normalized value between 0 and 1
        qreal vnorm = (v - m_minValue) / (m_maxValue - m_minValue);

        prevPoint = curPoint;

        curPoint.setX(curPoint.x() - m_scrollStep);
        curPoint.setY(this->height() * (1 - vnorm));

        if(!firstPoint) {
            painter->drawLine(prevPoint, curPoint);
        }

        firstPoint = false;

        iter--;
    }
}

void PlotWidget::addValue(qreal v)
{
    m_values.append(v);

    int valuesRequired = this->width() / m_scrollStep;

    if(m_values.size() > valuesRequired) {
        ValueList::Iterator delRangeEndIter = m_values.end() - valuesRequired;
        m_values.erase(m_values.begin(), delRangeEndIter);
    }

    // recalculate minimum and maximum value
    m_minValue =  1e27;
    m_maxValue = -1e27;

    for(const qreal &v: m_values) {
        if(v < m_minValue) {
            m_minValue = v;
        }

        if(v > m_maxValue) {
            m_maxValue = v;
        }
    }

    if(m_minValue == m_maxValue) {
        m_minValue -= 0.5;
        m_maxValue += 0.5;
    }
}

void PlotWidget::reset()
{
    m_values.clear();
}
