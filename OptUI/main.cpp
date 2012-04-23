#include <QtGui/QApplication>
#include "qmlapplicationviewer.h"
#include "main.h"
#include <QtCore/qmath.h>

MySettings::MySettings():
    qsettInternal(new QSettings("/home/user/.config/FakeCompany/OPPtimizer.conf",QSettings::NativeFormat,this))
{
}
MySettings::~MySettings(){
}

QString OpptimizerUtils::applySettings(int reqFreq, int reqVolt, bool SREnable, bool changeVolt){
    unsigned long newFreq = reqFreq * 1000 * 1000;
    QString reqStr;
    reqStr = QString::number(newFreq);

    QFile file("/proc/opptimizer");

    if (! file.open(QIODevice::WriteOnly | QIODevice::Text)){
        qDebug() << "OPP file open failed!!";
        qDebug() << file.errorString();
        return file.errorString();
    }

    if (changeVolt){
        reqStr += " " + QString::number(reqVolt);
    }

    QTextStream out(&file);

    qDebug() << reqStr;
    out << reqStr;
    file.close();
    if (changeVolt)
        return "Voltage & Frequency Updated";
    else
        return "Frequency Updated";
}

int OpptimizerUtils::testSettings(int testLength)
{
    //this function is adapted from http://shootout.alioth.debian.org/u32/program.php?test=mandelbrot&lang=gcc&id=2
    /*
    Copyright © 2004-2012 Brent Fulgham

    All rights reserved.

    Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

        Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
        Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or
        other materials provided with the distribution.
        Neither the name of "The Computer Language Benchmarks Game" nor the name of "The Computer Language Shootout Benchmarks" nor the names of its contributors
        may be used to endorse or promote products derived from this software without specific prior written permission.

    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
    OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
    INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
    OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
    ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
    */

    QDateTime startTime = QDateTime::currentDateTime();

    int w, h, bit_num = 0;
    char byte_acc = 0;
    int i, iter = 50;
    double x, y, limit = 2.0;
    double Zr, Zi, Cr, Ci, Tr, Ti;
    FILE *output;
    output = fopen("/home/user/MyDocs/test.pbm", "w");

    w = h = testLength;

    fprintf(output,"P4\n%d %d\n",w,h);

    for(y=0;y<h;++y)
    {
        qDebug() << y;
        if ((int)y % 100 == 0) // try to avoid force close dialog by going back to UI every 100 iterations
            qApp->processEvents();
        for(x=0;x<w;++x){
            Zr = Zi = Tr = Ti = 0.0;
            Cr = (2.0*x/w - 1.5); Ci=(2.0*y/h - 1.0);
            for (i=0;i<iter && (Tr+Ti <= limit*limit);++i){
                Zi = 2.0*Zr*Zi + Ci;
                Zr = Tr - Ti + Cr;
                Tr = Zr * Zr;
                Ti = Zi * Zi;
            }
            byte_acc <<= 1;
            if(Tr+Ti <= limit*limit) byte_acc |= 0x01;
            ++bit_num;
            if(bit_num == 8){
                putc(byte_acc,output);
                byte_acc = 0;
                bit_num = 0;
            }
            else if(x == w-1){
                byte_acc <<= (8-w%8);
                putc(byte_acc,output);
                byte_acc = 0;
                bit_num = 0;
            }
        }
    }
    fclose(output);
    return QDateTime::currentDateTime().secsTo(startTime) * -1;
}

void OpptimizerUtils::refreshStatus(){
    QProcess p;
    QString strOutput;
    QString strError;
    p.start("cat /proc/opptimizer");
    p.waitForFinished(-1);
    strOutput = p.readAllStandardOutput();
    strError = p.readAllStandardError();
    qDebug() << strOutput;
    qDebug() << strError;
    if (strError.length() > 1){
        qDebug() << strError;
        if(strError.contains("No such file or directory")){
            //module not loaded, try starting it
            qDebug() << "trying to start module...";
            QProcess processModule;
            processModule.start("/opt/opptimizer/bin/oppldr");
            processModule.waitForFinished(-1);
            p.start("cat /proc/opptimizer");
            p.waitForFinished(-1);
            strOutput = p.readAllStandardOutput();
            strError = p.readAllStandardError();
            if (strError.length() > 1){
                lastOPPtimizerStatus = "ERROR";
                qDebug() << "failed to start module!";
            }
            else
                lastOPPtimizerStatus = strOutput;
        }
    }
    else
        lastOPPtimizerStatus = strOutput;

    QProcess p2;
    QString strOutput2;
    QString strError2;
    p2.start("cat /sys/power/sr_vdd1_autocomp");
    p2.waitForFinished(-1);
    strOutput2 = p2.readAllStandardOutput();
    strError2 = p2.readAllStandardError();
    qDebug() << strOutput2;
    qDebug() << strError2;
    if (strError2.length() > 1)
        lastSmartReflexStatus = "ERROR";
    else
        lastSmartReflexStatus = strOutput2;

    emit newLogInfo(lastOPPtimizerStatus);
}

