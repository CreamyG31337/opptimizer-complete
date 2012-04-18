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
    qtc_packaging/debian_harmattan/changelog \
    s:\scratchbox-lance\opptimizer1\n9\opptimizer_n9.ko \
    s:\scratchbox-lance\opptimizer1\symsearch\n9\symsearch.ko

SUBDIRS += \
    OptUI \
    OptDaemon

contains(MEEGO_EDITION,harmattan) {
    target2.path = /etc/init/apps
    target2.files += qtc_packaging/debian_harmattan/opptimizer-daemon.conf
    INSTALLS += target2
}
