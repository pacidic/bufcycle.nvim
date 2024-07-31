
-- Internal variables
local internal = {}
internal.startup_ns = vim.uv.hrtime()
-- END Internal variables

local utils = {}
utils.circular_idx = function(idx, sz) return (idx - 1) % sz + 1 end

utils.circular_inc = function(idx, sz) return idx % sz + 1 end

utils.circular_dec = function(idx, sz) return (idx - 2) % sz + 1 end

utils.bounded_idx = function(idx, sz)
  if idx < 1 then
    return 1
  end

  if idx > sz then
    return sz
  end

  return idx
end

utils.make_buffer_info = function(bufnr, time_of_entry)
    -- return {bufnr=bufnr, time_of_entry=time_of_entry, name=vim.fn.bufname(bufnr)}
    return {bufnr = bufnr, time_of_entry = time_of_entry}
end

utils.now = function() return vim.uv.hrtime() - internal.startup_ns end

-- adds a nanosecond if the timestamp returned by now() equals last_ts
utils.unique_now = function(last_ts)
    local t_now = utils.now()
    if t_now == last_ts then t_now = t_now + 1 end

    return t_now
end

return utils
