package side_scroller

import rl "vendor:raylib"

mem: ^Memory

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
}

draw := proc() {
    rl.BeginDrawing()
    rl.ClearBackground(rl.WHITE)

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
        Player_Pos          = {1.0, 1.0},
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