import QtQuick 1.1
import com.nokia.meego 1.0

Page {
    anchors.fill: parent
    tools: commonTools
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
                 tab: tabStatus
                 text: "Status"
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
        currentTab: tabStatus
        anchors.fill: parent
        // define the content for tab 1
        StatusPage {
            id: tabStatus
            anchors { fill: tabGroup;}
        }
        // define the content for tab 2
        SettingsPage {
            id: settingsPage
            anchors { fill: tabGroup;}
        }
    }
    Menu {
        id: myMenu
        visualParent: pageStack
        MenuLayout {
            MenuItem { text: qsTr("Invert Colors"); onClicked: { theme.inverted = !theme.inverted; objQSettings.setValue("/settings/THEME/inverted", theme.inverted)}}
            MenuItem { text: qsTr("About OPPtimizer"); onClicked: pageStack.push(Qt.resolvedUrl("AboutPage.qml"))}
        }
    }
}
