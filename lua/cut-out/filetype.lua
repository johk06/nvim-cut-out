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
        local text = get_text(node)
        if #text == 1 then
            local module = text[1]:match [[^%s*require%(['"]([^'"]+)['"]%)%s*$]]
            if module then
                local path = vim.split(module, "[./]")
                return (path[#path]:gsub("[-%.]", "_"))
            end
        end
    end
}

M.c = {
    make_assignment = function(name, replacement)
        local expr_type = replacement:type()
        local text = get_text(replacement)
        local c_type
        if not name:find("%S%s+%S") then
            if expr_type == "number_literal" then
                local is_float = text[1]:find("%.")
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
