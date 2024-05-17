# blurhash-zig
Implementation of [BlurHash](https://github.com/woltapp/blurhash) algorithm in [Zig](https://ziglang.org/). For now it only supports encoding an image as a Hash

The [Nim implementation](https://github.com/SolitudeSF/blurhash) of BlurHash was used heavliy as a reference for this code

I also used [Zig Image Library](https://github.com/zigimg/zigimg) (aka zigimg) as a dependency to make my life a lot easier. Dependency management is handled with the official Zig package manager (see build.zig.zon)

# Usage
This code targets Zig 0.12.0 which is the latest stable release as of the code being written, so ensure that is installed before trying to run this.

The dependency libraries are pinned to versions which work with Zig 0.12.0

## Running on the command line
```
zig build run -- /path/to/image
```

## Using as a library
Add `blurhash-zig` to your `build.zig.zon` and into your build process from `build.zig`. As a reference, you can look at how this repo adds `zigimg` as a dependency

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

# Acknolwedgements
Thanks to [alexkuz](https://github.com/alexkuz) for updating this repo to work with Zig 0.12.0 and for heavy performance optimizations!