const std = @import("std");
const log = std.log.scoped(.@"issue5/example");

const Tardy = @import("tardy").Tardy(.auto);
const Runtime = @import("tardy").Runtime;

const StackContext = struct {
    mutex: std.Thread.Mutex = .{},
    stack: *std.ArrayList(usize),
    item: usize,

    fn init(allocator: std.mem.Allocator) !StackContext {
        const st = try allocator.create(std.ArrayList(usize));
        st.* = std.ArrayList(usize).init(allocator);
        return .{
            .stack = st,
            .item = undefined,
        };
    }

    pub fn deinit(self: *const StackContext) void {
        self.stack.deinit();
    }

    fn append_task(_: *Runtime, _: void, context: *StackContext) !void {
        context.mutex.lock();
        defer context.mutex.unlock();

        log.debug("appending {d} to stack", .{context.item});
        try context.stack.append(context.item);
        log.debug("items: {any}\n", .{context.stack.items});
    }
};

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    var t = try Tardy.init(.{
        .allocator = allocator,
        .threading = .{ .multi = 1 },
    });
    defer t.deinit();

    var stack_context = try StackContext.init(allocator);
    defer stack_context.deinit();

    try t.entry(
        &stack_context,
        struct {
            // this will be run in every runtime.
            fn init(rt: *Runtime, context: *StackContext) !void {
                context.item = 4;
                try rt.spawn(void, context, StackContext.append_task);
            }
        }.init,
        {},
        struct {
            fn deinit(_: *Runtime, _: void) !void {}
        }.deinit,
    );

    std.debug.print("{any}\n", .{stack_context.stack.items});
}
