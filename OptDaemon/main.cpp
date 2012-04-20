#include <QtCore/QCoreApplication>
#include <QtDebug>
#include <QFile>
#include <QTextStream>
#include <QObject>
#include <QProcess>
#include <main.h>
#include <QDataStream>


static const char AC_MODULE_HASH[] = {
//    0xac,0x34,0xf7,0x5,0x79,0x1d,0x4f,0x6,0xfd,0xf0,0x5e,0xd,0x14,0x29,0xb3,0x7a,0x80,0xf6,0x3b,0xbf
#include "../qtc_packaging/debian_harmattan/symsmodhash.inc"
};

static const char AC_MODULE2_HASH[] = {
#include "../qtc_packaging/debian_harmattan/opptmodhash.inc"
  //  0x9c,0xd3,0xda,0xb0,0x90,0x2e,0x65,0xe4,0xfe,0xa9,0x41,0xba,0x7,0x6b,0xff,0x95,0xe,0x51,0xde,0xab
};

int whitelist_module(const char hash[SHA1_HASH_LENGTH])
{
    QFile file(AC_MODLIST_PATH);
    if (! file.open(QIODevice::WriteOnly | QIODevice::Truncate)){
        qDebug() << "modlist file open failed!!";
        qDebug() << file.errorString();
        return 0;
    }
    //QDataStream out(&file);
    //int ret = out.writeRawData(hash,SHA1_HASH_LENGTH);
    int ret = file.write(hash,SHA1_HASH_LENGTH);
    qDebug() << file.errorString();
    file.close();
    return ret;
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

    QByteArray hashlist;
    hashlist = file.readAll();

    QByteArray NewHash;
    NewHash = QByteArray::fromRawData(AC_MODULE_HASH,sizeof(AC_MODULE_HASH));

    //qDebug() << sizeof(AC_MODULE_HASH);
    //qDebug() << NewHash.toHex();

    if (!hashlist.contains(NewHash.toHex())){
        NeedWhitelisting1 = true;
        qDebug() << "hash1 not found in whitelist";
    }
    else
        qDebug() << "hash1 already whitelisted";

    QByteArray NewHash2;
    NewHash2  = QByteArray::fromRawData(AC_MODULE2_HASH,sizeof(AC_MODULE2_HASH));
    if (!hashlist.contains(NewHash2.toHex())){
        NeedWhitelisting2 = true;
        qDebug() << "hash2 not found in whitelist";
    }
    else
        qDebug() << "hash2 already whitelisted";

    //whitelist modules
    if (NeedWhitelisting1){
        int ret = whitelist_module(AC_MODULE_HASH);
        if (ret < 1){
             qDebug() << "hash1 insert failed";
             return app.exec();
        }
        else
            qDebug() << "wrote hash1: " << ret << "bytes";
    }
    if (NeedWhitelisting2){
        int ret = whitelist_module(AC_MODULE2_HASH);
        if (ret < 1){
             qDebug() << "hash2 insert failed";
             return app.exec();
        }
        else
            qDebug() << "wrote hash2: " << ret << "bytes";
    }

    QProcess p;
    QString strOutput;
    QString strError;
    p.start("/sbin/modprobe symsearch");
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
    p.start("/sbin/modprobe opptimizer_n9");
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
