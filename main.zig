const std = @import("std");
const expect = std.testing.expect;
const zigimg = @import("zigimg");
const blurhash = @import("src/blurhash.zig");

pub fn main() !void {
    const stdout = std.io.getStdOut();

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var args = try std.process.argsWithAllocator(allocator);
    defer args.deinit();

    _ = args.next() orelse return error.InvalidPath;
    const filename = args.next() orelse return error.InvalidPath;

    if (filename.len == 0) {
        return error.InvalidPath;
    }

    var img = try zigimg.Image.fromFilePath(allocator, filename);
    defer img.deinit();

    const blurhash_str = try blurhash.encode(allocator, img, 4, 4);

    try stdout.writer().print("{s}\n", .{blurhash_str});
}

test "encoding - components = 4" {
    const allocator = std.testing.allocator;

    var img = try zigimg.Image.fromFilePath(allocator, "./image.png");
    defer img.deinit();

    const blurhash_str = try blurhash.encode(allocator, img, 4, 4);
    defer allocator.free(blurhash_str);

    try std.testing.expectEqualSlices(u8, blurhash_str, "UrQ]$mfQ~qj@ocofWFWB?bj[D%azf6WBj[t7"[0..36]);
}

test "encoding - components = 1" {
    const allocator = std.testing.allocator;

    var img = try zigimg.Image.fromFilePath(allocator, "./image.png");
    defer img.deinit();

    const blurhash_str = try blurhash.encode(allocator, img, 1, 1);
    defer allocator.free(blurhash_str);

    try std.testing.expectEqualSlices(u8, blurhash_str, "00Q]$m"[0..6]);
}
