
local utils = require("detail/utils")

local BoundedIter = {}

function BoundedIter:new(array, index)
    local instance = {
        array_ = array,
        idx_ = utils.bounded_idx(index, #array)
    }

    local mt = {
        __index = function(this, key)
            return rawget(this, key) or BoundedIter[key]
        end,
        __len = function(this) return #this.array_ end
    }

    setmetatable(instance, mt)

    return instance
end

function BoundedIter:len() return #self.array_ end

function BoundedIter:next()
    self.idx_ = utils.bounded_idx(self.idx_+1, #self.array_)
    return self:value()
end

function BoundedIter:prev()
    self.idx_ = utils.bounded_idx(self.idx_-1, #self.array_)
    return self:value()
end

function BoundedIter:value() return self.array_[self.idx_] end

local M_ = {}
M_.BoundedIter = BoundedIter

return M_
