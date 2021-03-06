// import QtQuick 1.0 // to target S60 5th Edition or Maemo 5
import QtQuick 1.1
import com.nokia.meego 1.0
import com.nokia.extras 1.0
import QtMobility.feedback 1.1

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

    //this gets called the first time the page is loaded, once it's done setting all the default values
    //seems to have stopped working now?? wtf. calling this stuff from main page also then
    Component.onCompleted: {
        console.debug("SettingsPage Completed...")
        //try to load whichever one is set on startup
        //selectedProfile = objQSettings.getValue("/settings/OcOnStartup/profile",0);
        //reloadProfile();
    }

    function checkHistory(){
        var ItersPassed = 0;
        var db = openDatabaseSync("OPPtimizer", "1.0", "OPPtimizer History", 1000000);
        db.transaction(function(tx) {
            // Create the history database table if it doesn't already exist, composite key on freq/volt
            tx.executeSql('CREATE TABLE IF NOT EXISTS History(Frequency INT, Voltage INT, IterationsPassed INT, SuspectedCrashes INT, PRIMARY KEY(Frequency, Voltage))');
            //total valid testing is sum of testing done at this voltage and this frequency, and also at higher frequencies with same voltage
            var rs = tx.executeSql('SELECT SUM(IterationsPassed) as IterationsPassed FROM History WHERE Frequency>=? AND Voltage=?;', [sliderFreq.value, sliderVolts.value]);
            if (rs.rows.length > 0){
                ItersPassed = rs.rows.item(0).IterationsPassed;
                if (ItersPassed == '') ItersPassed = 0 //got null
            }
        })
        console.debug("History search for exact combo " + sliderFreq.value+ " " +  sliderVolts.value + " shows iters passed: " + ItersPassed)
        cbTestTotal.value = ItersPassed;
    }

    //used to block things from being saved because we can't tell the difference between the user clicking and the system changing things as it loads :(
    function fnBlockEvents(){        
        blockEvents.restart();//make sure we get the full 200ms
    }

    //called on initial load and any time the profile is switched
    function reloadProfile(){
        console.debug("SettingsPage reloading...")
        fnBlockEvents();//don't save anything while loading
        swCustomVolts.checked = objQSettings.getValue("/settings/" + selectedProfile + "/CustomVolts/enabled",false)
        swSmartReflex1.checked = objQSettings.getValue("/settings/" + selectedProfile + "/SmartReflex1/enabled",true)
        swSmartReflex2.checked = objQSettings.getValue("/settings/" + selectedProfile + "/SmartReflex2/enabled",true)
        sliderVolts.value = objQSettings.getValue("/settings/" + selectedProfile + "/CPUVolts/value", objOpptimizerUtils.getDefaultVoltage())
        checkHistory();
        fixOCEnabled();
    }

    //sets OCEnabled switch depending on voltage and frequency. set while being dragged by user so no extra processing here
    function fixOCEnabled(){
        blockEvents.stop(); //no save code in oc on boot switch, not needed.
        badChoice.state = "OK"
        //is this profile supposed to be enabled on boot if possible?
        var enableOnBoot = false;
        if (objQSettings.getValue("/settings/OcOnStartup/profile",-1) == selectedProfile)
            enableOnBoot = true;

        //first find lowest frequency with this voltage and any suspected crashes, don't allow higher freq on boot without retesting
        var MinFreq
        var db = openDatabaseSync("OPPtimizer", "1.0", "OPPtimizer History", 1000000);
        db.transaction(function(tx) {
            var rs = tx.executeSql('SELECT MIN(Frequency) AS MINFREQ FROM History WHERE Voltage=? AND SuspectedCrashes > 0;', [sliderVolts.value]);
            if (rs.rows.length > 0){
                MinFreq = rs.rows.item(0).MINFREQ
                if (MinFreq == '') MinFreq = -1;//i guess you get a null row if using aggregates
            }else{
                //no rows
                MinFreq = -2;
            }
        })
        if (MinFreq <= sliderFreq.value && MinFreq > 0){
            //rejected because crashed at lower freq and same voltage
            swOCEnabled.enabled = false;
            swOCEnabled.checked = false;
            badChoice.state = "BAD"
            console.debug("Disabled and unchecked OC on boot because crashed at same or lower freq and same voltage")
            return;
        }

        if (cbTestTotal.value >= 15000){
            swOCEnabled.enabled = true;
        }
        else{
            //check for any frequency < selected with same voltage and 15k iters and 0 crashes, allow it
            var MaxFreq
            var db = openDatabaseSync("OPPtimizer", "1.0", "OPPtimizer History", 1000000);
            db.transaction(function(tx) {
                var rs = tx.executeSql('SELECT MAX(Frequency) AS MAXFREQ FROM History WHERE Voltage=? AND IterationsPassed >= 15000 AND SuspectedCrashes = 0;', [sliderVolts.value]);
                if (rs.rows.length > 0){
                    MaxFreq = rs.rows.item(0).MAXFREQ
                    if (MaxFreq == '') MaxFreq = -1;
                }else{
                    //no rows
                    MaxFreq = -2;
                }
            })
            console.debug(qsTr("Found previously tested max freq of '%1' at this voltage".arg(MaxFreq)))
            if (sliderFreq.value < MaxFreq){
                swOCEnabled.enabled = true;
            }
            else{
                swOCEnabled.enabled = false;
                console.debug("Disabled and unchecked OC on boot - freq above safely tested range")
            }
        }
    if (swOCEnabled.enabled && enableOnBoot){
        swOCEnabled.checked = true;
        console.debug("checked oc on boot switch")
    }
    else
        swOCEnabled.checked = false;
    }

    function startApply(){
        infoMessageBanner.topMargin = 10
        infoMessageBanner.text = "Applying settings, please wait...";
        var db = openDatabaseSync("OPPtimizer", "1.0", "OPPtimizer History", 1000000);
        db.transaction(function(tx) {
            // Add row for this freq/volt combo if doesn't exist already
            // then set suspected crashes to 1
            tx.executeSql('INSERT OR IGNORE INTO History VALUES(?,?,0,0);', [ sliderFreq.value, sliderVolts.value ]);
            tx.executeSql('UPDATE OR FAIL History SET SuspectedCrashes=1 WHERE Frequency=? AND Voltage=?;', [ sliderFreq.value, sliderVolts.value ]);
        })
        //db is supposed to be commited now, not sure how to flush cache for safety

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
        objOpptimizerUtils.setVDD1SmartReflexStatus(swSmartReflex1.checked);
        objOpptimizerUtils.setVDD2SmartReflexStatus(swSmartReflex2.checked);
        strStatus = objOpptimizerUtils.applySettings(cbFreq.value, cbVolts.value, swCustomVolts.checked);
        if (strStatus.indexOf("Updated") === -1){//some sort of error
            if (strStatus.indexOf("Permission denied") > -1)
                strStatus = "Permission error - Please reinstall this package using /usr/sbin/incept."
            infoMessageBanner.hide();
            infoMessageBanner.timerShowTime = 9000
            infoMessageBanner.text = strStatus;
            infoMessageBanner.show();
            overlayBlocker.visible = false;
            testAborted();
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
        //FOR DEBUGING WE CAN MAKE ALL TESTS REALLY FAST
        //objOpptimizerUtils.testSettings(500); //this branches to a new thread
        //END DEBUGGING
        overlayBenchmarking.visible = true
    }

    InfoBanner{
        id: infoMessageBanner
        z: 99
        topMargin: 10
    }    

    Timer{
        id: playHapticsEventAgain
        onTriggered: testCompleteEffect.start();
        interval: 250
    }

    HapticsEffect{
        id: testCompleteEffect
        attackIntensity: 1.0
        attackTime: 0
        intensity: 1.0
        duration: 50
        fadeTime: 10
        fadeIntensity: 0.5
    }

    Connections {
        target: objOpptimizerUtils
        onRenderedImageOut: {
            testCompleteEffect.start();
            playHapticsEventAgain.start();
            overlayBenchmarking.visible = false
            cbLastTest.value = timeWasted
            lblLastTestTime.text = "Completed in "
            infoMessageBanner.text = "Testing completed. Saving...";
            infoMessageBanner.show();
            badChoice.state = "OK"
            if (swOCEnabled.checked){
                objQSettings.setValue("/settings/OcOnStartup/profile",selectedProfile)
            }else{
                objQSettings.setValue("/settings/OcOnStartup/profile",-1)
            }
            objQSettings.setValue("/settings/" + selectedProfile + "/CPUVolts/value",sliderVolts.value)
            objQSettings.setValue("/settings/" + selectedProfile + "/CPUFreq/value",sliderFreq.value)
            objQSettings.setValue("/settings/" + selectedProfile + "/SmartReflex1/enabled",swSmartReflex1.checked)
            objQSettings.setValue("/settings/" + selectedProfile + "/SmartReflex2/enabled",swSmartReflex2.checked)
            objQSettings.setValue("/settings/" + selectedProfile + "/CustomVolts/enabled",swCustomVolts.checked)
            var db = openDatabaseSync("OPPtimizer", "1.0", "OPPtimizer History", 1000000);
            var totalIter = 0
            db.transaction(function(tx) {
                // Get existing iterations done
                var rs = tx.executeSql('SELECT IterationsPassed FROM History WHERE Frequency=? AND Voltage=?;', [ sliderFreq.value, sliderVolts.value ]);
                if (rs.rows.length > 0){//should have got 1 row
                    // update row to add iterations just done.                    
                    totalIter = parseInt(rs.rows.item(0).IterationsPassed) + sliderTest.value //javascript + sqlite = shit.
                    tx.executeSql('UPDATE History SET IterationsPassed=?, SuspectedCrashes=0 WHERE Frequency=? AND Voltage=?;', [ totalIter, sliderFreq.value, sliderVolts.value]);
                    console.debug("updated this combo from " + rs.rows.item(0).IterationsPassed + " to " + totalIter)
                    //also validate any rows with same voltage but lower freq
                    tx.executeSql('UPDATE History SET IterationsPassed=IterationsPassed+?, SuspectedCrashes=0 WHERE Frequency<=? AND Voltage=?;', [ totalIter, sliderFreq.value, sliderVolts.value]);
                }
            })
            cbTestTotal.value += sliderTest.value;
            fixOCEnabled();//enable oc on boot if > 15k now
            testCompleteEffect.stop();
        }
        onBadImageOut: {
            cbLastTest.visible = false
            badChoice.visible = true;
            lblLastTestTime.text = 'FAILED'
            badChoice.state = "BAD"
            overlayBenchmarking.visible = false
            cbLastTest.value = 0
            infoMessageBanner.text = "Testing FAILED! Invalid data was detected.";
            infoMessageBanner.show();
            infoMessageBanner.timerShowTime = 9000;
            swOCEnabled.checked = false
            swOCEnabled.enabled = false
        }
    }

    //call this if the test is stopped for some reason without crashing to remove suspected crashes from db
    function testAborted(){
        var db = openDatabaseSync("OPPtimizer", "1.0", "OPPtimizer History", 1000000);
        db.transaction(function(tx) {
            tx.executeSql('UPDATE History SET SuspectedCrashes=0 WHERE Frequency=? AND Voltage=?;', [ sliderFreq.value, sliderVolts.value]);
        })
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
                        }else{
                            swOCEnabled.checked = !swOCEnabled.checked
                            if (swOCEnabled.checked){
                                objQSettings.setValue("/settings/OcOnStartup/profile", selectedProfile)
                            }else{
                                objQSettings.setValue("/settings/OcOnStartup/profile", -1)
                            }
                            infoMessageBanner.text = "Saved..."
                            console.debug("saved startup key settings: " + swOCEnabled.checked.toString() + " " + selectedProfile.toString())
                            infoMessageBanner.show();
                            infoMessageBanner.topMargin = 200
                        }
                    }
                }
                Switch {
                    z: 15
                    anchors.fill: parent
                    id: swOCEnabled
                    checked: false
                    enabled: cbTestTotal.value >= 15000
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
                 checked: false
                 onCheckedChanged:{
                    if (!blockEvents.running) {
                        objQSettings.setValue("/settings/" + selectedProfile + "/CustomVolts/enabled",swCustomVolts.checked)
                        if (swCustomVolts.checked){
                            sliderVolts.value = objQSettings.getValue("/settings/" + selectedProfile + "/CPUVolts/value",1350000);
                            infoMessageBanner.text = "SmartReflex will be blocked from further adjusting this voltage only";
                            infoMessageBanner.timerShowTime = 3000;
                            infoMessageBanner.show();
                        }
                    }
                    if (!swCustomVolts.checked) {
                        sliderVolts.value = objOpptimizerUtils.getDefaultVoltage();
                        sliderVolts.enabled = false;
                    }
                    else{
                        sliderVolts.enabled = true;
                        parseInt(objQSettings.getValue("/settings/" + selectedProfile + "/CPUVolts/value", objOpptimizerUtils.getDefaultVoltage()),10)
                    }
                }
            }
        }

        Row {
            id: rowSR1
            anchors{
                topMargin: 10
                top: rowCustomVoltage.bottom
                right: parent.right
                left: parent.left
            }
            Label {
                width: rowSR1.width - rowSR1.spacing - swSmartReflex1.width
                height: swSmartReflex1.height
                text: "SmartReflex VDD1 (CPU)"
            }
            Switch {
                id: swSmartReflex1
                checked: false
                onCheckedChanged:{
                    if (!blockEvents.running) {
                        objQSettings.setValue("/settings/" + selectedProfile + "/SmartReflex1/enabled",swSmartReflex1.checked)
                        objOpptimizerUtils.setVDD1SmartReflexStatus(swSmartReflex1.checked);
                        if (!swSmartReflex1.checked){
                            infoMessageBanner.text = "SmartReflex will be completely disabled for the CPU. The CPU will use a bit more power.";
                            infoMessageBanner.timerShowTime = 3000;
                            infoMessageBanner.show();
                        }
                    }
                }
            }
        }
        Row {
            id: rowSR2
            anchors{
                topMargin: 10
                top: rowSR1.bottom
                right: parent.right
                left: parent.left
            }
            Label {
                width: rowSR2.width - rowSR2.spacing - swSmartReflex2.width
                height: swSmartReflex2.height
                text: "SmartReflex VDD2 (GPU)"
            }
            Switch {
                id: swSmartReflex2
                checked: false
                onCheckedChanged:{
                    if (!blockEvents.running) {
                        objQSettings.setValue("/settings/" + selectedProfile + "/SmartReflex2/enabled",swSmartReflex2.checked)
                        objOpptimizerUtils.setVDD2SmartReflexStatus(swSmartReflex2.checked);
                        if (!swSmartReflex2.checked){
                            infoMessageBanner.text = "SmartReflex will be completely disabled for the GPU. The GPU will use a bit more power.";
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
                top: rowSR2.bottom
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
                if (!blockEvents.running){
                    checkHistory()
                    fixOCEnabled()
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
            onValueChanged: {
                if (value >= 1387500){
                    dangerVolts = true;
                }
                else{
                    dangerVolts = false;
                }
                if (!blockEvents.running){
                    checkHistory()
                    fixOCEnabled()
                }
            }
        }

        Slider {
            id: sliderVolts
            enabled: false
            anchors{
                top: lblOCVolts.bottom
                left: parent.left
                right: parent.right
            }
            minimumValue: 1000000
            maximumValue: 1425000
            value: objQSettings.getValue("/settings/" + selectedProfile + "/CPUVolts/value", objOpptimizerUtils.getDefaultVoltage())
            stepSize: 12500
         }

        Button{
            id: btnApply
            anchors{
                top: sliderVolts.bottom
                horizontalCenter: parent.horizontalCenter
                topMargin: 25
            }
            text: "OPPtimize!"
            width: 200
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
        Item{
            id: badChoice
            anchors{
                left: parent.left
                right: parent.right
                top: btnApply.bottom
            }
            state: "OK"
            height: 0
            states: [
                State {
                    name: "BAD"
                    PropertyChanges { target: badChoice; height: 25 }
                    PropertyChanges { target: lblBadChoice; opacity: 100; anchors.topMargin: 10 }
                },
                State {
                    name: "OK"
                    PropertyChanges { target: badChoice; height: 0 }
                    PropertyChanges { target: lblBadChoice; opacity: 0; anchors.topMargin: 0 }
                }
            ]
            transitions: Transition {
                PropertyAnimation { properties: "height,opacity,anchors.topMargin"; easing.type: Easing.InOutQuad }
            }
            Label {
                id: lblBadChoice
                text: "THIS COMBINATION PROBABLY CRASHED"
                anchors{
                    horizontalCenter: parent.horizontalCenter
                }
            }
        }

        Label {
            id: lblTestLength1
            anchors{
                top: badChoice.bottom
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
                top: badChoice.bottom
                left: cbTest.right
                topMargin: 35
            }
            text: " test iterations"
        }

        Label {
            id: lblTestTotal
            anchors{
                top: sliderTest.bottom
                right: cbTestTotal.left
            }
            text: "Total "
        }

        CountBubble{
            id: cbTestTotal
            anchors{
                right: parent.right
                verticalCenter: lblTestTotal.verticalCenter
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
            text: "Completed in "
            visible: false
        }
        CountBubble{
            id: cbLastTest
            anchors{
                left: lblLastTestTime.right
                verticalCenter: lblLastTestTime.verticalCenter
            }
            value: 0
            largeSized: true
            visible: false
        }
    }//flickable
}//page
