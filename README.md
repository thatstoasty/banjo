# Banjo

TUI building blocks in Mojo.

![Mojo Version](https://img.shields.io/badge/Mojo%F0%9F%94%A5-26.1-orange)
![Build Status](https://github.com/thatstoasty/banjo/actions/workflows/build.yml/badge.svg)
![Test Status](https://github.com/thatstoasty/banjo/actions/workflows/test.yml/badge.svg)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## Adding the `banjo` package to your project

First, you'll need to configure your `pixi.toml` file to include the Modular community Conda channel. Add `"https://repo.prefix.dev/modular-community"` to the list of channels.

### Installing it from the `modular-community` Conda channel

Run the following commands in your terminal:

```bash
pixi add banjo && pixi install
```

This will add `banjo` to your project's dependencies and install it along with its dependencies.

### Building it from source

There's two ways to build `banjo` from source: directly from the Git repository or by cloning the repository locally.

#### Building from source: Git

Run the following commands in your terminal:

```bash
pixi add -g "https://github.com/thatstoasty/banjo.git" && pixi install
```

#### Building from source: Local

```bash
# Clone the repository to your local machine
git clone https://github.com/thatstoasty/banjo.git

# Add the package to your project from the local path
pixi add -s ./path/to/banjo && pixi install
```

This is very much a work in progress, but please do check out the examples in the `examples/` directory to see how to use it!
If you need `termios` functionality, you can use `mist`, which provides `termios` bindings and wrappers instead of `banjo` which attempts to provide a user friendly abstraction over terminal manipulation.

## Examples

### Sample

![Sample demo](https://github.com/thatstoasty/banjo/blob/main/doc/tapes/sample.gif)

### Snake

![Snake demo](https://github.com/thatstoasty/banjo/blob/main/doc/tapes/snake.gif)

## TODO

- Add alternate screen buffer support to renderer.
