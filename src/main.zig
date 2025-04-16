const std = @import("std");
const testing = std.testing;

pub const Builder = struct {
    allocator: std.mem.Allocator,
    buffer: []u8,
    len: usize = 0,

    const defaultSize = 1024;

    pub fn init(allocator: std.mem.Allocator, size: usize) !Builder {
        const reseved = switch (size) {
            0 => defaultSize,
            else => size,
        };
        return .{
            .allocator = allocator,
            .buffer = try allocator.alloc(u8, reseved),
        };
    }

    pub inline fn add(self: *Builder, string: []const u8) !void {
        try self.ensureLen(string.len);
        @memcpy(self.buffer[self.len .. self.len + string.len], string);
        self.len += string.len;
    }

    pub fn get(self: *Builder) []u8 {
        return self.buffer[0..self.len];
    }

    fn ensureLen(self: *Builder, additionalLen: usize) !void {
        const minimalLen = self.len + additionalLen;
        if (self.buffer.len < minimalLen) {
            var newSize = self.buffer.len * 2;
            while (newSize < minimalLen) {
                newSize *= 2;
            }
            self.buffer = try self.allocator.realloc(self.buffer, newSize);
        }
    }

    pub fn clear(self: *Builder) void {
        self.len = 0;
    }

    pub fn isEmpty(self: *Builder) bool {
        return self.len == 0;
    }

    pub fn deinit(self: *Builder) void {
        self.allocator.free(self.buffer);
    }
};
