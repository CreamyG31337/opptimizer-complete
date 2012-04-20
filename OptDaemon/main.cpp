#include <QtCore/QCoreApplication>
#include <QtDebug>
#include <QFile>
#include <QTextStream>
#include <QObject>
#include <QProcess>
#include <main.h>
#include <QDataStream>


static const char AC_MODULE_HASH[] = {
#include "../qtc_packaging/debian_harmattan/symsmodhash.inc"
};

static const char AC_MODULE2_HASH[] = {
#include "../qtc_packaging/debian_harmattan/opptmodhash.inc"
};

int whitelist_module(const char hash[SHA1_HASH_LENGTH])
{
    QFile file(AC_MODLIST_PATH);
    if (! file.open(QIODevice::WriteOnly | QIODevice::Append)){
        qDebug() << "modlist file open failed!!";
        qDebug() << file.errorString();
        return 0;
    }
    QDataStream out(&file);
    out.writeBytes(hash,SHA1_HASH_LENGTH);
    return 1;
}

int main(int argc, char *argv[])
{
    QCoreApplication app(argc, argv);

    //check if modules need whitelisting
    bool NeedWhitelisting1 = false;
    bool NeedWhitelisting2 = false;
    QFile file(AC_MODLIST_PATH);
    if (! file.open(QIODevice::ReadOnly)){
        qDebug() << "modlist file open failed!!";
        qDebug() << file.errorString();
        return app.exec();
    }
    else
        qDebug() << "modlist file opened successfully";

    //QDataStream in(&file);
    QByteArray hashlist;
    hashlist = file.readAll();
    //in >> hashlist;

    qDebug() << hashlist;

    QByteArray NewHash;
    NewHash.fromRawData(AC_MODULE_HASH,sizeof(AC_MODULE_HASH));

    qDebug() << NewHash;

    if (!hashlist.contains(NewHash)){
        NeedWhitelisting1 = true;
        qDebug() << "hash1 not found";
    }

    QByteArray NewHash2;
    NewHash2.fromRawData(AC_MODULE2_HASH,sizeof(AC_MODULE2_HASH));
    if (!hashlist.contains(NewHash2)){
        NeedWhitelisting2 = true;
        qDebug() << "hash2 not found";
    }

    //whitelist modules
    if (NeedWhitelisting1){
        int ret = whitelist_module(AC_MODULE_HASH);
        if (ret == 0)
             return app.exec();
    }
    if (NeedWhitelisting2){
        int ret = whitelist_module(AC_MODULE2_HASH);
        if (ret == 0)
             return app.exec();
    }

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
         return app.exec();
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
         return app.exec();
    //else
        //lastOPPtimizerStatus = strOutput;
    //handle error

    return app.exec();
}
