/*
 * Copyright (C) 2017 Jens Drescher, Germany
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

#ifndef HISTORYMODEL_H
#define HISTORYMODEL_H

#include <QAbstractListModel>
#include <QList>
#include <QDateTime>
#include <QtConcurrent>

struct TrackItem {
    int id;
    QString filename;
    bool ready;
    QString name;
    QDateTime time;
    int duration;
    qreal distance;
    qreal speed;
};

class HistoryModel : public QAbstractListModel
{
    Q_OBJECT
public:
    enum HistoryRoles {
        FilenameRole = Qt::UserRole + 1,
        ReadyRole,
        DateRole,
        DurationRole,
        DistanceRole,
        SpeedRole
    };

    explicit HistoryModel(QObject *parent = 0);
    ~HistoryModel();
    QHash<int, QByteArray> roleNames() const;
    int rowCount(const QModelIndex&) const;
    QVariant data(const QModelIndex &index, int role) const;
    QVariant headerData(int section, Qt::Orientation orientation, int role) const;
    Q_INVOKABLE bool removeTrack(int index);

signals:

public slots:
    void newTrackData(int num);
    void loadingFinished();

private:
    void readDirectory();
    QList<TrackItem> m_trackList;
    QFutureWatcher<TrackItem> trackLoading;

};

#endif // HISTORYMODEL_H
