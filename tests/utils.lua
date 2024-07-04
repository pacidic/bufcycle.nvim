local M_ = {}

local n_tmp_files = 0

M_.make_tmp_file = function()
    n_tmp_files = n_tmp_files + 1
    local tmp_path = os.tmpname() .. tostring(n_tmp_files)
    local file = io.open(tmp_path, "w")
    assert(file)
    file:write("file_" .. tostring(n_tmp_files), "w")
    file:close()

    return tmp_path
end

M_.make_tmp_files = function(n_files)
    local tmp_files = {}
    for i = 1, n_files do table.insert(tmp_files, M_.make_tmp_file()) end
    return tmp_files
end

M_.load_buffer = function(fname)
    vim.cmd('edit ' .. fname)
    return {
        bufnr = vim.api.nvim_get_current_buf(),
        name = vim.api.nvim_buf_get_name(0)
    }
end

M_.load_buffers = function(file_list)
    local buffers = {}
    for i = 1, #file_list do
        table.insert(buffers, M_.load_buffer(file_list[i]))
    end

    return buffers
end

M_.close_all_buffers = function() vim.cmd([[bufdo bd]]) end

return M_
