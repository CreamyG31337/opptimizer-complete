// import QtQuick 1.0 // to target S60 5th Edition or Maemo 5
import QtQuick 1.1
import com.nokia.meego 1.0
import com.nokia.extras 1.0

Page{
    id: settingsPage
    anchors.margins: UiConstants.DefaultMargin

    property bool dangerVolts
    property bool dangerFreq

    BusyIndicator{
        id: myBusyInd
        platformStyle: BusyIndicatorStyle { size: "large" }
        anchors.centerIn: parent
        visible: false
        running: false
        z: 50
    }

    function loadSettings(){
        swOCEnabled.checked = objQSettings.getValue("/settings/OcOnStartup/enabled",false);
        swCustomVolts.checked = objQSettings.getValue("/settings/CustomVolts/enabled",false);
        swSmartReflex.checked = objQSettings.getValue("/settings/SmartReflex/enabled",true);
        sliderFreq.value = objQSettings.getValue("/settings/CPUFreq/value",1000);
        sliderVolts.value = objQSettings.getValue("/settings/CPUVolts/value",1350000);
        sliderTest.value = objQSettings.getValue("/settings/TestLength/value",3000)
    }

    function startApply(){
        infoMessageBanner.text = "Applying settings, please wait...";
        infoMessageBanner.timerShowTime = 1500
        infoMessageBanner.show();
        pauseAndApply.start();
        objQSettings.setValue("/settings/TestLength/value",sliderTest.value)
    }

    function applySettings(){
        var strStatus;
        objOpptimizerUtils.setSmartReflexStatus(swSmartReflex.checked);
        strStatus = objOpptimizerUtils.applySettings(cbFreq.value, cbVolts.value, swSmartReflex.checked, swCustomVolts.checked);
        if (strStatus.indexOf("Updated") === -1){//some sort of error
            if (strStatus.indexOf("Permission denied") > -1)
                strStatus = "Permission error - Please reinstall this package using /usr/sbin/incept."
            infoMessageBanner.hide();
            infoMessageBanner.timerShowTime = 9000
            infoMessageBanner.text = strStatus;
            infoMessageBanner.show();
        }
        else{
            infoMessageBanner.hide();
            infoMessageBanner.timerShowTime = 2000
            infoMessageBanner.text = "Testing, please wait...";
            infoMessageBanner.show();
            testAndSave.start();
        }
    }

    function testAndSaveSettings(){
        lblLastTestTime.visible = true;
        cbLastTest.visible = true;
        cbLastTest.value = objOpptimizerUtils.testSettings(sliderTest.value); //this should really start a new thread but it doesn't yet
        infoMessageBanner.hide();
        infoMessageBanner.timerShowTime = 3000
        infoMessageBanner.text = "Testing completed. Saving...";
        infoMessageBanner.show();
        objQSettings.setValue("/settings/CPUVolts/value",sliderVolts.value)
        objQSettings.setValue("/settings/CPUFreq/value",sliderFreq.value)
        objQSettings.setValue("/settings/SmartReflex/enabled",swSmartReflex.checked)
        objQSettings.setValue("/settings/CustomVolts/enabled",swCustomVolts.checked)
    }

    Timer {
        id: blockEvents
        interval: 200; running: true; repeat: false
    }

    Timer {
        id: pauseAndApply
        interval: 1500; running: false; repeat: false
        onTriggered: applySettings();
    }

    Timer {
        id: testAndSave
        interval: 2000; running: false; repeat: false
        onTriggered: testAndSaveSettings()
    }

    ScrollDecorator {
        id: scrolldecorator
        flickableItem: flickable
    }

    Flickable{
        id: flickable
        anchors.fill: parent
        contentHeight: 700

        Row {
             id: rowEnabled
             anchors{
                 topMargin: 10
                 top: parent.top
                 right: parent.right
                 left: parent.left
             }
             Label {
                 id: lblApplyOnStartup
                 width: rowEnabled.width - rowEnabled.spacing - swOCEnabled.width
                 height: swOCEnabled.height
                 verticalAlignment: Text.AlignVCenter
                 text: "Apply on startup"
             }
             Switch {
                 id: swOCEnabled
                 checked: false //objQSettings.getValue("/settings/OcOnStartup/enabled",true)
                 enabled: false //not implemented
                 onCheckedChanged:{//wow this crappy harmattan QML is missing both the pressed and clicked events and properties for switches.
                    if (!blockEvents.running) {//so we get to use this instead. (onChecked fires too early -- when the component is created)
                        objQSettings.setValue("/settings/OcOnStartup/enabled",swOCEnabled.checked)
//                        if (swOCEnabled.checked){
//                           infoMessageBanner.text =
//                        }
                    }
                }
             }
         }

        Row {
             id: rowCustomVoltage
             anchors{
                 topMargin: 10
                 top: rowEnabled.bottom
                 right: parent.right
                 left: parent.left
             }
             Label {
                 width: rowCustomVoltage.width - rowCustomVoltage.spacing - swCustomVolts.width
                 height: swCustomVolts.height
                 verticalAlignment: Text.AlignVCenter
                 text: "Custom voltage"
             }
             Switch {
                 id: swCustomVolts
                 checked: objQSettings.getValue("/settings/CustomVolts/enabled",false)
                 onCheckedChanged:{
                    if (!blockEvents.running) {
                        objQSettings.setValue("/settings/CustomVolts/enabled",swCustomVolts.checked)
                        if (swCustomVolts.checked){
                            sliderVolts.value = objQSettings.getValue("/settings/CPUVolts/value",1350000);
                            infoMessageBanner.text = "SmartReflex will be blocked from further adjusting this voltage only";
                            infoMessageBanner.timerShowTime = 3000;
                            infoMessageBanner.show();
                        }
                        else{
                            sliderVolts.value = objOpptimizerUtils.getDefaultVoltage();
                        }
                    }
                }
            }
        }


        Row {
            id: rowSR
            anchors{
            topMargin: 10
            top: rowCustomVoltage.bottom
            right: parent.right
            left: parent.left
            }
            Label {
                width: rowSR.width - rowSR.spacing - swSmartReflex.width
                height: swSmartReflex.height
                text: "SmartReflex"
            }
            Switch {
                id: swSmartReflex
                checked: objQSettings.getValue("/settings/SmartReflex/enabled",true)
                onCheckedChanged:{
                    if (!blockEvents.running) {
                        objQSettings.setValue("/settings/SmartReflex/enabled",swSmartReflex.checked)
                        objOpptimizerUtils.setSmartReflexStatus(swSmartReflex.checked);
                        if (!swSmartReflex.checked){
                            infoMessageBanner.text = "SmartReflex will be completely disabled for the CPU. The CPU will use quite a bit more power.";
                            infoMessageBanner.timerShowTime = 3000;
                            infoMessageBanner.show();
                        }
                    }
                }
            }
        }

        Label {
            id:lblFreq
            anchors{
                top: rowSR.bottom
                left: parent.left
            }
            anchors.topMargin: 20
            text: "Frequency (MHz): "
            color: dangerFreq ? "red" : lblApplyOnStartup.color
        }
        CountBubble{
            id: cbFreq
            anchors.right: parent.right
            anchors.verticalCenter: lblFreq.verticalCenter
            anchors.topMargin: 20
            value: sliderFreq.value
            largeSized: true
            onValueChanged: {
                //if (!blockEvents.running)

                    if (value >= 1200){
                        dangerFreq = true;
                        //lblFreq.color = "red"
                    }
                    else{
                        dangerFreq = false;
                        //lblFreq.color = lblApplyOnStartup.color
                    }

            }
        }

        Slider {
            id: sliderFreq
            anchors{
                top: lblFreq.bottom
                left: parent.left
                right: parent.right
            }
            maximumValue: 1400
            minimumValue: 800
            value: objQSettings.getValue("/settings/CPUFreq/value",1000)
            stepSize: 5
         }

        Label {
            id: lblOCVolts
            anchors{
                top: sliderFreq.bottom
                left: parent.left
            }
            text: "Voltage (μV): "
            color: dangerVolts ? "red" : lblApplyOnStartup.color
        }

        CountBubble{
            id: cbVolts
            anchors.right: parent.right
            anchors.verticalCenter: lblOCVolts.verticalCenter
            value: sliderVolts.value
            largeSized: true
            enabled: swCustomVolts.checked
            onValueChanged: {
                //if (!blockEvents.running){
                    if (value >= 1387500){
                        dangerVolts = true;
                        //lblOCVolts.color = "red"
                    }
                    else{
                        dangerVolts = false;
                        //lblOCVolts.color = lblApplyOnStartup.color
                    }
                //}
            }
        }

        Slider {
            id: sliderVolts
            enabled: swCustomVolts.checked
            anchors{
                top: lblOCVolts.bottom
                left: parent.left
                right: parent.right
            }
            minimumValue: 1000000
            maximumValue: 1425000
            value: objQSettings.getValue("/settings/CPUVolts/value",1375000)
            stepSize: 12500
         }

        Button{
            id: btnApply
            anchors.top: sliderVolts.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            text: "OPPtimize!"
            width: 200
            anchors.topMargin: 25
            onClicked: {
                var warningmessage = "";
                if (dangerVolts){ warningmessage += "Voltage"; }
                if (warningmessage != "") warningmessage += " & ";
                if (dangerFreq) warningmessage += "Frequency";
                if (warningmessage != "")
                    appWindow.pageStack.push(Qt.resolvedUrl("Warning.qml"),
                                              {warnings: warningmessage})
                else
                    startApply();
            }
            style: NegativeButtonStyle {}
        }

        Label {
            id: lblTestLength
            anchors{
                top: btnApply.bottom
                left: parent.left
            }
            anchors.topMargin: 25
            text: "Test iterations: "
        }

        CountBubble{
            id: cbTest
            anchors.right: parent.right
            anchors.verticalCenter: lblTestLength.verticalCenter
            value: sliderTest.value
            largeSized: true
        }

        Slider {
            id: sliderTest
            anchors{
                top: lblTestLength.bottom
                left: parent.left
                right: parent.right
            }
            minimumValue: 0
            maximumValue: 16000
            value: objQSettings.getValue("/settings/TestLength/value",3000)
            stepSize: 1000
         }
        Label {
            id: lblLastTestTime
            anchors{
                top: sliderTest.bottom
                left: parent.left
            }
            text: "Completed in "
            visible: false
        }
        CountBubble{
            id: cbLastTest
            anchors.right: parent.right
            anchors.verticalCenter: lblLastTestTime.verticalCenter
            value: 0
            largeSized: true
            visible: false
        }
    }//flickable
    InfoBanner{
        id: infoMessageBanner
        z: 99
        topMargin: 10
    }
}//page
