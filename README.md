# bufcycle.nvim

bufcycle.nvim is a simple plugin that provides `forward` and `backward`
functions for cycling over the list of open buffers. An optional customisation
point is provided via the user-defined `skip` callback, which determines if a
buffer should be opened or not. The plugin aims to provide easier switching
between buffers when compared to `:bprev`/`:bnext`, or jump list
navigation via `<C-i>`/`<C-o>`. It is particularly useful in combination with
file explorer plugins such as
[dirvish](https://github.com/justinmk/vim-dirvish) or
[oil](https://github.com/stevearc/oil.nvim), which create temporary buffers that
a user would typically need to skip when switching between buffers.

## Prerequisites

- Neovim

## Installation

### Using [lazy-nvim](https://github.com/folke/lazy.nvim)

Add the following to your `lua/plugins.lua` file, adjust as needed

```lua
{
  'pacidic/bufcycle.nvim',
  config = function()
    local bufcycle = require("bufcycle")

    bufcycle.setup({
      skip = function(bufnr)
        return vim.bo[bufnr].filetype == 'dirvish'
      end,
      enable_bounded_buffer_iteration = true,
    })

    vim.keymap.set("n", '<C-n>', bufcycle.forward)
    vim.keymap.set("n", '<C-p>', bufcycle.backward)
    vim.keymap.set("n", '<C-l>', bufcycle.return_to_last_bufcycle_start)
  end,
}
```

### Using [rocks.nvim](https://github.com/nvim-neorocks/rocks.nvim)

Make sure the following lines are listed somewhere in the `[plugins]` section in the `rocks.toml` file

```
"rocks-git.nvim" = "scm"
"bufcycle.nvim" = { git = "pacidic/bufcycle.nvim" }
```

Create a `plugins/bufcycle.lua` file containing e.g.

```lua
local bufcycle = require("bufcycle")

bufcycle.setup({
  skip = function(bufnr)
    return vim.bo[bufnr].filetype == 'dirvish'
  end,
  enable_bounded_buffer_iteration = true,
})

vim.keymap.set("n", '<C-n>', bufcycle.forward)
vim.keymap.set("n", '<C-p>', bufcycle.backward)
vim.keymap.set("n", '<C-l>', bufcycle.return_to_last_bufcycle_start)
```

## Configuration

### `setup` table options

`enable_bounded_buffer_iteration`

If set to true, this enables "bounded" iteration, i.e. iteration through the
buffer history without cycling back to the initial buffer.

`skip`

A function that is called on every buffer switch when cycling through buffers.
The function takes the buffer number as an argument. If true is returned, then
the buffer is skipped by bufcycle.

### API functions

bufcycle.nvim does not provide any default key bindings. Instead, the following
functions should be bound to a suitable key mapping by the user.

`backward`

Starts a bufcycle, moves to previous buffer.

`forward`

Moves to next buffer while performing a bufcycle.

`return_to_last_bufcycle_start`

Returns to the buffer where the last bufcycle was started.
