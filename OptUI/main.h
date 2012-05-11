#ifndef MAIN_H
#define MAIN_H

#include <QtGui/QApplication>
#include <QtDeclarative/QDeclarativeView>
#include <QtDeclarative/QDeclarativeEngine>
#include <QtDeclarative>
#include <MDeclarativeCache>
#include <QtCore/QSettings>
#include <QtDeclarative/QDeclarativeContext>
#include <QtCore/QCoreApplication>
#include <QtCore/QtGlobal>
#include <QtCore/QStringList>
#include <QtCore/QObject>
#include <QtCore/QAbstractListModel>
#include <QtCore/QScopedPointer>
#include <QProcess>
#include <QDebug>
#include <QSharedPointer>
#include <QtAlgorithms>
#include <QStack>
#include <QMap>
#include <QFile>
#include <QFileInfo>


class OpptimizerLog : public QObject
{
    Q_OBJECT

signals:
    void newLogInfo(const QVariant &LogText);
};

class RenderThread : public QThread
{
    Q_OBJECT
public:
    RenderThread(QObject *parent = 0);
    ~RenderThread();
    void render(double testLength);
public slots:
    void abortRender();
signals:
    void renderedImage(int timeWasted);
    void updateStatus(int val);
    void badImage();
protected:
    void run();
private:
    QMutex mutex;
    QWaitCondition condition;
    bool abort;
    double testLength;
};

class OpptimizerUtils : public QObject
{
    Q_OBJECT
public:
    OpptimizerUtils(QObject *parent = 0);
    Q_INVOKABLE QString getModuleVersion();
    Q_INVOKABLE QString getMaxVoltage();
    Q_INVOKABLE int getDefaultVoltage();
    Q_INVOKABLE QString getSmartReflexStatus();
    Q_INVOKABLE void setSmartReflexStatus(bool newStatus);
    Q_INVOKABLE QString getMaxFreq();
    Q_INVOKABLE void refreshStatus();
    Q_INVOKABLE QString returnRawSettings();
    Q_INVOKABLE QString applySettings(int reqFreq, int reqVolt, bool SREnable, bool changeVolt);
    Q_INVOKABLE void testSettings(int testLength);
    Q_INVOKABLE void stopBenchmark();
private:
    QString lastOPPtimizerStatus;
    QString lastSmartReflexStatus;
    RenderThread thread;
signals:
    void newLogInfo(const QVariant &LogText);
    void renderedImageOut(int timeWasted);
    void badImageOut();
    void testStatus(int val);
};

//annoying wrapper class for qsettings
class MySettings : public QObject
{
    Q_OBJECT
public:
    explicit MySettings();
    virtual ~MySettings();
    Q_INVOKABLE QVariant getValue(QString keyval,QVariant defaultval){
        return qsettInternal->value(keyval,defaultval);
    }
    Q_INVOKABLE void setValue(QString key,QVariant value){
        qsettInternal->setValue(key,value);
    }
    Q_INVOKABLE void beginGroup(QString prefix){
        qsettInternal->beginGroup(prefix);
    }
    Q_INVOKABLE void endGroup(){
        qsettInternal->endGroup();
    }
    Q_INVOKABLE bool contains(QString key){
        return qsettInternal->contains(key);
    }
    Q_INVOKABLE QStringList childGroups(){
        return qsettInternal->childGroups();
    }
    Q_INVOKABLE QString group(){
        return qsettInternal->group();
    }
    Q_INVOKABLE void remove(QString key){
        qsettInternal->remove(key);
    }
    Q_INVOKABLE QString fileName(){
        return qsettInternal->fileName();
    }
    Q_INVOKABLE void clear(){
        qsettInternal->clear();
    }
private:
    QSettings *qsettInternal;
};


#endif // MAIN_H
