const std = @import("std");
const w4 = @import("wasm4");
const assets = @import("assets.zig");

const MAX_OBSTACLES: u8 = 30;
const BLACK = w4.Color.fromInt(0x120a19);
const DARK_RED = w4.Color.fromInt(0x7e1f23);
const PURPLE = w4.Color.fromInt(0x5e4069);
const LIGHT_RED = w4.Color.fromInt(0xc4181f);

const Guy = struct {
    position: [2]f32 = .{0, 0},
    anger: u8 = 0,
    punch_power: u8 = 0,
};

const Obstacle = struct {
    position: [2]f32 = .{0, 0},
};

var arena_mem: [1024 * 4]u8 = undefined;
var fba = std.heap.FixedBufferAllocator.init(&arena_mem);
var arena = std.heap.ArenaAllocator.init(fba.allocator());
var prev_input: w4.Gamepad = undefined;

var guy = Guy{};
var obstacles: [MAX_OBSTACLES]Obstacle = undefined;

export fn start() void {

    w4.palette.* = .{
        BLACK,
        DARK_RED,
        PURPLE,
        LIGHT_RED,
    };

    w4.draw.* = .{
        .color_1 = .palette_1,
        .color_2 = .palette_2,
        .color_3 = .palette_3,
        .color_4 = .palette_4,
    };

    guy.position[1] = 50;

    for (&obstacles, 0..) |*ob, i| {
        _ = i;
        ob.position = .{150, 50};
    }

}

var count: i32 = 0;
export fn update() void {

    for (&obstacles, 0..) |*ob, i| {
        _ = i;
        ob.position[0] -= 0.5;
    }

    {
        const input = w4.gamepads[0];
        if (prev_input.button_1) {
            const s = std.fmt.allocPrint(arena.allocator(), "count: {}", .{count}) catch "";
            w4.trace(s);
            count += 1;
        }

        prev_input = input;
    }

    w4.text("Hello from Zig!", 10, 10);

    w4.blit(&assets.ui, 1, 107, assets.ui_width, assets.ui_height, .{.format = .bpp_2});
    w4.rect(@intFromFloat(guy.position[0]), @intFromFloat(guy.position[1]), 16, 16);
    w4.text("Press X to blink", 16, 90);

    w4.draw.* = .{
        .color_1 = .palette_3,
        .color_2 = .palette_3,
    };
    for (&obstacles) |*ob| {
        w4.rect(@intFromFloat(ob.position[0]), @intFromFloat(ob.position[1]), 16, 16);
    }

    w4.draw.* = .{
        .color_1 = .palette_1,
        .color_2 = .palette_2,
        .color_3 = .palette_3,
        .color_4 = .palette_4,
    };

    _ = arena.reset(.retain_capacity);
}

