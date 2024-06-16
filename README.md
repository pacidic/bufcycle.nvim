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
    })

    vim.keymap.set("n", '<C-n>', bufcycle.forward)
    vim.keymap.set("n", '<C-p>', bufcycle.backward)
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
})

vim.keymap.set("n", '<C-n>', bufcycle.forward)
vim.keymap.set("n", '<C-p>', bufcycle.backward)
```

## Configuration

bufcycle.nvim does not provide any default key bindings. Instead, the `forward`
and `backward` functions should be bound to a suitable key combination by the
user, e.g.

```lua
local bufcycle = require("bufcycle")

vim.keymap.set("n", '<C-n>', bufcycle.forward)
vim.keymap.set("n", '<C-p>', bufcycle.backward)
```

An optional `skip` function may be provided via the `setup` function. With the
following configuration, any `dirvish` buffer should be skipped when calling
the `forward` or `backward` functions:

```lua
local bufcycle = require("bufcycle")

bufcycle.setup({
  skip = function(bufnr)
    return vim.bo[bufnr].filetype == 'dirvish'
  end,
})
```



