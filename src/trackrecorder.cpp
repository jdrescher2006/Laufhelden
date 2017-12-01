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

#include <QStandardPaths>
#include <QDir>
#include <QSaveFile>
#include <QXmlStreamWriter>
#include <QDebug>
#include <qmath.h>
#include "trackrecorder.h"

TrackRecorder::TrackRecorder(QObject *parent) :
    QObject(parent)
{
    qDebug()<<"TrackRecorder constructor";
    m_distance = 0.0;
    m_speed = 0.0;
    m_pace = 0.0;
    m_speedaverage = 0.0;
    m_paceaverage = 0.0;
    m_heartrateaverage = 0.0;
    m_accuracy = -1;
    m_isEmpty = true;
    m_autoSavePosition = 0;
    iCurrentHeartRate = 0;
    m_heartrateadded = 0;
    sWorkoutType = "running";
    m_altitude = 0;  
    m_posSrc = NULL;
    m_pause = false;
    m_running = false;
    m_PauseDuration = 0;

    // Load autosaved track if left from previous session
    loadAutoSave();

    // Setup periodic autosave
    m_autoSaveTimer.setInterval(60000);
    connect(&m_autoSaveTimer, SIGNAL(timeout()), this, SLOT(autoSave()));
    m_autoSaveTimer.start();   

    m_posSrc = QGeoPositionInfoSource::createDefaultSource(0);

    if (m_posSrc)
    {
        qDebug()<<"GPS initialized!";

        m_posSrc->setUpdateInterval(1000);

        connect(m_posSrc, SIGNAL(positionUpdated(QGeoPositionInfo)),
                this, SLOT(positionUpdated(QGeoPositionInfo)));
        connect(m_posSrc, SIGNAL(error(QGeoPositionInfoSource::Error)),
                this, SLOT(positioningError(QGeoPositionInfoSource::Error)));
    }
    else
    {
        qDebug()<<"Failed initializing PositionInfoSource!";
    }
}

TrackRecorder::~TrackRecorder()
{
    qDebug()<<"TrackRecorder destructor";
    autoSave();
    delete m_posSrc;
}

void TrackRecorder::vStartGPS()
{    
    if (m_posSrc != NULL)
    {
        qDebug()<<"Starting GPS";
        m_posSrc->startUpdates();
    }
}

void TrackRecorder::vEndGPS()
{
    if (m_posSrc != NULL)
    {
        qDebug()<<"Stopping GPS";
        m_posSrc->stopUpdates();        
    }
}

