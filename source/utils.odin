package side_scroller

import rl "vendor:raylib"

getRectPos := proc(centerX, centerY, widthX, widthY: f32) -> rl.Rectangle {
    return rl.Rectangle {
        height      = widthY,
        width       = widthX,
        x           = centerX - (widthX / 2),
        y           = centerY - (widthY),
    }
}