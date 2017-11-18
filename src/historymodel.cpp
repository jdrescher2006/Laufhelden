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

#include <QHash>
#include <QStandardPaths>
#include <QDir>
#include <QDebug>
#include "historymodel.h"
#include "trackloader.h"

TrackItem loadTrack(TrackItem track) {
    TrackItem data = track;
    qDebug()<<"Loading"<<data.filename;

    if(data.ready)
    {
        qDebug()<<"Already has data:"<<data.filename;        
        return data;
    }

    data.ready = true;
    TrackLoader loader;
    loader.setFilename(data.filename);
    data.name = loader.name();
    data.workout = loader.workout();
    data.time = loader.time();
    data.duration = loader.duration();
    data.distance = loader.distance();
    data.speed = loader.speed();
    data.stKey = loader.sTworkoutKey(); //Sports-Tracker workoutkey
    return data;
}

HistoryModel::HistoryModel(QObject *parent) :
    QAbstractListModel(parent)
{
    this->iWorkoutDuration = 0;
    this->rWorkoutDistance = 0.0;

    qDebug()<<"HistoryModel constructor";
    connect(&trackLoading, SIGNAL(resultReadyAt(int)), SLOT(newTrackData(int)));
    connect(&trackLoading, SIGNAL(finished()), SLOT(loadingFinished()));
    //readDirectory();
}

HistoryModel::~HistoryModel() {
    qDebug()<<"HistoryModel destructor";
    trackLoading.cancel();
    trackLoading.waitForFinished();
}

QHash<int, QByteArray> HistoryModel::roleNames() const {
    QHash<int, QByteArray> roles;
    roles[Qt::DisplayRole] = "name";
    roles[FilenameRole] = "filename";
    roles[WorkoutRole] = "workout";
    roles[ReadyRole] = "ready";
    roles[DateRole] = "date";
    roles[DurationRole] = "duration";
    roles[DistanceRole] = "distance";
    roles[SpeedRole] = "speed";

    return roles;
}

int HistoryModel::rowCount(const QModelIndex&) const
{
    return m_trackList.count();
}

qreal HistoryModel::rDistance()
{
    return this->rWorkoutDistance;
}

int HistoryModel::iDuration()
{
    return this->iWorkoutDuration;

}

QString HistoryModel::getSportsTrackerKey(const int index) const{
    if (index > 0 && index < m_trackList.length()){
        return m_trackList.at(index).stKey;
    }
    return "";
}

QVariant HistoryModel::data(const QModelIndex &index, int role) const {
    if(!index.isValid()) {
        return QVariant();
    }
    if(index.row() >= m_trackList.size()) {
        return QVariant();
    }
    if(!m_trackList.at(index.row()).ready) {
        // Data not loaded, trigger loading
    }
    if(role == Qt::DisplayRole) {
        if(!m_trackList.at(index.row()).ready) {
            // Data not loaded yet
            return QString("-");
        }
        return m_trackList.at(index.row()).name;
    }
    if(role == FilenameRole) {
        return m_trackList.at(index.row()).filename;
    }
    if(role == WorkoutRole) {
        return m_trackList.at(index.row()).workout;
    }
    if(role == DateRole) {
        if(!m_trackList.at(index.row()).ready) {
            // Data not loaded yet
            return m_trackList.at(index.row()).filename.left(10);
        }
        return m_trackList.at(index.row()).time.date().toString(Qt::SystemLocaleShortDate);
    }
    if(role == DurationRole) {
        if(!m_trackList.at(index.row()).ready) {
            // Data not loaded yet
            return QString("--h --m --s");
        }
        uint hours = m_trackList.at(index.row()).duration / (60*60);
        uint minutes = (m_trackList.at(index.row()).duration - hours*60*60) / 60;
        uint seconds = m_trackList.at(index.row()).duration - hours*60*60 - minutes*60;
        if(hours == 0) {
            if(minutes == 0) {
                return QString("%3s").arg(seconds);
            }
            return QString("%2m %3s")
                    .arg(minutes)
                    .arg(seconds, 2, 10, QLatin1Char('0'));
        }
        return QString("%1h %2m %3s")
                .arg(hours)
                .arg(minutes, 2, 10, QLatin1Char('0'))
                .arg(seconds, 2, 10, QLatin1Char('0'));
    }
    if(role == DistanceRole) {
        if(!m_trackList.at(index.row()).ready) {
            // Data not loaded yet
            return QString("-km");
        }
        return QString("%1km").arg(m_trackList.at(index.row()).distance / 1000, 0, 'f', 1);
    }
    if(role == SpeedRole) {
        if(!m_trackList.at(index.row()).ready) {
            // Data not loaded yet
            return QString("-km/h");
        }
        return QString("%1km/h").arg(m_trackList.at(index.row()).speed * 3.6, 0, 'f', 1);
    }
    return QVariant();
}

