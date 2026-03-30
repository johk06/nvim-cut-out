---@type cutout.filetype
local M = {}

local ts = vim.treesitter
local get_node_str = ts.get_node_text
local my_ts = require("cut-out.ts")
local get_text = my_ts.get_text

---@param t string
---@param node TSNode
---@param text string
---@return string?
local infer_ctype = function(t, node, text)
    if t == "number_literal" then
        local is_float = text:find("%.")
        if is_float then
            return "double"
        else
            return "int"
        end
    elseif t == "cast_expression" or t == "compound_literal_expression" then
        -- an explicit cast is one of the few situations where we know the type for certain
        return get_node_str(node:field("type")[1], 0)
    elseif t == "string_literal" then
        return "const char*"
    elseif t == "sizeof_expression" or text:find("sizeof") then
        return "size_t"
    elseif t == "char_literal" then
        return "char"
    else
        vim.print({t, node:sexpr()})
    end

    return nil
end

M.suggest_name = function(node)
    local expr_type = node:type()
    local text = get_node_str(node, 0)
    local type = infer_ctype(expr_type, node, text)

    if type then
        return ("%s "):format(type)
    else
        return nil
    end
end

M.make_assignment = function(name, replacement)
    local text = get_text(replacement)

    if not name:find("%S%s+%S") then
        -- if we get no type, we need to do something
        text[1] = ("auto %s = %s"):format(name, text[1])
    else
        text[1] = ("%s = %s"):format(name, text[1])
    end
    text[#text] = text[#text] .. ";"
    return text
end

M.make_replacement = function(name, replacement, node)
    local split = vim.split(name, " ")
    local last = split[#split]
    -- handle that way of declaring a pointer
    local var = last:gsub("%s*%*", "")
    return { var }
end


return M
