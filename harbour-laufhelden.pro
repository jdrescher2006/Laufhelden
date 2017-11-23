# The name of your app.
# NOTICE: name defined in TARGET has a corresponding QML filename.
#         If name defined in TARGET is changed, following needs to be
#         done to match new name:
#         - corresponding QML filename must be changed
#         - desktop icon filename must be changed
#         - desktop filename must be changed
#         - icon definition filename in desktop file must be changed
TARGET = harbour-laufhelden

# Define the preprocessor macro to get the application version in our application.
DEFINES += APP_VERSION=\"\\\"$${VERSION}\\\"\"

CONFIG += sailfishapp
QT += positioning location concurrent
QT += bluetooth sensors

SOURCES += src/harbour-laufhelden.cpp \
    src/trackrecorder.cpp \
    src/historymodel.cpp \
    src/trackloader.cpp \
    src/settings.cpp \
    src/bluetoothconnection.cpp \
    src/bluetoothdata.cpp \
    src/logwriter.cpp \
    src/plotwidget.cpp \
    src/light.cpp

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
                translations/harbour-laufhelden-es.ts \
                translations/harbour-laufhelden-sv.ts \
                translations/harbour-laufhelden-hu.ts

HEADERS += \
    src/trackrecorder.h \
    src/historymodel.h \
    src/trackloader.h \
    src/settings.h \
    src/bluetoothconnection.h \
    src/bluetoothdata.h \
    src/logwriter.h \
    src/plotwidget.h \
    src/light.h

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
    qml/pages/catch-action.wav \
    rpm/harbour-laufhelden.changes \
    qml/pages/ThresholdSettingsPage.qml \
    qml/tools/MediaPlayerControl.qml \
    qml/audio/hlvb.wav \
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
    qml/audio/hr_toohigh_en_male.wav \
    qml/audio/hr_normal_en_male.wav \
    qml/audio/hr_toolow_en_male.wav \
    qml/audio/pace_toohigh_en_male.wav \
    qml/audio/pace_toolow_en_male.wav \
    qml/audio/pace_normal_en_male.wav \
    qml/audio/hr_normal_de_male.wav \
    qml/audio/hr_toohigh_de_male.wav \
    qml/audio/hr_toolow_de_male.wav \
    qml/audio/pace_normal_de_male.wav \
    qml/audio/pace_toohigh_de_male.wav \
    qml/audio/pace_toolow_de_male.wav \
    qml/pages/SettingsMenu.qml \
    qml/pages/DiagramViewPage.qml \
    qml/tools/RecordPageDisplay.js \
    qml/pages/MapSettingsPage.qml

