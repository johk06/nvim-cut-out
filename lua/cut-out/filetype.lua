---@type table<string, cutout.filetype>
local M = {}
local ts = vim.treesitter

---@param node TSNode
---@return string[]
local get_text = function(node)
    return vim.split(ts.get_node_text(node, 0), "\n")
end

M.lua = {
    make_assignment = function(name, replacement)
        local text = get_text(replacement)
        text[1] = ("local %s = %s"):format(name, text[1])

        return text
    end,
    suggest_name = function(node)
        local node_type = node:type()
        if node_type == "function_call" then
            -- for requires: default to the last element of the module name
            if ts.get_node_text(node:field("name")[1], 0) == "require" then
                local module = node:field("arguments")[1]:child(1)
                if module and module:type() == "string" then
                    local content = module:field("content")[1]
                    local path = vim.split(ts.get_node_text(content, 0), "[./]")
                    return (path[#path]:gsub("[-%.]", "_"))
                end
            end
        elseif node_type == "dot_index_expression" then
            -- default to the field name
            return ts.get_node_text(node:field("field")[1], 0)
        end
    end
}

M.c = {
    suggest_name = function(node)
        local expr_type = node:type()
        local text = get_text(node)

        if expr_type == "number_literal" then
            local is_float = text[1]:find("%.")
            if is_float then
                return "double "
            else
                return "int "
            end
        elseif expr_type == "string_literal" then
            return "const char* "
        elseif expr_type == "sizeof_expression" or text[1]:find("sizeof") then
            return "size_t "
        end
    end,
    make_assignment = function(name, replacement)
        local text = get_text(replacement)

        if not name:find("%S%s+%S") then
            -- if we get no type, we need to do something
            text[1] = ("auto %s = %s"):format(name, text[1])
        else
            text[1] = ("%s = %s"):format(name, text[1])
        end
        text[#text] = text[#text] .. ";"
        return text
    end,
    make_replacement = function(name, replacement, node)
        local split = vim.split(name, " ")
        local last = split[#split]
        -- handle that way of declaring a pointer
        local var = last:gsub("%s*%*", "")
        return { var }
    end
}

M.python = {
    make_assignment = function(name, replacement)
        local text = get_text(replacement)
        text[1] = ("%s = %s"):format(name, text[1])

        return text
    end
}

---@type cutout.filetype
local sh_type_languages = {
    make_assignment = function(name, replacement)
        local text = get_text(replacement)
        text[1] = ("%s=%s"):format(name, text[1])
        return text
    end,
    make_replacement = function(name, replacement, node)
        local expr_type = node:type()
        if expr_type == "string" then
            return { ('"${%s}"'):format(name) }
        end
        return { ("${%s}"):format(name) }
    end,
}
M.bash = sh_type_languages
M.sh = sh_type_languages
M.zsh = sh_type_languages


return M
