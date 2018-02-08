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

struct TrackItem
{
    int id;
    QString filename;
    bool ready;
    QString name;
    QString workout;
    QDateTime time;
    int duration;
    qreal distance;
    qreal speed;
    QString stKey;
    QString description;
    QString fileSize;
    QString fileLastModified;
};

class HistoryModel : public QAbstractListModel
{
    Q_OBJECT

public:
    enum HistoryRoles {
        FilenameRole = Qt::UserRole + 1,
        ReadyRole,
        WorkoutRole,
        DateRole,
        DurationRole,
        DistanceRole,
        SpeedRole,
        DescriptionRole
    };

    explicit HistoryModel(QObject *parent = 0);
    ~HistoryModel();

	Q_PROPERTY(bool gpxFilesChanged READ gpxFilesChanged WRITE setGpxFilesChanged)

    QHash<int, QByteArray> roleNames() const;
    int rowCount(const QModelIndex&) const;
    QVariant data(const QModelIndex &index, int role) const;
    QVariant headerData(int section, Qt::Orientation orientation, int role) const;
    Q_INVOKABLE bool removeTrack(int index);
    Q_INVOKABLE void editTrack(int index);

    Q_INVOKABLE void readDirectory();
    Q_INVOKABLE void loadAllTracks();
	Q_INVOKABLE void saveAccelerationFile();
	Q_INVOKABLE void loadAccelerationFile();

    Q_INVOKABLE int iDuration();
    Q_INVOKABLE qreal rDistance();

    Q_INVOKABLE QString getSportsTrackerKey(const int index) const;


signals:
    void sigLoadingFinished();
    void sigLoadingError();
    void sigAmountGPXFiles(int iAmountGPXFiles);

public slots:
    void newTrackData(int num);
    void loadingFinished();

public:
	bool gpxFilesChanged() const;
    void setGpxFilesChanged(bool gpxFilesChanged);

private:    
    QList<TrackItem> m_trackList;
    QFutureWatcher<TrackItem> trackLoading;
    int iWorkoutDuration;	
    qreal rWorkoutDistance;
	bool bGPXFilesChanged;
    static bool bCompareDates(const TrackItem &ti1, const TrackItem &ti2);    
};

#endif // HISTORYMODEL_H
