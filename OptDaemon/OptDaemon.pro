contains(MEEGO_EDITION,harmattan) {
    target.path = /opt/opptimizer/bin
    INSTALLS += target
}

OTHER_FILES +=

SOURCES += \
    main.cpp

HEADERS += \
    main.h

QT += declarative
QT += sql
