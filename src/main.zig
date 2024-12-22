const std = @import("std");
const Tardy = @import("tardy").Tardy(.auto);
const Runtime = @import("tardy").Runtime;

pub fn main() !void {
    var t = try Tardy.init(.{ .allocator = std.heap.page_allocator });
    defer t.deinit();

    // XXX: this stack is not visible in init: add to init params!
    // var stack = std.ArrayList(usize).init(std.heap.page_allocator);
    // defer stack.deinit();

    // XXX: This struct fails with unable to unwrap null on utils.zig:27
    // because it neads to be `packed` to have a backing_integer field.
    // OTOH if I add packed it becomes u128 which fails on utils.zig:71.
    const StackContext = struct {
        stack: *std.ArrayList(usize),
        item: usize,

        fn append(_: *Runtime, _: void, context: @This()) !void {
            try context.stack.append(context.item);
        }
    };

    try t.entry(
        {},
        struct {
            fn init(rt: *Runtime, _: void) !void {
                var stack = std.ArrayList(usize).init(std.heap.page_allocator);
                defer stack.deinit();

                try rt.spawn(void, StackContext{ .stack = &stack, .item = 3 }, StackContext.append);
            }
        }.init,
        {},
        struct {
            fn deinit(_: *Runtime, _: void) !void {}
        }.deinit,
    );
}
