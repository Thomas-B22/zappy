const std = @import("std");
const allocator = std.heap.wasm_allocator;

const c = @cImport({
    @cInclude("ui_world.h");
});

var should_draw_mandel: bool = false;

export fn malloc(size: usize) callconv(.c) ?*anyopaque {
    const slice = allocator.alloc(u8, size) catch return null;
    return slice.ptr;
}

export fn free(ptr: ?*anyopaque) callconv(.c) void {
    _ = ptr;
}

export fn realloc(ptr: ?*anyopaque, size: usize) callconv(.c) ?*anyopaque {
    if (size == 0) return null;
    if (ptr) |p| {
        const new_ptr = malloc(size);
        if (new_ptr) |n_ptr| {
            @memcpy(@as([*]u8, @ptrCast(n_ptr))[0..size], @as([*]u8, @ptrCast(p))[0..size]);
            return n_ptr;
        }
        return null;
    }
    return malloc(size);
}

export fn abort() callconv(.c) noreturn {
    while (true) {}
}

export fn exports_ui_world_handle_input(state_ptr: usize) callconv(.c) void {
    _ = state_ptr;
}

export fn exports_ui_world_get_commands(ret_ptr: ?*c.ui_world_list_command_desc_t) callconv(.c) void {
    if (ret_ptr) |ret| {
        const items = allocator.alloc(c.ui_world_command_desc_t, 1) catch return;
        items[0] = .{
            .module = .{ .ptr = @constCast("zigbot".ptr), .len = 6 },
            .name = .{ .ptr = @constCast("zig_mandel".ptr), .len = 10 },
            .options = .{ .ptr = @constCast("".ptr), .len = 0 },
            .help = .{ .ptr = @constCast("Fractale de Mandelbrot en Zig !".ptr), .len = 31 },
        };
        ret.ptr = items.ptr;
        ret.len = 1;
    }
}

export fn exports_ui_world_run_command(cmd_ptr: ?*c.ui_world_command_desc_t, args_ptr: ?*c.ui_world_list_string_t, ret_ptr: ?*c.ui_world_response_command_t) callconv(.c) void {
    _ = cmd_ptr;
    _ = args_ptr;

    const message = "[Zigbot] Generation de la fractale activee !";
    var wit_str = c.ui_world_string_t{
        .ptr = @constCast(message.ptr),
        .len = message.len,
    };
    c.local_zappy_host_api_host_log(&wit_str);

    should_draw_mandel = true;

    if (ret_ptr) |ret| {
        ret.tag = 0;
    }
}

export fn exports_ui_world_update_module(time: f32, dt: f32, w: f32, h: f32, ret_ptr: ?*c.ui_world_list_render_command_t) callconv(.c) void {
    _ = time;
    _ = dt;

    const ret = if (ret_ptr) |r| r else return;

    if (!should_draw_mandel) {
        ret.ptr = null;
        ret.len = 0;
        return;
    }

    const cols: usize = 80;
    const rows: usize = 60;
    const total_rects = cols * rows;

    const items = allocator.alloc(c.ui_world_render_command_t, total_rects) catch {
        ret.ptr = null;
        ret.len = 0;
        return;
    };

    const block_w = w / @as(f32, @floatFromInt(cols));
    const block_h = h / @as(f32, @floatFromInt(rows));

    var idx: usize = 0;
    var py: usize = 0;
    while (py < rows) : (py += 1) {
        var px: usize = 0;
        while (px < cols) : (px += 1) {
            const x0 = (@as(f32, @floatFromInt(px)) / @as(f32, @floatFromInt(cols))) * 3.5 - 2.5;
            const y0 = (@as(f32, @floatFromInt(py)) / @as(f32, @floatFromInt(rows))) * 2.0 - 1.0;

            var x: f32 = 0.0;
            var y: f32 = 0.0;
            var iteration: u8 = 0;
            const max_iteration: u8 = 32;

            while (x * x + y * y <= 4.0 and iteration < max_iteration) {
                const xtemp = x * x - y * y + x0;
                y = 2.0 * x * y + y0;
                x = xtemp;
                iteration += 1;
            }

            var r: u8 = 0;
            var g: u8 = 0;
            var b: u8 = 0;
            if (iteration < max_iteration) {
                const it_32: u32 = iteration;
                r = @intCast((it_32 * 8) % 256);
                g = @intCast((it_32 * 4) % 256);
                b = @intCast((it_32 * 16) % 256);
            }

            items[idx] = .{ .tag = 0, .val = .{ .rect = .{
                .x = @as(f32, @floatFromInt(px)) * block_w,
                .y = @as(f32, @floatFromInt(py)) * block_h,
                .w = block_w,
                .h = block_h,
                .color = .{ .r = r, .g = g, .b = b, .a = 255 },
                .rotation = 0.0,
            } } };
            idx += 1;
        }
    }

    ret.ptr = items.ptr;
    ret.len = total_rects;
}

export fn exports_ui_world_accept_log(segments_ptr: ?*anyopaque) callconv(.c) void {
    _ = segments_ptr;
}
export fn exports_ui_world_serialize(ret_ptr: ?*anyopaque) callconv(.c) void {
    _ = ret_ptr;
}
export fn exports_ui_world_deserialize(state_ptr: ?*anyopaque) callconv(.c) void {
    _ = state_ptr;
}
export fn exports_ui_world_handle_event(event_ptr: ?*anyopaque, payload_ptr: ?*anyopaque) callconv(.c) void {
    _ = event_ptr;
    _ = payload_ptr;
}
