
contains(MEEGO_EDITION,harmattan) {
    target.path = /opt/OptDaemon/bin
    INSTALLS += target
}

OTHER_FILES +=

SOURCES += \
    main.cpp

HEADERS += \
    main.h
