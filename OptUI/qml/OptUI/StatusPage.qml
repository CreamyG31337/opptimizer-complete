// import QtQuick 1.0 // to target S60 5th Edition or Maemo 5
import QtQuick 1.1
import com.nokia.meego 1.0
import com.nokia.extras 1.0
import net.appcheck.Opptimizer 1.0

Page {
    id: statusPage
    anchors.margins: UiConstants.DefaultMargin
    BusyIndicator{
        id: myBusyInd
        platformStyle: BusyIndicatorStyle { size: "large" }
        anchors.centerIn: parent
        visible: false
        running: false
        z: 50
    }

    function refresh(){
        myBusyInd.running = true;
        myBusyInd.visible = true;
        objOpptimizerUtils.refreshStatus();
        lblModuleVal.text = objOpptimizerUtils.getModuleVersion();
        lblVoltVal.text = objOpptimizerUtils.getMaxVoltage();
        lblSR1Val.text = objOpptimizerUtils.getSmartReflexVDD1Status();
        lblSR2Val.text = objOpptimizerUtils.getSmartReflexVDD2Status();
        lblFreqVal.text = objOpptimizerUtils.getMaxFreq();
        myBusyInd.running = false;
        myBusyInd.visible = false;
    }

    Timer {
        id: blockEvents
        interval: 200; running: true; repeat: false
    }

    Flickable{
        id: flickable
        anchors.fill: parent
        contentHeight: 700

        Label{
            id: lblFreqText
            anchors{
                top: parent.top
                left: parent.left
                topMargin: 20
            }
            text: "Max. frequency (MHz): "
        }

        Label{
            id: lblFreqVal
            anchors{
                top: parent.top
                right: parent.right
                topMargin: 20
            }
            text: "Unknown"
            horizontalAlignment: Text.AlignRight
        }

        Label{
            id: lblVoltText
            anchors{
                left: parent.left
                top: lblFreqText.bottom
            }
            text: "Max. voltage (μV): "
        }

        Label{
            id: lblVoltVal
            anchors{
                top: lblFreqText.bottom
                right: parent.right
            }
            text: "Unknown"
            horizontalAlignment: Text.AlignRight
        }

        Label{
            id: lblSR1Text
            anchors{
                left: parent.left
                top: lblVoltVal.bottom
            }
            text: "SmartReflex VDD1 status: "
        }

        Label{
            id: lblSR1Val
            anchors{
                top: lblVoltVal.bottom
                right: parent.right
            }
            text: "Unknown"
            horizontalAlignment: Text.AlignRight
        }

        Label{
            id: lblSR2Text
            anchors{
                left: parent.left
                top: lblSR1Val.bottom
            }
            text: "SmartReflex VDD2 status: "
        }

        Label{
            id: lblSR2Val
            anchors{
                top: lblSR1Val.bottom
                right: parent.right
            }
            text: "Unknown"
            horizontalAlignment: Text.AlignRight
        }

        Label{
            id: lblModuleText
            anchors{
                left: parent.left
                top: lblSR2Val.bottom
            }
            text: "Kernel module version: "
        }

        Label{
            id: lblModuleVal
            anchors{
                top: lblSR2Val.bottom
                right: parent.right
            }
            text: "Unknown"
            horizontalAlignment: Text.AlignRight
        }

        Button{
            id: btnRefresh
            anchors{
                top: lblModuleVal.bottom
                horizontalCenter: parent.horizontalCenter
                topMargin: 50
            }
            text: "Refresh"
            width: 150
            onClicked: {
                refresh();
            }
        }

        Label{
            id: lblShowAllOutput
            anchors{
                top: btnRefresh.bottom
                topMargin: 25
                left: parent.left
            }
            text: "Show raw output"

        }

        Switch {
            anchors{
                top: btnRefresh.bottom
                right: parent.right
                topMargin: 25
            }
            id: swShowAllOutput
            checked: objQSettings.getValue("/settings/ShowAll/enabled",false)
            onCheckedChanged:{//wow this crappy harmattan QML is missing both the pressed and clicked events and properties for switches.
                if (!blockEvents.running) {//so we get to use this instead. (onChecked fires too early -- when the component is created)
                    objQSettings.setValue("/settings/ShowAll/enabled",swShowAllOutput.checked)
                    if (swShowAllOutput.checked){

                    }
                }
            }
        }

        ScrollDecorator {
            id: scrolldecorator
            flickableItem: flickableLog
        }
        FontLoader { id: fixedFont; name: "Courier" }
        Flickable{
            id: flickableLog
            anchors{
                topMargin: 20
                top: swShowAllOutput.bottom
                left: parent.left
                right: parent.right
                bottom: parent.bottom
            }
            contentHeight: txtLog.height
            clip: true
            TextArea {
                //platformInverted doesn't work.
                //wrapMode: TextEdit.NoWrap // would like this too but you get a binding loop when trying to set the
                //flickable contentwidth to this
                id: txtLog
                anchors{
                    left: parent.left
                    right: parent.right
                    rightMargin: 10
                }
                visible: swShowAllOutput.checked
                readOnly: true
                font { family: fixedFont.name; pointSize: 11; }
                Connections {
                    target: objOpptimizerLog
                    onNewLogInfo: {
                        if (txtLog.text.length > 4000){
                            txtLog.text = "(...log truncated)\n" + txtLog.text.slice(-2000);
                        }
                        txtLog.text = Qt.formatTime(new Date(),"hh:mm:ss") + ": " + LogText;
                    }
                }
            }
        }

        Component.onCompleted: {
            refresh();
        }
        Connections {
            target: platformWindow
            onActiveChanged: {
                if (platformWindow.active){
                    refresh();
                }
                else{
                      //App became inactive
                }
            }
        }
    }//Flickable
}//page
