package side_scroller

import "core:math"
import "core:math/rand"
import rl "vendor:raylib"

burst :: proc(parts: ^[dynamic]Particle, at: rl.Vector2, count: int) {
    for _ in 0 ..< count {
        angle := rand.float32() * 2.0 * math.PI
        speed := 80.0 + rand.float32() * 220.0
        append(parts, Particle{
            pos     = at,
            velocity= { math.cos(angle) * speed, math.sin(angle) * speed },
            //color   = rl.ColorFromHSV(rand.float32() * 360.0, 0.8, 1.0),
            color     = rl.BLUE,
            radius  = 2.0 + rand.float32() * 4.0,
            life = 0.6 + rand.float32() * 0.9,
        })
    }
}