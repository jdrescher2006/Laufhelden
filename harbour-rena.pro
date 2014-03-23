# The name of your app.
# NOTICE: name defined in TARGET has a corresponding QML filename.
#         If name defined in TARGET is changed, following needs to be
#         done to match new name:
#         - corresponding QML filename must be changed
#         - desktop icon filename must be changed
#         - desktop filename must be changed
#         - icon definition filename in desktop file must be changed
TARGET = harbour-rena

CONFIG += sailfishapp
QT += positioning location concurrent

SOURCES += src/harbour-rena.cpp \
    src/trackrecorder.cpp \
    src/historymodel.cpp \
    src/trackloader.cpp

OTHER_FILES += qml/harbour-rena.qml \
    qml/cover/CoverPage.qml \
    rpm/harbour-rena.spec \
    rpm/harbour-rena.yaml \
    harbour-rena.desktop \
    qml/pages/RecordPage.qml \
    qml/pages/SaveDialog.qml \
    qml/pages/HistoryPage.qml \
    qml/pages/DetailedViewPage.qml \
    qml/pages/AboutPage.qml \
    qml/pages/ConfirmClearDialog.qml

HEADERS += \
    src/trackrecorder.h \
    src/historymodel.h \
    src/trackloader.h

