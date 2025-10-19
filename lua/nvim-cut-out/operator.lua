local M = {}

local vim_ts = vim.treesitter
local api = vim.api
local my_ts = require("nvim-cut-out.ts")
local hlns = api.nvim_create_namespace("nvim-cut-out")
local config = require("nvim-cut-out").options
local replacers = config.replacers
local assigners = config.assigners

local function get_mark(mark)
    return api.nvim_buf_get_mark(0, mark)
end

---@return Range4
local function get_op_region(mode)
    local start, stop
    if mode == "visual" then
        start = get_mark("<")
        stop = get_mark(">")
    else
        start = get_mark("[")
        stop = get_mark("]")
    end

    return {
        start[1] - 1, start[2],
        stop[1] - 1, stop[2]
    }
end

---@type "expression"|"target"
local next_phase = "expression"
---@type TSNode
local last_node
---@type string
local last_register

---@param range Range4
local select_expr_to_cut = function(range)
    local parser = assert(vim_ts.get_parser(0))
    local node = parser:node_for_range(range)
    if not node then
        return
    end
    last_node = node
    next_phase = "target"
    last_register = vim.v.register
    local win_start, win_end = vim.fn.getpos("w0"), vim.fn.getpos("w$")
    local winrange = { win_start[2] - 1, win_start[3], win_end[2] - 1, win_end[3], }

    local possible_matches = my_ts.find_matching_inside_node(node, assert(parser:node_for_range(winrange)), winrange)
    for _, n in ipairs(possible_matches) do
        local srow, scol, erow, ecol = n:range()
        api.nvim_buf_set_extmark(0, hlns, srow, scol, {
            end_row = erow,
            end_col = ecol,
            hl_group = config.hl_group
        })
    end

    api.nvim_feedkeys("g@", "n", false)
    api.nvim_create_autocmd("SafeState", {
        once = true,
        callback = function()
            next_phase = "expression"
            api.nvim_buf_clear_namespace(0, hlns, 0, -1)
        end
    })
end

---@param range Range4
local select_region = function(range)
    local parser = vim.treesitter.get_parser(0)
    if not last_node or not parser then
        return
    end

    -- force whole lines
    range[1] = 0
    range[4] = #api.nvim_buf_get_lines(0, range[3], range[3] + 1, false)[1]
    local containing_node = assert(parser:node_for_range(range))
    local matching = my_ts.find_matching_inside_node(last_node, containing_node, range)

    local ft = vim.bo.ft
    local name
    local prompt = config.prompt
    if type(prompt) == "function" then
        name = prompt(last_node)
    else
        name = vim.fn.input(prompt)
    end
    local replacer = replacers[ft]

    if assigners[ft] then
        local assignment = assigners[ft](name, last_node)
        if assignment then
            vim.fn.setreg(last_register, assigners[ft](name, last_node))
        end
    else
        vim.notify(("Cut Out: No assigner found for '%s'"):format(ft), vim.log.levels.WARN)
    end

    -- operate bottom up to avoid disturbing the tree
    for node in vim.iter(matching):rev() do
        local srow, scol, erow, ecol = node:range()
        local replacement = replacer and replacer(name, last_node, node) or { name }
        api.nvim_buf_set_text(0, srow, scol, erow, ecol, replacement)
    end
end

M.opfunc = function(mode)
    if not pcall(vim.treesitter.get_parser, 0) then
        vim.notify("Cut Out: Treesitter is required", vim.log.levels.ERROR)
        return
    end

    local range = get_op_region(mode)
    if next_phase == "expression" then
        select_expr_to_cut(range)
    else
        select_region(range)
    end
end

return M
