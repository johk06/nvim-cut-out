local M = {}
local vim_ts = vim.treesitter

---@param parser vim.treesitter.LanguageTree
---@param range1 Range4
---@param range2 Range4
M.node_for_range = function(parser, range1, range2)
    return parser:node_for_range(range1) or parser:tree_for_range(range2):root()
end

---@param node TSNode
---@param dest table
local function rec_serialize_node(node, dest)
    if node:child_count() == 0 then
        if node:named() then
            local expr_type = node:type()
            table.insert(dest, {
                expr_type, vim_ts.get_node_text(node, 0)
            })
        end
    else
        for n, f in node:iter_children() do
            if n:child_count() > 0 then
                local tbl = { f, n:type() }
                table.insert(dest, tbl)
                rec_serialize_node(n, tbl)
            else
                rec_serialize_node(n, dest)
            end
        end
    end
end

---@param node TSNode
---@return table
local serialize_node = function(node)
    local dest = {}
    rec_serialize_node(node, dest)
    return dest
end

---@param a any
---@param b any
---@return boolean
local function compare_serial_nodes(a, b)
    if type(a) == "table" and type(b) == "table" then
        if #a ~= #b then
            return false
        end
        for i = 1, #a do
            if not compare_serial_nodes(a[i], b[i]) then
                return false
            end
        end
        return true
    else
        return a == b
    end
end

---@param type string
---@param needle table
---@param haystack TSNode
---@param dest TSNode[]
---@param range Range4
local function find_matching_nodes(type, needle, haystack, dest, range)
    for n, f in haystack:iter_children() do
        local s = serialize_node(n)
        if n:type() == type and compare_serial_nodes(s, needle) then
            ---@diagnostic disable-next-line: missing-fields Lua 5.1 allows for this
            if vim_ts._range.contains(range, { n:range() }) then
                table.insert(dest, n)
            end
        else
            find_matching_nodes(type, needle, n, dest, range)
        end
    end
end

---@param needle TSNode
---@param haystack TSNode
---@param range Range4
---@return TSNode[]
M.find_matching_inside_node = function(needle, haystack, range)
    local s = serialize_node(needle)
    local dest = {}
    find_matching_nodes(needle:type(), s, haystack, dest, range)
    return dest
end

return M
