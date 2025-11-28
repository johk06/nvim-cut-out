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
    - Suggestions for likely names, e.g. for module imports
- Using a regular textobject allows undoing in only two steps:
    - One for pasting the declaration
    - One for the expression replacement

## Installation
Use any plugin manager.
To setup call the `setup()` method of the `require("cut-out")` module,
or let your plugin manager handle the setup, for example by setting the `opts` field for lazy.

## Usage
Use the `co` operator (by default) to **c**ut **o**ut text.
A replacement will be put into the specified register (the unnamed register by default).

All of the below examples can be tried in this buffer as long as you have the treesitter parsers for those languages installed.

### Lua Examples

#### Factor out a reused expression
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

#### Cache a `require`d module
```lua
print(require("lib.useful-module"))

require("lib.useful-module").func(1)
```

- with your cursor on the beginning of the first line, type `coib`
- type `2j` to apply to the whole file
- the name `useful_module` will be suggested
- hit `<cr>` to accept it or edit it
- paste the assignment at the beginning of the file

### C Example
```c
size_t bufsize = sizeof(struct some_struct) * size;
some_struct* do_something(some_struct* s, size_t size) {
    some_struct* s1 = malloc(bufsize);
    some_struct* s2 = malloc(bufsize);
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
Change or set an entry inside the `opts.filetype` table.
The supported fields are:
- `make_replacement`: Generate the text that will be put where the expression was
- `make_assignment`: Generate the assignment statement
- `suggest_name`: Suggest a likely name

## Fully Supported Languages (PRs welcome)
Fully supported means:
- The language's variable reference syntax is handled (this matters mostly for
  languages that use sigils, like `$var` in the shell)
- Assignments can be generated automatically
  If this cannot be done, the replacement will still be performed but you need to type the declaration yourself
- Likely variable names are generated for common use cases

| Language | Assigning    | Custom Replacer | Name Suggestions |
|----------|--------------|-----------------|-
| C        | Partially[^1]| No              | No
| Lua      | Supported    | No              | Yes
| Shell[^2]| Supported    | Yes             | No
| Python   | Supported    | No              | No

[^1]: For typed languages it can be hard or impossible to get the type of an expression.
Cut-Out will do it's best for constants, string literals etc, but it's best if you
manually specify a type by just inputting the full declaration.

[^2]: `bash`, Plain `sh` and `zsh`
