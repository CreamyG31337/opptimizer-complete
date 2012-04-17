// import QtQuick 1.0 // to target S60 5th Edition or Maemo 5
import QtQuick 1.1
import com.nokia.meego 1.0

Page{
    id: aboutPage
    anchors.margins: UiConstants.DefaultMargin
    ToolBarLayout {
        id: noTools
        anchors {
            left: parent.left;
            right: parent.right;
            bottom: parent.bottom
        }
        ToolIcon{
            id: toolIcoBack
            iconId: "toolbar-back";
            onClicked: { pageStack.pop(); }
        }
    }
    tools: noTools
    Label{
        id: lblVersion
        text: "OPPtimizer version 1.0.0"
        anchors.verticalCenter: parent.verticalCenter
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: 20
    }

    Label{
        id: lblLinkOPPtimizer
        text: "latest version / more info"
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: 20
        anchors.top: lblVersion.bottom
        font.underline: true
        color: "steelblue"
        MouseArea{
            anchors.fill: parent
            onClicked: {
                myBusyInd.running = true;
                myBusyInd.visible = true;
                Qt.openUrlExternally("http://talk.maemo.org/showthread.php?t=83357")
                thisIsDumb.start();
            }
        }
    }

    Label{
        id: lblDisclaimer
        anchors.top: lblLinkOPPtimizer.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        text: "Using this application may void your device warranty\n"
             +"Even a small overclock can reduce the life of the hardware\n"
             +"You have nobody to blame but yourself if this happens\n"
    }

    BusyIndicator{
        id: myBusyInd
        platformStyle: BusyIndicatorStyle { size: "large" }
        anchors.centerIn: aboutPage
        visible: false
        running: false
        z: 50
    }

    Timer {
        id: thisIsDumb
        interval: 5000
        running: false
        repeat: false
        onTriggered: {
            myBusyInd.running = false;
            myBusyInd.visible = false;
        }
    }

}
