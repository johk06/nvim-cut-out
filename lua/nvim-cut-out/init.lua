local M = {}

---@alias cutout.replacer fun(name: string, replacement: TSNode, node: TSNode): string[]
---@alias cutout.assigner fun(name: string, replacement: TSNode): string[]

---@class cutout.config
---@field keys string? Set to false to not create mappings
---@field hl_group string?
---@field prompt string|fun(replacement: TSNode): string
---@field replacers table<string, cutout.replacer>
---@field assigners table<string, cutout.assigner>

local ft = require("nvim-cut-out.filetype")

---@type cutout.config
local options = {
    keys = "co",
    hl_group = "Visual",
    prompt = "Name: ",
    replacers = ft.replacers,
    assigners = ft.assigners,
}


M.setup = function(overrides)
    local opts = vim.tbl_deep_extend("force", options, overrides)
    M.options = opts

    if opts.keys then
        vim.keymap.set({"x", "n"}, opts.keys, M.operator, {
            desc = "Cut out expression",
            expr = true
        })
    end
end

M.operator = function()
    vim.o.operatorfunc = "v:lua.require'nvim-cut-out.operator'.opfunc"
    return "g@"
end


local f = function(array)
    local var = array[1][1] + 1
    local another = array[1][1] - 20
end

return M
