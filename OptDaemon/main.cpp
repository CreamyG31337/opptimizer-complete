#include <QtCore/QCoreApplication>
#include <QtDebug>
#include <QFile>
#include <QTextStream>
#include <QObject>
#include <QProcess>
#include <sys/utsname.h>


int main(int argc, char *argv[])
{
    QCoreApplication app(argc, argv);



    //struct utsname u_name;


    QProcess p;

    QString strOutput;
    QString strError;
    p.start("/sbin/insmod /lib/modules/2.6.32.48-dfl61-20115101/symsearch.ko");
    p.waitForFinished(-1);
    strOutput = p.readAllStandardOutput();
    strError = p.readAllStandardError();
    qDebug() << strOutput;
    qDebug() << strError;
    if (strError.length() > 1)
        app.exit(0);
        //lastOPPtimizerStatus = "ERROR";
    //else
        //lastOPPtimizerStatus = strOutput;
    //handle error
    p.start("/sbin/insmod /lib/modules/2.6.32.48-dfl61-20115101/opptimizer_n9.ko");
    p.waitForFinished(-1);
    strOutput = p.readAllStandardOutput();
    strError = p.readAllStandardError();
    qDebug() << strOutput;
    qDebug() << strError;
    if (strError.length() > 1)
        //lastOPPtimizerStatus = "ERROR";
        app.exit(0);
    //else
        //lastOPPtimizerStatus = strOutput;
    //handle error

    return app.exec();
}
