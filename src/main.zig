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

    pub fn add(self: *Builder, string: []const u8) !void {
        try self.ensureLen(string.len);
        std.mem.copyForwards(u8, self.buffer[self.len..], string);
        self.len += string.len;
    }

    pub fn get(self: *Builder) ![:0]u8 {
        try self.ensureLen(1);
        self.buffer[self.len] = 0;
        return self.buffer[0..self.len :0];
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

test "basic concatination" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var builder: Builder = try Builder.init(allocator, 0);
    defer builder.deinit();

    try testing.expectEqual(@as(usize, 0), builder.len);
    try test_add_string(&builder);
    try testing.expectEqual(@as(usize, 13), builder.len);
    try testing.expectEqualStrings(test_string, try builder.get());
}

test "basic concatination with size 1" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var builder: Builder = try Builder.init(allocator, 1);
    defer builder.deinit();

    try testing.expectEqual(@as(usize, 0), builder.len);
    try test_add_string(&builder);
    try testing.expectEqual(@as(usize, 13), builder.len);
    try testing.expectEqualStrings(test_string, try builder.get());
    try testing.expectEqual(@as(usize, 16), builder.buffer.len);
}

test "clear and isEmpty" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var builder: Builder = try Builder.init(allocator, 0);
    defer builder.deinit();

    try testing.expect(builder.isEmpty());

    try test_add_string(&builder);

    try testing.expect(!builder.isEmpty());
    try testing.expectEqualStrings(test_string, try builder.get());

    builder.clear();

    try testing.expect(builder.isEmpty());
    try testing.expectEqualStrings("", try builder.get());
    try testing.expectEqual(@as(usize, 0), builder.len);
}

const test_string = "Hello, world!";

fn test_add_string(builder: *Builder) !void {
    try builder.add("Hello");
    try builder.add(",");
    try builder.add(" ");
    try builder.add("world");
    try builder.add("!");
}

pub const JoinerOptions = struct {
    prefix: [:0]const u8 = "",
    delimiter: [:0]const u8 = "",
    suffix: [:0]const u8 = "",
    size: usize = 0,
};

pub const Joiner = struct {
    builder: Builder = undefined,
    options: JoinerOptions,
    isInitialized: bool = false,
    isFinalized: bool = false,

    pub fn init(allocator: std.mem.Allocator, options: JoinerOptions) !Joiner {
        return .{
            .builder = try Builder.init(allocator, options.size),
            .options = options,
        };
    }

    pub fn add(self: *Joiner, string: []const u8) !void {
        if (!self.isInitialized) {
            try self.builder.add(self.options.prefix);
            self.isInitialized = true;
        } else {
            try self.builder.add(self.options.delimiter);
        }
        try self.builder.add(string);
    }

    pub fn get(self: *Joiner) ![:0]u8 {
        if (!self.isInitialized) {
            try self.builder.add(self.options.prefix);
            self.isInitialized = true;
        }
        if (!self.isFinalized) {
            try self.builder.add(self.options.suffix);
            self.isFinalized = true;
        }
        return self.builder.get();
    }

    pub fn clear(self: *Joiner) void {
        self.builder.clear();
        self.isInitialized = false;
        self.isFinalized = false;
    }

    pub fn isEmpty(self: *Joiner) bool {
        return self.builder.len == 0;
    }

    pub fn deinit(self: *Joiner) void {
        self.builder.deinit();
    }

    pub fn len(self: *Joiner) usize {
        var length = self.builder.len;
        if (!self.isInitialized) {
            length += self.options.prefix.len;
        }
        if (!self.isFinalized) {
            length += self.options.prefix.len;
        }
        return length;
    }
};

test "empty joiner" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var joiner: Joiner = try Joiner.init(allocator, .{});
    defer joiner.deinit();

    try testing.expectEqualStrings("", try joiner.get());
}

test "comma delimited" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var joiner: Joiner = try Joiner.init(allocator, .{ .delimiter = "," });
    defer joiner.deinit();

    try joiner.add("one");
    try joiner.add("two");
    try joiner.add("three");

    try testing.expectEqualStrings("one,two,three", try joiner.get());
}

test "comma delimited with prefix and suffix" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var joiner: Joiner = try Joiner.init(allocator, .{ .prefix = "[", .delimiter = ",", .suffix = "]" });
    defer joiner.deinit();

    try joiner.add("one");
    try joiner.add("two");
    try joiner.add("three");

    try testing.expectEqualStrings("[one,two,three]", try joiner.get());
}

test "empty delimiter with prefix and suffix" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var joiner: Joiner = try Joiner.init(allocator, .{ .prefix = "[", .suffix = "]" });
    defer joiner.deinit();

    try joiner.add("one");
    try joiner.add("two");
    try joiner.add("three");

    try testing.expectEqualStrings("[onetwothree]", try joiner.get());
}

test "empty delimiter with no prefix or suffix" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var joiner: Joiner = try Joiner.init(allocator, .{});
    defer joiner.deinit();

    try joiner.add("one");
    try joiner.add("two");
    try joiner.add("three");

    try testing.expectEqualStrings("onetwothree", try joiner.get());
}
