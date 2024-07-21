local api = require("bufcycle")
local utils = require("tests/utils")

local global = {}
global.tmp_files = {}
global.tmp_buffers = {}

describe("the api", function()
    local n_files = 5
    local n_buffers = 5

    local created_tmp_files = {}

    local create_tmp_file = function()
        local tmp_file = utils.make_tmp_file()
        table.insert(created_tmp_files, tmp_file)
        return tmp_file
    end

    setup(function() global.tmp_files = utils.make_tmp_files(n_files) end)

    teardown(function()
        for i = 1, #global.tmp_files do os.remove(global.tmp_files[i]) end
    end)

    before_each(function()
        api.setup()
        global.tmp_buffers = utils.load_buffers(global.tmp_files)
    end)

    after_each(function()
        utils.close_all_buffers()
        for i = 1, #created_tmp_files do os.remove(created_tmp_files[i]) end
    end)

    it("sets up the plugin correctly without a skip function", function()
        global.tmp_buffers = utils.load_buffers(global.tmp_files)

        api.backward()
        assert.are.equal(vim.api.nvim_get_current_buf(), n_buffers - 1)

        api.forward()
        assert.are.equal(vim.api.nvim_get_current_buf(), n_buffers)
    end)

    it("sets up the plugin correctly when a skip function is provided",
       function()
        api.setup({
            skip = function(bufnr)
                if bufnr == global.tmp_buffers[n_buffers - 1].bufnr then
                    return true
                end

                return false
            end
        })

        global.tmp_buffers = utils.load_buffers(global.tmp_files)

        api.backward()
        assert.are.equal(vim.api.nvim_get_current_buf(), n_buffers - 2)

        api.forward()
        assert.are.equal(vim.api.nvim_get_current_buf(), n_buffers)
    end)

    it("moves backward when calling backward and cycles", function()
        for idx = #global.tmp_buffers, 1, -1 do
            assert.are.equal(vim.api.nvim_get_current_buf(),
                             global.tmp_buffers[idx].bufnr)
            api.backward()
        end
        assert.are.equal(vim.api.nvim_get_current_buf(),
                         global.tmp_buffers[#global.tmp_buffers].bufnr)
    end)

    it("moves forward after calling backward and cycles ", function()
        api.backward()
        assert.are.equal(vim.api.nvim_get_current_buf(),
                         global.tmp_buffers[#global.tmp_buffers - 1].bufnr)

        api.forward()
        assert.are.equal(vim.api.nvim_get_current_buf(),
                         global.tmp_buffers[#global.tmp_buffers].bufnr)

        api.forward()
        assert.are.equal(vim.api.nvim_get_current_buf(),
                         global.tmp_buffers[1].bufnr)
    end)

    it("does not cycle when enable_bounded_buffer_iteration is set to true", function()
        api.setup({enable_bounded_buffer_iteration=true})
        global.tmp_buffers = utils.load_buffers(global.tmp_files)

        assert.are.equal(vim.api.nvim_get_current_buf(),
                         global.tmp_buffers[n_buffers].bufnr)

        for _ = 1,n_buffers+5 do
          api.backward()
        end

        assert.are.equal(vim.api.nvim_get_current_buf(), global.tmp_buffers[1].bufnr)

        for _ = 1,n_buffers+5 do
          api.forward()
        end

        assert.are.equal(vim.api.nvim_get_current_buf(), global.tmp_buffers[n_buffers].bufnr)
    end)

    it("moves backward correctly after calling backward and jumping", function()

        assert.are.equal(vim.api.nvim_get_current_buf(),
                         global.tmp_buffers[n_buffers].bufnr)
        api.backward()
        api.backward()
        api.backward()

        assert.are.equal(vim.api.nvim_get_current_buf(),
                         global.tmp_buffers[n_buffers - 3].bufnr)

        local loaded_buffer = utils.load_buffer(create_tmp_file())
        assert(loaded_buffer)

        assert.are.equal(vim.api.nvim_get_current_buf(), loaded_buffer.bufnr)

        api.backward()
        assert.are.equal(vim.api.nvim_get_current_buf(),
                         global.tmp_buffers[n_buffers - 3].bufnr)
    end)

    it("jumps back to start of last iteration correctly", function()

        assert.are_equal(vim.api.nvim_get_current_buf(),
                         global.tmp_buffers[n_buffers].bufnr)

        api.backward()
        api.backward()
        api.forward()

        assert.are_equal(vim.api.nvim_get_current_buf(),
                         global.tmp_buffers[n_buffers-1].bufnr)

        api.return_to_last_bufcycle_start()

        assert.are_equal(vim.api.nvim_get_current_buf(),
                         global.tmp_buffers[n_buffers].bufnr)

        local loaded_buffer = utils.load_buffer(create_tmp_file())
        assert(loaded_buffer)

        assert.are_equal(vim.api.nvim_get_current_buf(),
                         loaded_buffer.bufnr)

        api.return_to_last_bufcycle_start()

        assert.are_equal(vim.api.nvim_get_current_buf(),
                         global.tmp_buffers[n_buffers].bufnr)
    end)
end)
