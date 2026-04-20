-- MATLAB development layer
-- Filetype detection lives in lua/config/filetypes.lua
-- Requires MATLAB installed and on PATH (or MATLAB_PATH env var set)

local function find_matlab_root()
	local env = os.getenv("MATLAB_PATH")
	if env and env ~= "" then
		return env
	end

	local handle = io.popen("command -v matlab 2>/dev/null")
	if not handle then
		return nil
	end
	local path = handle:read("*l")
	handle:close()
	if not path or path == "" then
		return nil
	end

	return path:gsub("/bin/matlab$", "")
end

return {
	-- ─── MATLAB LSP ──────────────────────────────────────
	{
		"neovim/nvim-lspconfig",
		optional = true,
		config = function()
			if vim.fn.executable("matlab-language-server") ~= 1 then
				return
			end

			local capabilities = require("blink.cmp").get_lsp_capabilities()
			local matlab_root = find_matlab_root()

			vim.lsp.config("matlab_ls", {
				cmd = { "matlab-language-server", "--stdio" },
				filetypes = { "matlab" },
				root_markers = { ".git", "*.prj" },
				capabilities = capabilities,
				settings = {
					MATLAB = {
						indexWorkspace = true,
						installPath = matlab_root or "",
						matlabConnectionTiming = "onStart",
						telemetry = false,
					},
				},
			})
			vim.lsp.enable("matlab_ls")
		end,
	},

	-- ─── Linting via mlint ───────────────────────────────
	{
		"mfussenegger/nvim-lint",
		optional = true,
		opts = function(_, opts)
			if vim.fn.executable("mlint") ~= 1 then
				return opts
			end

			opts.linters_by_ft = opts.linters_by_ft or {}
			opts.linters_by_ft.matlab = { "mlint" }

			local lint = require("lint")
			lint.linters.mlint = {
				cmd = "mlint",
				stdin = false,
				args = { "-id" },
				stream = "stderr",
				ignore_exitcode = true,
				parser = require("lint.parser").from_pattern(
					"L (%d+) %(C (%d+)%): (%w+): (.+)",
					{ "lnum", "col", "code", "message" },
					nil,
					{ severity = vim.diagnostic.severity.WARN }
				),
			}
			return opts
		end,
	},

	-- ─── Run commands via toggleterm ─────────────────────
	{
		"akinsho/toggleterm.nvim",
		optional = true,
		init = function()
			local function term_exec(cmd, name)
				vim.cmd(string.format("TermExec cmd=%q name=%s direction=horizontal", cmd, name or "matlab"))
			end

			vim.api.nvim_create_user_command("MatlabRun", function()
				local file = vim.fn.expand("%:p")
				if file == "" or not file:match("%.m$") then
					vim.notify("Current buffer is not a .m file", vim.log.levels.ERROR)
					return
				end
				local dir = vim.fn.expand("%:p:h")
				local script = vim.fn.expand("%:t:r")
				term_exec(string.format("matlab -batch \"cd('%s'); %s\"", dir, script), "matlab")
			end, { desc = "Run current .m file in MATLAB (-batch mode)" })

			vim.api.nvim_create_user_command("MatlabRepl", function()
				term_exec("matlab -nodesktop -nosplash", "matlab-repl")
			end, { desc = "Open MATLAB CLI REPL" })

			vim.api.nvim_create_user_command("MatlabRunFn", function(opts)
				local args = opts.args
				if args == "" then
					vim.notify("Usage: :MatlabRunFn <expression>", vim.log.levels.ERROR)
					return
				end
				local dir = vim.fn.expand("%:p:h")
				term_exec(string.format("matlab -batch \"cd('%s'); %s\"", dir, args), "matlab")
			end, { nargs = "+", desc = "Run a MATLAB expression" })

			vim.api.nvim_create_user_command("MatlabLint", function()
				local file = vim.fn.expand("%:p")
				term_exec("mlint -id " .. file, "matlab")
			end, { desc = "Run mlint on current .m file" })
		end,
	},
}
