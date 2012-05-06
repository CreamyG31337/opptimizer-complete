// import QtQuick 1.0 // to target S60 5th Edition or Maemo 5
import QtQuick 1.1
import com.nokia.meego 1.0
import com.nokia.extras 1.0

Page{
    id: settingsPage
    anchors.margins: UiConstants.DefaultMargin
    anchors.fill: parent

    property bool dangerVolts
    property bool dangerFreq
    property int selectedProfile: 0

    BusyIndicator{
        id: myBusyInd
        platformStyle: BusyIndicatorStyle { size: "large" }
        anchors.centerIn: parent
        visible: false
        running: false
        z: 50
    }

    function checkHistory(){
        var ItersPassed = 0;
        var db = openDatabaseSync("OPPtimizer", "1.0", "OPPtimizer History", 1000000);
        db.transaction(function(tx) {
            // Create the history database table if it doesn't already exist, composite key on freq/volt
            tx.executeSql('CREATE TABLE IF NOT EXISTS History(Frequency INT, Voltage INT, IterationsPassed INT, SuspectedCrashes INT, PRIMARY KEY(Frequency, Voltage))');
            var rs = tx.executeSql('SELECT IterationsPassed FROM History WHERE Frequency=? AND Voltage=?;', [sliderFreq.value, sliderVolts.value]);
            if (rs.rows.length > 0){
                ItersPassed = rs.rows.item(0).IterationsPassed;
            }
        })
        console.debug("checkhistory finds iters passed: " + ItersPassed)
        cbTestTotal.value = ItersPassed;
    }

    function fnBlockEvents(){
        blockEvents.start();
    }

    function fixOCEnabled(){
        fnBlockEvents()
        if (cbTestTotal.value >= 15000){
            swOCEnabled.enabled = true;
            if (objQSettings.getValue("/settings/OcOnStartup/enabled",false) && (objQSettings.getValue("/settings/OcOnStartup/profile",-1) == selectedProfile))
                swOCEnabled.checked = true;
            console.debug("enabled oc on boot switch, checked = " + objQSettings.getValue("/settings/OcOnStartup/enabled",false) + objQSettings.getValue("/settings/OcOnStartup/profile",-1) + selectedProfile)

        }
        else{
            //check for any frequency < selected with same voltage and 15k iters and 0 crashes, allow it
            var MaxFreq = 0
            var db = openDatabaseSync("OPPtimizer", "1.0", "OPPtimizer History", 1000000);
            db.transaction(function(tx) {
                var rs = tx.executeSql('SELECT MAX(Frequency) AS MAXFREQ FROM History WHERE Voltage=? AND IterationsPassed >= 15000 AND SuspectedCrashes = 0;', [sliderVolts.value]);
                if (rs.rows.length > 0){
                    MaxFreq = rs.rows.item(0).MAXFREQ
                }
            })
            console.debug("found max freq of " + MaxFreq)
            if (sliderFreq.value < MaxFreq){
                swOCEnabled.enabled = true;
                console.debug("enabled switch but left oc on boot as is")
            }
            else{
                swOCEnabled.enabled = false;
                swOCEnabled.checked = false;
            }

            console.debug("disabled oc on boot")
        }
        //this stuff doesn't seem to be needed due to the bindings updating fine
//        if (objQSettings.getValue("/settings/OcOnStartup/enabled",false) && (objQSettings.getValue("/settings/OcOnStartup/profile",-1 === selectedProfile) )) {
//            swOCEnabled.checked = true;
//        }
//        else{
//            swOCEnabled.checked = false;
//        }
//        swCustomVolts.checked = objQSettings.getValue("/settings/" + selectedProfile + "/CustomVolts/enabled",false);
//        swSmartReflex.checked = objQSettings.getValue("/settings/" + selectedProfile + "/SmartReflex/enabled",true);
//        sliderFreq.value = objQSettings.getValue("/settings/" + selectedProfile + "/CPUFreq/value",1000);
//        sliderVolts.value = objQSettings.getValue("/settings/" + selectedProfile + "/CPUVolts/value",1350000);
//        sliderTest.value = objQSettings.getValue("/settings/TestLength/value",3000);
//        checkHistory();
    }

    function startApply(){
        infoMessageBanner.topMargin = 10
        infoMessageBanner.text = "Applying settings, please wait...";
        var db = openDatabaseSync("OPPtimizer", "1.0", "OPPtimizer History", 1000000);
        db.transaction(function(tx) {
            // Add row for this freq/volt combo if doesn't exist already
            tx.executeSql('INSERT OR IGNORE INTO History VALUES(?,?,0,1);', [ sliderFreq.value, sliderVolts.value ]);//set suspected crashes to 1 for now
            // Get existing iterations done
//            var rs = tx.executeSql('SELECT IterationsPassed FROM History WHERE Frequency=? AND Voltage=?;', [ sliderFreq.value, sliderVolts.value ]);
//            if (rs.rows.length > 0){//should have got 1 row
//                // update row to add iterations just done
//                totalIter = parseInt(rs.rows.item(0).IterationsPassed) + sliderTest.value //javascript + sqlite = shit.
//                tx.executeSql('UPDATE History SET IterationsPassed=? WHERE Frequency=? AND Voltage=?;', [ totalIter, sliderFreq.value, sliderVolts.value]);
//                console.debug("tried to update total iters from " + rs.rows.item(0).IterationsPassed + " to " + totalIter)
//            }
        })

        overlayBlocker.visible = true;
        infoMessageBanner.timerShowTime = 1500
        infoMessageBanner.show();
        pauseAndApply.start();
        objQSettings.setValue("/settings/TestLength/value",sliderTest.value)
    }

    Timer {
        id: pauseAndApply
        interval: 1500; running: false; repeat: false
        onTriggered: applySettings();
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
            overlayBlocker.visible = false;
            //count as crash?
        }
        else{
            infoMessageBanner.hide();
            testAndSave.start();
        }
    }

    Timer {
        id: testAndSave
        interval: 2000; running: false; repeat: false
        onTriggered: testAndSaveSettings()
    }

    function testAndSaveSettings(){
        overlayBlocker.visible = false;
        lblLastTestTime.visible = true;
        cbLastTest.visible = true;
        testProgress.maximumValue = sliderTest.value;
        testProgress.value = 0;
        objOpptimizerUtils.testSettings(sliderTest.value); //this branches to a new thread
        overlayBenchmarking.visible = true
    }

    InfoBanner{
        id: infoMessageBanner
        z: 99
        topMargin: 10
    }    

    Connections {
        target: objOpptimizerUtils
        onRenderedImageOut: {
            overlayBenchmarking.visible = false
            cbLastTest.value = timeWasted
            infoMessageBanner.text = "Testing completed. Saving...";
            infoMessageBanner.show();
            objQSettings.setValue("/settings/" + selectedProfile + "/CPUVolts/value",sliderVolts.value)
            objQSettings.setValue("/settings/" + selectedProfile + "/CPUFreq/value",sliderFreq.value)
            objQSettings.setValue("/settings/" + selectedProfile + "/SmartReflex/enabled",swSmartReflex.checked)
            objQSettings.setValue("/settings/" + selectedProfile + "/CustomVolts/enabled",swCustomVolts.checked)
            var db = openDatabaseSync("OPPtimizer", "1.0", "OPPtimizer History", 1000000);
            var totalIter = 0
            db.transaction(function(tx) {
                // Add row for this freq/volt combo if not exist already
                //tx.executeSql('INSERT OR IGNORE INTO History VALUES(?,?,0,0);', [ sliderFreq.value, sliderVolts.value ]);
                // Get existing iterations done
                var rs = tx.executeSql('SELECT IterationsPassed FROM History WHERE Frequency=? AND Voltage=?;', [ sliderFreq.value, sliderVolts.value ]);
                if (rs.rows.length > 0){//should have got 1 row
                    // update row to add iterations just done
                    totalIter = parseInt(rs.rows.item(0).IterationsPassed) + sliderTest.value //javascript + sqlite = shit.
                    tx.executeSql('UPDATE History SET IterationsPassed=?, SuspectedCrashes=0, WHERE Frequency=? AND Voltage=?;', [ totalIter, sliderFreq.value, sliderVolts.value]);
                    console.debug("tried to update total iters from " + rs.rows.item(0).IterationsPassed + " to " + totalIter)
                }
            })
            cbTestTotal.value = totalIter;
        }
    }

    Timer {
        id: blockEvents
        interval: 200; running: true; repeat: false
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
            Item{
                width: swCustomVolts.width
                height: swCustomVolts.height
                MouseArea{
                    z: 20
                    anchors.fill: parent
                    onClicked: {
                        if (!swOCEnabled.enabled){
                            infoMessageBanner.text = "15,000 test iterations are required to apply on startup";
                            infoMessageBanner.show();
                            infoMessageBanner.topMargin = 200
                        }
                        else
                            swOCEnabled.checked = !swOCEnabled.checked
                    }
                }
                Switch {
                    z: 15
                    anchors.fill: parent
                    id: swOCEnabled
                    checked: false
                    enabled: cbTestTotal.value >= 15000
                    onCheckedChanged:{//wow this crappy harmattan QML is missing both the pressed and clicked events and properties for switches.
                        if (!blockEvents.running) {//so we get to use this instead. (onChecked fires too early -- when the component is created)
                            objQSettings.setValue("/settings/OcOnStartup/enabled",swOCEnabled.checked)
                            //also add profile #
                            objQSettings.setValue("/settings/OcOnStartup/profile", selectedProfile)
                        }
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
                 checked: objQSettings.getValue("/settings/" + selectedProfile + "/CustomVolts/enabled",false)
                 onCheckedChanged:{
                    if (!blockEvents.running) {
                        objQSettings.setValue("/settings/" + selectedProfile + "/CustomVolts/enabled",swCustomVolts.checked)
                        if (swCustomVolts.checked){
                            sliderVolts.value = objQSettings.getValue("/settings/" + selectedProfile + "/CPUVolts/value",1350000);
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
                checked: objQSettings.getValue("/settings/" + selectedProfile + "/SmartReflex/enabled",true)
                onCheckedChanged:{
                    if (!blockEvents.running) {
                        objQSettings.setValue("/settings/" + selectedProfile + "/SmartReflex/enabled",swSmartReflex.checked)
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
                topMargin: 20
            }
            text: "Frequency (MHz)"
            color: dangerFreq ? "red" : lblApplyOnStartup.color
        }
        CountBubble{
            id: cbFreq
            anchors{
                right: parent.right
                verticalCenter: lblFreq.verticalCenter
                topMargin: 20
            }
            value: sliderFreq.value
            largeSized: true
            onValueChanged: {
                if (value >= 1200){
                    dangerFreq = true;
                }
                else{
                    dangerFreq = false;
                }
                checkHistory()
                fixOCEnabled()
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
            value: objQSettings.getValue("/settings/" + selectedProfile + "/CPUFreq/value",1000)
            stepSize: 5
        }

        Label {
            id: lblOCVolts
            anchors{
                top: sliderFreq.bottom
                left: parent.left
                topMargin: 20
            }
            text: "Voltage (μV)"
            color: dangerVolts ? "red" : lblApplyOnStartup.color
        }

        CountBubble{
            id: cbVolts
            anchors{
                right: parent.right
                verticalCenter: lblOCVolts.verticalCenter
            }
            value: sliderVolts.value
            largeSized: true
            enabled: swCustomVolts.checked
            onValueChanged: {
                if (value >= 1387500){
                    dangerVolts = true;
                }
                else{
                    dangerVolts = false;
                }
                checkHistory()
                fixOCEnabled()
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
            value: objQSettings.getValue("/settings/" + selectedProfile + "/CPUVolts/value",1375000)
            stepSize: 12500
         }

        Button{
            id: btnApply
            anchors{
                top: sliderVolts.bottom
                horizontalCenter: parent.horizontalCenter
            }
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
            id: lblTestLength1
            anchors{
                top: btnApply.bottom
                left: parent.left
                topMargin: 35
            }
            text: "Do "
        }

        CountBubble{
            id: cbTest
            anchors{
                left: lblTestLength1.right
                verticalCenter: lblTestLength1.verticalCenter
            }
            value: sliderTest.value
            largeSized: true
        }

        Label {
            id: lblTestLength2
            anchors{
                top: btnApply.bottom
                left: cbTest.right
                topMargin: 35
            }
            text: " test iterations"
        }

        Label {
            id: lblTestTotal
            anchors{
                top: btnApply.bottom
                right: cbTestTotal.left
                topMargin: 35
            }
            text: "Total "
        }

        CountBubble{
            id: cbTestTotal
            anchors{
                right: parent.right
                verticalCenter: lblTestLength1.verticalCenter
            }
            value: 0
            largeSized: true
            onValueChanged: {
                fixOCEnabled()
            }
        }

        Slider {
            id: sliderTest
            anchors{
                top: lblTestLength1.bottom
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
            text: "Completed in"
            visible: false
        }
        CountBubble{
            id: cbLastTest
            anchors{
                right: parent.right
                verticalCenter: lblLastTestTime.verticalCenter
            }
            value: 0
            largeSized: true
            visible: false
        }
    }//flickable
}//page
