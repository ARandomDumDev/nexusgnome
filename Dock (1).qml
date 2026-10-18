import QtQuick
import QtQuick.Window

// NexusGNOME Dock — Liquid Glass. Needs Qt 6.6+ and refraction.frag.qsb next to this file.
Window {
    id: root
    visible: true
    color: "transparent"
    title: "NexusGNOME Dock"
    flags: Qt.Tool | Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint | Qt.WindowDoesNotAcceptFocus

    readonly property int slot: 72
    readonly property int padX: 18
    readonly property int pillH: 80
    readonly property int pillRadius: 32
    readonly property real peak: 0.42

    property var apps: [
        { name: "Files",    accent: "#5aa9ff", running: true,
          path: "M20 20a2 2 0 0 0 2-2V8a2 2 0 0 0-2-2h-7.9a2 2 0 0 1-1.7-.9l-.8-1.2A2 2 0 0 0 7.9 3H4a2 2 0 0 0-2 2v13a2 2 0 0 0 2 2Z" },
        { name: "Browser",  accent: "#43d3e6", running: true,
          path: "M12 2a10 10 0 1 0 0 20a10 10 0 1 0 0-20M2 12h20M12 2a14.5 14.5 0 0 0 0 20a14.5 14.5 0 0 0 0-20" },
        { name: "Terminal", accent: "#9fb0c6", running: false, path: "M4 17l6-6-6-6M12 19h8" },
        { name: "Settings", accent: "#c4d4ea", running: false,
          path: "M21 4h-7M10 4H3M21 12h-9M8 12H3M21 20h-5M12 20H3M14 2v4M8 10v4M16 18v4" },
        { name: "Music",    accent: "#6f9dff", running: false,
          path: "M9 18V5l12-2v13M6 15a3 3 0 1 0 0 6a3 3 0 1 0 0-6M18 13a3 3 0 1 0 0 6a3 3 0 1 0 0-6" },
        { name: "NexusNet", accent: "#4fd9f2", running: false,
          path: "M12 20h.01M2 8.8a15 15 0 0 1 20 0M5 12.9a10 10 0 0 1 14 0M8.5 16.4a5 5 0 0 1 7 0" },
        { name: "Trash",    accent: "#b4c0d0", running: false,
          path: "M3 6h18M19 6v14c0 1-1 2-2 2H7c-1 0-2-1-2-2V6M8 6V4c0-1 1-2 2-2h4c1 0 2 1 2 2v2M10 11v6M14 11v6" }
    ]

    readonly property int pillW: slot * apps.length + padX * 2
    width: pillW + 80
    height: 150
    x: (Screen.width - width) / 2
    y: Screen.height - height - 6

    // Glass position inside the window.
    readonly property real dockX: (width - pillW) / 2
    readonly property real dockY: height - 20 - pillH

    // Pointer state: one value drives every icon.
    property real lens: hit.hovered ? 1 : 0
    property real px: 0                       // pointer x, in glass coordinates
    Behavior on lens { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
    Behavior on px {
        enabled: root.lens > 0.6
        SpringAnimation { spring: 5; damping: 0.55; epsilon: 0.2 }
    }

    // Ambient shadow (stacked rects: no blur pass).
    Repeater {
        model: 6
        Rectangle {
            required property int index
            x: root.dockX - (index + 1) * 4
            y: root.dockY - (index + 1) * 3 + 8
            width: root.pillW + (index + 1) * 8
            height: root.pillH + (index + 1) * 8
            radius: root.pillRadius + (index + 1) * 4
            color: Qt.rgba(0, 0, 0, 0.05 - index * 0.007)
        }
    }

    GlassSurface {
        x: root.dockX; y: root.dockY
        width: root.pillW; height: root.pillH
        radius: root.pillRadius
    }

    // Icons render into this layer; the shader then bends them at the glass edge.
    Item {
        id: iconLayer
        anchors.fill: parent
        visible: false

        Repeater {
            id: icons
            model: root.apps
            DockItem {
                required property var modelData
                required property int index
                readonly property real d: (root.px - (root.padX + root.slot * (index + 0.5))) / root.slot

                name: modelData.name
                accent: modelData.accent
                iconPath: modelData.path
                running: modelData.running
                peak: root.peak
                magnify: 1 + root.peak * root.lens * Math.exp(-0.8 * d * d)
                hovered: root.lens > 0.3 && Math.abs(d) < 0.5

                x: root.dockX + root.padX + index * root.slot
                y: root.dockY
                width: root.slot
                height: root.pillH
            }
        }
    }

    ShaderEffectSource {
        id: iconTex
        sourceItem: iconLayer
        live: true
        hideSource: true
        visible: false
    }

    ShaderEffect {
        anchors.fill: parent
        fragmentShader: Qt.resolvedUrl("refraction.frag.qsb")
        property variant sourceTexture: iconTex
        property size  resolution: Qt.size(width, height)
        property point pillPos: Qt.point(root.dockX, root.dockY)
        property size  pillSize: Qt.size(root.pillW, root.pillH)
        property real  radius: root.pillRadius
        property real  strength: 16
        property real  thickness: 22
        property real  dispersion: 0.12
    }

    // Single input surface: dock plus headroom for magnified icons.
    Item {
        x: root.dockX; y: root.dockY - 34
        width: root.pillW; height: root.pillH + 34
        HoverHandler {
            id: hit
            cursorShape: Qt.PointingHandCursor
            onPointChanged: root.px = point.position.x
        }
        TapHandler {
            onTapped: (p) => {
                const i = Math.floor((p.position.x - root.padX) / root.slot)
                if (i >= 0 && i < icons.count) icons.itemAt(i).launch()
            }
        }
    }
}
