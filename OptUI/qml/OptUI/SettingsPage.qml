// import QtQuick 1.0 // to target S60 5th Edition or Maemo 5
import QtQuick 1.1
import com.nokia.meego 1.0
import com.nokia.extras 1.0

Page{
    anchors.margins: UiConstants.DefaultMargin

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
        contentHeight: 800

        Row {
             id: rowEnabled
             anchors{
                 topMargin: 10
                 top: parent.top
                 right: parent.right
                 left: parent.left
             }
             Label {
                 width: rowEnabled.width - rowEnabled.spacing - swOCEnabled.width
                 height: swOCEnabled.height
                 verticalAlignment: Text.AlignVCenter
                 text: "Apply on Startup"

             }
             Switch {
                 id: swOCEnabled
                 checked: false //objQSettings.getValue("/settings/OcOnStartup/enabled",true)
                 enabled: false //not implemented
                 onCheckedChanged:{//wow this crappy harmattan QML is missing both the pressed and clicked events and properties for switches.
                    if (!blockEvents.running) {//so we get to use this instead. (onChecked fires too early -- when the component is created)
                        objQSettings.setValue("/settings/OcOnStartup/enabled",swOCEnabled.checked)
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
                 text: "Custom Voltage"
             }
             Switch {
                 id: swCustomVolts
                 checked: objQSettings.getValue("/settings/CustomVolts/enabled",true)
                 onCheckedChanged:{
                    if (!blockEvents.running) {
                        objQSettings.setValue("/settings/CustomVolts/enabled",swCustomVolts.checked)
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
                enabled: false
                onCheckedChanged:{
                    if (!blockEvents.running) {
                        objQSettings.setValue("/settings/SmartReflex/enabled",swSmartReflex.checked)
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
            text: "Frequency (MHz): "
        }
        CountBubble{
            id: cbFreq
            anchors.left: lblFreq.right
            anchors.verticalCenter: lblFreq.verticalCenter
            value: sliderFreq.value
            largeSized: true
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
                 value: 1000
                 stepSize: 5
         }

        Label {
            id: lblOCVolts
            anchors{
                top: sliderFreq.bottom
                left: parent.left
            }
            text: "Voltage (uV): "
        }

        CountBubble{
            id: cbVolts
            anchors.left: lblOCVolts.right
            anchors.verticalCenter: lblOCVolts.verticalCenter
            value: sliderVolts.value
            largeSized: true
            enabled: swCustomVolts.checked
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
            maximumValue: 1387500
            value: 1375000
            stepSize: 12500
         }

        Button{
            id: btnApply
            anchors.top: sliderVolts.bottom
            anchors.right: parent.right
            text: "Apply"
            onClicked: {
                var strError;
                strError = objOpptimizerUtils.applySettings(cbFreq.value, cbVolts.value, null, null);
                infoMessageBanner.text = strError;
                infoMessageBanner.show();
                //refresh status
                //statusPage.refresh(); (call via c++?)
            }
        }
    }//flickable
    InfoBanner{
        id: infoMessageBanner
        z: 99
        topMargin: 10
    }
}//page
