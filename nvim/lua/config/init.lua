-- lua/config/init.lua
local M = {}

-- Detect if running over SSH
M.is_remote = os.getenv("SSH_CLIENT") ~= nil
           or os.getenv("SSH_TTY") ~= nil

return M
