#include <main.h>

int main(int argc, char *argv[])
{
    QCoreApplication app(argc, argv);

    //should set same as UI for qsettings, it doesn't work though. have to set path manually below
    QCoreApplication::setOrganizationName("FakeCompany");
    QCoreApplication::setOrganizationDomain("appcheck.net");
    QCoreApplication::setApplicationName("OPPtimizer");

    QString strBootReason = "";
    MeeGo::QmSystemState MySystemState;
    int BootReason = MySystemState.getBootReason();
    if (BootReason == MeeGo::QmSystemState::BootReason_Wdg32kTimeout) strBootReason = "32k watchdog timeout";
    if (BootReason == MeeGo::QmSystemState::BootReason_SecViolation) strBootReason = "Security violation";
    if (BootReason == MeeGo::QmSystemState::BootReason_SwdgTimeout) strBootReason = "Security watchdog timeout";
    if (BootReason == MeeGo::QmSystemState::BootReason_Unknown) strBootReason = "Unknown BootReason";
    if (strBootReason != ""){
        qDebug() << "bad boot reason - overclock aborted: " << strBootReason;
        return 0;
    }
    //don't abort for this one yet, it can be normal.
    if (BootReason == MeeGo::QmSystemState::BootReason_SWReset) {
        strBootReason = "SW reset issued by the system.";
        qDebug() << "boot reason suspicious but not fatal: " << strBootReason;
    }

    //run loader to enable modules
    if (!QFileInfo("/proc/opptimizer").exists()){
        if(QProcess::execute("/opt/opptimizer/bin/oppldr")){
            qDebug() << "loader failed";
            return -1;
        }
        else
            qDebug() << "loader started";
    }else{
        qDebug() << "kernel modules already loaded";
    }

    //load qsettings
    QSettings objQsettings("/home/user/.config/FakeCompany/OPPtimizer.conf",
                           QSettings::NativeFormat,&app);

    qDebug() << "read " +  QString::number(objQsettings.allKeys().count()) + " keys";

    int requestedProfile = objQsettings.value("/settings/OcOnStartup/profile",-1).toInt();

    if (requestedProfile == -1){
        qDebug() << "OC on boot is disabled or problem with QSettings";
        return 0;
    }

    QString strReqestedProfile =  QString::number(requestedProfile);

    int requestedFrequency = objQsettings.value("/settings/" + strReqestedProfile + "/CPUFreq/value",-1).toInt();
    int requestedVoltage = objQsettings.value("/settings/" + strReqestedProfile + "/CPUVolts/value",-1).toInt();
    bool reqCustomVoltage = objQsettings.value("/settings/" + strReqestedProfile + "/CustomVolts/enabled",true).toBool();
    bool reqVDD1SmartReflexStatus = objQsettings.value("/settings/" + strReqestedProfile + "/SmartReflex1/enabled",true).toBool();
    bool reqVDD2SmartReflexStatus = objQsettings.value("/settings/" + strReqestedProfile + "/SmartReflex2/enabled",true).toBool();

    qDebug() << "going to set FREQ/VOLTS/CustomVolts/SR1/SR2: " << requestedFrequency << " " << requestedVoltage << " " << reqCustomVoltage << " " << reqVDD1SmartReflexStatus << reqVDD2SmartReflexStatus;

    //load database
    QDeclarativeEngine engine;
    engine.setOfflineStoragePath("/opt/opptimizer/"); //actually useless here

    QSqlDatabase db;
    db = QSqlDatabase::addDatabase("QSQLITE");
    if (!db.isValid()){
        qDebug() << "QSQLITE database driver failed to load -- aborting";
        qDebug() << db.lastError();
        return -1;
    }

    //QML sets the database name to the md5 hash of what we told it to...
    db.setDatabaseName("/opt/opptimizer/Databases/210b4f1841d3275bfa1bdb5b8eef09c8.sqlite");
    db.open();
    if (!db.isOpen()){
        qDebug() << "OPPtimizer database failed to load -- aborting";
        qDebug() << db.lastError();
        return -1;
    }

    QSqlQuery query;
    bool queryValid;
    //voltage in the db and settings object both are equal to the default if custom voltage was disabled
    //if there is a frequency >= request that is fully tested at this voltage we are okay to proceed
    query.prepare("SELECT SUM(IterationsPassed) FROM History WHERE Frequency >=? AND Voltage=?;");
    query.bindValue(0, requestedFrequency);
    query.bindValue(1, requestedVoltage);
    queryValid = query.exec();
    if (!queryValid){
        qDebug() << "database select 1 failed -- aborting";
        qDebug() << query.lastError();
        return -1;
    }
    QVariant IterationsPassed;
    while (query.next()) {
        IterationsPassed = query.value(0);
        qDebug() << IterationsPassed.toInt();
    }

    if (IterationsPassed.toInt() < 15000){
        qDebug() << "Insufficient testing at this voltage and selected or higher frequencies";
        return 0;
    }

    //do one more query to check if any crashes have occured at a frequency <= request and same voltage
    query.clear();
    query.prepare("SELECT * FROM History WHERE Frequency <=? AND Voltage=? AND SuspectedCrashes > 0;");
    query.bindValue(0, requestedFrequency);
    query.bindValue(1, requestedVoltage);
    queryValid = query.exec();
    if (!queryValid){
        qDebug() << "database select 2 failed -- aborting";
        qDebug() << query.lastError();
        return -1;
    }
    if (query.size() > 0){//any # rows returned = bad
        qDebug() << "aborting because this voltage is unstable at selected or a lower frequency";
        return 0;
    }

    qDebug() << "proceeding with overclock...";

    //mark this voltage/freq as bad for now so we can avoid any reboot loop caused by unstable overclock
    query.clear();
    query.prepare("UPDATE History SET SuspectedCrashes=1 WHERE Frequency=? AND Voltage=?;");
    query.bindValue(0, requestedFrequency);
    query.bindValue(1, requestedVoltage);
    queryValid = query.exec();
    if (!queryValid){
        qDebug() << "database update pre oc failed -- aborting";
        qDebug() << query.lastError();
        return -1;
    }
    //commit / close db to avoid corruption
    query.finish();
    db.commit();
    db.close();

    //do overclock
    QFile file0("/sys/power/sr_vdd1_autocomp");
    if (! file0.open(QIODevice::WriteOnly | QIODevice::Text)){
        qDebug() << "/sys/power/sr_vdd1_autocomp open failed!!";
        qDebug() << file0.errorString();
        return -1;
    }
    QString reqSRStr0 = reqVDD1SmartReflexStatus ? "1" : "0";
    QTextStream out0(&file0);
    out0 << reqSRStr0;
    file0.close();

    QFile file1("/sys/power/sr_vdd2_autocomp");
    if (! file1.open(QIODevice::WriteOnly | QIODevice::Text)){
        qDebug() << "/sys/power/sr_vdd2_autocomp open failed!!";
        qDebug() << file1.errorString();
        return -1;
    }
    QString reqSRStr1 = reqVDD2SmartReflexStatus ? "1" : "0";
    QTextStream out1(&file1);
    out1 << reqSRStr1;
    file1.close();

    QFile file2("/proc/opptimizer");
    if (! file2.open(QIODevice::WriteOnly | QIODevice::Text)){
        qDebug() << "OPP file open failed!!";
        qDebug() << file2.errorString();
        return -1;
    }
    unsigned long newFreq = requestedFrequency * 1000 * 1000;
    QString reqOCStr = QString::number(newFreq);
    if (reqCustomVoltage){
        reqOCStr += " " + QString::number(requestedVoltage);
    }
    QTextStream out2(&file2);
    out2 << reqOCStr;
    qDebug() << "sent string to /proc/opptimizer : " << reqOCStr;
    file2.close();

    //sleep for a few seconds
    qDebug() << "sleeping 15 sec";
    sleep(15);
    qDebug() << "awoken, going to mark this combo as ok again";

    //mark this voltage/freq as safe again
    db.open();
    if (!db.isOpen()){
        qDebug() << "OPPtimizer database failed to load after oc -- combo will be left marked unstable";
        qDebug() << db.lastError();
        return 0;
    }
    query.prepare("UPDATE History SET SuspectedCrashes = 0 WHERE Frequency =? AND Voltage=?;");
    query.bindValue(0, requestedFrequency);
    query.bindValue(1, requestedVoltage);
    queryValid = query.exec();
    if (!queryValid){
        qDebug() << "database update post oc failed -- combo will be left marked unstable";
        qDebug() << query.lastError();
        return 0;
    }
    //exit, don't restart
    return 0;

    return app.exec();
}
