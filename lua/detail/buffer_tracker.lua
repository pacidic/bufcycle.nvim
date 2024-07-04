
local cit = require("detail/circular_iter")
local logging = require("detail/logging")
local utils = require("detail/utils")

local BufferTracker = {}

-- private functions
local function should_track_buffer(bufnr, skip_func)
    if not bufnr or not vim.api.nvim_buf_is_valid(bufnr) then
        logging.LOG("should_track_buffer: buffer not set or invalid")
        return false
    end

    if skip_func and skip_func(bufnr) then
        logging.LOG("should_track_buffer: skipping %s", bufnr)
        return false
    end

    return true
end

-- END private functions

function BufferTracker:new(skip_func)

    local instance = {
        last_entry_time_ = 0,
        current_buffer_ = nil,
        buffer_entry_time_map_ = {},
        skip_func_ = skip_func
    }

    local mt = {
        __index = function(tbl, key)
            return rawget(tbl, key) or BufferTracker[key]
        end,
        __newindex = function(tbl, key, value) rawset(tbl, key, value) end,
        __len = function(tbl) return #tbl.buffer_entry_time_map_ end
    }

    setmetatable(instance, mt)

    return instance
end

function BufferTracker:n_tracked() return #self end

function BufferTracker:on_buf_enter(bufnr)
    self.last_entry_time_ = utils.unique_now(self.last_entry_time_)
    self.current_buffer_ = utils.make_buffer_info(bufnr, self.last_entry_time_)

    logging.LOG("on_buf_enter: %s", logging.lazy_write(self.current_buffer_))
end

function BufferTracker:on_buf_leave()
    if not self.current_buffer_ or
        not should_track_buffer(self.current_buffer_.bufnr, self.skip_func_) then
        self.current_buffer_ = nil
        return nil
    end

    logging.LOG("on_buf_leave: upsert %s", logging.lazy_write(self.current_buffer_))
    local current_bufnr = self.current_buffer_.bufnr

    self.buffer_entry_time_map_[current_bufnr] = self.current_buffer_.time_of_entry

    -- reset current_buffer_ to nil, since we have left it
    self.current_buffer_ = nil

    return current_bufnr
end

function BufferTracker:on_buf_delete(bufnr)
    logging.LOG("on_buf_delete: deleting %s", bufnr)

    self.buffer_entry_time_map_[bufnr] = nil
    if self.current_buffer_ and self.current_buffer_.bufnr == bufnr then
        self.current_buffer_ = nil
    end
end

-- returns a circular iterator at the position of the current buffer
function BufferTracker:circular_iter()
    local sorted_array = {}
    for bufnr, time_of_entry in pairs(self.buffer_entry_time_map_) do
        table.insert(sorted_array, utils.make_buffer_info(bufnr, time_of_entry))
    end

    if self.current_buffer_ then
        table.insert(sorted_array, self.current_buffer_)
    end

    table.sort(sorted_array,
               function(a, b) return a.time_of_entry < b.time_of_entry end)

    return cit.CircularIter:new(sorted_array, #sorted_array)
end

local M_ = {}
M_.BufferTracker = BufferTracker

return M_
