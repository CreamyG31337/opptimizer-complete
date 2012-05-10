import QtQuick 1.1
import com.nokia.meego 1.0

Page {
    id: mainPage
    anchors.fill: parent
    tools: commonTools
    Component.onCompleted:{
        //try to load whichever one is set on startup
        if (objQSettings.getValue("/settings/OcOnStartup/enabled",false))
            headerSelectionDialog.selectedIndex = objQSettings.getValue("/settings/OcOnStartup/profile",0);
//        if (headerSelectionDialog.selectedIndex == -1)
//            headerSelectionDialog.selectedIndex = 0;
    }

    Header {
        id: pageHeader
        title: "OPPtimizer"
    }
    SelectionDialog {
        id: headerSelectionDialog
        titleText: "Choose Profile"
        model: ListModel {
            ListElement {name:"1"}
            ListElement {name:"2"}
            ListElement {name:"3"}
            ListElement {name:"4"}
            ListElement {name:"5"}
        }
        onAccepted: {
            pageHeader.title = "OPPtimizer: Profile " + (selectedIndex + 1);
            settingsPage.selectedProfile = selectedIndex;
            settingsPage.reloadProfile();
        }
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
                     pageHeader.hideIt();
                     pageHeader.title = "OPPtimizer"
                 }
             }
             TabButton {
                 tab: settingsPage
                 text: "Settings"
                 onClicked: {
                    pageHeader.showIt();
                    pageHeader.title = "OPPtimizer: Profile " + (headerSelectionDialog.selectedIndex + 1);
                 }
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
            anchors {
                fill: tabGroup
                topMargin: 72
            }
        }
        // define the content for tab 2
        SettingsPage {
            id: settingsPage
            anchors {
                fill: tabGroup
                topMargin: 72
            }
        }
    }
    Menu {
        id: myMenu
        visualParent: pageStack
        MenuLayout {
            MenuItem { text: qsTr("Reset Settings"); onClicked: {
                    objQSettings.clear();
                    //settingsPage.loadSettings();
                    var db = openDatabaseSync("OPPtimizer", "1.0", "OPPtimizer History", 1000000);
                    db.transaction(function(tx) {
                         tx.executeSql('DROP TABLE IF EXISTS OPPtimizer.History');
                    })
                    pageHeader.title = "OPPtimizer: Profile " + (headerSelectionDialog.selectedIndex + 1);
                    settingsPage.fnBlockEvents();
                    settingsPage.selectedProfile = headerSelectionDialog.selectedIndex;
                    settingsPage.fixOCEnabled();
                }}
            MenuItem { text: qsTr("Invert Colors"); onClicked: { theme.inverted = !theme.inverted; objQSettings.setValue("/settings/THEME/inverted", theme.inverted)}}
            MenuItem { text: qsTr("About OPPtimizer"); onClicked: pageStack.push(Qt.resolvedUrl("AboutPage.qml"))}
        }
    }
    function settingsStartApply(){
        settingsPage.startApply();
    }
    function settingsAbortTest(){
        settingsPage.testAborted();
    }
}
