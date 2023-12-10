const std = @import("std");
const math = std.math;

const base83_chars = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz#$%*+,-.:;=?@[]^_{|}~";

const base83_index = struct {
    pub fn buildIndex() []const u8 {
        const index: [126]u8 = std.mem.zeroes(u8);
        for (base83_chars, 0..) |c, i| {
            index[c] = i;
        }
    }
}.buildIndex();

// This is 20 for now because we have need of calcing 83^MAX_BLURHASH_STRING_LEN, which fits into a u128
const MAX_BLURHASH_STRING_LEN = 20;

fn base83Index(c: u8) error{Base83Error}!u8 {
    if (c > base83_index.len) return error.Base83Error;
    const idx = base83_index[c];
    return if (idx == 0) error.Base83Error else idx;
}

// TODO not sure about the return type here
pub fn decode(s: []const u8) error{Base83Error}!i16 {
    var res: i16 = 0;
    for (s) |c| {
        res = (res * 83) + try base83Index(c);
    }

    return res;
}

// TODO can n be negative?
pub fn encode(buf: []u8, n: u32, l: usize) ![]const u8 {
    for (0..l) |i| {
        const calc = (n / math.pow(u128, 83, l - i - 1)) % 83;
        const digit: usize = @truncate(calc);

        buf[i] = base83_chars[digit];
    }

    return buf[0..l];
}

pub fn encodeByte(n: u32) u8 {
    return base83_chars[n % 83];
}
