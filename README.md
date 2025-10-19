# nvim-cut-out
Speed up refactoring by extracting reused expressions into a single variable.

## Features
- Treesitter aware expression selection - insignificant whitespace, commas etc are ignored.
- Interactive preview for matched expressions
- Easy selection via textobjects
- Customizable modification and creation of assignment statements

## Installation
Use any package manager.

## Usage
Use the `co` operator to **c**ut **o**ut text.
A replacement will be put into the specified register (`"` by default).

### Example
Look at the following lua example
```lua
local f = function(array)
    local var = array[1][1] + 1
    local another = array[1][1] - 20
end
```

- with your cursor on `var` hit `coiW` (cut out inner WORD)
- type `ip` to replace the highlighted matches in the current paragraph
- type `first<cr>` to select the name for your new variable
- type `p` to paste the generated assignment
