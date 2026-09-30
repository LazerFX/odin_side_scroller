package side_scroller

import rl "vendor:raylib"

mem: ^Memory

GRAVITY :: 0

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
    if rl.IsKeyDown(rl.KeyboardKey.D) {
        mem.Player_Velocity.x = 1
    } else if rl.IsKeyDown(rl.KeyboardKey.A){ 
        mem.Player_Velocity.x = -1
    } else {
        mem.Player_Velocity.x = 0
    }

    mem.Player_Pos.x += mem.Player_Velocity.x
    mem.Player_Pos.y += mem.Player_Velocity.y
}

draw := proc() {
    rl.BeginDrawing()
    rl.ClearBackground(rl.WHITE)

    drawGround()
    drawPlayer()

    rl.EndDrawing()
}

drawGround := proc() {
    lineHeight := rl.GetRenderHeight() / 2
    lineRight := rl.GetRenderWidth()
    rl.DrawLine(0, lineHeight, lineRight, lineHeight, rl.BLACK)
}

drawPlayer := proc() {
    rect := getRectPos(mem.Player_Pos.x, mem.Player_Pos.y, 10, 10)
    rl.DrawRectangleRec(rect, rl.PINK)
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

    posX := (f32)(rl.GetRenderWidth()) / 2
    posY := (f32)(rl.GetRenderHeight()) / 2

    mem^ = Memory {
        Continue_Running    = true,
        Player_Pos          = { posX, posY },
        Player_Velocity     = { 0, 0 },
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

@(export)
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