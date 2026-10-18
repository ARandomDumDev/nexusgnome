import QtQuick
import QtQuick.Window
import QtQuick.Layouts

Window {
    id: root
    visible: true
    width: 660
    height: 112
    x: (Screen.width - width) / 2
    y: Screen.height - height - 18
    color: "transparent"
    flags: Qt.Tool | Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint
    title: "NexusGNOME Dock"

    property var apps: [
        { name: "Files", glyph: "▰", color: "#70b7ff" },
        { name: "Browser", glyph: "◉", color: "#57d7e8" },
        { name: "Terminal", glyph: ">_", color: "#a7b7ca" },
        { name: "Settings", glyph: "⚙", color: "#d7e4f4" },
        { name: "Music", glyph: "♫", color: "#77aaff" },
        { name: "NexusNet", glyph: "✳", color: "#5bd5ef" },
        { name: "Trash", glyph: "▤", color: "#c3cedc" }
    ]

    Rectangle {
        anchors.fill: parent
        anchors.margins: 5
        radius: 30
        color: "#c915202d"
        border.width: 1
        border.color: "#70ffffff"

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 18
            height: 1
            radius: 1
            color: "#65ffffff"
        }

        RowLayout {
            anchors.centerIn: parent
            spacing: 10

            Repeater {
                model: root.apps

                delegate: Item {
                    id: item
                    required property var modelData
                    Layout.preferredWidth: 68
                    Layout.preferredHeight: 78

                    property bool hovered: mouse.containsMouse

                    Rectangle {
                        id: icon
                        width: item.hovered ? 58 : 50
                        height: width
                        radius: 15
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: item.hovered ? 1 : 9
                        color: "#252f4054"
                        border.width: 1
                        border.color: "#55ffffff"

                        Behavior on width {
                            NumberAnimation { duration: 130; easing.type: Easing.OutCubic }
                        }
                        Behavior on y {
                            NumberAnimation { duration: 130; easing.type: Easing.OutCubic }
                        }

                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: 1
                            radius: 14
                            gradient: Gradient {
                                GradientStop { position: 0.0; color: "#35ffffff" }
                                GradientStop { position: 0.48; color: "#08ffffff" }
                                GradientStop { position: 1.0; color: "#10000000" }
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: modelData.glyph
                            color: modelData.color
                            font.pixelSize: modelData.glyph === ">_" ? 23 : 29
                            font.bold: true
                        }

                        MouseArea {
                            id: mouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: console.log("Dock item:", modelData.name)
                        }
                    }

                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom
                        width: 4
                        height: 4
                        radius: 2
                        color: "#e5f3ff"
                        opacity: item.hovered ? 1 : 0

                        Behavior on opacity {
                            NumberAnimation { duration: 100 }
                        }
                    }

                    Rectangle {
                        visible: item.hovered
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: -21
                        width: label.implicitWidth + 18
                        height: 25
                        radius: 8
                        color: "#ed17212e"
                        border.width: 1
                        border.color: "#50ffffff"

                        Text {
                            id: label
                            anchors.centerIn: parent
                            text: modelData.name
                            color: "#f4f8ff"
                            font.pixelSize: 11
                        }
                    }
                }
            }
        }
    }
}
