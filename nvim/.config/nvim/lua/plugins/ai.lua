return {
  "yetone/avante.nvim",
  event = "VeryLazy",
  lazy = false,
  version = false, -- Set this to "*" if you want to pin to stable releases
  build = "make",  -- Run `make BUILD_FROM_SOURCE=true` if you need to build from source
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
    "stevearc/dressing.nvim",
    "nvim-lua/plenary.nvim",
    "MunifTanjim/nui.nvim",
    
    --- Optional but highly recommended dependencies
    "nvim-telescope/telescope.nvim", -- For file_selector provider
    "hrsh7th/nvim-cmp",              -- For autocompletion in Avante commands
    "nvim-tree/nvim-web-devicons",   -- Or echasnovski/mini.icons
    {
      "MeanderingProgrammer/render-markdown.nvim",
      opts = {
        file_types = { "markdown", "Avante" },
      },
      ft = { "markdown", "Avante" },
    },
  },
  opts = {
    -- Specify the main provider
    provider = "openai",
    auto_suggestions_provider = "openai", -- Can be set to a different provider if desired
    
    -- Provider configurations
    providers = {
      openai = {
        endpoint = "https://api.openai.com/v1",
        model = "gpt-5-mini", -- Or your preferred model (e.g., "o1", "o3-mini")
        timeout = 30000, -- Timeout in milliseconds
        api_key_name = "OPENAI_API_KEY", -- The environment variable to read the key from
        
        -- All model-specific parameters go here
        extra_request_body = {
          temperature = 0,
          max_completion_tokens = 8192,
        },
      },
    },
  },
}
