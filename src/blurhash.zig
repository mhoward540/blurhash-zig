const std = @import("std");
const math = std.math;
const base83 = @import("base83.zig");
const zigimg = @import("zigimg");


fn toXYZ(n: f64) f64 {
    if (n <= 0.04045) {
        return n / 12.92;
    } else {
        return math.pow(f64, (n + 0.055) / 1.055, 2.4);
    }
}

fn signPow(a: f64, b: f64) f64 {
    if (a < 0.0) {
        return math.pow(f64, @abs(a), b) * -1;
    } else {
        return math.pow(f64, a, b);
    }
}

fn toUintSrgb(n: f64) u8 {
    const v = math.clamp(n, 0.0, 1.0);
    if (v <= 0.0031308) {
        return @intFromFloat(v * 12.92 * 255.0 + 0.5);
    } else {
        return @intFromFloat((math.pow(f64, v, 1.0 / 2.4) * 1.055 - 0.055) * 255.0 + 0.5);
    }
}

pub fn encode(allocator: std.mem.Allocator, img: zigimg.Image, components_x: u8, components_y: u8) ![]const u8 {
    if (components_x > 9 or components_x < 1 or components_y > 9 or components_y < 1) {
        return error.BlurhashError;
    }

    var iterator = img.iterator();

    const buf = try allocator.alloc(u8, 2 * components_x * components_y + 4);
    defer allocator.free(buf);

    var buf_stream = std.io.fixedBufferStream(buf);
    var result = buf_stream.writer();

    var comps = try allocator.alloc([3]f64, components_x * components_y);
    defer allocator.free(comps);

    const l: f64 = @floatFromInt(img.width * img.height);
    var max_component: f64 = 0.0;

    var x: usize = 0;
    var y: usize = 0;

    const f_width: f64 = @floatFromInt(img.width);
    const f_height: f64 = @floatFromInt(img.height);

    while (iterator.next()) |pixel| {
        if (pixel.a != 1.0) {
            return error.UnsupportedPixelFormat;
        }

        var comp_idx: usize = 0;
        var norm_factor: f64 = 1.0;
        for (0..components_y) |j| {
            for (0..components_x) |i| {
                const basis: f64 = norm_factor *
                    @cos(math.pi * @as(f64, @floatFromInt(i * x)) / f_width) *
                    @cos(math.pi * @as(f64, @floatFromInt(j * y)) / f_height);

                // TODO handle rgba by normalizing the rgba values to rgb
                comps[comp_idx][0] += basis * toXYZ(pixel.r);
                comps[comp_idx][1] += basis * toXYZ(pixel.g);
                comps[comp_idx][2] += basis * toXYZ(pixel.b);

                comp_idx += 1;
                norm_factor = 2.0;
            }
        }

        x = (x + 1) % img.width;
        if (x == 0) {
            y += 1;
        }
    }

    for (0..comps.len) |comp_idx| {
        comps[comp_idx][0] /= l;
        comps[comp_idx][1] /= l;
        comps[comp_idx][2] /= l;


        if (comp_idx != 0) {
            max_component = @max(max_component, @max(
                @abs(comps[comp_idx][0]),
                @max(
                    @abs(comps[comp_idx][1]),
                    @abs(comps[comp_idx][2]),
                )
            ));
        }
    }

    const dc_value: u32 =
        @shlExact(@as(u32, toUintSrgb(comps[0][0])), 16) |
        @shlExact(@as(u32, toUintSrgb(comps[0][1])), 8) |
        @as(u32, toUintSrgb(comps[0][2]));

    const quant_max_value: u32 = @intFromFloat(@max(0, @min(82, @floor(max_component * 166 - 0.5))));
    var norm_max_value: f64 = 0.0;

    try result.writeByte(base83.encodeByte(components_x - 1 + (components_y - 1) * 9));

    if (comps.len > 1) {
        norm_max_value = @as(f64, @floatFromInt(quant_max_value + 1)) / 166.0;
        try result.writeByte(base83.encodeByte(quant_max_value));
    } else {
        norm_max_value = 1.0;
        try result.writeByte(base83.encodeByte(0));
    }

    var enc_buf:[4]u8 = undefined;
    _ = try result.write(try base83.encode(&enc_buf, dc_value, 4));

    for (1..comps.len) |k| {
        const comp_r: u32 = @intFromFloat(@max(0, @min(18, @floor(signPow(comps[k][0] / norm_max_value, 0.5) * 9 + 9.5))));
        const comp_g: u32 = @intFromFloat(@max(0, @min(18, @floor(signPow(comps[k][1] / norm_max_value, 0.5) * 9 + 9.5))));
        const comp_b: u32 = @intFromFloat(@max(0, @min(18, @floor(signPow(comps[k][2] / norm_max_value, 0.5) * 9 + 9.5))));

        _ = try result.write(
            try base83.encode(
                &enc_buf,
                (comp_r * 19 * 19) + (comp_g * 19) + comp_b,
                2
            )
        );
    }

    const written = buf_stream.getWritten();
    const str = try allocator.alloc(u8, written.len);
    @memcpy(str, written);

    return str;
}
