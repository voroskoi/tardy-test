const std = @import("std");
const Tardy = @import("tardy").Tardy(.auto);
const Runtime = @import("tardy").Runtime;

pub fn main() !void {
    var t = try Tardy.init(.{ .allocator = std.heap.page_allocator });
    defer t.deinit();

    try t.entry(
        {},
        struct {
            fn init(_: *Runtime, _: void) !void {}
        }.init,
        {},
        struct {
            fn deinit(_: *Runtime, _: void) !void {}
        }.deinit,
    );
}
