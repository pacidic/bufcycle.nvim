
local logging = require("detail/logging")
local bt = require("detail/buffer_tracker")

-- internal variables
local internal = {}
internal.buffer_tracker = nil
internal.buffer_iter = nil
internal.buffer_iter_start = nil
internal.enable_bounded_buffer_iteration = nil
-- END internal variables

-- free functions
-- returns nil if circular_iter:len() <= 1
local function make_buffer_iter(buffer_tracker, buffer_iter)
    if buffer_iter ~= nil then
      logging.LOG("make_buffer_iter: buffer_iter is nil")
      return buffer_iter, false
    end

    local iter = nil
    if not internal.enable_bounded_buffer_iteration then
      logging.LOG("make_buffer_iter: CircularIter")
      iter = buffer_tracker:circular_iter()
    else
      logging.LOG("make_buffer_iter: BoundedIter")
      iter = buffer_tracker:bounded_iter()
    end

    if iter:len() <= 1 then
      logging.LOG("make_buffer_iter: no/single buffer, returning nil")
      return nil, false
    end
    return iter, true
end

-- returns nil if current position of buffer_iter does not match bufnr
local function is_iteration_in_progress(buffer_iter, bufnr)
    if buffer_iter and buffer_iter:value().bufnr == bufnr then
        -- The bufnr being entered was not the result of cycling through the buffer_iter.
        logging.LOG("is_iteration_in_progress: yes")
        return true
    end

    return false
end
-- END free functions

-- api
local api = {}

api.backward = function()

    logging.LOG("backward: buffer tracker size %d", internal.buffer_tracker:n_tracked())

    local new_buffer_iter = false
    internal.buffer_iter, new_buffer_iter = make_buffer_iter(
                                        internal.buffer_tracker,
                                        internal.buffer_iter)

    if not internal.buffer_iter then
      logging.LOG("backward: no buffer iter")
      return
    end

    if new_buffer_iter then
      internal.buffer_iter_start = internal.buffer_iter:value()
    end

    local prev_bufnr = internal.buffer_iter:prev().bufnr

    if vim.api.nvim_buf_is_valid(prev_bufnr) then
      logging.LOG("backward: switching to %d", prev_bufnr)
      vim.api.nvim_set_current_buf(prev_bufnr)
    else
      logging.LOG("backward: buffer %d is not valid", prev_bufnr)
    end
end

api.forward = function()
    -- can't move forward, unless we have moved backward already, in which case buffer_iter must be set
    if internal.buffer_iter == nil then
      logging.LOG("forward: no buffer_iter")
      return
    end

    local next_bufnr = internal.buffer_iter:next().bufnr

    if vim.api.nvim_buf_is_valid(next_bufnr) then
      logging.LOG("forward: switching to %d", next_bufnr)
      vim.api.nvim_set_current_buf(next_bufnr)
    end
end

api.return_to_last_bufcycle_start = function()
    if internal.buffer_iter_start ~= nil then
      internal.buffer_iter = nil
      if vim.api.nvim_buf_is_valid(internal.buffer_iter_start.bufnr) then
        logging.LOG("return_to_last_bufcycle_start: switching to %d", internal.buffer_iter_start.bufnr)
        vim.api.nvim_set_current_buf(internal.buffer_iter_start.bufnr)
      end
    end
end

api.setup = function(cfg)
    local buffer_tracker_group = vim.api.nvim_create_augroup("buffer_tracker",
                                                             {clear = true})

    if cfg == nil then cfg = {} end

    internal.buffer_tracker = bt.BufferTracker:new(cfg.skip)
    internal.enable_bounded_buffer_iteration = cfg.enable_bounded_buffer_iteration

    vim.api.nvim_create_autocmd({"BufNew", "BufEnter"}, {
        group = buffer_tracker_group,
        pattern = "*",
        callback = function()
            local entered_bufnr = vim.fn.bufnr()
            internal.buffer_tracker:on_buf_enter(entered_bufnr)

            if not is_iteration_in_progress(internal.buffer_iter,
                                            entered_bufnr) then
                internal.buffer_iter = nil
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

    vim.api.nvim_create_autocmd({"BufDelete"}, {
        group = buffer_tracker_group,
        pattern = "*",
        callback = function()
            internal.buffer_tracker:on_buf_delete(vim.fn.bufnr())
        end
    })

    logging.LOG("setup: complete")
end
-- END api

return api
