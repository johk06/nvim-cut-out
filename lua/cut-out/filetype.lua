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
    local c_type
    if not name:find("%S%s+%S") then
        if expr_type == "number_literal" then
            local is_float = val:find("%.")
            if is_float then
                c_type = "double"
            else
                c_type = "int"
            end
        elseif expr_type == "string_literal" then
            c_type = "const char*"
        elseif expr_type == "sizeof_expression" then
            c_type = "size_t"
        else
            print(expr_type)
            c_type = "auto"
        end
    end

    if c_type then
        text[1] = ("%s %s = %s"):format(c_type, name, text[1])
    else
        text[1] = ("%s = %s"):format(name, text[1])
    end
    text[#text] = text[#text] .. ";"
    return text
end

M.replacers.c = function(name, replacement, node)
    local split = vim.split(name, " ")
    local last = split[#split]
    -- handle that way of declaring a pointer
    local var = last:gsub("%s*%*", "")
    return { var }
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