void TrackRecorder::positionUpdated(const QGeoPositionInfo &newPos)
{
    if (newPos.hasAttribute(QGeoPositionInfo::HorizontalAccuracy))
    {
        m_accuracy = newPos.attribute(QGeoPositionInfo::HorizontalAccuracy);
    }
    else
    {
        m_accuracy = -1;
    }
    emit accuracyChanged();

    m_currentPosition = newPos.coordinate();
    emit currentPositionChanged();

    //If recorder is running and is paused
    if(this->m_running == true && this->m_pause == true)
    {
        m_PauseDuration = m_PauseDuration + 1; //add one second (update interval)
        emit pauseTimeChanged();
    }


    //Check if horizontal accuracy is enough
    if (newPos.hasAttribute(QGeoPositionInfo::HorizontalAccuracy) == false || (newPos.attribute(QGeoPositionInfo::HorizontalAccuracy) > 30.0))
    {
        return;
    }

    qDebug()<<"Groundspeed: " << QString::number(newPos.GroundSpeed);

    if(m_running)
    {
        m_points.append(newPos);
        m_heartrate.append(this->iCurrentHeartRate);
        m_pausearray.append(this->m_pause);

        if (iCurrentHeartRate != 9999 && iCurrentHeartRate != 0)
            m_heartrateadded = m_heartrateadded + iCurrentHeartRate;

        this->iCurrentHeartRate = 9999;

        emit pointsChanged();

        if(m_isEmpty)
        {
            m_isEmpty = false;
            m_minLat = m_maxLat = newPos.coordinate().latitude();
            m_minLon = m_maxLon = newPos.coordinate().longitude();
            emit isEmptyChanged();
        }

        if(newPos.coordinate().latitude() < m_minLat)
        {
            m_minLat = newPos.coordinate().latitude();
        } else if(newPos.coordinate().latitude() > m_maxLat)
        {
            m_maxLat = newPos.coordinate().latitude();
        }
        if(newPos.coordinate().longitude() < m_minLon)
        {
            m_minLon = newPos.coordinate().longitude();
        } else if(newPos.coordinate().longitude() > m_maxLon)
        {
            m_maxLon = newPos.coordinate().longitude();
        }

        emit newTrackPoint(newPos.coordinate(), m_points.size()-1);

        if(m_points.size() > 1 && this->m_pause == false)
        {
            // Next line triggers following compiler warning?
            // \usr\include\qt5\QtCore\qlist.h:452: warning: assuming signed overflow does not occur when assuming that (X - c) > X is always false [-Wstrict-overflow]


            //Calculate average heartrate
            if (m_heartrate.size() > 0)
            {
                m_heartrateaverage = m_heartrateadded / m_heartrate.size();
                emit heartrateaverageChanged();
            }

            //Calculate distance in meter [m]
            qreal rCurrentDistance = m_points.at(m_points.size()-2).coordinate().distanceTo(m_points.at(m_points.size()-1).coordinate());
            qDebug()<<"Distance :"<<rCurrentDistance;
            m_distance += rCurrentDistance;
            emit distanceChanged();

            //Fill distance array. Save the last few values to have a better speed/pace calculation.
            if (m_distancearray.length() == 7)
                m_distancearray.removeFirst();
            m_distancearray.append(rCurrentDistance);

            rCurrentDistance = 0.0;
            //Calculate distance over the last few gps points
            for(int i=0 ; i < m_distancearray.length(); i++)
            {
                rCurrentDistance += m_distancearray[i];
            }
            qDebug()<<"Added distance: "<<rCurrentDistance;
            qDebug()<<"Update interval:"<<updateInterval();

            //Calculate speed in [km/h]
            m_speed = (rCurrentDistance / 1000.0) / (((updateInterval() * m_distancearray.length()) / 1000) / 3600.0);
            qDebug()<<"Speed:"<<m_speed;
            emit speedChanged();

            //Calculate pace in [min/km]
            m_pace = (((updateInterval() * m_distancearray.length()) / 1000.0) / 60.0) / (rCurrentDistance / 1000.0);

            qDebug()<<"Pace:"<<m_pace;
            emit paceChanged();

            //Calculate workout time
            QDateTime first = m_points.at(0).timestamp();
            QDateTime last = m_points.at(m_points.size()-1).timestamp();
            qint64 iWorkoutTimeSec = first.secsTo(last);

            //Calculate average speed
            m_speedaverage = (m_distance / 1000.0) / (iWorkoutTimeSec / 3600.0);
            qDebug()<<"AVG speed:"<<m_speedaverage;
            emit speedaverageChanged();

            //Calculate average pace
            m_paceaverage = (iWorkoutTimeSec / 60.0) / (m_distance / 1000.0);
            qDebug()<<"AVG pace:"<<m_paceaverage;
            emit paceaverageChanged();

            //Get altitude
            m_altitude = newPos.coordinate().altitude();


            emit valuesChanged();
            emit timeChanged();            
        }        
    }
}

void TrackRecorder::positioningError(QGeoPositionInfoSource::Error error)
{
    qDebug()<<"Positioning error:"<<error;
}

