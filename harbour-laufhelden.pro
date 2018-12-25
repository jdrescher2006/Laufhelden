# The name of your app.
# NOTICE: name defined in TARGET has a corresponding QML filename.
#         If name defined in TARGET is changed, following needs to be
#         done to match new name:
#         - corresponding QML filename must be changed
#         - desktop icon filename must be changed
#         - desktop filename must be changed
#         - icon definition filename in desktop file must be changed
TARGET = harbour-laufhelden

include (o2/src/src.pri)

# Define the preprocessor macro to get the application version in our application.
DEFINES += APP_VERSION=\"\\\"$${VERSION}\\\"\"

CONFIG += sailfishapp
QT += positioning location concurrent
QT += bluetooth sensors
QT += dbus

SOURCES += src/harbour-laufhelden.cpp \
    src/trackrecorder.cpp \
    src/historymodel.cpp \
    src/trackloader.cpp \
    src/settings.cpp \
    src/logwriter.cpp \
    src/plotwidget.cpp \
    src/light.cpp \
    src/pebblemanagercomm.cpp \
    src/pebblewatchcomm.cpp \
    src/timeformatter.cpp \
    src/device.cpp \
    src/deviceinfo.cpp \
    src/serviceinfo.cpp

OTHER_FILES += qml/harbour-laufhelden.qml \
    qml/cover/CoverPage.qml \
    rpm/harbour-laufhelden.spec \
    rpm/harbour-laufhelden.yaml \
    harbour-laufhelden.desktop \
    qml/pages/RecordPage.qml \
    qml/pages/SaveDialog.qml \
    translations/*.ts \
    qml/pages/DetailedViewPage.qml \
    qml/pages/AboutPage.qml \
    qml/pages/SettingsPage.qml

SAILFISHAPP_ICONS = 86x86 108x108 128x128 256x256

# to disable building translations every time, comment out the
# following CONFIG line
CONFIG += sailfishapp_i18n

TRANSLATIONS += translations/harbour-laufhelden-de.ts \
                translations/harbour-laufhelden-pl.ts \
                translations/harbour-laufhelden-sv.ts \
                translations/harbour-laufhelden-hu.ts \
                translations/harbour-laufhelden-fi_FI.ts \
                translations/harbour-laufhelden-nl.ts \
                translations/harbour-laufhelden-nl_BE.ts \
                translations/harbour-laufhelden-es.ts \
                translations/harbour-laufhelden-ru.ts \
                translations/harbour-laufhelden-fr.ts

HEADERS += \
    src/trackrecorder.h \
    src/historymodel.h \
    src/trackloader.h \
    src/settings.h \
    src/logwriter.h \
    src/plotwidget.h \
    src/light.h \
    src/pebblemanagercomm.h \
    src/pebblewatchcomm.h \
    src/timeformatter.h \
    src/device.h \
    src/deviceinfo.h \
    src/serviceinfo.h

DISTFILES += \
    qml/pages/MainPage.qml \
    qml/pages/BTConnectPage.qml \
    qml/tools/Messagebox.qml \
    qml/laufhelden.png \
    qml/pages/PreRecordPage.qml \
    qml/workouticons/biking.png \
    qml/workouticons/mountainBiking.png \
    qml/workouticons/running.png \
    qml/workouticons/walking.png \
    qml/tools/ScreenBlank.qml \
    rpm/harbour-laufhelden.changes \
    qml/pages/ThresholdSettingsPage.qml \
    qml/tools/MediaPlayerControl.qml \
    qml/img/calendar.png \
    qml/img/bat0.png \
    qml/tools/Thresholds.js \
    qml/tools/JSTools.js \
    qml/tools/SharedResources.js \
    qml/img/bat20.png \
    qml/img/bat50.png \
    qml/img/bat80.png \
    qml/img/bat100.png \
    qml/img/flame.png \
    qml/img/heart.png \
    qml/img/length.png \
    qml/img/mountains.png \
    qml/img/speed.png \
    qml/img/speedavg.png \
    qml/img/time.png \
    qml/img/cd_logo.jpg \
    qml/img/icon-lock-error.png \
    qml/img/icon-lock-info.png \
    qml/img/icon-lock-ok.png \
    qml/img/icon-lock-warning.png \    
    qml/pages/SettingsMenu.qml \
    qml/pages/DiagramViewPage.qml \
    qml/tools/RecordPageDisplay.js \
    qml/pages/MapSettingsPage.qml \
    qml/img/map_pause.png \
    qml/img/map_play.png \
    qml/img/map_resume.png \
    qml/img/map_stop.png \
    qml/workouticons/skiing.png \
    qml/tools/SportsTracker.js \
    qml/pages/SportsTrackerUploadPage.qml \
    qml/pages/SportsTrackerSettingsPage.qml \
    qml/pages/PebbleSettingsPage.qml \
    qml/tools/PebbleComm.qml \
    qml/pages/StravaActivityPage.qml \    
    qml/img/cover.png \
    qml/img/general.png \
    qml/img/map.png \
    qml/img/pebble.png \
    qml/img/sportstracker.png \
    qml/img/strava.png \
    qml/img/voicecoach.png

include(libs/qmlsortfilterproxymodel/SortFilterProxyModel.pri)
