package side_scroller

import "core:fmt"
import "core:mem"
import rl "vendor:raylib"
import MainMem "structs"

@(export)
setup :: proc() -> ^MainMem.Memory {
    create_allocator()

    create_screen()

    memory := new(MainMem.Memory)
    defer { free(memory) }

    memory^ = MainMem.Memory {
        { 0.0, 0.0 },
    }
    return memory
}

create_screen :: proc() {
    rl.InitWindow(1920, 1080, "Side Scroller")
    rl.SetTargetFPS(60)
}

create_allocator :: proc() {
    track:      mem.Tracking_Allocator
    mem.tracking_allocator_init(&track, context.allocator)
    context.allocator = mem.tracking_allocator(&track)

    defer {
        if len(track.allocation_map) > 0 {
            fmt.eprintf("=== %v allocations not freed: ===\n", len(track.allocation_map))
            for _, entry in track.allocation_map {
                fmt.eprintf("- %v bytes @ %v\n", entry.size, entry.location)
            }
        }
        mem.tracking_allocator_destroy(&track)
    }
}