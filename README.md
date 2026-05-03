# atob.nvim

Neovim plugin wrapper for [atob](https://github.com/wingitman/atob) — a
universal CLI conversion tool.

## Requirements

- Neovim 0.10+
- The `atob` binary on your `PATH` (see [atob install instructions](https://github.com/wingitman/atob#install))

## Installation

### lazy.nvim

```lua
{
  'wingitman/atob.nvim',
  config = function()
    require('atob').setup()
  end,
}
```

### packer.nvim

```lua
use {
  'wingitman/atob.nvim',
  config = function()
    require('atob').setup()
  end,
}
```

## Configuration

```lua
require('atob').setup({
  -- Path or name of the atob binary (must be on PATH or an absolute path)
  binary = 'atob',

  -- Visual-mode keymap to convert the current selection in-place.
  -- Set to false to disable.
  keymap = '<leader>ab',
})
```

## Usage

### Normal mode — `:Atob`

Opens a `vim.ui.select` picker listing every available converter.

- For **text converters**: prompts for input, shows the result in a floating
  window. Press `y` to copy to clipboard, `q`/`<Esc>`/`<CR>` to close.
- For **file converters** (csv↔xlsx): prompts for input and output file paths,
  runs the conversion, shows a status notification.

### Visual mode — `<leader>ab` (default)

Select any text in visual mode, press the keymap, pick a converter — the
selection is **replaced in-place** with the converted output.

Works with characterwise (`v`), linewise (`V`), and block (`<C-v>`) selections.

## Examples

| Action | How |
|---|---|
| Base64-encode a word | Select word in visual, `<leader>ab`, pick `base64-encode` |
| Pretty-print JSON | Select JSON blob, `<leader>ab`, pick `json-pretty` |
| Generate a UUID | `:Atob`, pick `uuid-generate`, leave input blank |
| Convert epoch | `:Atob`, pick `epoch-human`, enter the timestamp |
| csv → xlsx | `:Atob`, pick `csv-xlsx`, enter paths when prompted |

## Project structure

```
atob.nvim/
├── plugin/
│   └── atob.lua          # auto-loaded stub, guards double-init
└── lua/
    └── atob/
        ├── init.lua      # setup(), config merging, command/keymap registration
        ├── core.lua      # shells out to atob binary (list, convert, convert_file)
        ├── picker.lua    # vim.ui.select picker + floating result window
        └── visual.lua    # visual selection capture and in-place replacement
```
