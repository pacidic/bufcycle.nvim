local bt = require("detail/buffer_tracker")
local utils = require("tests/utils")

local internal = {}
internal.tmp_files = {}
internal.tmp_buffers = {}

local function is_lt(_, arguments)
    local expected = arguments[1]
    return function(value) return value < expected end
end

local function is_gt(_, arguments)
    local expected = arguments[1]
    return function(value) return value > expected end
end

assert:register("assertion", "is_lt", is_lt)
assert:register("assertion", "is_gt", is_gt)

local function enter_buffers(buffer_tracker, buflist, pre_enter_func,
                             post_enter_func)
    if post_enter_func == nil then
        post_enter_func = function(_, _) buffer_tracker:on_buf_leave() end
    end

    for i, info in ipairs(buflist) do
        if pre_enter_func then pre_enter_func(i, info) end
        buffer_tracker:on_buf_enter(info.bufnr)
        if post_enter_func then post_enter_func(i, info) end
    end
end

describe("BufferTracker", function()
    setup(function() internal.tmp_files = utils.make_tmp_files(5) end)

    teardown(function()
        for i = 1, #internal.tmp_files do
            os.remove(internal.tmp_files[i])
        end
    end)

    before_each(function()
        internal.tmp_buffers = utils.load_buffers(internal.tmp_files)
    end)

    after_each(function() utils.close_all_buffers() end)

    it(
        "should track all entered, valid buffers when no skip function is present",
        function()
            local buffer_tracker = bt.BufferTracker:new()
            assert.are.equal(buffer_tracker:circular_iter():len(), 0)

            enter_buffers(buffer_tracker, internal.tmp_buffers)

            assert.are.equal(buffer_tracker:circular_iter():len(),
                             #internal.tmp_buffers)
        end)

    it(
        "provides the tracked buffers in entry-time order via the circular_iter function",
        function()
            local buffer_tracker = bt.BufferTracker:new()

            enter_buffers(buffer_tracker, internal.tmp_buffers)

            local circular_iter = buffer_tracker:circular_iter()

            assert.are.equal(circular_iter:len(), #internal.tmp_buffers)

            for idx = circular_iter:len(), 1, -1 do
                local time_of_entry = circular_iter:value().time_of_entry
                assert.are.equal(circular_iter:value().bufnr,
                                 internal.tmp_buffers[idx].bufnr)
                circular_iter:prev()
                assert.is_lt(circular_iter:value().time_of_entry, time_of_entry)
            end

            assert.are.equal(buffer_tracker:circular_iter():len(),
                             #internal.tmp_buffers)
            circular_iter:next()
            for idx = 1, #internal.tmp_buffers do
                local time_of_entry = circular_iter:value().time_of_entry
                assert.are.equal(circular_iter:value().bufnr,
                                 internal.tmp_buffers[idx].bufnr)

                circular_iter:next()
                assert.is_gt(circular_iter:value().time_of_entry, time_of_entry)
            end
        end)

    it("should not track invalid buffers", function()
        local invalid_ids = {
            [internal.tmp_buffers[2].bufnr] = true,
            [internal.tmp_buffers[3].bufnr] = true
        }
        local buffer_tracker = bt.BufferTracker:new()

        local pre_enter_func = function(_, info)
            if invalid_ids[info.bufnr] then
                vim.api.nvim_buf_delete(info.bufnr, {})
            end
        end

        local post_enter_func = function(_, info)
            buffer_tracker:on_buf_leave()
            if invalid_ids[info.bufnr] then
                assert.are.not_equal(
                    buffer_tracker:circular_iter():value().bufnr, info.bufnr)
            end
        end

        enter_buffers(buffer_tracker, internal.tmp_buffers, pre_enter_func,
                      post_enter_func)

        local circular_iter = buffer_tracker:circular_iter()
        local expected_n_tracked = #internal.tmp_files -
                                       vim.tbl_count(invalid_ids)

        assert.are.equal(circular_iter:len(), expected_n_tracked)
    end)

    it(
        "should skip buffers for which a user-provided skip function returns true",
        function()
            local skip_ids = {
                [internal.tmp_buffers[2].bufnr] = true,
                [internal.tmp_buffers[3].bufnr] = true
            }
            local buffer_tracker = bt.BufferTracker:new(function(bufnr)
                return skip_ids[bufnr]
            end)

            local post_enter_func = function(_, info)
                buffer_tracker:on_buf_leave()
                if skip_ids[info.bufnr] then
                    assert.are.not_equal(
                        buffer_tracker:circular_iter():value().bufnr, info.bufnr)
                end
            end

            enter_buffers(buffer_tracker, internal.tmp_buffers, nil,
                          post_enter_func)

            local circular_iter = buffer_tracker:circular_iter()
            local expected_n_tracked = #internal.tmp_files -
                                           vim.tbl_count(skip_ids)

            assert.are.equal(circular_iter:len(), expected_n_tracked)
        end)
end)
