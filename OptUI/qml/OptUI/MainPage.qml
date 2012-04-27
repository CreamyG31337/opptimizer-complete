import QtQuick 1.1
import com.nokia.meego 1.0

Page {
    id: mainPage
    anchors.fill: parent
    tools: commonTools
    Header {
      id: pageHeader
      title: "OPPtimizer"
    }
    ToolBarLayout {
         id: commonTools
         anchors{
             bottom: parent.bottom
         }
         ToolIcon{
             id: toolIcoBack
             iconId: "toolbar-back";
             onClicked: { myMenu.close(); pageStack.pop(); }
             visible: false
         }
         ButtonRow {
             style: TabButtonStyle { }
             TabButton {
                 tab: statusPage
                 text: "Status"
                 onClicked: {
                     statusPage.refresh();
                 }
             }
             TabButton {
                 tab: settingsPage
                 text: "Settings"
             }
         }
         ToolIcon {
             platformIconId: "toolbar-view-menu"
             anchors.right: (parent === undefined) ? undefined : parent.right
             onClicked: (myMenu.status == DialogStatus.Closed) ? myMenu.open() : myMenu.close()
         }
     }
    TabGroup {
        id: tabGroup
        currentTab: statusPage
        anchors.fill: parent
        // define the content for tab 1
        StatusPage {
            id: statusPage
            anchors { fill: tabGroup;}
            anchors.topMargin: 72
        }
        // define the content for tab 2
        SettingsPage {
            id: settingsPage
            anchors { fill: tabGroup;}
            anchors.topMargin: 72

        }
    }
    Menu {
        id: myMenu
        visualParent: pageStack
        MenuLayout {
            MenuItem { text: qsTr("Reset Settings"); onClicked: {objQSettings.clear(); settingsPage.loadSettings();}}
            MenuItem { text: qsTr("Invert Colors"); onClicked: { theme.inverted = !theme.inverted; objQSettings.setValue("/settings/THEME/inverted", theme.inverted)}}
            MenuItem { text: qsTr("About OPPtimizer"); onClicked: pageStack.push(Qt.resolvedUrl("AboutPage.qml"))}
        }
    }
    Rectangle {
        z: 99
        id: overlayBenchmarking
        anchors.fill: parent
        color: "#60000000"
        visible: false
        Label {
            anchors.centerIn: parent
            width: parent.width
            text: "Testing"
            font.pixelSize: 70
            font.bold: true
            color: "white"
            horizontalAlignment: Text.AlignHCenter
        }
    }
    function whatthefuck(){
        //the question is WHY can't I just call this directly...
        settingsPage.startApply();
    }
}
