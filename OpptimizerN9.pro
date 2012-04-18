TEMPLATE = subdirs

OTHER_FILES += \
    qtc_packaging/debian_harmattan/rules \
    qtc_packaging/debian_harmattan/README \
    qtc_packaging/debian_harmattan/manifest.aegis \
    qtc_packaging/debian_harmattan/copyright \
    qtc_packaging/debian_harmattan/control \
    qtc_packaging/debian_harmattan/compat \
    qtc_packaging/debian_harmattan/OpptimizerN9.postinst \
    qtc_packaging/debian_harmattan/OpptimizerN9.prerm \
    qtc_packaging/debian_harmattan/OpptimizerN9.preinst \
    qtc_packaging/debian_harmattan/changelog

SUBDIRS += \
    OptUI \
    OptDaemon

contains(MEEGO_EDITION,harmattan) {
    target2.path = /etc/init/apps
    target2.files += qtc_packaging/debian_harmattan/opptimizer-daemon.conf
    INSTALLS += target2

    target3.path = /lib/modules/2.6.32.48-dfl61-20115101
    target3.files += qtc_packaging/debian_harmattan/symsearch.ko \
        qtc_packaging/debian_harmattan/opptimizer_n9.ko
    INSTALLS += target3
}
