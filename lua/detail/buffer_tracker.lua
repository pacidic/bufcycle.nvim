
local bit = require("detail/bounded_iter")
local cit = require("detail/circular_iter")
local logging = require("detail/logging")
local utils = require("detail/utils")

local BufferTracker = {}

-- private functions
local function should_cycle_buffer(bufnr, skip_func)
    if not bufnr or not vim.api.nvim_buf_is_valid(bufnr) then
        logging.LOG("should_cycle_buffer: buffer not set or invalid")
        return false
    end

    if skip_func and skip_func(bufnr) then
        logging.LOG("should_cycle_buffer: skipping %s", bufnr)
        return false
    end

    return true
end

-- END private functions

function BufferTracker:new(skip_func)

    local instance = {
        last_entry_time_ = 0,
        current_bufnr_ = nil,
        buffer_map_ = {},
        skip_func_ = skip_func
    }

    local mt = {
        __index = function(tbl, key)
            return rawget(tbl, key) or BufferTracker[key]
        end,
        __newindex = function(tbl, key, value) rawset(tbl, key, value) end,
        __len = function(tbl) return #tbl.buffer_map_ end
    }

    setmetatable(instance, mt)

    return instance
end

function BufferTracker:n_tracked() return #self end

function BufferTracker:on_buf_enter(bufnr)
    self.last_entry_time_ = utils.unique_now(self.last_entry_time_)
    self.current_bufnr_ = bufnr
    self.buffer_map_[bufnr] = utils.make_buffer_info(bufnr, self.last_entry_time_)
end

function BufferTracker:on_buf_leave()
    local current_bufnr = self.current_bufnr_

    -- reset current_bufnr_ to nil, since we have left it
    self.current_bufnr_ = nil

    return current_bufnr
end

function BufferTracker:on_buf_delete(bufnr)
    logging.LOG("on_buf_delete: deleting %s", bufnr)

    self.buffer_map_[bufnr] = nil
    if self.current_bufnr_ and self.current_bufnr_ == bufnr then
        self.current_bufnr_ = nil
    end
end

function BufferTracker:sorted_array()

    local sorted_array = {}

    for n, bufnr in ipairs(vim.api.nvim_list_bufs()) do
      if should_cycle_buffer(bufnr, self.skip_func_) then
        local buf_prop = self.buffer_map_[bufnr]
        if buf_prop then
          table.insert(sorted_array, buf_prop)
        end
      end
    end

    logging.LOG("BufferTracker:sorted_array(): %s", logging.lazy_write(sorted_array))

    table.sort(sorted_array,
               function(a, b) return a.time_of_entry < b.time_of_entry end)

    return sorted_array
end

function BufferTracker:bounded_iter()
  local sorted_array = self:sorted_array()
  return bit.BoundedIter:new(sorted_array, #sorted_array)
end

-- returns a circular iterator at the position of the current buffer
function BufferTracker:circular_iter()
  local sorted_array = self:sorted_array()
  return cit.CircularIter:new(sorted_array, #sorted_array)
end

local M_ = {}
M_.BufferTracker = BufferTracker

return M_
