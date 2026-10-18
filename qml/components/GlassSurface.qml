import QtQuick

Rectangle {
    id: surface
    radius: 24
    color: "#b91a2636"
    border.width: 1
    border.color: "#70ffffff"
    clip: true

    Rectangle {
        anchors.fill: parent
        anchors.margins: 1
        radius: Math.max(0, parent.radius - 1)
        color: "transparent"
        border.width: 1
        border.color: "#16ffffff"
    }

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: radius
        height: 1
        radius: 1
        color: "#55ffffff"
    }
}