QVariant HistoryModel::headerData(int section, Qt::Orientation orientation, int role) const {
    qDebug()<<"headerData";
    if(role != Qt::DisplayRole) {
        return QVariant();
    }
    if(orientation == Qt::Horizontal) {
        return QString("Column %1").arg(section);
    } else {
        return QString("Row %1").arg(section);
    }
}

bool HistoryModel::removeTrack(int index) {
    QString dirName = QStandardPaths::writableLocation(QStandardPaths::HomeLocation) + "/Laufhelden";
    QDir dir = QDir(dirName);
    if(!dir.exists()) {
        qDebug()<<"Directory doesn't exist";
        return false;
    }
    QString filename = m_trackList.at(index).filename;
    bool success = dir.remove(filename);
    if(success) {
        beginRemoveRows(QModelIndex(), index, index);
        m_trackList.removeAt(index);
        endRemoveRows();
        qDebug()<<"Removed:"<<filename;
        return true;
    } else {
        qDebug()<<"Removing failed:"<<filename;
        return false;
    }
}

void HistoryModel::newTrackData(int num) {
    TrackItem data = trackLoading.resultAt(num);
    qDebug()<<"Finished loading"<<data.filename;
    m_trackList[data.id] = data;
    QModelIndex index = QAbstractItemModel::createIndex(data.id, 0);
    emit dataChanged(index, index);
}

void HistoryModel::loadingFinished()
{
    qDebug()<<"Data loading finished";

    this->iWorkoutDuration = 0;
    this->rWorkoutDistance = 0.0;

    //Get workout time
    for(int j=0;j<m_trackList.length();j++)
    {
        this->iWorkoutDuration = this->iWorkoutDuration + m_trackList.at(j).duration;
        this->rWorkoutDistance = this->rWorkoutDistance + m_trackList.at(j).distance;               
    }

    //Now we should sort the array after date!
    qSort(m_trackList.begin(), m_trackList.end(), HistoryModel::bCompareDates);

    emit this->sigLoadingFinished();
}

bool HistoryModel::bCompareDates(const TrackItem &ti1, const TrackItem &ti2)
{
    return ti1.time > ti2.time;
}

void HistoryModel::readDirectory() {
    if(trackLoading.isRunning()) {
        trackLoading.cancel();
        trackLoading.waitForFinished();
    }

    QString dirName = QStandardPaths::writableLocation(QStandardPaths::HomeLocation) + "/Laufhelden";
    QDir dir = QDir(dirName);
    if(!dir.exists()) {
        qDebug()<<"Directory doesn't exist, nothing to read";

        emit this->sigLoadingError();

        return;
    }
    dir.setFilter(QDir::Files);
    dir.setSorting(QDir::Name | QDir::Reversed);
    dir.setNameFilters(QStringList("*.gpx"));
    QStringList entries = dir.entryList();

    emit this->sigAmountGPXFiles(entries.size());

    for(int i=0;i<entries.size();i++)
    {
        //Check if we already have an item with the current filename
        bool bAlreadyHaveItem = false;

        qDebug()<<"CurrentFilename: "<<entries.at(i);

        for(int j=0;j<m_trackList.length();j++)
        {
            //qDebug()<<"Filename["<<j<<"]: "<<m_trackList.at(j).filename;

            if (m_trackList.at(j).filename == entries.at(i))
            {
                //qDebug()<<"Found by loop!";
                bAlreadyHaveItem = true;
                break;
            }
        }
        if (bAlreadyHaveItem)
            continue;

        TrackItem item;
        item.id = i;
        item.filename = entries.at(i);
        item.ready = false;
        item.name = item.filename;
        item.workout = "";
        item.time = QDateTime();
        item.duration = 0;
        item.distance = 0;
        item.speed = 0;

        m_trackList.append(item);
    }
    trackLoading.setFuture(QtConcurrent::mapped(m_trackList, loadTrack));
}
