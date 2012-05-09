contains(MEEGO_EDITION,harmattan) {
    target.path = /opt/opptimizer/bin
    INSTALLS += target
}

OTHER_FILES +=

SOURCES += \
    main.cpp

HEADERS += \
    main.h

MOBILITY += systeminfo
CONFIG += mobility
CONFIG += qmsystem2

QT += declarative
QT += sql
