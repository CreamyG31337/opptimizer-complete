// import QtQuick 1.0 // to target S60 5th Edition or Maemo 5
import QtQuick 1.1
import com.nokia.meego 1.0
import com.nokia.extras 1.0

Page{
    id: warningPage
    anchors.margins: UiConstants.DefaultMargin
     property string warnings

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
            onClicked: { appWindow.pageStack.pop(mainPage); }
        }
    }

    Label {
        id: txtWarning
        text: "The " + warnings + " selected may be dangerously high!"
        color: "red"
        width: parent.width
        anchors.horizontalCenter: parent.horizontalCenter
        font.pixelSize: 40
    }

    Button{
        id: btnConfirm
        anchors{
            horizontalCenter: parent.horizontalCenter
            verticalCenter: parent.verticalCenter
            topMargin: 25
        }
        text: "OPPtimize!"
        width: 170
        onClicked: {
            pageStack.pop(mainPage);
            appWindow.pageStack.currentPage.whatthefuck();
        }
        style: NegativeButtonStyle {}
    }

    Button{
        id: btnCancel
        anchors{
            topMargin: 25
            bottom: parent.bottom
            left: parent.left
            right: parent.right
        }
        text: "Cancel"
        height: parent.height / 3
        onClicked: {
            appWindow.pageStack.pop(mainPage);
        }
       // style: PositiveButtonStyle {} //i don't like green cancel buttons
    }
    tools: noTools
}
