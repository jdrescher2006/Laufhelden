import QtQuick 2.0
import org.nemomobile.dbus 2.0

Item {
    property bool enabled: false
    function request(){
        var method = "req_display"+(enabled?"":"_cancel")+"_blanking_pause";
        //console.log('screen blank:', enabled, method);
        dbif.call(method, [])
    }

    onEnabledChanged: {
        request();
    }

    DBusInterface {
        id: dbif

        service: "com.nokia.mce"
        path: "/com/nokia/mce/request"
        iface: "com.nokia.mce.request"

        bus: DBusInterface.SystemBus
    }
    Timer { //request seems to time out after a while:
        running: parent.enabled
        interval: 15000 //minimum setting for blank display is 15s
        repeat: true
        onTriggered: {
            if(parent.enabled) {
                parent.request()
            }
        }
    }

    Component.onDestruction: {
        if(enabled){
            enabled=false
        }
    }
}
