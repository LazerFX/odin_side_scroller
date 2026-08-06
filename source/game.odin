package side_scroller

import rl "vendor:raylib"

mem: ^Memory

GRAVITY :: 490

/* 
 | ################################
 |
 | Local Functions for Doing Stuff™
 |
 | ################################
*/

update := proc() {
    if rl.IsKeyPressed(.ESCAPE) {
        mem.Continue_Running = false
    }

    if rl.IsMouseButtonPressed(.LEFT) {
        burst(&mem.Particles, rl.GetMousePosition(), 1000)
    }
}

draw := proc() {
    rl.BeginDrawing()
    rl.ClearBackground(rl.WHITE)

    dt := rl.GetFrameTime()

    for i in 0 ..< len(mem.Particles) {
        particle            := &mem.Particles[i]
        particle.life       -= dt
        particle.velocity.y += GRAVITY * dt
        particle.pos        += particle.velocity * dt
    }

    retain(
        &mem.Particles,
        proc(p: Particle) -> bool {
            return p.life > 0
        },
    )

    for particle in mem.Particles {
        rl.DrawCircleV(
            particle.pos,
            particle.radius,
            particle.color,
        )
    }

    rl.EndDrawing()
}

/* 
 | ###################################
 |
 | Exported Functions for Gameplay API
 |
 | ###################################
*/

@(export)
game_init :: proc() {
    mem = new(Memory)

    mem^ = Memory {
        Continue_Running    = true,
        Particles           = make([dynamic]Particle, 5000),
    }

    game_hot_reloaded(mem)
}

@(export)
game_init_window :: proc() {
    rl.SetConfigFlags({.WINDOW_RESIZABLE, .VSYNC_HINT})
    rl.InitWindow(1920, 1080, "Odin-Raylib Based Side Scroller")
    rl.SetWindowPosition(4800, 540)
    rl.SetTargetFPS(60)
    rl.SetExitKey(nil)
}

@(export)
game_shutdown :: proc() {
    free(mem)
}

@(export)
game_shutdown_window :: proc() {
    rl.CloseWindow()
}

@(export)
game_update :: proc() {
    update()
    draw()

    free_all(context.temp_allocator)
}

@(export)
game_memory :: proc() -> rawptr {
    return mem
}

game_memory_size :: proc() -> int {
    return size_of(Memory)
}

@(export)
game_hot_reloaded :: proc(newmem: rawptr) {
    mem = (^Memory)(newmem)
}

@(export)
game_should_run :: proc() -> bool {
    return mem.Continue_Running && !rl.WindowShouldClose()
}

@(export)
game_force_reload :: proc() -> bool {
    return rl.IsKeyPressed(.F5)
}

@(export)
game_force_restart :: proc() -> bool {
    return rl.IsKeyPressed(.F6)
}