/*
 Writes given GPXcontent to Laufhelden folder in the device. This is used by Sports-Tracker.com downloader
*/
bool TrackRecorder::writeStGpxToFile(QString gpxcontent, QString filename, QString desc, QString sTkey, QString activity){
    QString homeDir = QStandardPaths::writableLocation(QStandardPaths::HomeLocation);
    QString subDir = "Laufhelden";
    filename = filename + ".gpx";

    qDebug()<<"File:"<<homeDir<<"/"<<subDir<<"/"<<filename;

    QDir home = QDir(homeDir);
    if(!home.exists(subDir)){
        qDebug()<<"Directory does not exist, creating";
        if(home.mkdir(subDir)) {
            qDebug()<<"Directory created";
        }
        else{
            qDebug()<<"Directory creation failed, aborting";
            return false;
        }
    }

    QXmlStreamReader xml(gpxcontent);
    if(!xml.readNextStartElement()) {
        qDebug()<<"Downloaded content is not xml format?";
        return false;
    }

    //Read elements under metadata tag and only add elements which are missing
    bool nameFound = false;
    bool descFound = false;
    bool extensionsFound = false;
    bool stFound = false;
    //bool meerunFound = false;

    while(!xml.atEnd()){
        while(xml.readNextStartElement()){
            if(xml.name() == "metadata"){
                while(xml.readNextStartElement()){
                    if(xml.name() == "name"){
                        nameFound = true;
                    }
                    else if(xml.name() == "desc"){
                        descFound = true;
                    }
                    else if(xml.name() == "extensions"){
                        extensionsFound = true;
                        while(xml.readNextStartElement()){
                            if(xml.name() == "sportstracker"){
                                stFound = true;
                            }
                            /*else if (xml.name() == "meerun"){ //meerun tags are removed when exported to Sporst-tracker.
                                meerunFound = true;
                            }*/
                            else
                            {
                                xml.skipCurrentElement();
                            }
                        }
                    }
                    else{
                        xml.skipCurrentElement();
                    }
                }
                break;
            }
            xml.skipCurrentElement();
        }
    }

    QFile file;
    file.setFileName(homeDir + "/" + subDir + "/" + filename);
    if(!file.open(QIODevice::WriteOnly | QIODevice::Text)) {
        qDebug()<<"File opening failed, aborting";
        return false;
    }

    // Inject data depending what exist in GPX.

    QString injectElement = "";
    if (!nameFound){
        injectElement += "  <name>"+desc+"</name>\n"; //Add name, for now same as description
        qDebug() << " <name> injected "<<desc;
    }
    if (!descFound){
        injectElement += "    <desc>"+desc+"</desc>\n"; //Add description if not found
        qDebug() << " <desc> injected "<<desc;
    }

    //Store Sports-Tracker.com key so we detect which are downloaded from there
    if (stFound == false && extensionsFound == false){
        //If extensions is missing
        injectElement +=  "    <extensions>\n";
        injectElement +=  "        <sportstracker workoutkey=\""+sTkey+"\" activity=\""+activity+"\"></sportstracker>\n";
        injectElement +=  "    </extensions>\n";
        qDebug() << " <sportstracker workoutkey injected "<<sTkey;
    }
    else{
        qDebug() << "sports-tracker key found, extensions found and meerun found";
    }

    //Finally inject name, desc and extensions if they are still missing
    injectElement += "</metadata>";
    gpxcontent = gpxcontent.replace("</metadata>",injectElement);


    //Write QString to file using stream
    QTextStream stream(&file);
    stream << gpxcontent;
    file.flush();
    file.close();

    if(file.error()){
        qDebug()<<"Error in writing to a file";
        qDebug()<<file.errorString();
        return false;
    } else{
        qDebug()<<"GPX file successfully written";
        return true;
    }
}

