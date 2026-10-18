import QtQuick
import QtQuick.Shapes

// One dock slot: glass tile + vector icon + running dot + tooltip.
// The dock drives `magnify` (1.0 = resting) and `hovered`.
Item {
    id: item
    required property string name
    required property color accent
    required property string iconPath   // SVG path on a 24px grid
    property bool running: false
    property real magnify: 1
    property bool hovered: false
    property real peak: 0.42
    property int tileSize: 50
    property real bounce: 0

    function launch() { console.log("Dock item:", name); hop.restart() }

    SequentialAnimation {
        id: hop
        NumberAnimation { target: item; property: "bounce"; to: 18; duration: 160; easing.type: Easing.OutQuad }
        NumberAnimation { target: item; property: "bounce"; to: 0;  duration: 380; easing.type: Easing.OutBounce }
    }

    Rectangle {
        id: tile
        width: item.tileSize; height: item.tileSize
        x: (item.width - width) / 2
        y: item.height - 15 - height - item.bounce - (item.magnify - 1) * 6
        radius: 15
        scale: item.magnify
        transformOrigin: Item.Bottom
        antialiasing: true
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.30 + 0.25 * Math.min(1, (item.magnify - 1) / item.peak))
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.alpha(item.accent, 0.42) }
            GradientStop { position: 1.0; color: Qt.alpha(item.accent, 0.14) }
        }

        Rectangle {
            anchors.fill: parent
            anchors.margins: 1.5
            anchors.bottomMargin: parent.height * 0.5
            radius: 13.5
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#52ffffff" }
                GradientStop { position: 1.0; color: "#00ffffff" }
            }
        }

        Shape {
            anchors.centerIn: parent
            width: 24; height: 24
            scale: 1.15
            preferredRendererType: Shape.CurveRenderer
            ShapePath {
                strokeColor: Qt.lighter(item.accent, 1.55)
                strokeWidth: 1.7
                fillColor: "transparent"
                capStyle: ShapePath.RoundCap
                joinStyle: ShapePath.RoundJoin
                PathSvg { path: item.iconPath }
            }
        }
    }

    Rectangle {
        visible: item.running
        width: 4; height: 4; radius: 2
        x: (item.width - width) / 2
        y: item.height - 9
        color: "#e9f3ff"; opacity: 0.85
    }

    Rectangle {
        width: label.implicitWidth + 20; height: 26; radius: 10
        x: (item.width - width) / 2
        y: tile.y - (item.magnify - 1) * tile.height - height - 10
        color: "#e6141c28"
        border.width: 1; border.color: "#40ffffff"
        opacity: item.hovered ? 1 : 0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 120 } }
        Text {
            id: label
            anchors.centerIn: parent
            text: item.name
            color: "#f4f8ff"
            font.pixelSize: 12; font.weight: Font.Medium
            renderType: Text.QtRendering
        }
    }
}
