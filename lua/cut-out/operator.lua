local M = {}

local vim_ts = vim.treesitter
local api = vim.api
local my_ts = require("cut-out.ts")
local hlns = api.nvim_create_namespace("cut-out")
local config = require("cut-out").options
local filetype = config.filetypes

local highlight_matching = function(matching, group)
    for _, n in ipairs(matching) do
        local srow, scol, erow, ecol = n:range()
        api.nvim_buf_set_extmark(0, hlns, srow, scol, {
            end_row = erow,
            end_col = ecol,
            hl_group = group
        })
    end
end

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

---@type TSNode
local last_node
---@type string
local last_register
---@type Range4
local last_range
---@type integer?
local last_aucmd

---@param range Range4
local select_expr_to_cut = function(range)
    local parser = assert(vim_ts.get_parser(0):language_for_range(range))
    local node = parser:node_for_range(range)
    if not node then
        return
    end
    last_node = node
    last_register = vim.v.register
    last_range = range

    local win_start, win_end = vim.fn.getpos("w0"), vim.fn.getpos("w$")
    local winrange = {
        win_start[2] - 1, win_start[3], win_end[2] - 1,
        #api.nvim_buf_get_lines(0, win_end[2] - 1, win_end[2], false)[1],
    }

    local containing_node = my_ts.node_for_range(parser, winrange, range)
    local possible_matches = my_ts.find_matching_inside_node(node, containing_node, winrange)

    highlight_matching(possible_matches, config.hl_group)

    last_aucmd = api.nvim_create_autocmd("SafeState", {
        once = true,
        callback = function()
            api.nvim_buf_clear_namespace(0, hlns, 0, -1)
            last_aucmd = nil
        end
    })

    vim.o.operatorfunc = "v:lua.require'cut-out.operator'.final_opfunc"
    api.nvim_feedkeys("g@", "nt", false)
end

---@param mode "line"|"char"
---@param range Range4
local select_region = function(mode, range)
    local parser = vim.treesitter.get_parser(0):language_for_range(last_range)
    if not last_node or not parser then
        return
    end

    -- force whole lines
    if mode == "line" then
        range[2] = 0
        range[4] = #api.nvim_buf_get_lines(0, range[3], range[3] + 1, false)[1]
    end
    local containing_node = my_ts.node_for_range(parser, range, last_range)
    local matching = my_ts.find_matching_inside_node(last_node, containing_node, range)
    if last_aucmd then
        api.nvim_del_autocmd(last_aucmd)
        api.nvim_buf_clear_namespace(0, hlns, 0, -1)
        vim.cmd.redraw()
        last_aucmd = nil
    end
    highlight_matching(matching, config.hl_group)

    local ft = parser:lang()
    local for_ft = filetype[ft] or {}
    local prompt = config.prompt
    local default_name
    if for_ft.suggest_name then
        default_name = for_ft.suggest_name(last_node)
    end
    local name = vim.fn.input(prompt, default_name or "")

    local replacer = for_ft.make_replacement
    local assigner = for_ft.make_assignment

    if assigner then
        local assignment = assigner(name, last_node)
        if assignment then
            vim.fn.setreg(last_register, assigner(name, last_node))
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
    api.nvim_buf_clear_namespace(0, hlns, 0, -1)
end

M.opfunc = function(mode)
    if not pcall(vim.treesitter.get_parser, 0) then
        vim.notify("Cut Out: Treesitter is required", vim.log.levels.ERROR)
        return
    end

    local range = get_op_region(mode)
    select_expr_to_cut(range)
end

M.final_opfunc = function(mode)
    local range = get_op_region(mode)
    select_region(mode, range)
end

return M
