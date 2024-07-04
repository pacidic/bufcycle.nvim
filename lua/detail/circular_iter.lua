
local utils = require("detail/utils")

local CircularIter = {}

function CircularIter:new(array, index)
    local instance = {
        array_ = array,
        idx_ = utils.circular_idx(index or 1, #array)
    }

    local mt = {
        __index = function(this, key)
            return rawget(this, key) or CircularIter[key]
        end,
        __len = function(this) return #this.array_ end
    }

    setmetatable(instance, mt)

    return instance
end

function CircularIter:len() return #self.array_ end

function CircularIter:next()
    self.idx_ = utils.circular_inc(self.idx_, #self.array_)
    return self:value()
end

function CircularIter:prev()
    self.idx_ = utils.circular_dec(self.idx_, #self.array_)
    return self:value()
end

function CircularIter:value() return self.array_[self.idx_] end

local M_ = {}
M_.CircularIter = CircularIter

return M_
