# bufcycle.nvim

bufcycle.nvim is a simple plugin that provides `forward` and `backward`
functions for cycling over the list of open buffers. An optional customisation
point is provided via the user-defined `skip` callback, which determines if a
buffer should be opened or not. The plugin aims to make switching between
adjacent buffers less awkward compared to `:bprev` or `:bnext`, or simple
navigation of the jumplist via  `<C-i>`/ `<C-o>`. It is particularly useful in
combination with file explorer plugins such as [dirvish]() or [oil](), which
create temporary buffers the user may not be interested in revisiting.

## Prerequistes

- Neovim

## Installation

Using [lazy-nvim](https://github.com/folke/lazy-nvim)

```lua
```

Using [rocks.nvim](https://github.com/)

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

An optional `skip` function may be passed to the `setup` function. for example,
with the following configuration, any `dirvish` buffer should be skipped when
cycling through the buffer list using the `forward` or `backward` functions.

```lua
local bufcycle = require("bufcycle")

bufcycle.setup({
  skip = function(bufnr)
    return vim.bo[bufnr].filetype == 'dirvish'
  end,
})
```



