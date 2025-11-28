# nvim-cut-out

Cutout (or Cut-Out) is a general purpose plugin to aid in refactoring code.
It does this by allowing a user to extract reused expressions into variables.

## Features
- Quickly refactor reused expressions by turning them into a single variable.
- Treesitter based expression selection - insignificant whitespace (including newlines), commas etc are ignored.
- No LSP required
- Interactive preview for matched expressions
- Easy selection via textobjects
- Customizable expression replacement and creation of assignment statements
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

This operator takes *two* textobjects (unlike vanilla Vim commands like `d` or `c`).
The first textobject specifies what you want to cut out, it will be expanded to cover
the entire treesitter node.
The second textobject specifies in which region you want to perform that substitution.

You can try the examples below  in this file if you have the treesitter parsers installed.

## Examples

### Lua - Factor out a reused expression

```lua
local f = function(array)
    local var = array[1][1] + 1
    local another = array[1][1] - 20
end
```

1. with your cursor on `array` hit `coiW` (cut out inner WORD)
2. type `ip` to replace the highlighted matches in the current paragraph
3. type `first<cr>` to select the name for your new variable
4. type `p` to paste the generated assignment

### Lua - Cache a `require`d module

```lua
print(require("lib.useful-module").field)

require("lib.useful-module").func(1)
```

1. with your cursor on the beginning of the first line, type `coi(` (cut out inside parentheses)
2. type `2j` to apply to the whole block (in a real file, use `G`)
3. the name `useful_module` will be suggested
4. hit `<cr>` to accept it or edit it
5. paste the assignment at the beginning of the block (use `P` to paste above)

### C - Cut out calculated allocation size

```c
some_struct* do_something(some_struct* s, size_t size) {
    some_struct* s1 = malloc(sizeof(struct some_struct) * size);
    some_struct* s2 = malloc(sizeof(struct some_struct) * size);
}
```

1. with your cursor anywhere before or inside `malloc(...)` press `coi(` (cut out inside parentheses)
2. press `a{` to change for the entire function
3. since the `sizeof` statement is included, the type `size_t` will be suggested
4. type `bufsize<cr>` to specify the name
5. press `p` to paste the generated declaration

## Configuration
Simply pass an option table to the setup function as usual.
Lazy-loading should not be necessary as the bulk of the plugin is only loaded
once the key mapping is invoked.

### Changing the mapping
The keys `co` are not used by default anywhere in (Neo)Vim, so they should work.
If you want to use other keys, simple change the `opts.keys` option.
Setting it to `false` will allow you to manually map the function.

```lua
-- manually call the operator
require("cut-out").operator()
```

Recommended alternatives to `co`:
- `yc` "yank common"
- `yd` "yank definition"
- `cr` "cut reused"

### Customizing behavior per filetype
Cutout can be configured to behave differently for any filetype.
To do this, change or set an entry inside the `opts.filetype` table.
The supported fields are:
- `make_replacement`: Generate the text that will be put where the expression was
- `make_assignment`: Generate the assignment statement that will be yanked
- `suggest_name`: Suggest a conventional/useful name.
  For typed languages, this should also generate the likely type of the expression.

## Fully Supported Languages (PRs welcome)
Fully supported means:
- The language's variable reference syntax is handled. This mostly matters for
  languages that use sigils, like `$var` in the shell.
- Assignments can be generated automatically.
  If this cannot be done, the replacement will still be performed but you need to type the declaration yourself.
- A likely name for the variable is suggested.

| Language | Assigning    | Custom Replacer | Name Suggestions
|----------|--------------|-----------------|-
| C        | Partially[^1]| No              | Yes
| Lua      | Supported    | No              | Yes
| Shell[^2]| Supported    | Yes             | No
| Python   | Supported    | No              | No

[^1]: For typed languages it can be hard or impossible to get the type of an expression.
This plugin will do its best for constants, string literals etc, and present that as part of the name suggestion.
If there is no good type generated there, specify it manually.

[^2]: `bash`, plain `sh` and `zsh`

## Tips & Recipes
### Syntax-aware textobjects
Using something like [nvim-treesitter-textobjects](https://github.com/nvim-treesitter/nvim-treesitter-textobjects)
greatly improves the efficiency of Cutout.

E.g. you could use `coiaif` to factor out the value of the function argument
under the cursor in the whole function.