void TrackRecorder::exportGpx(QString name, QString desc)
{
    qDebug()<<"Exporting track to gpx";
    if(m_points.size() < 1) {
        qDebug()<<"Nothing to save";
        return; // Nothing to save
    }
    QString homeDir = QStandardPaths::writableLocation(QStandardPaths::HomeLocation);
    QString subDir = "Laufhelden";
    QString filename;

    filename = sWorkoutType + "-" + m_points.at(0).timestamp().toLocalTime().toString() + "-" + QString("%1km").arg(m_distance / 1000, 0, 'f', 1) + ".gpx";

    qDebug()<<"File:"<<homeDir<<"/"<<subDir<<"/"<<filename;

    QDir home = QDir(homeDir);
    if(!home.exists(subDir))
    {
        qDebug()<<"Directory does not exist, creating";
        if(home.mkdir(subDir))
        {
            qDebug()<<"Directory created";
        }
        else
        {
            qDebug()<<"Directory creation failed, aborting";
            return;
        }
    }

    QSaveFile file;
    file.setFileName(homeDir + "/" + subDir + "/" + filename);
    if(!file.open(QIODevice::WriteOnly | QIODevice::Text)) {
        qDebug()<<"File opening failed, aborting";
        return;
    }

    QXmlStreamWriter xml;
    xml.setDevice(&file);
    xml.setAutoFormatting(true);    // Human readable output
    xml.writeStartDocument();
    xml.writeDefaultNamespace("http://www.topografix.com/GPX/1/1");
    xml.writeStartElement("gpx");
    xml.writeAttribute("xsi:schemaLocation", "http://www.topografix.com/GPX/1/1 http://www.topografix.com/GPX/1/1/gpx.xsd http://www.garmin.com/xmlschemas/GpxExtensions/v3 http://www.garmin.com/xmlschemas/GpxExtensionsv3.xsd http://www.garmin.com/xmlschemas/TrackPointExtension/v1 http://www.garmin.com/xmlschemas/TrackPointExtensionv1.xsd");
    xml.writeAttribute("version", "1.1");
    xml.writeAttribute("Creator", "Laufhelden");
    xml.writeAttribute("xmlns:xsi", "http://www.w3.org/2001/XMLSchema-instance");
    xml.writeAttribute("xmlns:gpxtpx", "http://www.garmin.com/xmlschemas/TrackPointExtension/v1");

    xml.writeStartElement("metadata");

        xml.writeTextElement("name", name);
        xml.writeTextElement("desc", desc);

        xml.writeStartElement("extensions");
            xml.writeStartElement("meerun");
                xml.writeAttribute("uid", "1c53fb3a34cd468a");
                xml.writeAttribute("activity", this->sWorkoutType);
                xml.writeAttribute("filtered", "false");
                xml.writeAttribute("interval", "1");
                xml.writeAttribute("elevationCorrected", "false");
                xml.writeAttribute("manualPause", "true");
                xml.writeAttribute("autoPause", "false");
                xml.writeAttribute("autoPauseSensitivity", "medium");
                xml.writeAttribute("gpsPause", "false");
                xml.writeAttribute("createLapOnPause", "false");
            xml.writeEndElement(); // meerun
        xml.writeEndElement(); // extensions

    xml.writeEndElement(); // metadata

    xml.writeStartElement("trk");

    for(int i=0 ; i < m_points.size(); i++)
    {
        qDebug()<<"i: "<<QString::number(i);

        //If we have the first point or the start of a pause, we have to start a new track segment
        if (i == 0 || (i > 0 && m_pausearray.at(i) == false && m_pausearray.at(i-1) == true))
        {
            xml.writeStartElement("trkseg");
        }

        //Check if the coordinates are invalid or if this is a pause point
        if(m_points.at(i).coordinate().type() == QGeoCoordinate::InvalidCoordinate || m_pausearray.at(i) == true)
        {
            // No position info or this is a pause point, skip this point
        }
        else
        {
            xml.writeStartElement("trkpt");
            xml.writeAttribute("lat", QString::number(m_points.at(i).coordinate().latitude(), 'g', 15));
            xml.writeAttribute("lon", QString::number(m_points.at(i).coordinate().longitude(), 'g', 15));

            xml.writeTextElement("time", m_points.at(i).timestamp().toUTC().toString(Qt::ISODate));
            if(m_points.at(i).coordinate().type() == QGeoCoordinate::Coordinate3D) {
                xml.writeTextElement("ele", QString::number(m_points.at(i).coordinate().altitude(), 'g', 15));
            }

            xml.writeStartElement("extensions");
            if(m_points.at(i).hasAttribute(QGeoPositionInfo::Direction)) {
                xml.writeTextElement("dir", QString::number(m_points.at(i).attribute(QGeoPositionInfo::Direction), 'g', 15));
            }
            if(m_points.at(i).hasAttribute(QGeoPositionInfo::GroundSpeed)) {
                xml.writeTextElement("g_spd", QString::number(m_points.at(i).attribute(QGeoPositionInfo::GroundSpeed), 'g', 15));
            }
            if(m_points.at(i).hasAttribute(QGeoPositionInfo::VerticalSpeed)) {
                xml.writeTextElement("v_spd", QString::number(m_points.at(i).attribute(QGeoPositionInfo::VerticalSpeed), 'g', 15));
            }
            if(m_points.at(i).hasAttribute(QGeoPositionInfo::MagneticVariation)) {
                xml.writeTextElement("m_var", QString::number(m_points.at(i).attribute(QGeoPositionInfo::MagneticVariation), 'g', 15));
            }
            if(m_points.at(i).hasAttribute(QGeoPositionInfo::HorizontalAccuracy)) {
                xml.writeTextElement("h_acc", QString::number(m_points.at(i).attribute(QGeoPositionInfo::HorizontalAccuracy), 'g', 15));
            }
            if(m_points.at(i).hasAttribute(QGeoPositionInfo::VerticalAccuracy)) {
                xml.writeTextElement("v_acc", QString::number(m_points.at(i).attribute(QGeoPositionInfo::VerticalAccuracy), 'g', 15));
            }

            if(m_heartrate.count() > 0 && m_heartrate.at(i) != 9999)
            {
                xml.writeStartElement("gpxtpx:TrackPointExtension");
                xml.writeTextElement("gpxtpx:hr", QString::number(m_heartrate.at(i), 'g', 15));
                xml.writeEndElement(); // gpxtpx:TrackPointExtension
            }

            xml.writeEndElement(); // extensions

            xml.writeEndElement(); // trkpt
        }

        //If we have the last point or the end of a pause, we need to end the current track segment
        if (i == (m_points.size() - 1) || (i < (m_points.size() - 1) && m_pausearray.at(i) == false && m_pausearray.at(i+1) == true))
        {
            xml.writeEndElement(); // trkseg
        }
    }   

    xml.writeEndElement(); // trk
    xml.writeEndElement(); // gpx
    xml.writeEndDocument();

    file.commit();
    file.flush();

    if(file.error())
    {
        qDebug()<<"Error in writing to a file";
        qDebug()<<file.errorString();
    } else
    {
        qDebug()<<"GPX file successfully written";
        QDir appDir = QDir(homeDir + "/" + subDir);
        appDir.remove("Autosave");
    }    
}

