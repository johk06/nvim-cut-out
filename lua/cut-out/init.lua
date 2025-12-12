local M = {}

---@alias cutout.replacer fun(name: string, replacement: TSNode, node: TSNode): string[]
---@alias cutout.assigner fun(name: string, replacement: TSNode): string[]?
---@alias cutout.name_suggester fun(node: TSNode): string?

---@class cutout.filetype
---@field make_replacement cutout.replacer?
---@field make_assignment cutout.assigner?
---@field suggest_name cutout.name_suggester?

---@class cutout.config
---@field keys string|false? Set to false to not create mappings
---@field visual_keys string|false? Set to false to not create mappings
---@field hl_group string?
---@field prompt string
---@field filetypes table<string, cutout.filetype>


---@type cutout.config
---@diagnostic disable-next-line: missing-fields Populate them only in setup()
local options = {
    keys = "co",
    visual_keys = "R",
    hl_group = "Visual",
    prompt = "Extract as: ",
}


M.setup = function(overrides)
    local ft = require("cut-out.filetype")
    options.filetypes = ft
    local opts = vim.tbl_deep_extend("force", options, overrides)
    M.options = opts

    if opts.keys then
        vim.keymap.set("n", opts.keys, M.operator, {
            desc = "Cut out expression",
            expr = true
        })
    end
    if opts.visual_keys then
        vim.keymap.set("x", opts.visual_keys, M.operator, {
            desc = "Cut out expression",
            expr = true
        })
    end
end

M.operator = function()
    vim.o.operatorfunc = "v:lua.require'cut-out.operator'.opfunc"
    return "g@"
end

return M
