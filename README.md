# Termios

TUI building blocks in Mojo via `libc`.

## Installation

1. First, you'll need to configure your `pixi.toml` file to include my Conda channel. Add `"https://repo.prefix.dev/mojo-community"` to the list of channels.
2. Next, add `banjo` to your project's dependencies by running `pixi add banjo`.
3. Finally, run `pixi install` to install in `banjo`. You should see the `.mojopkg` files in `$CONDA_PREFIX/lib/mojo/`.

This is very much a work in progress, but please do check out the examples in the `examples/` directory to see how to use it!
If you need `termios` functionality, you can use `mist`, which provides `termios` bindings and wrappers instead of `banjo` which attempts to provide a TEA based interface over it (like `charmbracelet/bubbletea in Go).
