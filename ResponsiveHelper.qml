import QtQuick 2.2
import QtQuick.Window 2.0

Item {
    id: root
    width: defaultBarWidth
    height: 0

    //**********************
    // Public input properties
    //
    // Load or unloads the helper window
    property bool active: true

    // Window element of the target application to test
    property Window targetWindow

    // Shows or hide responsive toolbar
    property bool showResponiveToolbar: true

    // List of presets to display
    property ListModel presets: ListModel {}
    // Index of the initial preset used
    property int initialPreset: -1
    // Current preset index
    property int currentPreset: -1

    // List of custom actions
    property ListModel actions: ListModel {}

    // List of custom actions
    property alias extraContent: extraContentColumn.children

    //**********************
    // Public properties
    //
    // Custom pixel density value
    property real pixelDensity: Screen.pixelDensity
    // Custom DPI value
    readonly property int dpi: pixelDensity * 25.4

    // Initial application window settings
    readonly property int initialWidth: d.initialWidth
    readonly property int initialHeight: d.initialHeight
    readonly property int initialPixelDensity: d.initialPixelDensity

    // Bar width
    readonly property int defaultBarWidth: 125

    //**********************
    // Signals
    //
    signal actionClicked(int actionIndex)

    //**********************
    // Public functions
    //
    function setDpi(dpiValue) {
        pixelDensity = dpiValue / 25.4;
    }

    function setWindowWidth(value) {
        var newWidth = (1*value).toFixed(0);
        var diff = value - targetWindow.width;

        // Move the application window to keep our window at the same spot when possible
        if (root.x < targetWindow.x / 2) {
            var availableSpace = Screen.desktopAvailableWidth - targetWindow.x - targetWindow.width;
            if (diff > 0 && availableSpace <= diff)
                targetWindow.x -= diff - availableSpace;
        }
        else {
            if (diff < 0)
                targetWindow.x -= diff;
            else if (targetWindow.x > 0)
                targetWindow.x = Math.max(0, targetWindow.x - diff)
        }

        targetWindow.width = newWidth;
    }

    function setWindowHeight(value) {
        var newHeight = (1*value).toFixed(0);
        targetWindow.height = newHeight;
    }

    //**********************
    // Internal logic
    //
    onTargetWindowChanged: {
        if (initialPreset >= 0) {
            d.setPreset(initialPreset);
        }

        d.initialWidth = targetWindow.width;
        d.initialHeight = targetWindow.height;
        d.initialPixelDensity = root.pixelDensity;
    }

    onDpiChanged: {
        var preset = presets.get(root.currentPreset);
        if (preset && root.dpi !== preset.dpi)
            root.currentPreset = -1
    }

    onCurrentPresetChanged: {
        d.setPreset(currentPreset);
    }

    QtObject {
        id: d
        property int initialWidth
        property int initialHeight
        property real initialPixelDensity: Screen.pixelDensity

        property int textHeight: 20

        function updateCurrentPreset() {
            var preset = presets.get(root.currentPreset);
            if (!preset || (targetWindow.width !== preset.width || targetWindow.height !== preset.height)) {
                for (var i = 0; i < presets.count; ++i) {
                    var p = presets.get(i)
                    if (p.width === targetWindow.width && p.height === targetWindow.height) {
                        root.currentPreset = i
                        return
                    }
                }
                root.currentPreset = -1
            }
        }

        function setPreset(index) {
            if (index < 0 || index > presets.count-1) {
                return;
            }

            if (root.currentPreset !== index) {
                root.currentPreset = index
                return;
            }

            setWindowWidth(presets.get(index).width)
            setWindowHeight(presets.get(index).height)

            if (presets.get(index).dpi)
                setDpi(presets.get(index).dpi)
        }
    }

    Connections {
        target: targetWindow
        onWidthChanged: { d.updateCurrentPreset() }
        onHeightChanged: { d.updateCurrentPreset() }
    }

    Loader {
        active: root.active && root.targetWindow
        sourceComponent: responsiveHelperComponent
    }

    Column {
        id: extraContentColumn
        width: parent.width
        visible: false
    }

    //**********************
    // GUI
    //
    Component {
        id: responsiveHelperComponent

        Window {
            id: helperWindow
            visible: true
            x: targetWindow.x + root.x + windowOffset.x
            y: targetWindow.y + root.y + windowOffset.y
            width: root.width
            height: root.height
            color: "#202020"
            flags: Qt.FramelessWindowHint

            property point windowOffset: Qt.point(0, 0)

            Component.onCompleted: {
                root.width = Qt.binding(function() { return barColumn.width; });
                root.height = Qt.binding(function() { return barColumn.height; });
            }

            Connections {
                target: targetWindow
                onClosing: {
                    helperWindow.close();
                }
                onActiveChanged: {
                    helperWindow.raise();
                }
            }

            Connections {
                target: root
                onTargetWindowChanged: {
                    dpiEdit.bind();
                    widthEdit.bind();
                    heightEdit.bind();
                }
            }

            Column {
                id: barColumn
                spacing: 1
                width: root.width

                Component.onCompleted: {
                    extraContentColumn.parent = barColumn
                    extraContentColumn.visible = true
                }

                MouseArea {
                    id: mouseArea
                    width: parent.width
                    height: 20

                    property point originMousePosition

                    onPressed: {
                        originMousePosition.x = mouseX
                        originMousePosition.y = mouseY
                    }
                    onPositionChanged: {
                        helperWindow.windowOffset.x += mouseX - originMousePosition.x
                        helperWindow.windowOffset.y += mouseY - originMousePosition.y
                    }

                    Grid {
                        anchors.centerIn: parent
                        columns: 5
                        rows: 2
                        spacing: 3
                        Repeater { model: 10; Rectangle { width: 4; height: width; radius: width/2 } }
                    }
                }

                //---------------
                // @Button
                Rectangle {
                    color: baseColor
                    height: 30
                
                    property bool selected: false
                    property color baseColor: "#555"
                
                    signal clicked
                
                    Rectangle {
                        anchors.fill: parent
                        color: "#FFF"
                        opacity: 0.3
                        visible: parent.selected
                    }
                
                    Text {
                        text: parent.text
                        anchors.centerIn: parent
                        color: parent.selected ? "#FFF" : "#EEE"
                    }
                
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            parent.clicked()
                        }
                        onPressed: {
                            parent.color = Qt.lighter(parent.baseColor)
                        }
                        onReleased: {
                            parent.color = parent.baseColor
                        }
                    }
                    //---- Redefinitions ----
                    property string text: "Hide"
                    width: parent.width
                    onClicked: {
                        helperWindow.close()
                    }
                }

                Item {
                    width: parent.width
                    height: 10
                }

                //***************************************************************************
                // Responsive-related settings
                //
                Column {
                    width: parent.width
                    height: visible ? childrenRect.height : 0
                    visible: root.showResponiveToolbar
                    spacing: 1

                    //---------------
                    // @Button
                    Rectangle {
                        color: baseColor
                        height: 30
                    
                        property bool selected: false
                        property color baseColor: "#555"
                    
                        signal clicked
                    
                        Rectangle {
                            anchors.fill: parent
                            color: "#FFF"
                            opacity: 0.3
                            visible: parent.selected
                        }
                    
                        Text {
                            text: parent.text
                            anchors.centerIn: parent
                            color: parent.selected ? "#FFF" : "#EEE"
                        }
                    
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                parent.clicked()
                            }
                            onPressed: {
                                parent.color = Qt.lighter(parent.baseColor)
                            }
                            onReleased: {
                                parent.color = parent.baseColor
                            }
                        }
                        //---- Redefinitions ----
                        width: parent.width
                        property string text: (targetWindow.height > targetWindow.width) ? "Landscape" : "Portrait"
                        onClicked: {
                            var height = targetWindow.height
                            root.setWindowHeight(root.targetWindow.width)
                            root.setWindowWidth(height)
                        }
                    }

                    //---------------
                    // @Button
                    Rectangle {
                        color: baseColor
                        height: 30
                    
                        property bool selected: false
                        property color baseColor: "#555"
                    
                        signal clicked
                    
                        Rectangle {
                            anchors.fill: parent
                            color: "#FFF"
                            opacity: 0.3
                            visible: parent.selected
                        }
                    
                        Text {
                            text: parent.text
                            anchors.centerIn: parent
                            color: parent.selected ? "#FFF" : "#EEE"
                        }
                    
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                parent.clicked()
                            }
                            onPressed: {
                                parent.color = Qt.lighter(parent.baseColor)
                            }
                            onReleased: {
                                parent.color = parent.baseColor
                            }
                        }
                        //---- Redefinitions ----
                        property string text: "Reset"
                        width: parent.width
                        onClicked: {
                            root.setWindowWidth(d.initialWidth)
                            root.setWindowHeight(d.initialHeight)
                            root.pixelDensity = d.initialPixelDensity
                        }
                    }

                    //**********************
                    // DPI
                    //
                    Text {
                        text: "DPI"
                        color: "white"
                        height: d.textHeight
                        width: parent.width
                        wrapMode: Text.Wrap
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignBottom
                    }

                    Row {
                        width: parent.width
                        height: childrenRect.height
                        spacing: 1

                        //---------------
                        // @Button
                        Rectangle {
                            color: baseColor
                        
                            property bool selected: false
                            property color baseColor: "#555"
                        
                            signal clicked
                        
                            Rectangle {
                                anchors.fill: parent
                                color: "#FFF"
                                opacity: 0.3
                                visible: parent.selected
                            }
                        
                            Text {
                                text: parent.text
                                anchors.centerIn: parent
                                color: parent.selected ? "#FFF" : "#EEE"
                            }
                        
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    parent.clicked()
                                }
                                onPressed: {
                                    parent.color = Qt.lighter(parent.baseColor)
                                }
                                onReleased: {
                                    parent.color = parent.baseColor
                                }
                            }
                            //---- Redefinitions ----
                            height: dpiEdit.height
                            width: parent.width / 4
                            property string text: "-"
                            onClicked: {
                                root.pixelDensity /= 1.3
                            }
                        }
                        //---------------
                        // @TextField
                        Rectangle {
                            color: "#555"
                            height: 30
                        
                            property string text
                        
                            signal discarded()
                            signal editingFinished(string value)
                        
                            TextInput {
                                anchors.fill: parent
                                horizontalAlignment: TextEdit.AlignHCenter
                                verticalAlignment: TextEdit.AlignVCenter
                                color: "#EEE"
                                font.bold: true
                                validator: IntValidator{bottom: 0; top: 5000;}
                                property Item componentRoot: parent
                        
                                onFocusChanged: {
                                    parent.color = focus ? "#999" : "#555"
                                }
                                Component.onCompleted: {
                                    bind()
                                    validator.bottom = parent.minimum
                                    validator.top = parent.maximum
                                }
                                Keys.onEscapePressed: {
                                    focus = false
                                    bind()
                                }
                                onEditingFinished: {
                                    focus = false
                                    parent.editingFinished(text)
                                    bind()
                                }
                                function bind() {
                                    text = Qt.binding(function() { return parent.text } )
                                }
                            }
                            //---- Redefinitions ----
                            id: dpiEdit
                            width: parent.width / 2
                            text: root.dpi.toFixed(0)
                            property int minimum: 1
                            property int maximum: 999
                            onEditingFinished: {
                                root.setDpi(value)
                            }
                        }

                        //---------------
                        // @Button
                        Rectangle {
                            color: baseColor
                        
                            property bool selected: false
                            property color baseColor: "#555"
                        
                            signal clicked
                        
                            Rectangle {
                                anchors.fill: parent
                                color: "#FFF"
                                opacity: 0.3
                                visible: parent.selected
                            }
                        
                            Text {
                                text: parent.text
                                anchors.centerIn: parent
                                color: parent.selected ? "#FFF" : "#EEE"
                            }
                        
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    parent.clicked()
                                }
                                onPressed: {
                                    parent.color = Qt.lighter(parent.baseColor)
                                }
                                onReleased: {
                                    parent.color = parent.baseColor
                                }
                            }
                            //---- Redefinitions ----
                            height: dpiEdit.height
                            width: parent.width / 4
                            property string text: "+"
                            onClicked: {
                                root.pixelDensity *= 1.3
                            }
                        }
                    }

                    //**********************
                    // Width
                    //
                    Text {
                        text: "Width"
                        color: "white"
                        height: d.textHeight
                        width: parent.width
                        wrapMode: Text.Wrap
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignBottom
                    }

                    Row {
                        id: row
                        width: parent.width
                        height: childrenRect.height
                        spacing: 1

                        //---------------
                        // @Button
                        Rectangle {
                            color: baseColor
                        
                            property bool selected: false
                            property color baseColor: "#555"
                        
                            signal clicked
                        
                            Rectangle {
                                anchors.fill: parent
                                color: "#FFF"
                                opacity: 0.3
                                visible: parent.selected
                            }
                        
                            Text {
                                text: parent.text
                                anchors.centerIn: parent
                                color: parent.selected ? "#FFF" : "#EEE"
                            }
                        
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    parent.clicked()
                                }
                                onPressed: {
                                    parent.color = Qt.lighter(parent.baseColor)
                                }
                                onReleased: {
                                    parent.color = parent.baseColor
                                }
                            }
                            //---- Redefinitions ----
                            height: widthEdit.height
                            width: parent.width / 4
                            property string text: "-"
                            onClicked: {
                                root.setWindowWidth(root.targetWindow.width / 1.1)
                            }
                        }
                        //---------------
                        // @TextField
                        Rectangle {
                            color: "#555"
                            height: 30
                        
                            property string text
                        
                            signal discarded()
                            signal editingFinished(string value)
                        
                            TextInput {
                                anchors.fill: parent
                                horizontalAlignment: TextEdit.AlignHCenter
                                verticalAlignment: TextEdit.AlignVCenter
                                color: "#EEE"
                                font.bold: true
                                validator: IntValidator{bottom: 0; top: 5000;}
                                property Item componentRoot: parent
                        
                                onFocusChanged: {
                                    parent.color = focus ? "#999" : "#555"
                                }
                                Component.onCompleted: {
                                    bind()
                                    validator.bottom = parent.minimum
                                    validator.top = parent.maximum
                                }
                                Keys.onEscapePressed: {
                                    focus = false
                                    bind()
                                }
                                onEditingFinished: {
                                    focus = false
                                    parent.editingFinished(text)
                                    bind()
                                }
                                function bind() {
                                    text = Qt.binding(function() { return parent.text } )
                                }
                            }
                            //---- Redefinitions ----
                            id: widthEdit
                            width: parent.width / 2
                            property int minimum: 10
                            property int maximum: 5000
                            text: root.targetWindow.width

                            onEditingFinished: {
                                root.setWindowWidth(value)
                            }
                        }

                        //---------------
                        // @Button
                        Rectangle {
                            color: baseColor
                        
                            property bool selected: false
                            property color baseColor: "#555"
                        
                            signal clicked
                        
                            Rectangle {
                                anchors.fill: parent
                                color: "#FFF"
                                opacity: 0.3
                                visible: parent.selected
                            }
                        
                            Text {
                                text: parent.text
                                anchors.centerIn: parent
                                color: parent.selected ? "#FFF" : "#EEE"
                            }
                        
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    parent.clicked()
                                }
                                onPressed: {
                                    parent.color = Qt.lighter(parent.baseColor)
                                }
                                onReleased: {
                                    parent.color = parent.baseColor
                                }
                            }
                            //---- Redefinitions ----
                            height: widthEdit.height
                            width: parent.width / 4
                            property string text: "+"
                            onClicked: {
                                root.setWindowWidth(root.targetWindow.width * 1.1)
                            }
                        }
                    }

                    //**********************
                    // Height
                    //
                    Text {
                        text: "Height"
                        color: "white"
                        width: parent.width
                        height: d.textHeight
                        wrapMode: Text.Wrap
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignBottom
                    }

                    Row {
                        width: parent.width
                        height: childrenRect.height
                        spacing: 1

                        //---------------
                        // @Button
                        Rectangle {
                            color: baseColor
                        
                            property bool selected: false
                            property color baseColor: "#555"
                        
                            signal clicked
                        
                            Rectangle {
                                anchors.fill: parent
                                color: "#FFF"
                                opacity: 0.3
                                visible: parent.selected
                            }
                        
                            Text {
                                text: parent.text
                                anchors.centerIn: parent
                                color: parent.selected ? "#FFF" : "#EEE"
                            }
                        
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    parent.clicked()
                                }
                                onPressed: {
                                    parent.color = Qt.lighter(parent.baseColor)
                                }
                                onReleased: {
                                    parent.color = parent.baseColor
                                }
                            }
                            //---- Redefinitions ----
                            height: heightEdit.height
                            width: parent.width / 4
                            property string text: "-"
                            onClicked: {
                                root.setWindowHeight(root.targetWindow.height / 1.1)
                            }
                        }
                        //---------------
                        // @TextField
                        Rectangle {
                            color: "#555"
                            height: 30
                        
                            property string text
                        
                            signal discarded()
                            signal editingFinished(string value)
                        
                            TextInput {
                                anchors.fill: parent
                                horizontalAlignment: TextEdit.AlignHCenter
                                verticalAlignment: TextEdit.AlignVCenter
                                color: "#EEE"
                                font.bold: true
                                validator: IntValidator{bottom: 0; top: 5000;}
                                property Item componentRoot: parent
                        
                                onFocusChanged: {
                                    parent.color = focus ? "#999" : "#555"
                                }
                                Component.onCompleted: {
                                    bind()
                                    validator.bottom = parent.minimum
                                    validator.top = parent.maximum
                                }
                                Keys.onEscapePressed: {
                                    focus = false
                                    bind()
                                }
                                onEditingFinished: {
                                    focus = false
                                    parent.editingFinished(text)
                                    bind()
                                }
                                function bind() {
                                    text = Qt.binding(function() { return parent.text } )
                                }
                            }
                            //---- Redefinitions ----
                            id: heightEdit
                            width: parent.width / 2
                            text: root.targetWindow.height
                            property int minimum: 10
                            property int maximum: 5000

                            onEditingFinished: {
                                root.setWindowHeight(value)
                            }
                        }

                        //---------------
                        // @Button
                        Rectangle {
                            color: baseColor
                        
                            property bool selected: false
                            property color baseColor: "#555"
                        
                            signal clicked
                        
                            Rectangle {
                                anchors.fill: parent
                                color: "#FFF"
                                opacity: 0.3
                                visible: parent.selected
                            }
                        
                            Text {
                                text: parent.text
                                anchors.centerIn: parent
                                color: parent.selected ? "#FFF" : "#EEE"
                            }
                        
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    parent.clicked()
                                }
                                onPressed: {
                                    parent.color = Qt.lighter(parent.baseColor)
                                }
                                onReleased: {
                                    parent.color = parent.baseColor
                                }
                            }
                            //---- Redefinitions ----
                            height: heightEdit.height
                            width: parent.width / 4
                            property string text: "+"
                            onClicked: {
                                root.setWindowHeight(root.targetWindow.height * 1.1)
                            }
                        }
                    }

                    //**********************
                    // Presets
                    //
                    Text {
                        text: "Presets"
                        width: parent.width
                        height: d.textHeight
                        color: "white"
                        wrapMode: Text.Wrap
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignBottom
                        visible: root.presets.count > 0
                    }

                    Repeater {
                        model: root.presets

                        //---------------
                        // @Button
                        Rectangle {
                            color: baseColor
                            height: 30
                        
                            property color baseColor: "#555"
                        
                            signal clicked
                        
                            Rectangle {
                                anchors.fill: parent
                                color: "#FFF"
                                opacity: 0.3
                                visible: parent.selected
                            }
                        
                            Text {
                                text: parent.text
                                anchors.centerIn: parent
                                color: parent.selected ? "#FFF" : "#EEE"
                            }
                        
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    parent.clicked()
                                }
                                onPressed: {
                                    parent.color = Qt.lighter(parent.baseColor)
                                }
                                onReleased: {
                                    parent.color = parent.baseColor
                                }
                            }
                            //---- Redefinitions ----
                            width: parent.width
                            property string text: {
                                var label = model.width + " x " + model.height;
                                if (model.dpi)
                                    label += " (" + model.dpi + "dpi)";

                                if (root.currentPreset === index)
                                    return "[" + label + "]";

                                return label;
                            }
                            property bool selected: root.currentPreset === index
                            onClicked: {
                                root.currentPreset = index;
                            }
                        }
                    }
                }

                //**********************
                // Actions & Buttons
                //
                Text {
                    text: "Actions"
                    width: parent.width
                    height: d.textHeight
                    color: "white"
                    wrapMode: Text.Wrap
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignBottom
                    visible: root.actions.count > 0
                }

                Repeater {
                    model: root.actions

                    //---------------
                    // @Button
                    Rectangle {
                        color: baseColor
                        height: 30
                    
                        property bool selected: false
                        property color baseColor: "#555"
                    
                        signal clicked
                    
                        Rectangle {
                            anchors.fill: parent
                            color: "#FFF"
                            opacity: 0.3
                            visible: parent.selected
                        }
                    
                        Text {
                            text: parent.text
                            anchors.centerIn: parent
                            color: parent.selected ? "#FFF" : "#EEE"
                        }
                    
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                parent.clicked()
                            }
                            onPressed: {
                                parent.color = Qt.lighter(parent.baseColor)
                            }
                            onReleased: {
                                parent.color = parent.baseColor
                            }
                        }
                        //---- Redefinitions ----
                        width: parent.width
                        property string text: model.text
                        onClicked: {
                            root.actionClicked(index);
                        }
                    }
                }
            }
        }
    }
}
