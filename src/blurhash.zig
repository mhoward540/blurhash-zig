const std = @import("std");
const math = std.math;
const base83 = @import("./base83.zig");
const zigimg = @import("zigimg");
const String = @import("zig-string").String;


fn toXYZ(n: f64) f64 {
    if (n <= 0.04045) {
        return n / 12.92;
    } else {
        return math.pow(f64, (n + 0.055) / 1.055, 2.4);
    }
}

fn signPow(a: f64, b: f64) f64 {
    if (a < 0.0) {
        return math.pow(f64, @fabs(a), b) * -1;
    } else {
        return math.pow(f64, a, b);
    }
}

fn toUintSrgb(n: f64) u8 {
    const v = math.clamp(n, 0.0, 1.0);
    if (v <= 0.0031308) {
        return @floatToInt(u8, v * 12.92 * 255.0 + 0.5);
    } else {
        return @floatToInt(u8, (math.pow(f64, v, 1.0 / 2.4) * 1.055 - 0.055) * 255.0 + 0.5);
    }
}

pub fn encode(allocator_ref: *std.mem.Allocator, img: zigimg.Image, componentsX: u8, componentsY: u8) ![]u8 {
    if (componentsX > 9 or componentsX < 1 or componentsY > 9 or componentsY < 1) {
        return error.BlurhashError;
    }

    var allocator = allocator_ref.*;

    // kinda lame - copying the image into an array that we can index into to more easily follow the algorithm
    var pixels = try allocator.alloc(zigimg.color.Colorf32, img.width * img.height);
    defer allocator.free(pixels);

    var iterator = img.iterator();
    var index: usize = 0;
    var foundAlpha = false;
    while (iterator.next()) |pixel| {
        pixels[index] = pixel;
        // check if the image has an alpha component. This can be done with PixelFormat, but
        // some rgb images are encoded as rgba with alpha at max (1.0 in this case)
        foundAlpha = foundAlpha or (pixel.a != 1.0);
        index += 1;
    }

    if (foundAlpha) {
        return error.UnsupportedPixelFormat;
    }

    var result = String.init(allocator_ref);
    defer result.deinit();

    var comps = try allocator.alloc([3]f64, componentsX * componentsY);
    defer allocator.free(comps);

    const l = @intToFloat(f64, pixels.len);
    var j: u8 = 0;
    var maxComponent: f64 = 0.0;
    while (j < componentsY) : (j += 1) {
        var i: u8 = 0;
        while (i < componentsX) : (i += 1) {
            const normFactor: f64 = if (j == 0 and i == 0) 1.0 else 2.0;
            // represents r, g, b
            var comp = [_]f64{ 0.0, 0.0, 0.0 };

            var y: usize = 0;
            while (y < img.height) : (y += 1) {
                const yw: usize = y * img.width;

                var x: usize = 0;
                while (x < img.width) : (x += 1) {
                    const basis: f64 = normFactor *
                        @cos(math.pi * @intToFloat(f64, i) * @intToFloat(f64, x) / @intToFloat(f64, img.width)) *
                        @cos(math.pi * @intToFloat(f64, j) * @intToFloat(f64, y) / @intToFloat(f64, img.height));

                    // TODO handle rgba by normalizing the rgba values to rgb
                    comp[0] += basis * toXYZ(pixels[x + yw].r);
                    comp[1] += basis * toXYZ(pixels[x + yw].g);
                    comp[2] += basis * toXYZ(pixels[x + yw].b);
                }
            }

            comp[0] /= l;
            comp[1] /= l;
            comp[2] /= l;
            comps[j * componentsX + i] = comp;

            if (!(i == 0 and j == 0)) {
                maxComponent = math.max(maxComponent, math.max3(
                    @fabs(comp[0]),
                    @fabs(comp[1]),
                    @fabs(comp[2]),
                ));
            }
        }
    }

    const dcValue: u32 =
        @shlExact(@as(u32, toUintSrgb(comps[0][0])), 16) |
        @shlExact(@as(u32, toUintSrgb(comps[0][1])), 8) |
        @as(u32, toUintSrgb(comps[0][2]));

    const quantMaxValue: u32 = @floatToInt(u32, math.max(0, math.min(82, @floor(maxComponent * 166 - 0.5))));
    var normMaxValue: f64 = 0.0;

    try result.concat(try base83.encode(allocator_ref, componentsX - 1 + (componentsY - 1) * 9, 1));

    if (comps.len > 1) {
        normMaxValue = @intToFloat(f64, quantMaxValue + 1) / 166.0;
        try result.concat(try base83.encode(allocator_ref, quantMaxValue, 1));
    } else {
        normMaxValue = 1.0;
        try result.concat(try base83.encode(allocator_ref, 0, 1));
    }

    try result.concat(try base83.encode(allocator_ref, dcValue, 4));

    var i: u64 = 1;
    while (i < comps.len) : (i += 1) {
        try result.concat(
            try base83.encode(
                allocator_ref,
                (
                    (@floatToInt(u32, math.max(0, math.min(18, @floor(signPow(comps[i][0] / normMaxValue, 0.5) * 9 + 9.5)))) * 19 * 19) +
                    (@floatToInt(u32, math.max(0, math.min(18, @floor(signPow(comps[i][1] / normMaxValue, 0.5) * 9 + 9.5)))) * 19) +
                    @floatToInt(u32, math.max(0, math.min(18, @floor(signPow(comps[i][2] / normMaxValue, 0.5) * 9 + 9.5))))
                ),
                2
            )
        );
    }

    return (try result.toOwned()) orelse "";
}
