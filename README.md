# blurhash-zig
Implementation of [BlurHash](https://github.com/woltapp/blurhash) algorithm in [Zig](https://ziglang.org/). For now it only supports encoding an image as a Hash

The [Nim implementation](https://github.com/SolitudeSF/blurhash) of BlurHash was used heavliy as a reference for this code

I also used [Zig Image Library](https://github.com/zigimg/zigimg) (aka zigimg) and [Zig String](https://github.com/JakubSzark/zig-string) as dependencies to make my life a lot easier. Dependency management is handled with the unofficial package manager [gyro](https://github.com/mattnite/gyro)

# Usage
This code targets Zig 0.9.1 which is the latest stable release as of the code being written, so ensure that is installed before trying to run this.

This also uses gyro to handle dependencies. As this code uses Zig 0.9.1, and the current release of gyro seemst to expect a build from the current master branch (higher than 0.10.0-dev), you need to install a compatible version of gyro. [0.4.1 worked for me](https://github.com/mattnite/gyro/releases/tag/0.4.1) 

The dependency libraries are pinned to versions which work with Zig 0.9.1

## Running on the command line
```
gyro build run -- /path/to/image
```

## Using as a library
Init your gyro project and add this repo as a dependency. Ensure your `build.zig` uses the gyro generated `deps.zig`. You can check the `build.zig` from this repo as a reference to see what that might look like
```bash
gyro init
gyro add --src github mhoward540/blurhash-zig
```

Then import it in your code:
```zig
const blurhash = @import("blurhash");
```

You need to pass an instance of a `zigimg.Image` to the blurhash `encode` function right now, so you'll probably need zigimg as a dependency for your own code as well

## Running tests
```
gyro build test
```

# Image format support
It can read all file formats supported by zigimg, though I've only tested and confirmed PNG and QOI images as working. This implmentation does not handle Alpha values / transparency, so it will return an error when encountering an image which has any transparency. 
