# zigStringUtil

a small library with little helpers for String handling.

## Builder

can be used to concatinate strings together

## Joiner

simmilar to Builder used to concatenate strings but it can add a prefix, suffix and insert delimiter

## zig module
To use this as a module in you project create a `build.zig.zon` file, adding zigStringUtil as dependency.

The url and hash are from the current master version, tested with zig 0.11.0

```zig
.{ 
    .name = "myProject", 
    .version = "0.0.1", 
    .dependencies = .{ 
        .zigStringUtil = .{
            .url = "https://github.com/SuSonicTH/zigStringUtil/archive/66577eecdd273b626fe59b6d46b3349331fda632.tar.gz",
            .hash = "1220024750ad8df560a590919c57725eda68f68f7756d443aa32a3a8be8ee21905a9",
        } 
    } 
}
```

and in your `build.zig` add the module as dependecy
```zig
const zigStringUtil = b.dependency("zigStringUtil", .{
    .target = target,
    .optimize = optimize,
});
```

and add it as a module to your exe/lib
```zig
//sample exe
const exe = b.addExecutable(.{
    .name = "zli",
    .root_source_file = .{ .path = "src/main.zig" },
    .target = target,
    .optimize = optimize,
});

//add module
exe.addModule("zigStringUtil", zigStringUtil.module("zigStringUtil"));
```
