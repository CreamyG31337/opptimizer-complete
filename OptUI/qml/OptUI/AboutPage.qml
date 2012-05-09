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
        anchors{
            topMargin: 20
            top: parent.top
            horizontalCenter: parent.horizontalCenter
        }
        horizontalAlignment: Text.AlignHCenter
    }

    Label{
        id: lblDonate
        anchors{
            left: parent.left
            right: parent.right
            topMargin: 20
            top: lblirc.bottom
//            horizontalCenter: parent.horizontalCenter
        }
        text: "OPPtimizer is free and open source software, but please show your support by donating if you are able."
        horizontalAlignment: Text.AlignJustify
    }

    Label{
        id: lblLinkDonate2
        text: "PayPal"
        anchors{
            horizontalCenter: parent.horizontalCenter
            leftMargin: 10
            left: lblLinkDonate.right
            top: lblDonate.bottom
        }
        font.underline: true
        color: "steelblue"
        MouseArea{
            anchors.fill: parent
            onClicked: {
                myBusyInd.running = true;
                myBusyInd.visible = true;
                Qt.openUrlExternally("https://www.paypal.com/cgi-bin/webscr?cmd=_donations&business=creamygoodness31337%40hotmail%2ecom&lc=CA&item_name=Creamy%20Goodness%20N9%20Apps&currency_code=CAD&bn=PP%2dDonationsBF%3abtn_donateCC_LG%2egif%3aNonHosted")
                thisIsDumb.start();
            }
        }
    }

    Label{
        id: lblVersion
        text: "OPPtimizer version 1.2.0\nCreated by Lance Colton"
        anchors{
            top: lblLinkDonate2.bottom
            horizontalCenter: parent.horizontalCenter
            topMargin: 30
        }
        color: "orange"
    }

    Label{
        id: lblLinkOPPtimizer
        text: "Latest version / More info"
        anchors{
            horizontalCenter: parent.horizontalCenter
            topMargin: 20
            top: lblVersion.bottom
        }
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
        anchors{
            left: parent.left
            right: parent.right
            topMargin: 20
            top: lblLinkOPPtimizer.bottom
        }
        color: "red"
        horizontalAlignment: Text.AlignJustify
        text: "Using this application may void your device warranty. Even a small overclock can reduce the life of the hardware. You have nobody to blame but yourself if this happens"
    }

    Label{
        id: lblThanks
        anchors{
            left: parent.left
            right: parent.right
            topMargin: 20
            top: lblDisclaimer.bottom
        }
        color: "green"
        horizontalAlignment: Text.AlignHCenter
        text: "Additional thanks to @tekahuna, Tiago Sousa, Skrilax_CZ, itsnotabigtruck"
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
