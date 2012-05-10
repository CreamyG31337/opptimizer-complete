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

OpptimizerUtils::OpptimizerUtils(QObject *parent){
    QObject::connect(&thread, SIGNAL(renderedImage(int)),
           this, SIGNAL(renderedImageOut(int)));
    QObject::connect(&thread, SIGNAL(updateStatus(int)),
           this, SIGNAL(testStatus(int)));
}

void OpptimizerUtils::testSettings(int testLength)
{
    thread.render(testLength);
}

void OpptimizerUtils::stopBenchmark()
{
    thread.abortRender();
}

void OpptimizerUtils::refreshStatus(){
    if (!QFileInfo("/proc/opptimizer").exists()){
        if(QProcess::execute("/opt/opptimizer/bin/oppldr")){
            lastOPPtimizerStatus = "FAILED TO EXECUTE LOADER";
            emit newLogInfo(lastOPPtimizerStatus);
            return;
        }
    }

    QFile file("/proc/opptimizer");
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text)){
        lastOPPtimizerStatus = "ERROR";
    }
    else
        lastOPPtimizerStatus = file.readAll();

    QFile file2("/sys/power/sr_vdd1_autocomp");
    if (!file2.open(QIODevice::ReadOnly | QIODevice::Text)){
        lastSmartReflexStatus = "ERROR";
    }
    else
        lastSmartReflexStatus = file2.readAll();

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

    QRegExp rx("\\Wv(\\d+(\\.\\d+)+)");
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

    QRegExp rx1("vdata->u_volt_calib:\\s+(\\d+)");
    QRegExp rx2("vdata->u_volt_dyn_nominal:\\s+(\\d+)");

    int pos1 = rx1.indexIn(lastOPPtimizerStatus);
    if (pos1 > -1) {
        QString uvCalibStr = rx1.cap(1);
        long long uvCalibInt = uvCalibStr.toLongLong();
        if (uvCalibInt != 0)
            return rx1.cap(1);
        int pos2 = rx2.indexIn(lastOPPtimizerStatus);
        if (pos2 > -1){
            return rx2.cap(1);
        }
    }
        return "Unknown";
}

int OpptimizerUtils::getDefaultVoltage(){
    if(lastOPPtimizerStatus == "ERROR"){
        return -1;
        qDebug() << "default voltage get failed 1";
    }

    QRegExp rx1("Default_vdata->u_volt_calib:\\s+(\\d+)");
    QRegExp rx2("Default_vdata->u_volt_dyn_nominal:\\s+(\\d+)");

    int pos1 = rx1.indexIn(lastOPPtimizerStatus);
    if (pos1 > -1) {
        QString uvCalibStr = rx1.cap(1);
        long long uvCalibInt = uvCalibStr.toLongLong();
        if (uvCalibInt != 0){
            qDebug() << "got default voltage from u_volt_calib: " + rx1.cap(1);
            return rx1.cap(1).toInt();
        }
        int pos2 = rx2.indexIn(lastOPPtimizerStatus);
        if (pos2 > -1){
            qDebug() << "got default voltage from u_volt_dyn_nominal: " + rx2.cap(1);
            return rx2.cap(1).toInt();
        }
    }
        return -2;
        qDebug() << "default voltage get failed 2";
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

    QRegExp rx("opp rate:\\s+(1?\\d\\d\\d)");
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
    viewer.engine()->setOfflineStoragePath("/opt/opptimizer");
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

RenderThread::RenderThread(QObject *parent)
 : QThread(parent)
{
    abort = false;
}

RenderThread::~RenderThread()
{
  //  mutex.lock();
    abort = true;
    //condition.wakeOne();
  //  mutex.unlock();

    wait();
}

void RenderThread::render(double testLength)
{
    QMutexLocker locker(&mutex);
    this->testLength = testLength;
    this->abort = false;

    if (!isRunning()) {
        start(NormalPriority);//low is too low to stress cpu
    }
}

void RenderThread::abortRender()
{
 //   mutex.lock();
    this->abort = true;
 //   mutex.unlock();
}

void RenderThread::run()
{
 //   mutex.lock();
    double testLength = this->testLength;
 //   mutex.unlock();

    //this function is adapted from http://shootout.alioth.debian.org/u32/program.php?test=mandelbrot&lang=gcc&id=2
    /*
    Copyright � 2004-2012 Brent Fulgham

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
    //output = fopen("/dev/null", "w");

    w = h = testLength;

    fprintf(output,"P4\n%d %d\n",w,h);

    for(y=0;y<h;++y)
    {
        if (abort)
            return;
        if ((int)y % 50 == 0){
            emit updateStatus((int)y);
            //qDebug() << y;
        }

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
    int timeWasted = QDateTime::currentDateTime().secsTo(startTime) * -1;
    emit renderedImage(timeWasted);

    //check file for corruption
    QFile file("/home/user/MyDocs/test.pbm");
    file.open(QIODevice::ReadOnly);
    QByteArray fileData = file.readAll();
    QByteArray hashData = QCryptographicHash::hash(fileData,QCryptographicHash::Md5);
    qDebug() << hashData.toHex();


 //   mutex.lock();
 //   mutex.unlock();
}

