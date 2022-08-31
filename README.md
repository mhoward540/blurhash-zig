# blurhash-zig
Implementation of [BlurHash](https://github.com/woltapp/blurhash) algorithm in [Zig](https://ziglang.org/). For now it only supports encoding an image as a Hash

The [Nim implmentation](https://github.com/SolitudeSF/blurhash) of BlurHash was used heavliy as a reference for this code

I also used [Zig Image Library](https://github.com/zigimg/zigimg) (aka zigimg) and [Zig String](https://github.com/JakubSzark/zig-string) as dependencies to make my life a lot easier

# Usage
This code targets Zig 0.9.1 which is the latest stable release as of the code being written, so ensure that is installed before trying to run this. The dependency libraries are pinned to versions which work with Zig 0.9.1

## Running on the command line
```
zig build run -- /path/to/image
```

## Using as a library (not functioning - WIP)
Clone down the repo as a submodule of your project. Then add the package path `blurhash-zig` to your `build.zig` like so:
```zig
exe.addPackagePath("blurhash", "blurhash-zig/src/blurhash.zig");
```

Then import it in your code:
```zig
const blurhash = @import("blurhash");
```

You need to pass an instance of a `zigimg.Image` to the blurhash `encode` function right now, so you'll probably need zigimg as a dependency for your own code as well

## Running tests
```
zig build test
```

# Image format support
It can read all file formats supported by zigimg, though I've only tested and confirmed PNG and QOI images as working. This implmentation does not handle Alpha values / transparency, so it will return an error when encountering an image which has any transparency. 
