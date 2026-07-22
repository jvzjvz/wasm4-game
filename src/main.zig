const std = @import("std");
const w4 = @import("wasm4");
const assets = @import("assets.zig");

const MAX_OBSTACLES: u8 = 30;
const BLACK = w4.Color.fromInt(0x120a19);
const DARK_RED = w4.Color.fromInt(0x7e1f23);
const PURPLE = w4.Color.fromInt(0x5e4069);
const LIGHT_RED = w4.Color.fromInt(0xc4181f);

const Direction = enum {
    Left, Right,

    fn value(direction: Direction) f32 {
        return switch (direction) {
            .Left => -1.0,
            .Right => 1.0,
        };
    }
};

const vec2 = struct {
    x: f32, y: f32
};

const Guy = struct {
    const speed = 1.0;

    position: vec2,
    face_direction: Direction,
    collider: [4]f32,
    ducking: bool,
    anger: u8,
    punch_power: u8,
};

const Obstacle = struct {
    position: vec2,
};

var arena_mem: [1024 * 4]u8 = undefined;
var fba = std.heap.FixedBufferAllocator.init(&arena_mem);
var arena = std.heap.ArenaAllocator.init(fba.allocator());
var prev_input: w4.Gamepad = undefined;

var guy = std.mem.zeroInit(Guy, .{
    .face_direction = .Right
});
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

    guy.position.x = 50;

    for (&obstacles, 0..) |*ob, i| {
        _ = i;
        ob.position = .{.x = 150, .y = 50};
    }

}

var count: i32 = 0;
export fn update() void {

    for (&obstacles, 0..) |*ob, i| {
        _ = i;
        ob.position.x -= 0.5;
    }

    {
        const input = w4.gamepads[0];
        if (input.button_left) {
            guy.position.x -= Guy.speed;
        } else if (input.button_right) {
            guy.position.x += Guy.speed;
        }

        if (input.button_up) {
            guy.position.y -= Guy.speed;
        } else if (input.button_down) {
            guy.position.y += Guy.speed;
        }

        if (input.button_1) {
            guy.face_direction = .Right;
        }

        if (input.button_2) {
            guy.face_direction = .Left;
        }

        prev_input = input;
    }

    w4.text("Hello from Zig!", 10, 10);

    w4.rect(@intFromFloat(guy.position.x), @intFromFloat(guy.position.y), 16, 16);

    {
        w4.draw.* = .{
            .color_1 = .palette_4,
            .color_2 = .palette_4,
        };

        const len = 40;
        const x: i32 = @intFromFloat(guy.position.x);
        const y: i32 = @intFromFloat(guy.position.y);

        if (guy.face_direction == .Left) {
            w4.line(x - len, y, x, y);
        } else if (guy.face_direction == .Right){
            w4.line(x, y, x + len, y);
        }
    }

    w4.text("Press X to blink", 16, 90);

    w4.draw.* = .{
        .color_1 = .palette_3,
        .color_2 = .palette_3,
    };
    for (&obstacles) |*ob| {
        w4.rect(@intFromFloat(ob.position.x), @intFromFloat(ob.position.y), 16, 16);
    }

    w4.draw.* = .{
        .color_1 = .palette_1,
        .color_2 = .palette_2,
        .color_3 = .palette_3,
        .color_4 = .palette_4,
    };
    w4.blit(&assets.ui, 1, 107, assets.ui_width, assets.ui_height, .{.format = .bpp_2});

    _ = arena.reset(.retain_capacity);
}
