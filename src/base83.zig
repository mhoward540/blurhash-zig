const std = @import("std");
const math = std.math;
const String = @import("zig-string").String;

// TODO can use a map for this (maybe even comptime?), just lazy right now
// TODO At the very least it could just be a string :)
const base83_chars = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz#$%*+,-.:;=?@[]^_{|}~";
const MAX_COMPONENTS = 9;

// This is 20 for now because we have need of calcing 83^MAX_BLURHASH_STRING_LEN, which fits into a u128
const MAX_BLURHASH_STRING_LEN = 20;

fn base83_index(c: u8) error{Base83Error}!u8 {
    const needle = &([_]u8{c});
    const res = std.mem.indexOf(u8, base83_chars, needle) orelse return error.Base83Error;
    return @truncate(u8, res);
}

// TODO not sure about the return type here
pub fn decode(s: []const u8) error{Base83Error}!i16 {
    var res: i16 = 0;
    for (s) |c| {
        res = (res * 83) + try base83_index(c);
    }

    return res;
}

// TODO can n be negative?
// TODO is there a nicer way to do this than having a destination variable? Maybe a struct?
pub fn encode(allocator_ref: *std.mem.Allocator, n: u32, l: usize) ![]const u8 {
    var result = String.init(allocator_ref);
    defer result.deinit();

    var i: u8 = 1;
    while (i <= l) : (i += 1) {
        const calc = (n / math.pow(u128, 83, l - i)) % 83;
        const digit = @truncate(usize, calc);

        const charlist = [_]u8{base83_chars[digit]};
        try result.concat(charlist[0..1]);
    }

    return (try result.toOwned()) orelse "";
}
