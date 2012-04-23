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
        lblSRVal.text = objOpptimizerUtils.getSmartReflexStatus();
        lblFreqVal.text = objOpptimizerUtils.getMaxFreq();
        myBusyInd.running = false;
        myBusyInd.visible = false;
    }

    Timer {
        id: blockEvents
        interval: 200; running: true; repeat: false
    }

    Label{
        id: lblFreqText
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.topMargin: 20
        text: "Max. frequency (MHz): "
    }

    Label{
        id: lblFreqVal
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: 20
        text: "Unknown"
        horizontalAlignment: Text.AlignRight
    }

    Label{
        id: lblVoltText
        anchors.left: parent.left
        anchors.top: lblFreqText.bottom
        text: "Max. voltage (μV): "
    }

    Label{
        id: lblVoltVal
        anchors.top: lblFreqText.bottom
        anchors.right: parent.right
        text: "Unknown"
        horizontalAlignment: Text.AlignRight
    }

    Label{
        id: lblSRText
        anchors.left: parent.left
        anchors.top: lblVoltVal.bottom
        text: "SmartReflex status: "
    }

    Label{
        id: lblSRVal
        anchors.top: lblVoltVal.bottom
        anchors.right: parent.right
        text: "Unknown"
        horizontalAlignment: Text.AlignRight
    }

    Label{
        id: lblModuleText
        anchors.left: parent.left
        anchors.top: lblSRVal.bottom
        text: "Kernel module version: "
    }

    Label{
        id: lblModuleVal
        anchors.top: lblSRVal.bottom
        anchors.right: parent.right
        text: "Unknown"
        horizontalAlignment: Text.AlignRight
    }
    Button{
        id: btnRefresh
        anchors.top: lblModuleVal.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        text: "Refresh"
        width: 150
        anchors.topMargin: 50
        onClicked: {
            refresh();
        }
    }

    Label{
        id: lblShowAllOutput
        anchors.top: btnRefresh.bottom
        anchors.topMargin: 25
        anchors.left: parent.left
        text: "Show Raw Output"

    }

    Switch {
        anchors.top: btnRefresh.bottom
        anchors.right: parent.right
        anchors.topMargin: 25
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


    Item{
       // width: 250
        //height: 250
        anchors.topMargin: 20
        anchors.top: swShowAllOutput.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom

        ScrollDecorator {
            id: scrolldecorator
            flickableItem: flickableLog
        }
        Flickable{
            id: flickableLog
            contentHeight: txtLog.height
            width: parent.width
            height: parent.height
            clip: true
            TextArea {
                //platformInverted doesn't work.
                id: txtLog
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.rightMargin: 10
                visible: swShowAllOutput.checked
                readOnly: true

                Connections {
                    target: objOpptimizerLog
                    onNewLogInfo: {
                        if (txtLog.text.length > 4000){
                            txtLog.text = "(...log truncated)\n" + txtLog.text.slice(-2000);
                        }
                        txtLog.text = Qt.formatTime(new Date(),"hh:mm:ss") + ": " + LogText;
                        //this really needs to scroll to the bottom now, but there's no way??
                    }
                }
            }
        }
    }



    //returnRawSettings

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
}//page
