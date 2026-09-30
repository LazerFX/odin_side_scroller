package side_scroller

import rl "vendor:raylib"

Memory :: struct {
    Continue_Running:   bool,
    Player_Pos:         rl.Vector2,
    Player_Velocity:    rl.Vector2,
}