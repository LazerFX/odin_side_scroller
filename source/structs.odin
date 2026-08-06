package side_scroller

import rl "vendor:raylib"

Memory :: struct {
    Continue_Running:   bool,
    Particles:          [dynamic]Particle,
}

Particle :: struct {
    pos:        rl.Vector2,
    velocity:   rl.Vector2,
    color:      rl.Color,
    radius:     f32,
    life:       f32,
}