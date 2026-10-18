import QtQuick
import QtQuick.Window
import QtQuick.Shapes

// NexusGNOME Dock — Liquid Glass style
// Requires Qt 6.6+ (CurveRenderer for crisp vector icons; older Qt falls back to default renderer).
Window {
    id: root
    visible: true
    color: "transparent"
    title: "NexusGNOME Dock"
    flags: Qt.Tool | Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint | Qt.WindowDoesNotAcceptFocus

    // ---- Tunables -------------------------------------------------------
    readonly property int slot: 72          // width of one dock slot
    readonly property int iconSize: 50      // resting tile size
    readonly property int padX: 18          // inner horizontal padding of the glass
    readonly property int pillH: 80
    readonly property int pillRadius: 32
    readonly property real peak: 0.42       // max extra magnification (0.42 = 142%)
    readonly property real stroke: 1.7      // icon line weight (24px grid)

    property var apps: [
        { name: "Files",    accent: "#5aa9ff", running: true,
          path: "M20 20a2 2 0 0 0 2-2V8a2 2 0 0 0-2-2h-7.9a2 2 0 0 1-1.7-.9l-.8-1.2A2 2 0 0 0 7.9 3H4a2 2 0 0 0-2 2v13a2 2 0 0 0 2 2Z" },
        { name: "Browser",  accent: "#43d3e6", running: true,
          path: "M12 2a10 10 0 1 0 0 20a10 10 0 1 0 0-20M2 12h20M12 2a14.5 14.5 0 0 0 0 20a14.5 14.5 0 0 0 0-20" },
        { name: "Terminal", accent: "#9fb0c6", running: false,
          path: "M4 17l6-6-6-6M12 19h8" },
        { name: "Settings", accent: "#c4d4ea", running: false,
          path: "M21 4h-7M10 4H3M21 12h-9M8 12H3M21 20h-5M12 20H3M14 2v4M8 10v4M16 18v4" },
        { name: "Music",    accent: "#6f9dff", running: false,
          path: "M9 18V5l12-2v13M6 15a3 3 0 1 0 0 6a3 3 0 1 0 0-6M18 13a3 3 0 1 0 0 6a3 3 0 1 0 0-6" },
        { name: "NexusNet", accent: "#4fd9f2", running: false,
          path: "M12 20h.01M2 8.8a15 15 0 0 1 20 0M5 12.9a10 10 0 0 1 14 0M8.5 16.4a5 5 0 0 1 7 0" },
        { name: "Trash",    accent: "#b4c0d0", running: false,
          path: "M3 6h18M19 6v14c0 1-1 2-2 2H7c-1 0-2-1-2-2V6M8 6V4c0-1 1-2 2-2h4c1 0 2 1 2 2v2M10 11v6M14 11v6" }
    ]

    // Window = glass + room for shadow, magnified icons and tooltips.
    readonly property int pillW: slot * apps.length + padX * 2
    width: pillW + 80
    height: 150
    x: (Screen.width - width) / 2
    y: Screen.height - height - 6

    Item {
        id: dock
        width: root.pillW
        height: root.pillH
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 20

        // Magnification state: one pointer value drives every icon.
        property real lens: hit.hovered ? 1 : 0
        property real px: 0
        Behavior on lens { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
        Behavior on px {
            enabled: dock.lens > 0.6
            SpringAnimation { spring: 5; damping: 0.55; epsilon: 0.2 }
        }

        // ---- Soft ambient shadow (cheap stacked layers, no blur effect) ----
        Repeater {
            model: 6
            Rectangle {
                required property int index
                anchors.fill: parent
                anchors.margins: -(index + 1) * 4
                anchors.topMargin: -(index + 1) * 3
                anchors.bottomMargin: -(index + 1) * 5
                y: 8
                radius: root.pillRadius + (index + 1) * 4
                color: Qt.rgba(0, 0, 0, 0.05 - index * 0.007)
            }
        }

        // ---- Glass body: painted once, cached as a texture -----------------
        Canvas {
            id: glass
            anchors.fill: parent
            renderTarget: Canvas.FramebufferObject
            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()

            onPaint: {
                const ctx = getContext("2d")
                ctx.reset()
                const w = width, h = height, r = root.pillRadius

                function path(inset) {
                    ctx.beginPath()
                    ctx.roundedRect(inset, inset, w - inset * 2, h - inset * 2,
                                    r - inset, r - inset)
                }

                // Base tint keeps the dock legible on any wallpaper.
                path(0)
                ctx.fillStyle = "rgba(18, 26, 40, 0.50)"
                ctx.fill()

                // Volume: bright top, clear middle, soft bounce light at the bottom.
                path(0)
                let body = ctx.createLinearGradient(0, 0, 0, h)
                body.addColorStop(0.00, "rgba(255,255,255,0.26)")
                body.addColorStop(0.45, "rgba(255,255,255,0.05)")
                body.addColorStop(0.80, "rgba(255,255,255,0.04)")
                body.addColorStop(1.00, "rgba(255,255,255,0.16)")
                ctx.fillStyle = body
                ctx.fill()

                // Edge lensing: stacked inset strokes fake the bent-light band
                // that glass shows right at its border.
                ctx.lineWidth = 1.4
                for (let i = 0; i < 7; i++) {
                    path(1.6 + i * 1.3)
                    ctx.strokeStyle = "rgba(255,255,255," + (0.13 * Math.pow(1 - i / 7, 2)).toFixed(3) + ")"
                    ctx.stroke()
                }

                // Darkened inner shoulder just inside the bright band (depth).
                path(11)
                ctx.lineWidth = 3
                ctx.strokeStyle = "rgba(0,0,0,0.06)"
                ctx.stroke()

                // Specular rim: light catches opposite corners only.
                path(0.75)
                ctx.lineWidth = 1.5
                let rim = ctx.createLinearGradient(0, 0, w, h)
                rim.addColorStop(0.00, "rgba(255,255,255,0.95)")
                rim.addColorStop(0.18, "rgba(255,255,255,0.30)")
                rim.addColorStop(0.50, "rgba(255,255,255,0.10)")
                rim.addColorStop(0.82, "rgba(255,255,255,0.30)")
                rim.addColorStop(1.00, "rgba(255,255,255,0.85)")
                ctx.strokeStyle = rim
                ctx.stroke()

                // Crisp dark hairline outside the rim separates glass from the desktop.
                path(0.25)
                ctx.lineWidth = 0.5
                ctx.strokeStyle = "rgba(0,0,0,0.30)"
                ctx.stroke()

                // Top sheen: a thin horizontal highlight fading out at both ends.
                let sheen = ctx.createLinearGradient(r * 0.6, 0, w - r * 0.6, 0)
                sheen.addColorStop(0.0, "rgba(255,255,255,0)")
                sheen.addColorStop(0.5, "rgba(255,255,255,0.55)")
                sheen.addColorStop(1.0, "rgba(255,255,255,0)")
                ctx.fillStyle = sheen
                ctx.fillRect(r * 0.6, 1.5, w - r * 1.2, 1)
            }
        }

        // ---- Icons ----------------------------------------------------------
        Repeater {
            id: icons
            model: root.apps

            delegate: Item {
                id: slotItem
                required property var modelData
                required property int index

                x: root.padX + index * root.slot
                width: root.slot
                height: dock.height

                readonly property real cx: x + width / 2
                readonly property real d: (dock.px - cx) / root.slot
                readonly property real s: 1 + root.peak * dock.lens * Math.exp(-0.8 * d * d)
                readonly property bool active: dock.lens > 0.3 && Math.abs(d) < 0.5
                property real bounce: 0

                function launch() {
                    console.log("Dock item:", modelData.name)
                    hop.restart()
                }

                SequentialAnimation {
                    id: hop
                    NumberAnimation { target: slotItem; property: "bounce"; to: 18; duration: 160; easing.type: Easing.OutQuad }
                    NumberAnimation { target: slotItem; property: "bounce"; to: 0;  duration: 380; easing.type: Easing.OutBounce }
                }

                // Glass tile
                Rectangle {
                    id: tile
                    width: root.iconSize
                    height: root.iconSize
                    x: (parent.width - width) / 2
                    y: parent.height - 15 - height - slotItem.bounce - (slotItem.s - 1) * 6
                    radius: 15
                    scale: slotItem.s
                    transformOrigin: Item.Bottom
                    antialiasing: true
                    border.width: 1
                    border.color: Qt.rgba(1, 1, 1, 0.30 + 0.25 * Math.min(1, (slotItem.s - 1) / root.peak))

                    gradient: Gradient {
                        GradientStop { position: 0.0; color: Qt.alpha(slotItem.modelData.accent, 0.42) }
                        GradientStop { position: 1.0; color: Qt.alpha(slotItem.modelData.accent, 0.14) }
                    }

                    // Upper specular lobe
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

                    // Vector icon (24px grid)
                    Shape {
                        anchors.centerIn: parent
                        width: 24
                        height: 24
                        scale: 1.15
                        preferredRendererType: Shape.CurveRenderer
                        ShapePath {
                            strokeColor: Qt.lighter(slotItem.modelData.accent, 1.55)
                            strokeWidth: root.stroke
                            fillColor: "transparent"
                            capStyle: ShapePath.RoundCap
                            joinStyle: ShapePath.RoundJoin
                            PathSvg { path: slotItem.modelData.path }
                        }
                    }
                }

                // Running indicator
                Rectangle {
                    visible: slotItem.modelData.running
                    width: 4; height: 4; radius: 2
                    x: (parent.width - width) / 2
                    y: parent.height - 9
                    color: "#e9f3ff"
                    opacity: 0.85
                }

                // Tooltip
                Rectangle {
                    id: tip
                    width: label.implicitWidth + 20
                    height: 26
                    radius: 10
                    x: (parent.width - width) / 2
                    y: tile.y - (slotItem.s - 1) * tile.height - height - 10
                    color: "#e6141c28"
                    border.width: 1
                    border.color: "#40ffffff"
                    opacity: slotItem.active ? 1 : 0
                    visible: opacity > 0
                    Behavior on opacity { NumberAnimation { duration: 120 } }

                    Text {
                        id: label
                        anchors.centerIn: parent
                        text: slotItem.modelData.name
                        color: "#f4f8ff"
                        font.pixelSize: 12
                        font.weight: Font.Medium
                        renderType: Text.QtRendering
                    }
                }
            }
        }

        // Single input surface (covers the dock plus headroom for magnified icons).
        Item {
            x: 0
            y: -34
            width: parent.width
            height: parent.height + 34

            HoverHandler {
                id: hit
                cursorShape: Qt.PointingHandCursor
                onPointChanged: dock.px = point.position.x
            }
            TapHandler {
                onTapped: (p) => {
                    const i = Math.floor((p.position.x - root.padX) / root.slot)
                    if (i >= 0 && i < icons.count)
                        icons.itemAt(i).launch()
                }
            }
        }
    }
}
