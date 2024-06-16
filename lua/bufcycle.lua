
local skip_func = nil

local function find_if(array, func)
  for i,val in ipairs(array) do
    if func(val) then
      return i
    end
  end

  return nil
end

local function circular_dec(idx, sz)
  return (idx - 2) % sz + 1
end

local function circular_inc(idx, sz)
  return idx % sz + 1
end

local function open_next_buf(buflist, increment)
  local current_bufnr = vim.api.nvim_get_current_buf()

  local current_bufidx = find_if(buflist, function(bufnr)
    return bufnr == current_bufnr
  end)

  assert(current_bufidx ~= nil)

  local idx = increment(current_bufidx, #buflist)

  local bufnr = current_bufnr
  while idx ~= current_bufidx do
    local other_bufnr = buflist[idx]
    if vim.api.nvim_buf_is_loaded(other_bufnr) then
      if skip_func and not skip_func(other_bufnr) then
        bufnr = other_bufnr
        break
      end
    end

    idx = increment(idx, #buflist)
  end

  vim.api.nvim_set_current_buf(bufnr)
end

local backward = function()
  local buflist = vim.api.nvim_list_bufs()
  open_next_buf(buflist, circular_dec)
end

local forward = function()
  local buflist = vim.api.nvim_list_bufs()
  open_next_buf(buflist, circular_inc)
end

local setup = function(cfg)
  cfg = cfg or {}
  if cfg.skip then
    skip_func = cfg.skip
  end
end

return {
  backward = backward,
  forward = forward,
  setup = setup,
}
