-- ~/.config/nvim/lua/theme_engine.lua
local M = {}

function M.apply_matugen()
    -- Safely attempt to load the generated Matugen file
    local status, colors = pcall(require, "matugen_colors")
    
    if not status then
        vim.notify("Matugen colors not found. Using fallback.", vim.log.levels.WARN)
        -- Hardcoded fallback colors so you can still see your code
        colors = { 
            bg = "#1a1b26", 
            fg = "#c0caf5", 
            primary = "#7aa2f7" 
        }
    end

    -- Set the terminal colors (so :terminal looks right)
    vim.g.terminal_color_0 = colors.bg
    vim.g.terminal_color_1 = colors.primary

    -- Apply basic UI highlights
    local hl = vim.api.nvim_set_hl
    hl(0, "Normal", { fg = colors.fg, bg = colors.bg })
    hl(0, "Keyword", { fg = colors.primary, bold = true })
    
    -- Sync the cursor color to your Matugen primary
    hl(0, "Cursor", { bg = colors.primary, fg = colors.bg })
end

return M
