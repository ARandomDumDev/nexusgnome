import QtQuick

// Glass body: painted once into a cached texture (repaints only on resize).
Canvas {
    id: surface
    property real radius: 32
    property color tint: "#80121a28"

    renderTarget: Canvas.FramebufferObject
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    onRadiusChanged: requestPaint()
    onTintChanged: requestPaint()

    onPaint: {
        const ctx = getContext("2d")
        ctx.reset()
        const w = width, h = height, r = radius

        function path(i) {
            ctx.beginPath()
            ctx.roundedRect(i, i, w - i * 2, h - i * 2, r - i, r - i)
        }

        path(0); ctx.fillStyle = tint; ctx.fill()

        path(0)
        const body = ctx.createLinearGradient(0, 0, 0, h)
        body.addColorStop(0.00, "rgba(255,255,255,0.26)")
        body.addColorStop(0.45, "rgba(255,255,255,0.05)")
        body.addColorStop(0.80, "rgba(255,255,255,0.04)")
        body.addColorStop(1.00, "rgba(255,255,255,0.16)")
        ctx.fillStyle = body; ctx.fill()

        // Soft edge band (the shader supplies the real bending on top of this).
        ctx.lineWidth = 1.4
        for (let i = 0; i < 6; i++) {
            path(1.6 + i * 1.3)
            ctx.strokeStyle = "rgba(255,255,255," + (0.10 * Math.pow(1 - i / 6, 2)).toFixed(3) + ")"
            ctx.stroke()
        }

        // Specular rim: light catches opposite corners only.
        path(0.75); ctx.lineWidth = 1.5
        const rim = ctx.createLinearGradient(0, 0, w, h)
        rim.addColorStop(0.00, "rgba(255,255,255,0.95)")
        rim.addColorStop(0.18, "rgba(255,255,255,0.30)")
        rim.addColorStop(0.50, "rgba(255,255,255,0.10)")
        rim.addColorStop(0.82, "rgba(255,255,255,0.30)")
        rim.addColorStop(1.00, "rgba(255,255,255,0.85)")
        ctx.strokeStyle = rim; ctx.stroke()

        path(0.25); ctx.lineWidth = 0.5
        ctx.strokeStyle = "rgba(0,0,0,0.30)"; ctx.stroke()

        const sheen = ctx.createLinearGradient(r * 0.6, 0, w - r * 0.6, 0)
        sheen.addColorStop(0.0, "rgba(255,255,255,0)")
        sheen.addColorStop(0.5, "rgba(255,255,255,0.55)")
        sheen.addColorStop(1.0, "rgba(255,255,255,0)")
        ctx.fillStyle = sheen
        ctx.fillRect(r * 0.6, 1.5, w - r * 1.2, 1)
    }
}
