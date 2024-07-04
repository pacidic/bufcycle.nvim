local lfs = require("lfs")

local logging = require("detail/logging")
local bt = require("detail/buffer_tracker")

-- internal variables
local internal = {}
internal.circular_buffer_iter = nil
-- END internal variables

-- free functions
-- returns nil if circular_iter:len() <= 1
local function make_circular_buffer_iter(buffer_tracker, circular_buffer_iter)
    if circular_buffer_iter ~= nil then return circular_buffer_iter end

    local circular_iter = buffer_tracker:circular_iter()
    if circular_iter:len() <= 1 then return nil end
    return circular_iter
end

-- returns nil if current position of circular_buffer_iter does not match bufnr
local function is_iteration_in_progress(circular_buffer_iter, bufnr)
    if circular_buffer_iter and circular_buffer_iter:value().bufnr == bufnr then
        -- The bufnr being entered was not the result of cycling through the circular_buffer_iter.
        logging.LOG("check_iteration_in_progress: yes")
        return true
    end

    return false
end
-- END free functions

-- api
local api = {}

api.backward = function()
    internal.circular_buffer_iter = make_circular_buffer_iter(
                                        internal.buffer_tracker,
                                        internal.circular_buffer_iter)
    if not internal.circular_buffer_iter then return end

    local prev_bufnr = internal.circular_buffer_iter:prev().bufnr

    logging.LOG("backward: switching to %d", prev_bufnr)
    vim.api.nvim_set_current_buf(prev_bufnr)
end

api.forward = function()
    -- can't move forward, unless we have moved backward already, in which case circular_buffer_iter must be set
    if internal.circular_buffer_iter == nil then return end

    local next_bufnr = internal.circular_buffer_iter:next().bufnr

    logging.LOG("forward: switching to %d", next_bufnr)
    vim.api.nvim_set_current_buf(next_bufnr)
end

api.setup = function(cfg)
    local buffer_tracker_group = vim.api.nvim_create_augroup("buffer_tracker",
                                                             {clear = true})

    if cfg == nil then cfg = {} end

    internal.buffer_tracker = bt.BufferTracker:new(cfg.skip)

    vim.api.nvim_create_autocmd("BufEnter", {
        group = buffer_tracker_group,
        pattern = "*",
        callback = function()
            local entered_bufnr = vim.fn.bufnr()
            internal.buffer_tracker:on_buf_enter(entered_bufnr)

            if not is_iteration_in_progress(internal.circular_buffer_iter,
                                            entered_bufnr) then
                internal.circular_buffer_iter = nil
            end
        end
    })

    -- add current buffer to buffer list on BufLeave event
    -- this is to ensure that e.g. the FileType is set when calling
    -- the user-supplied skip function on the current buffer.
    vim.api.nvim_create_autocmd("BufLeave", {
        group = buffer_tracker_group,
        pattern = "*",
        callback = function() internal.buffer_tracker:on_buf_leave() end
    })

    vim.api.nvim_create_autocmd({"BufUnload", "BufDelete"}, {
        group = buffer_tracker_group,
        pattern = "*",
        callback = function()
            internal.buffer_tracker:on_buf_delete(vim.fn.bufnr())
        end
    })
end
-- END api

return {backward = api.backward, forward = api.forward, setup = api.setup}