void TrackRecorder::clearTrack()
{
    //Clear all variables
    m_distance = 0.0;
    m_speed = 0.0;
    m_pace = 0.0;
    m_speedaverage = 0.0;
    m_paceaverage = 0.0;
    m_heartrateaverage = 0.0;
    m_isEmpty = true;
    m_autoSavePosition = 0;
    iCurrentHeartRate = 0;
    m_heartrateadded = 0;
    m_altitude = 0;
    m_pause = false;
    m_running = false;
    m_PauseDuration = 0;
    //Clear all arrays
    m_points.clear();
    m_heartrate.clear();
    m_pausearray.clear();


    QString homeDir = QStandardPaths::writableLocation(QStandardPaths::HomeLocation);
    QString subDir = "Laufhelden";
    QDir appDir = QDir(homeDir + "/" + subDir);
    appDir.remove("Autosave");

    emit distanceChanged();
    emit timeChanged();
    emit pauseTimeChanged();
    emit isEmptyChanged();
    emit pointsChanged();
}

qreal TrackRecorder::accuracy() const {
    return m_accuracy;
}

int TrackRecorder::points() const {
    return m_points.size();
}

qreal TrackRecorder::distance() const {
    return m_distance;
}

qreal TrackRecorder::speed() const {
    return m_speed;
}

qreal TrackRecorder::pace() const {
    return m_pace;
}

qreal TrackRecorder::speedaverage() const {
    return m_speedaverage;
}

qreal TrackRecorder::paceaverage() const {
    return m_paceaverage;
}

qreal TrackRecorder::heartrateaverage() const {
    return m_heartrateaverage;
}

double TrackRecorder::altitude() const
{
    return m_altitude;
}


bool TrackRecorder::running() const
{
    return m_running;
}

void TrackRecorder::setRunning(bool running)
{
    this->m_running = running;

    emit runningChanged();
}


bool TrackRecorder::pause() const
{
    return m_pause;
}

void TrackRecorder::setPause(bool pause)
{
    if(!m_posSrc)
    {
        qDebug()<<"Can't pause, position source not initialized!";
        return;
    }
    this->m_pause = pause;

    emit pauseChanged();
}

QString TrackRecorder::paceStr() const
{
    QString strPace = "";

    qreal rMinutes = qFloor(m_pace);
    qreal rSeconds = qCeil((m_pace * 60) - (rMinutes * 60));

    strPace = QString::number(rMinutes) + ":" + QString::number(rSeconds);

    return strPace;
}

QString TrackRecorder::paceaverageStr() const
{
    QString strPace = "";

    qreal rMinutes = qFloor(m_paceaverage);
    qreal rSeconds = qCeil((m_paceaverage * 60) - (rMinutes * 60));

    strPace = QString::number(rMinutes) + ":" + QString::number(rSeconds);

    return strPace;
}

QString TrackRecorder::startingDateTime() const
{
    if(m_points.size() < 2)
        return "";
    else
        return m_points.at(0).timestamp().toLocalTime().toString();
}

