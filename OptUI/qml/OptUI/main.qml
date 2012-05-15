import QtMobility.systeminfo 1.1
import QtQuick 1.1
import com.nokia.meego 1.0

PageStackWindow {
    id: appWindow
    initialPage: mainPage
    anchors.margins: UiConstants.DefaultMargin

    Component.onCompleted: {
        theme.inverted = objQSettings.getValue("/settings/THEME/inverted",true)
        theme.colorScheme = "darkOrange"
        if (myNetInfo.networkStatus == "Connected" || myNetInfo.networkStatus == "Home Network"){
            objOpptimizerUtils.startCheckForUpdates()
        }
    }

    MainPage {
        id: mainPage
    }

    Rectangle {//thanks http://fiferboy.blogspot.com/2011/10/inactive-doesnt-have-to-be-boring.html
        id: overlayRect
        anchors.fill: parent
        color: "#60000000"
        visible: !platformWindow.active
        Label {
            anchors.centerIn: parent
            width: parent.width
            text: "OPPtimizer"
            font.pixelSize: 70
            font.bold: true
            color: "white"
            horizontalAlignment: Text.AlignHCenter
        }
    }

    Rectangle {//just prevent people touching things when they shouldn't without me
        //having to enable/disable controls individually
        id: overlayBlocker
        anchors.fill: parent
        color: "#D0000000"
        visible: false
        MouseArea{//dummy to prevent click through window
            anchors.fill: parent
        }
    }

    Item{
        id: overlayBenchmarking
        z:98
        visible: false
        anchors.fill: parent
        ProgressBar {
            z:99
            id: testProgress
            anchors{
                top: parent.verticalCenter
                horizontalCenter: parent.horizontalCenter
            }
            minimumValue: 0
            maximumValue: 1000
            value: 0
            width: parent.width - 60
        }
        Rectangle {
            z: 90
            anchors.fill: parent
            color: "#D0000000"
            Label {
                id: lblTesting
                anchors{
                    horizontalCenter: parent.horizontalCenter
                    bottom: parent.verticalCenter
                }
                width: parent.width
                text: "Testing"
                font.pixelSize: 70
                font.bold: true
                color: "white"
                horizontalAlignment: Text.AlignHCenter
            }
            MouseArea{//dummy to prevent click through window
                anchors.fill: parent
            }
            Button {
                id: btnAbortTest
                anchors{
                    bottom: parent.bottom
                    horizontalCenter: parent.horizontalCenter
                    bottomMargin: 25
                }
                text: "Stop test"
                width: parent.width - 50
                height: parent.height / 3
                onClicked: {
                    objOpptimizerUtils.stopBenchmark();                    
                    mainPage.settingsAbortTest();
                    overlayBenchmarking.visible = false;
                }
            }
        }
    }

    Dialog {
        id: updateDialog
        title:
            Item{
            width: parent.width
            height: 100
                Label{
                id: dialogTitle
                    anchors {
                        left: parent.left
                        right: parent.right
                        centerIn: parent
                    }
                    text: "Update check complete"
                    font{
                        bold: true
                        pixelSize: 26
                    }
                }
            }
        content:
            Item {
                id: name
                width: parent.width
                height: 200
                Label {
                    id: dialogContentText
                    font.pixelSize: 22
                    anchors{
                        left: parent.left
                        right: parent.right
                        centerIn: parent
                    }
                    text: "err"
                }
            }
        buttons:
            ButtonRow {
                id: btnRow
                height: 100
                style: ButtonStyle { }
                anchors.horizontalCenter: parent.horizontalCenter
                Button {id: btn1; visible: false; text: "OK"; onClicked: updateDialog.reject()}
                Button {id: btn2; visible: false; text: "Yes"; onClicked: updateDialog.accept()}
                Button {id: btn3; visible: false; text: "No"; onClicked: updateDialog.reject()}
            }
        onAccepted: {
          Qt.openUrlExternally("http://talk.maemo.org/showthread.php?t=83357")
        }
    }

    Connections {
        target: objOpptimizerUtils
        onTestStatus: {
            testProgress.value = val
        }
        onNewVersion: {
            dialogContentText.text = message
            btn1.visible = false;
            btn2.visible = true;
            btn3.visible = true;
            btnRow.checkedButton = null
            updateDialog.open();
        }
        onNoNewVersion: {
            if (mainPage.manualUpdate == "Y")
            {
                dialogContentText.text = message
                btn1.visible = true;
                btn2.visible = false;
                btn3.visible = false;
                btnRow.checkedButton = null
                updateDialog.open();
            }
        }
    }

    NetworkInfo {
        id: myNetInfo
    }
}
