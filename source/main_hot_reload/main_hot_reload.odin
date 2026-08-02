package main

import "core:c/libc"
import "core:mem"
import "core:dynlib"
import "core:fmt"
import "core:log"
import "core:os"
import "core:path/filepath"
import "core:time"

when ODIN_OS == .Windows {
    DLL_EXT :: ".dll"
} else when ODIN_OS == .Darwin {
    DLL_EXT :: ".dylib"
} else {
    DLL_EXT :: ".so"
}

GAME_DLL_DIR :: "build/hot_reload/"
GAME_DLL_PATH :: GAME_DLL_DIR + "game" + DLL_EXT

copy_dll :: proc(to: string) -> bool {
    copy_err := os.copy_file(to, GAME_DLL_PATH)

    if copy_err != nil {
        fmt.printfln("Failed to copy {0} to {1}: %v", GAME_DLL_PATH, to, copy_err)
        return false
    }

    return true
}

Game_API :: struct {
    modification_time:  time.Time,
    api_version:        int,

    lib:                dynlib.Library,

    force_reload:       proc() -> bool,
    force_restart:      proc() -> bool,
    init_window:        proc(),
    init:               proc(),
    hot_reload:         proc(mem: rawptr),
    memory:             proc() -> rawptr,
    should_run:         proc() -> bool,
    shutdown:           proc(),
    shutdown_window:    proc(),
    update:             proc(),
}

get_game_api_file :: proc(api_version: int) -> string {
    return fmt.tprintf("{0}game_{1}{2}", GAME_DLL_DIR, api_version, DLL_EXT)
}

load_game_api :: proc(api_version: int) -> (api: Game_API, ok: bool) {
    mod_time, mod_time_error := os.last_write_time_by_name(GAME_DLL_PATH)
    if mod_time_error != os.ERROR_NONE {
        fmt.printfln("Failed getting last write time of {0}, error code: {1}", GAME_DLL_PATH, mod_time_error)
        return
    }

    game_dll_name := get_game_api_file(api.api_version)
    copy_dll(game_dll_name) or_return

    _, ok = dynlib.initialize_symbols(&api, game_dll_name, "game_", "lib")
    if !ok {
        fmt.printfln("Failed to initialize symbols: {0}", dynlib.last_error())
    }

    api.api_version = api_version
    api.modification_time = mod_time
    ok = true

    return
}

unload_game_api :: proc(api: ^Game_API) {
    if api.lib != nil {
        if !dynlib.unload_library(api.lib) {
            fmt.printfln("Failed unloading lib: {0}", dynlib.last_error())
        }
    }

    if os.remove(get_game_api_file(api.api_version)) != nil {
        fmt.printfln("Failed to remove {0}", get_game_api_file(api.api_version))
    }
}

main :: proc() {
    exe_path := os.args[0]
    exe_dir := filepath.dir(string(exe_path))
    os.set_working_directory(exe_dir)

    context.logger = log.create_console_logger()

    default_allocator := context.allocator
    tracking_allocator: mem.Tracking_Allocator
    mem.tracking_allocator_init(&tracking_allocator, default_allocator)
    context.allocator = mem.tracking_allocator(&tracking_allocator)

    game_api_version := 0
    game_api, game_api_ok := load_game_api(game_api_version)

    if !game_api_ok {
        fmt.println("Failed to load Game API")
        return
    }

    game_api_version += 1
    game_api.init_window()
    game_api.init()

    old_game_apis := make([dynamic]Game_API, default_allocator)

    gameloop: for game_api.should_run() {
        game_api.update()
        force_restart, reload := check_for_reload(&game_api)
        if force_restart || reload {
            new_game_api, new_game_api_ok := load_game_api(game_api_version)

            if !new_game_api_ok {
                log.error("New Game Api is not OK - quitting")
                break gameloop
            }

            if force_restart {
                do_restart(&tracking_allocator, &old_game_apis, &game_api, &new_game_api)
            } else if reload {
                do_reload(&old_game_apis, &game_api, &new_game_api)
            }
        }

        if len(tracking_allocator.bad_free_array) > 0 {
            for b in tracking_allocator.bad_free_array {
                log.errorf("Bad free at: %v", b.location)
            }
        }
    }

    free_all(context.temp_allocator)
    game_api.shutdown()
    if reset_tracking_allocator(&tracking_allocator) {
        libc.getchar() // Wait to shutdown if there are errors
    }

    for &g in old_game_apis {
        unload_game_api(&g)
    }

    delete(old_game_apis)

    game_api.shutdown_window()
    unload_game_api(&game_api)
    mem.tracking_allocator_destroy(&tracking_allocator)
}

do_restart :: proc(tracking_allocator: ^mem.Tracking_Allocator, old_game_apis: ^[dynamic]Game_API, new_game_api: ^Game_API, game_api: ^Game_API) {
    game_api.shutdown()
    reset_tracking_allocator(&tracking_allocator^)

    for &g in old_game_apis {
        unload_game_api(&g)
    }

    clear(old_game_apis)
    unload_game_api(game_api)
    game_api^ = new_game_api^
    game_api.init()
}

    reset_tracking_allocator :: proc(a: ^mem.Tracking_Allocator) -> bool {
        err := false

        for _, value in a.allocation_map {
            log.error("%v: Leaked %v bytes\n", value.location, value.size)
            err = true
        }

        mem.tracking_allocator_clear(a)
        return err
    }

do_reload :: proc(old_game_apis: ^[dynamic]Game_API, game_api: ^Game_API, new_game_api: ^Game_API) {
    append(old_game_apis, game_api^)
    game_memory := game_api.memory()
    game_api^ = new_game_api^
    game_api.hot_reload(game_memory)
}

check_for_reload :: proc(game_api: ^Game_API) -> (force_restart: bool, reload: bool) {
    force_reload := game_api.force_reload()
    force_restart = game_api.force_restart()
    reload = force_reload || force_restart
    game_dll_mod, game_dll_mod_err := os.last_write_time_by_name(GAME_DLL_PATH)

    if game_dll_mod_err == os.ERROR_NONE && game_api.modification_time != game_dll_mod {
        reload = true
    }

    return force_restart, reload
}