QString TrackRecorder::pauseTime() const
{
    uint hours, minutes, seconds;

    hours = this->m_PauseDuration / (60*60);
    minutes = (this->m_PauseDuration - hours*60*60) / 60;
    seconds = this->m_PauseDuration - hours*60*60 - minutes*60;

    QString timeStr = QString("%1h %2m %3s")
            .arg(hours, 2, 10, QLatin1Char('0'))
            .arg(minutes, 2, 10, QLatin1Char('0'))
            .arg(seconds, 2, 10, QLatin1Char('0'));

    return timeStr;
}

QString TrackRecorder::pebblePauseTime() const
{
    uint hours, minutes;

    hours = this->m_PauseDuration / (60*60);
    minutes = (this->m_PauseDuration - hours*60*60) / 60;

    QString timeStr = QString("%1:%2")
            .arg(hours, 2, 10, QLatin1Char('0'))
            .arg(minutes, 2, 10, QLatin1Char('0'));

    return timeStr;
}

QString TrackRecorder::time() const
{
    uint hours, minutes, seconds;

    if(m_points.size() < 2)
    {
        hours = 0;
        minutes = 0;
        seconds = 0;
    }
    else
    {
        QDateTime first = m_points.at(0).timestamp();
        QDateTime last = m_points.at(m_points.size()-1).timestamp();
        qint64 difference = first.secsTo(last);

        //Substract the pause time from the overall time
        difference = difference - this->m_PauseDuration;

        hours = difference / (60*60);
        minutes = (difference - hours*60*60) / 60;
        seconds = difference - hours*60*60 - minutes*60;
    }

    QString timeStr = QString("%1h %2m %3s")
            .arg(hours, 2, 10, QLatin1Char('0'))
            .arg(minutes, 2, 10, QLatin1Char('0'))
            .arg(seconds, 2, 10, QLatin1Char('0'));

    return timeStr;
}

QString TrackRecorder::pebbleTime() const
{
    uint hours, minutes;

    if(m_points.size() < 2)
    {
        hours = 0;
        minutes = 0;
    }
    else
    {
        QDateTime first = m_points.at(0).timestamp();
        QDateTime last = m_points.at(m_points.size()-1).timestamp();
        qint64 difference = first.secsTo(last);

        //Substract the pause time from the overall time
        difference = difference - this->m_PauseDuration;

        hours = difference / (60*60);
        minutes = (difference - hours*60*60) / 60;
    }

    QString timeStr = QString("%1:%2")
            .arg(hours, 2, 10, QLatin1Char('0'))
            .arg(minutes, 2, 10, QLatin1Char('0'));

    return timeStr;
}

bool TrackRecorder::isEmpty() const {
    return m_isEmpty;
}

QGeoCoordinate TrackRecorder::currentPosition() const {
    return m_currentPosition;
}

int TrackRecorder::updateInterval() const {
    return m_posSrc->updateInterval();
}

void TrackRecorder::setUpdateInterval(int updateInterval) {
    if(!m_posSrc) {
        qDebug()<<"Can't set update interval, position source not initialized!";
        return;
    }
    m_posSrc->setUpdateInterval(updateInterval);
    qDebug()<<"Setting update interval to"<<updateInterval<<"msec";
    emit updateIntervalChanged();
}

bool TrackRecorder::pausePointAt(int index)
{
    if(index < m_pausearray.length())
    {
        return m_pausearray.at(index);
    }
    else
    {
        return false;
    }
}

QGeoCoordinate TrackRecorder::trackPointAt(int index)
{
    if(index < m_points.length())
    {
        return m_points.at(index).coordinate();
    }
    else
    {
        return QGeoCoordinate();
    }
}