QString OpptimizerUtils::returnRawSettings()
{
    if (lastOPPtimizerStatus.length() > 1)
        return lastOPPtimizerStatus;
    else
        return "UNKNOWN";
}

QString OpptimizerUtils::getModuleVersion(){
    if(lastOPPtimizerStatus == "ERROR")
        return "ERR";

    QRegExp rx("\\Wv(\\d+\\.\\d+)");
    int pos = rx.indexIn(lastOPPtimizerStatus);
    if (pos > -1) {
        return rx.cap(1);
    }
    else
        return "Unknown";
}

QString OpptimizerUtils::getMaxVoltage(){
    if(lastOPPtimizerStatus == "ERROR")
        return "ERR";

    QRegExp rx1("vdata->u_volt_dyn_nominal:\\s+(\\d+)");
    QRegExp rx2("vdata->u_volt_dyn_nominal:\\s+(\\d+)");

    int pos = rx.indexIn(lastOPPtimizerStatus);
    if (pos > -1) {
        return rx.cap(1);
    }
    else
        return "Unknown";
}

QString OpptimizerUtils::getDefaultVoltage(){
    if(lastOPPtimizerStatus == "ERROR")
        return "ERR";

    QRegExp rx("Default_vdata->u_volt_dyn_nominal:\\s+(\\d+)");
    int pos = rx.indexIn(lastOPPtimizerStatus);
    if (pos > -1) {
        return rx.cap(1);
    }
    else
        return "Unknown";
}

QString OpptimizerUtils::getSmartReflexStatus(){
    if(lastSmartReflexStatus == "ERROR")
        return "ERR";
    if (lastSmartReflexStatus.left(1) == "1")
        return "On";
    if (lastSmartReflexStatus.left(1) == "0")
        return "Off";
    return "Unknown";
}

void OpptimizerUtils::setSmartReflexStatus(bool newStatus){
    QString reqStr = newStatus ? "1" : "0";
    qDebug() << "setting sr to " + reqStr;
    QFile file("/sys/power/sr_vdd1_autocomp");
    if (! file.open(QIODevice::WriteOnly | QIODevice::Text)){
        qDebug() << "/sys/power/sr_vdd1_autocomp open failed!!";
        //qDebug() << file.errorString();
        //return file.errorString(); // this will never fail anyways. probably :)
    }
    QTextStream out(&file);
    out << reqStr;
    file.close();
}


QString OpptimizerUtils::getMaxFreq(){
    if(lastOPPtimizerStatus == "ERROR")
        return "ERR";

    QRegExp rx("opp rate:\\s+(\\d\\d\\d\\d)");
    int pos = rx.indexIn(lastOPPtimizerStatus);
    if (pos > -1) {
        return QString::number(rx.cap(1).toInt());
    }
    else
        return "Unknown";
}

Q_DECL_EXPORT int main(int argc, char *argv[]){
    QCoreApplication::setOrganizationName("FakeCompany");
    QCoreApplication::setOrganizationDomain("appcheck.net");
    QCoreApplication::setApplicationName("OPPtimizer");

    MySettings objSettings;
    OpptimizerUtils objOpptimizerUtils;
    OpptimizerLog objOpptimizerLog;

    QScopedPointer<QApplication> app(createApplication(argc, argv));
    QmlApplicationViewer viewer;
    viewer.rootContext()->setContextProperty("objQSettings",&objSettings);
    viewer.rootContext()->setContextProperty("objOpptimizerUtils",&objOpptimizerUtils);

    qmlRegisterType<OpptimizerLog>("net.appcheck.Opptimizer", 1, 0, "OpptimizerLog");

    viewer.rootContext()->setContextProperty("objOpptimizerLog",&objOpptimizerLog);

    QObject::connect(&objOpptimizerUtils, SIGNAL(newLogInfo(QVariant)),
           &objOpptimizerLog, SIGNAL(newLogInfo(QVariant)));

    viewer.setOrientation(QmlApplicationViewer::ScreenOrientationAuto);
    viewer.setMainQmlFile(QCoreApplication::applicationDirPath() +
                QLatin1String("/../qml/optui/main.qml"));
    viewer.showFullScreen();

    return app->exec();
}
