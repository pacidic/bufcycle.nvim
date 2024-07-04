
local lfs = require("lfs")

local opt = {}
opt.enable_logging = false
opt.logger = nil
opt.log_level = nil

local logging = {}
logging.LOG = function(...)
    if not opt.enable_logging then return end

    if opt.logger == nil then
        require("logging.file")
        local logdir = vim.fn.stdpath("data") .. '/bufcycle_nvim'

        if not lfs.attributes(logdir, "mode") then lfs.mkdir(logdir) end

        opt.logger = logging.file(logdir .. "/lualogging.log")

        opt.log_level = logging.DEBUG
        opt.logger:setLevel(opt.log_level)
    end

    opt.logger:log(opt.log_level, unpack({...}))
end

logging.lazy_write = function(val, no_indent_or_linebreaks)
    if not opt.enable_logging then return end

    local pstr = vim.inspect(val)
    if no_indent_or_linebreaks then
        pstr = pstr:gsub("%s+", " "):gsub(", %s", ", ")
    end

    return pstr
end

return logging