int TrackRecorder::fitZoomLevel(int width, int height) {
    if(m_points.size() < 2 || width < 1 || height < 1) {
        // One point track or zero size map
        return 20;
    }

    // Keep also current position in view
    qreal minLon = qMin(m_minLon, (qreal)m_currentPosition.longitude());
    qreal maxLon = qMax(m_maxLon, (qreal)m_currentPosition.longitude());
    qreal minLat = qMin(m_minLat, (qreal)m_currentPosition.latitude());
    qreal maxLat = qMax(m_maxLat, (qreal)m_currentPosition.latitude());

    qreal trackMinX = (minLon + 180) / 360;
    qreal trackMaxX = (maxLon + 180) / 360;
    qreal trackMinY = sqrt(1-qLn(minLat*M_PI/180 + 1/qCos(minLat*M_PI/180))/M_PI);
    qreal trackMaxY = sqrt(1-qLn(maxLat*M_PI/180 + 1/qCos(maxLat*M_PI/180))/M_PI);

    qreal coord, pixel;
    qreal trackAR = qAbs((trackMaxX - trackMinX) / (trackMaxY - trackMinY));
    qreal windowAR = (qreal)width/(qreal)height;
    if(trackAR > windowAR ) {
        // Width limits
        coord = qAbs(trackMaxX - trackMinX);
        pixel = width;
    } else {
        // height limits
        coord = qAbs(trackMaxY - trackMinY);
        pixel = height;
    }

    // log2(x) = ln(x)/ln(2)
    int z = qFloor(qLn(pixel/256.0 * 1.0/coord * qCos((m_minLat+m_maxLat)/2*M_PI/180))
                   / qLn(2)) + 1;
    return z;
}

QGeoCoordinate TrackRecorder::trackCenter() {
    // Keep also current position in view
    qreal minLon = qMin(m_minLon, (qreal)m_currentPosition.longitude());
    qreal maxLon = qMax(m_maxLon, (qreal)m_currentPosition.longitude());
    qreal minLat = qMin(m_minLat, (qreal)m_currentPosition.latitude());
    qreal maxLat = qMax(m_maxLat, (qreal)m_currentPosition.latitude());

    return QGeoCoordinate((minLat+maxLat)/2, (minLon+maxLon)/2);
}

void TrackRecorder::autoSave()
{
    QString homeDir = QStandardPaths::writableLocation(QStandardPaths::HomeLocation);
    QString subDir = "Laufhelden";
    QString filename = "Autosave";
    QDir home = QDir(homeDir);

    if(m_points.size() < 1) {
        // Nothing to save
        return;
    }

    qDebug()<<"Autosaving";

    if(!home.exists(subDir)) {
        qDebug()<<"Directory does not exist, creating";
        if(home.mkdir(subDir)) {
            qDebug()<<"Directory created";
        } else {
            qDebug()<<"Directory creation failed, aborting";
            return;
        }
    }
    QFile file;
    file.setFileName(homeDir + "/" + subDir + "/" + filename);
    if(!file.open(QIODevice::WriteOnly | QIODevice::Text | QIODevice::Append)) {
        qDebug()<<"File opening failed, aborting";
        return;
    }
    QTextStream stream(&file);
    stream.setRealNumberPrecision(15);

    while(m_autoSavePosition < m_points.size())
    {
        stream<<m_points.at(m_autoSavePosition).coordinate().latitude();
        stream<<" ";
        stream<<m_points.at(m_autoSavePosition).coordinate().longitude();
        stream<<" ";
        stream<<m_points.at(m_autoSavePosition).timestamp().toUTC().toString(Qt::ISODate);
        stream<<" ";
        if(m_points.at(m_autoSavePosition).coordinate().type() == QGeoCoordinate::Coordinate3D) {
            stream<<m_points.at(m_autoSavePosition).coordinate().altitude();
            stream<<" ";
        } else {
            stream<<"nan ";
        }
        stream<<m_points.at(m_autoSavePosition).attribute(QGeoPositionInfo::Direction);
        stream<<" ";
        stream<<m_points.at(m_autoSavePosition).attribute(QGeoPositionInfo::GroundSpeed);
        stream<<" ";
        stream<<m_points.at(m_autoSavePosition).attribute(QGeoPositionInfo::VerticalSpeed);
        stream<<" ";
        stream<<m_points.at(m_autoSavePosition).attribute(QGeoPositionInfo::MagneticVariation);
        stream<<" ";
        stream<<m_points.at(m_autoSavePosition).attribute(QGeoPositionInfo::HorizontalAccuracy);
        stream<<" ";
        stream<<m_points.at(m_autoSavePosition).attribute(QGeoPositionInfo::VerticalAccuracy);
        stream<<" ";
        stream<<m_heartrate.at(m_autoSavePosition);
        stream<<" ";
        stream<<m_pausearray.at(m_autoSavePosition);

        stream<<'\n';
        m_autoSavePosition++;
    }
    stream.flush();
    file.close();
}

