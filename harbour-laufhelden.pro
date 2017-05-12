# The name of your app.
# NOTICE: name defined in TARGET has a corresponding QML filename.
#         If name defined in TARGET is changed, following needs to be
#         done to match new name:
#         - corresponding QML filename must be changed
#         - desktop icon filename must be changed
#         - desktop filename must be changed
#         - icon definition filename in desktop file must be changed
TARGET = harbour-laufhelden

# Application version
VERSION = 0.0.1
VERSION_SUFFIX =

# Define the preprocessor macro to get the application version in our application.
DEFINES += APP_VERSION=\\\"$$VERSION\\\" APP_VERSION_SUFFIX=\\\"$$VERSION_SUFFIX\\\"

CONFIG += sailfishapp
QT += positioning location concurrent

SOURCES += src/harbour-laufhelden.cpp \
    src/trackrecorder.cpp \
    src/historymodel.cpp \
    src/trackloader.cpp \
    src/settings.cpp

OTHER_FILES += qml/harbour-laufhelden.qml \
    qml/cover/CoverPage.qml \
    rpm/harbour-laufhelden.spec \
    rpm/harbour-laufhelden.yaml \
    harbour-laufhelden.desktop \
    qml/pages/RecordPage.qml \
    qml/pages/SaveDialog.qml \
    qml/pages/HistoryPage.qml \
    qml/pages/DetailedViewPage.qml \
    qml/pages/AboutPage.qml \
    qml/pages/ConfirmClearDialog.qml \
    qml/pages/SettingsPage.qml

SAILFISHAPP_ICONS = 86x86 108x108 128x128 256x256

HEADERS += \
    src/trackrecorder.h \
    src/historymodel.h \
    src/trackloader.h \
    src/settings.h

DISTFILES += \
    qml/cd_logo.jpg \
    qml/pages/MainPage.qml

