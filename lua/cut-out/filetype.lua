---@type table<string, cutout.filetype>
local M = {}
local ts = vim.treesitter
local get_node_str = ts.get_node_text
local my_ts = require("cut-out.ts")
local get_text = my_ts.get_text

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
            if get_node_str(node:field("name")[1], 0) == "require" then
                local module = node:field("arguments")[1]:child(1)
                if module and module:type() == "string" then
                    local content = module:field("content")[1]
                    local path = vim.split(get_node_str(content, 0), "[./]")
                    return (path[#path]:gsub("[-%.]", "_"))
                end
            end
        elseif node_type == "dot_index_expression" then
            -- default to the field name
            return get_node_str(node:field("field")[1], 0)
        end
    end
}

local ft_c = require("cut-out.filetypes.c")
M.c = ft_c
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

M.typst = {
    make_assignment = function(name, replacement)
        local text = get_text(replacement)
        text[1] = ("let %s = %s"):format(name, text[1])
        return text
    end
}

return M