void TrackRecorder::loadAutoSave()
{
    QString homeDir = QStandardPaths::writableLocation(QStandardPaths::HomeLocation);
    QString subDir = "Laufhelden";
    QString filename = "Autosave";
    QFile file;
    file.setFileName(homeDir + "/" + subDir + "/" + filename);
    if(!file.exists()) {
        qDebug()<<"No autosave found";
        return;
    }

    qDebug()<<"Loading autosave";

    if(!file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        qDebug()<<"File opening failed, aborting";
        return;
    }
    QTextStream stream(&file);

    int iPointIndex = 0;

    while(!stream.atEnd())
    {
        QGeoPositionInfo point;
        uint iHeartrate;
        bool bPause;
        qreal lat, lon, alt, temp;
        QString timeStr;
        stream>>lat>>lon>>timeStr>>alt;
        point.setCoordinate(QGeoCoordinate(lat, lon, alt));
        point.setTimestamp(QDateTime::fromString(timeStr,Qt::ISODate));
        stream>>temp;
        if(temp == temp) {  // If value is not nan
            point.setAttribute(QGeoPositionInfo::Direction, temp);
        }
        stream>>temp;
        if(temp == temp) {
            point.setAttribute(QGeoPositionInfo::GroundSpeed, temp);
        }
        stream>>temp;
        if(temp == temp) {
            point.setAttribute(QGeoPositionInfo::VerticalSpeed, temp);
        }
        stream>>temp;
        if(temp == temp) {
            point.setAttribute(QGeoPositionInfo::MagneticVariation, temp);
        }
        stream>>temp;
        if(temp == temp) {
            point.setAttribute(QGeoPositionInfo::HorizontalAccuracy, temp);
        }
        stream>>temp;
        if(temp == temp) {
            point.setAttribute(QGeoPositionInfo::VerticalAccuracy, temp);
        }

        stream>>temp;
        if(temp == temp)
        {
            iHeartrate = temp;
        }

        stream>>temp;
        if(temp == temp)
        {
            bPause = temp;
        }


        stream.readLine(); // Read rest of the line, if any
        m_points.append(point);
        m_heartrate.append(iHeartrate);
        m_pausearray.append(bPause);

        iPointIndex++;

        if(m_points.size() > 1)
        {
            if(point.coordinate().latitude() < m_minLat) {
                m_minLat = point.coordinate().latitude();
            } else if(point.coordinate().latitude() > m_maxLat) {
                m_maxLat = point.coordinate().latitude();
            }
            if(point.coordinate().longitude() < m_minLon) {
                m_minLon = point.coordinate().longitude();
            } else if(point.coordinate().longitude() > m_maxLon) {
                m_maxLon = point.coordinate().longitude();
            }
        }
        else
        {
            m_minLat = m_maxLat = point.coordinate().latitude();
            m_minLon = m_maxLon = point.coordinate().longitude();
        }
        emit newTrackPoint(point.coordinate(), iPointIndex);
    }
    m_autoSavePosition = m_points.size();
    file.close();

    qDebug()<<m_autoSavePosition<<"track points loaded";

    if(m_points.size() > 1)
    {
        for(int i=1;i<m_points.size();i++)
        {
            //Sum up pause duration
            if (m_pausearray.at(i) == true)
            {
                m_PauseDuration = m_PauseDuration + 1; //add one second (update interval)
            }

            m_distance += m_points.at(i-1).coordinate().distanceTo(m_points.at(i).coordinate());

            if (m_heartrate.at(i - 1) != 9999 && m_heartrate.at(i - 1) != 0)
                m_heartrateadded = m_heartrateadded + m_heartrate.at(i - 1);
        }
        emit distanceChanged();
        emit pointsChanged();
        emit timeChanged();
        emit pauseTimeChanged();

        this->m_pause = true;
        this->m_running = true;
    }

    if(!m_points.isEmpty())
    {
        this->m_isEmpty = false;
        emit isEmptyChanged();
    }
}

void TrackRecorder::vSetCurrentHeartRate(uint heartRate)
{
    this->iCurrentHeartRate = heartRate;

    return;
}

QString TrackRecorder::workoutType() const
{
    return this->sWorkoutType;
}
void TrackRecorder::setWorkoutType(QString workoutType)
{
    this->sWorkoutType = workoutType;
}
