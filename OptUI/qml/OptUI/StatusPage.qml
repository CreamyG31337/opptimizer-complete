// import QtQuick 1.0 // to target S60 5th Edition or Maemo 5
import QtQuick 1.1
import com.nokia.meego 1.0
import com.nokia.extras 1.0

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

    Label{
        id: lblFreqText
        anchors.top: parent.top
        anchors.left: parent.left
        text: "Max Frequency (MHz): "
    }

    Label{
        id: lblFreqVal
        anchors.top: parent.top
        anchors.left: lblFreqText.right
        text: "Unknown"
    }

    Label{
        id: lblVoltText
        anchors.left: parent.left
        anchors.top: lblFreqText.bottom
        text: "Max Voltage (uV): "
    }

    Label{
        id: lblVoltVal
        anchors.top: lblFreqText.bottom
        anchors.left: lblVoltText.right
        text: "Unknown"
    }

    Label{
        id: lblSRText
        anchors.left: parent.left
        anchors.top: lblVoltVal.bottom
        text: "SmartReflex Status: "
    }

    Label{
        id: lblSRVal
        anchors.top: lblVoltVal.bottom
        anchors.left: lblSRText.right
        text: "Unknown"
    }

    Label{
        id: lblModuleText
        anchors.left: parent.left
        anchors.top: lblSRVal.bottom
        text: "Kernel Module Version: "
    }

    Label{
        id: lblModuleVal
        anchors.top: lblSRVal.bottom
        anchors.left: lblModuleText.right
        text: "Unknown"
    }
    Button{
        id: btnRefresh
        anchors.top: lblModuleVal.bottom
        anchors.right: parent.right
        text: "Refresh"
        onClicked: {
            refresh();
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
}//page
