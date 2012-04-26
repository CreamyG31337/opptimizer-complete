// import QtQuick 1.0 // to target S60 5th Edition or Maemo 5
import QtQuick 1.1
import com.nokia.meego 1.0
import com.nokia.extras 1.0

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
        id: lblirc
        text: "visit #inception\nirc.freenode.net"
        anchors.topMargin: 20
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
    }

    Label{
        id: lblDonate
        anchors.left: parent.left
        anchors.right: parent.right
        text: "OPPtimizer is free and open source software, but please show your support by donating if you are able."
        anchors.topMargin: 20
        anchors.top: lblirc.bottom
        anchors.horizontalCenter: parent.horizontalCenter
    }

    Label{
        id: lblLinkDonate
        text: "Donate"
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: lblDonate.bottom
        font.underline: true
        color: "steelblue"
        MouseArea{
            anchors.fill: parent
            onClicked: {
                myBusyInd.running = true;
                myBusyInd.visible = true;
                Qt.openUrlExternally("https://www.wepay.com/donations/n9-apps-by-creamy-goodness")
                thisIsDumb.start();
            }
        }
    }


    Label{
        id: lblVersion
        text: "OPPtimizer version 1.0.0\nCreated by Lance Colton"
        anchors.top: lblLinkDonate.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: 30
        color: "orange"
    }

    Label{
        id: lblLinkOPPtimizer
        text: "Latest version / More info"
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
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.topMargin: 20
        anchors.top: lblLinkOPPtimizer.bottom
        color: "red"
        text: "Using this application may void your device warranty. Even a small overclock can reduce the life of the hardware. You have nobody to blame but yourself if this happens"
    }

    Label{
        id: lblThanks
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.topMargin: 20
        anchors.top: lblDisclaimer.bottom
        color: "green"
        text: "Additional thanks to Jeffrey Kawika Patricio, Tiago Sousa, Skrilax_CZ, itsnotabigtruck"
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
