# Cut-Out for Neovim
Speed up refactoring by extracting expressions into a variable.
While avoiding having to come up with a regex to match exactly what you want.

## Features
- Quickly refactor reused expressions by turning them into a single variable
- Treesitter based expression selection - insignificant whitespace (including newlines), commas etc are ignored.
- No LSP required
- Interactive preview for matched expressions
- Easy selection via textobjects
- Customizable modification and creation of assignment statements
    - Allows for language specific behavior, conventions etc
- Using a regular textobject allows undoing in two steps:
    - One for pasting the declaration
    - One for the expression replacement

## Installation
Use any plugin manager.
To setup call the `setup()` method of the `require("cut-out")` module,
or let your plugin manager handle the setup, for example by setting the `opts` field for lazy.

## Usage
Use the `co` operator (by default) to **c**ut **o**ut text.
A replacement will be put into the specified register (the unnamed register by default).

### Lua Example
```lua
local f = function(array)
    local var = array[1][1] + 1
    local another = array[1][1] - 20
end
```
- with your cursor on `array` hit `coiW` (cut out inner WORD)
- type `ip` to replace the highlighted matches in the current paragraph
- type `first<cr>` to select the name for your new variable
- type `p` to paste the generated assignment

### C Example
```c
some_struct* do_something(some_struct* s, size_t size) {
    some_struct* s1 = malloc(sizeof(struct some_struct) * size);
    some_struct* s2 = malloc(sizeof(struct some_struct) * size);
}
```
- with your cursor anywhere inside `malloc(...)` press `coi(` (cut-out inside parentheses)
- press `a{` to change for the entire function
- type `size_t bufsize<cr>` to specify the type and name
- press `p` to paste the generated declaration

## Configuration
Configure cut-out by passing a table of options.
Lazy-loading should not be necessary as the bulk of the plugin is only loaded
once the keys are typed.

### Changing the keybind
The `co` keys are not used by default anywhere in vim, so they should work.
If you want to use any other keys, simple change the `opts.keys`.
Setting it to `false` will allow you to manually map the function.
```lua
-- manually call the operator
require("cut-out").operator()
```

### Customizing behavior per filetype
Change or set an entry inside the `opts.assigners` or `opts.replacers` table to a function.

## Fully Supported Languages (PRs welcome)
| Language | Assigning | Custom Replacer
|----------|-----------|-
| C        | Partially[^1]| No
| Lua      | Supported | No
| Shell    | Supported | Yes

[^1]: For typed languages it can be hard or impossible to get the type of an expression.
Cut-Out will do it's best for constants, string literals etc, but it's best if you
manually specify a type by just inputting the full declaration.
