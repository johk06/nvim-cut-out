local M = {}
local ts = vim.treesitter

---@type table<string, cutout.replacer>
M.replacers = {}
---@type table<string, cutout.assigner>
M.assigners = {}

M.assigners.lua = function(name, replacement)
    local text = vim.split(ts.get_node_text(replacement, 0), "\n")
    text[1] = ("local %s = %s"):format(name, text[1])

    return text
end

M.assigners.c = function(name, replacement)
    local expr_type = replacement:type()
    local val = ts.get_node_text(replacement, 0)
    local text = vim.split(val, "\n")
    local c_type = "auto"
    if expr_type == "number_literal" then
        local is_float = val:find("%.")
        if is_float then
            c_type = "double"
        else
            c_type = "int"
        end
    elseif expr_type == "string_literal" then
        c_type = "const char*"
    else
        print(expr_type)
    end

    text[1] = ("%s %s = %s"):format(c_type, name, text[1])
    text[#text] = text[#text] .. ";"
    return text
end

---@type cutout.replacer
local sh_replacer = function(name, replacement, node)
    local expr_type = node:type()
    if expr_type == "string" then
        return { ('"${%s}"'):format(name) }
    end
    return { ("${%s}"):format(name) }
end

M.replacers.sh = sh_replacer
M.replacers.bash = sh_replacer

---@type cutout.assigner
local sh_assigner = function(name, replacement)
    local text = vim.split(ts.get_node_text(replacement, 0), "\n")
    text[1] = ("%s=%s"):format(name, text[1])
    return text
end

M.assigners.sh = sh_assigner
M.assigners.bash = sh_assigner


return M
