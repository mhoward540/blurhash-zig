const std = @import("std");
const expect = std.testing.expect;
const zigimg = @import("zigimg");
const blurhash = @import("./src/blurhash.zig");

pub fn main() !void {
    const stdout = std.io.getStdOut();

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var allocator = gpa.allocator();

    var args = try std.process.argsWithAllocator(allocator);
    defer args.deinit();

    _ = try args.next(allocator) orelse return error.InvalidPath;
    const filename = try (args.next(allocator) orelse return error.InvalidPath);

    if (filename.len == 0) {
        return error.InvalidPath;
    }

    var img = try zigimg.Image.fromFilePath(allocator, filename);
    defer img.deinit();

    const blurhashStr = blurhash.encode(&allocator, img, 4, 4);

    try stdout.writer().print("{s}\n", .{blurhashStr});
}

test "encoding - components = 4" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var allocator = gpa.allocator();

    var img = try zigimg.Image.fromFilePath(allocator, "./image.png");
    defer img.deinit();

    const blurhashStr = try blurhash.encode(&allocator, img, 4, 4);
    try std.testing.expectEqualSlices(u8, blurhashStr, "UrQ]$mfQ~qj@ocofWFWB?bj[D%azf6WBj[t7"[0..36]);
}

test "encoding - components = 1" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var allocator = gpa.allocator();

    var img = try zigimg.Image.fromFilePath(allocator, "./image.png");
    defer img.deinit();

    const blurhashStr = try blurhash.encode(&allocator, img, 1, 1);
    try std.testing.expectEqualSlices(u8, blurhashStr, "00Q]$m"[0..6]);
}
