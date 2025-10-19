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

## Configuration
Configure cut-out by passing a table of options.
Lazy-loading should not be necessary as the bulk of the plugin is only loaded
once the keys are typed.

### Customizing behavior per filetype
Change or set an entry inside the `opts.assigners` or `opts.replacers` table to a function.

## Supported Languages (PRs welcome)
| Language | Assigning | Custom Replacer
|----------|-----------|-
| C        | Partially[^1]| No
| Lua      | Supported | No
| Shell    | Supported | Yes

[^1]: For typed languages it can be hard to impossible to get the type of an expression.
