const std = @import("std");
const w4 = @import("wasm4");
const assets = @import("assets.zig");

const MAX_OBSTACLES: u8 = 30;
const BLACK = w4.Color.fromInt(0x120a19);
const DARK_RED = w4.Color.fromInt(0x7e1f23);
const PURPLE = w4.Color.fromInt(0x5e4069);
const LIGHT_RED = w4.Color.fromInt(0xc4181f);

const Rand = struct {
    state: u32 = undefined,

    fn init(self: *Rand, seed: u32) void {
        self.state = seed;
    }

    fn next(self: *Rand) u32 {
        self.state = self.state *% 1103515245 +% 12345;
        return self.state;
    }

    fn range(self: *Rand, lower: i32, upper: i32) i32 {
        const u_range = @as(u32, @intCast(lower - upper + 1));
        const offset = @as(i32, @intCast(self.next() % u_range));
        return lower + offset;
    }

    fn boolean(self: *Rand) bool {
        return (self.next() & 1) == 1;
    }
};

const Direction = enum {
    Left, Right,

    // fn value(direction: Direction) i32 {
    //     return switch (direction) {
    //         .Left => -1,
    //         .Right => 1,
    //     };
    // }
};

const vec2 = struct {
    x: f32, y: f32
};

const Guy = struct {
    const SPEED = 1.0;
    const MAX_PUNCH_POWER = 100;
    const PUNCH_GROWTH = 2;

    position: vec2,
    face_direction: Direction,
    collider: [4]f32,
    ducking: bool,
    anger: u8,
    punch_power: u8,
};

const Obstacle_Kind = enum {
    Car,
    SmallGuy,
    BigGuy,
};

const Obstacle = struct {
    kind: Obstacle_Kind,
    position: vec2,
    speed: f32,
};

var arena_mem: [1024 * 4]u8 = undefined;
var fba = std.heap.FixedBufferAllocator.init(&arena_mem);
var arena = std.heap.ArenaAllocator.init(fba.allocator());
var prev_input: w4.Gamepad = undefined;

var guy = std.mem.zeroInit(Guy, .{
    .face_direction = .Right
});

var obstacles: [MAX_OBSTACLES]Obstacle = undefined;
var obstacle_count: i32 = 0;
var waves_defeated: u8 = 0;
const rand: Rand = undefined;

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

    spawn_wave();
}

var game_started = false;
var frames_since_game_start = 0;

export fn update() void {
    const input = w4.gamepads[0];

    if (!game_started) {
        frames_since_game_start += 1;
        rand.state +%= (w4.mouse_x + 123) * (w4.mouse_y * 67) + frames_since_game_start;

        if (input.button_1) {
            game_started = true;
        }
    }
    if (obstacle_count <= 0) {
        waves_defeated += 1;
        spawn_wave();
    }

    for (0..obstacle_count) |i| {
        var ob = &obstacles[i];
        ob.position.x -= 0.5;
    }

    {
        if (input.button_left) {
            guy.position.x -= Guy.SPEED;
        } else if (input.button_right) {
            guy.position.x += Guy.SPEED;
        }

        if (input.button_up) {
            guy.position.y -= Guy.SPEED;
        } else if (input.button_down) {
            guy.position.y += Guy.SPEED;
        }

        if (input.button_1) {
            guy.face_direction = .Right;
        }

        if (input.button_2) {
            guy.face_direction = .Left;
        }

        if (input.button_1) {
            guy.punch_power += Guy.PUNCH_GROWTH;
            guy.punch_power = clamp(u8, guy.punch_power, 0, Guy.MAX_PUNCH_POWER);

            const msg = std.fmt.allocPrint(arena.allocator(), "punch_power: {}", .{guy.punch_power}) catch "";
            w4.trace(msg);
        }

        if (guy.punch_power != 0 and !input.button_1 and !prev_input.button_1) {
            const msg = std.fmt.allocPrint(arena.allocator(), "released punch {}", .{guy.punch_power}) catch "";
            w4.trace(msg);
            guy.punch_power = 0;
        }

        prev_input = input;
    }

    w4.text("Hello from Zig!", 10, 10);



    // guy draw
    {

        const x: i32 = @intFromFloat(guy.position.x);
        const y: i32 = @intFromFloat(guy.position.y);
        // w4.rect(x, y, 16, 16);

        w4.draw.* = .{
            .color_1 = .transparent,
            .color_2 = .palette_1,
            .color_3 = .palette_3,
            .color_4 = .palette_4,
        };

        // guy.face_direction.value() * 
        w4.blit(&assets.guy_idle, x, y, assets.guy_idle_width, assets.guy_idle_height, .{.format = .bpp_2});

        w4.draw.* = .{
            .color_1 = .palette_4,
            .color_2 = .palette_4,
        };

        const len = 40;
        // const x: i32 = @intFromFloat(guy.position.x);
        // const y: i32 = @intFromFloat(guy.position.y);

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
    // for (&obstacles) |*ob| {
    //     w4.rect(@intFromFloat(ob.position.x), @intFromFloat(ob.position.y), 16, 16);
    // }

    for (0..obstacle_count) |i| {
        var ob = &obstacles[i];
        ob.position.x -= 0.5;

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

fn spawn_wave() void {
    const x_left_spawn: f32 = -180.0;
    const x_right_spawn: f32 = 180.0;
    // const rand = std.crypto.random;
    const b = rand.boolean();

    const obstacles_to_spawn = waves_defeated * 2 + 1;

    for (0..obstacles_to_spawn) |i| {
        obstacles[i] = std.mem.zeroInit(Obstacle, .{});
        obstacles[i].position.x = if (b) x_left_spawn else x_right_spawn;
    }

    obstacle_count = obstacles_to_spawn;
}

fn clamp(comptime T: type, value: T, lower: T, upper: T) T {
    if (value < lower) return lower;
    if (value > upper) return upper;
    return value;
}
