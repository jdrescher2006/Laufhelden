/*
 * Copyright (C) 2017-2018 Jens Drescher, Germany
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

TrackItem loadTrack(TrackItem track)
{
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
    data.description = loader.description();
    data.stKey = loader.sTworkoutKey(); //Sports-Tracker workoutkey

    //Get file properties
    QString dirName = QStandardPaths::writableLocation(QStandardPaths::HomeLocation) + "/Laufhelden";
    QString fullFilename = dirName + "/" + data.filename;
    QFileInfo infoObject(fullFilename);
    data.fileSize = QString::number(infoObject.size());
    data.fileLastModified = infoObject.lastModified().toString(Qt::ISODate);

    return data;
}

HistoryModel::HistoryModel(QObject *parent) :
    QAbstractListModel(parent)
{
    this->iWorkoutDuration = 0;
    this->rWorkoutDistance = 0.0;
	this->bGPXFilesChanged = true;

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
    roles[DescriptionRole] = "description";

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
            return qreal(0);
        }
        //return QString("%1km").arg(m_trackList.at(index.row()).distance / 1000, 0, 'f', 1);
        return m_trackList.at(index.row()).distance;
    }
    if(role == SpeedRole) {
        if(!m_trackList.at(index.row()).ready) {
            // Data not loaded yet
            return qreal(0);
        }
        //return QString("%1km/h").arg(m_trackList.at(index.row()).speed * 3.6, 0, 'f', 1);
        return (m_trackList.at(index.row()).speed * 3.6);
    }
    if(role == DescriptionRole) {
        if(!m_trackList.at(index.row()).ready) {
            // Data not loaded yet
            return QString("-");
        }
        return m_trackList.at(index.row()).description;
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

void HistoryModel::editTrack(int index)
{
	QString dirName = QStandardPaths::writableLocation(QStandardPaths::HomeLocation) + "/Laufhelden";
    QDir dir = QDir(dirName);
    if(!dir.exists()) 
	{
        qDebug()<<"Directory doesn't exist";
        return;
	}
	QString filename = m_trackList.at(index).filename;

	
}

bool HistoryModel::removeTrack(int index)
{
    QString dirName = QStandardPaths::writableLocation(QStandardPaths::HomeLocation) + "/Laufhelden";
    QDir dir = QDir(dirName);
    if(!dir.exists()) 
	{
        qDebug()<<"Directory doesn't exist";
        return false;
    }
    QString filename = m_trackList.at(index).filename;
    bool success = dir.remove(filename);
    if(success)
    {
        beginRemoveRows(QModelIndex(), index, index);
        m_trackList.removeAt(index);
        endRemoveRows();
        qDebug()<<"Removed:"<<filename;

        this->bGPXFilesChanged = true;
        this->saveAccelerationFile();

        return true;
    } else
    {
        qDebug()<<"Removing failed:"<<filename;
        return false;
    }
}

bool HistoryModel::gpxFilesChanged() const
{
    return this->bGPXFilesChanged;
}
void HistoryModel::setGpxFilesChanged(bool gpxFilesChanged)
{
	this->bGPXFilesChanged = gpxFilesChanged;
}

void HistoryModel::newTrackData(int num)
{
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
	
    this->saveAccelerationFile();

    //Now we should sort the array after date!
    qSort(m_trackList.begin(), m_trackList.end(), HistoryModel::bCompareDates);

    emit this->sigLoadingFinished();
}

bool HistoryModel::bCompareDates(const TrackItem &ti1, const TrackItem &ti2)
{
    return ti1.time > ti2.time;
}

void HistoryModel::loadAccelerationFile()
{
	//Clear tracklist	
	if (m_trackList.length() >= 0)
		this->m_trackList.clear();

	QString dirName = QStandardPaths::writableLocation(QStandardPaths::HomeLocation) + "/Laufhelden";
    QString fullFilename = dirName + "/AccelerationHelper.dat";
    qDebug()<<"Reading helper file:"<<fullFilename;

	QFile fileObject(fullFilename);

	if(!fileObject.exists()) 
	{
        qDebug()<<"No acceleration file found!";
        return;
    }

	if(!fileObject.open(QIODevice::ReadOnly | QIODevice::Text)) 
	{
        qDebug()<<"Acceleration file opening failed, aborting";
        return;
    }

    QTextStream streamObject(&fileObject);
    streamObject.setCodec("UTF-8");
    TrackItem item;

	//Assume everything OK while reading the file. Should then be consistent with GPX files in directory.
	this->bGPXFilesChanged = false;	

	int iIndexCounter = 0;

	while(!streamObject.atEnd())
    {
		QString sLine = streamObject.readLine();
	
		//Check if we are at the start of a new track item.
		if (sLine.startsWith("1: "))
		{
            item.id = iIndexCounter;
		    item.filename = sLine.mid(3);
		    item.ready = false;
		    item.name = "";
		    item.workout = "";
		    item.time = QDateTime();
		    item.duration = 0;
		    item.distance = 0;
		    item.speed = 0;
		    item.description = "";
		    item.fileSize = "";
		    item.fileLastModified = "";
			item.stKey = "";

			iIndexCounter++;
		}
		else if (sLine.startsWith("2: "))
			item.name = sLine.mid(3);
		else if (sLine.startsWith("3: "))
			item.workout = sLine.mid(3);
		else if (sLine.startsWith("4: "))
            item.time = QDateTime::fromString(sLine.mid(3),Qt::ISODate);
		else if (sLine.startsWith("5: "))
            item.duration = sLine.mid(3).toInt();
		else if (sLine.startsWith("6: "))
            item.distance = sLine.mid(3).toDouble();
		else if (sLine.startsWith("7: "))
            item.speed = sLine.mid(3).toDouble();
		else if (sLine.startsWith("8: "))
			item.description = sLine.mid(3);
		else if (sLine.startsWith("9: "))
			item.fileSize = sLine.mid(3);
		else if (sLine.startsWith("10: "))
			item.fileLastModified = sLine.mid(4);
		else if (sLine.startsWith("11: "))
		{
			//Now, this is the last parameter for this track item.
			item.stKey = sLine.mid(4);


			//Get file properties
			QString dirName = QStandardPaths::writableLocation(QStandardPaths::HomeLocation) + "/Laufhelden";
			fullFilename = dirName + "/" + item.filename;
			QFileInfo infoObject(fullFilename);

			//Check if file exists
			if (infoObject.exists())
			{
				//OK, file exists. Now check if file is consistent			
                QString sFileSize = QString::number(infoObject.size());
				QString sLastModified = infoObject.lastModified().toString(Qt::ISODate);

                //qDebug()<<"item nr: "<<item.id;
                //qDebug()<<"sFileSize: "<<sFileSize;


				if (sFileSize == item.fileSize && sLastModified == item.fileLastModified)
					item.ready = true;
				else
				{
					item.ready = false;
                    this->bGPXFilesChanged = true;	//GPX file will be reloaded due to item.ready=false

                    qDebug()<<"File not consistent: "<<item.filename;
                    qDebug()<<"sFileSize/item.fileSize: "<<sFileSize<<"/"<<item.fileSize;
                    qDebug()<<"sLastModified/item.fileLastModified: "<<sLastModified<<"/"<<item.fileLastModified;
				}

				m_trackList.append(item);
			}
		}
	}	
}

void HistoryModel::saveAccelerationFile()
{
	//If there are no changes in the GPX files, don't do anything here
	if (this->bGPXFilesChanged == false)
		return;

    if (m_trackList.length() <= 0)
        return;

    QString dirName = QStandardPaths::writableLocation(QStandardPaths::HomeLocation) + "/Laufhelden";
    QString fullFilename = dirName + "/AccelerationHelper.dat";
    qDebug()<<"Writing helper file:"<<fullFilename;

    QFile fileObject(fullFilename);

    if (fileObject.open(QFile::WriteOnly | QFile::Text))
    {
        QTextStream streamObject(&fileObject);
        streamObject.setCodec("UTF-8");

        for(int i=0; i<m_trackList.length(); i++)
        {
            streamObject << "1: " << this->m_trackList.at(i).filename << '\n';
            streamObject << "2: " << this->m_trackList.at(i).name << '\n';
            streamObject << "3: " << this->m_trackList.at(i).workout << '\n';
            streamObject << "4: " << this->m_trackList.at(i).time.toString(Qt::ISODate) << '\n';
            streamObject << "5: " << this->m_trackList.at(i).duration << '\n';
            streamObject << "6: " << this->m_trackList.at(i).distance << '\n';
            streamObject << "7: " << this->m_trackList.at(i).speed << '\n';
            streamObject << "8: " << this->m_trackList.at(i).description << '\n';
            streamObject << "9: " << this->m_trackList.at(i).fileSize << '\n';
            streamObject << "10: " << this->m_trackList.at(i).fileLastModified << '\n';
            streamObject << "11: " << this->m_trackList.at(i).stKey << '\n';
            streamObject << '\n';
        }
    }
    else
    {
        qDebug() << "error opening helper file\n";
        return;
    }

    fileObject.flush();
    fileObject.close();
}

void HistoryModel::loadAllTracks()
{
	trackLoading.setFuture(QtConcurrent::mapped(m_trackList, loadTrack));    
}

void HistoryModel::readDirectory()
{
    if(trackLoading.isRunning())
    {
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

        //qDebug()<<"CurrentFilename: "<<entries.at(i);

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

		//There are more GPX files in the directory which need to be loaded.
		this->bGPXFilesChanged = true;

        TrackItem item;
        item.id = m_trackList.length();
        item.filename = entries.at(i);
        item.ready = false;
        item.name = item.filename;
        item.workout = "";
        item.time = QDateTime();
        item.duration = 0;
        item.distance = 0;
        item.speed = 0;
        item.description = "";
        item.fileSize = "";
        item.fileLastModified = "";
		item.stKey = "";

        m_trackList.append(item);
    }
}
