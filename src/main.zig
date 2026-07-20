const w4 = @import("wasm4");

const smiley = [8]u8{
    0b11000011,
    0b10000001,
    0b00100100,
    0b00100100,
    0b00000000,
    0b00100100,
    0b10011001,
    0b11000011,
};

export fn start() void {
    w4.palette.* = .{
        w4.Color.fromInt(0x000000),
        w4.Color.fromInt(0x555555),
        w4.Color.fromInt(0xAAAAAA),
        w4.Color.fromInt(0xFFFFFF),
    };
}

export fn update() void {
    w4.draw.color_1 = .palette_2;
    w4.text("Hello from Zig!", 10, 10);

    if (w4.gamepads[0].button_1) {
        w4.draw.color_1 = .palette_4;
    }

    w4.blit(&smiley, 76, 76, 8, 8, .{});
    w4.text("Press X to blink", 16, 90);
}
