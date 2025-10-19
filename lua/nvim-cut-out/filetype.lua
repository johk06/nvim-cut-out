local M = {}

---@type table<string, cutout.replacer>
M.replacers = {}
---@type table<string, cutout.assigner>
M.assigners = {}

M.assigners.lua = function(name, replacement)
    local text = vim.split(vim.treesitter.get_node_text(replacement, 0), "\n")
    text[1] = ("local %s = %s"):format(name, text[1])

    return text
end


return M
