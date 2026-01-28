--[[

=====================================================================
==================== READ THIS BEFORE CONTINUING ====================
=====================================================================
========                                    .-----.          ========
========         .----------------------.   | === |          ========
========         |.-""""""""""""""""""-.|   |-----|          ========
========         ||                    ||   | === |          ========
========         ||   KICKSTART.NVIM   ||   |-----|          ========
========         ||                    ||   | === |          ========
========         ||                    ||   |-----|          ========
========         ||:Tutor              ||   |:::::|          ========
========         |'-..................-'|   |____o|          ========
========         `"")----------------(""`   ___________      ========
========        /::::::::::|  |::::::::::\  \ no mouse \     ========
========       /:::========|  |==hjkl==:::\  \ required \    ========
========      '""""""""""""'  '""""""""""""'  '""""""""""'   ========
========                                                     ========
=====================================================================
=====================================================================

What is Kickstart?

  Kickstart.nvim is *not* a distribution.

  Kickstart.nvim is a starting point for your own configuration.
    The goal is that you can read every line of code, top-to-bottom, understand
    what your configuration is doing, and modify it to suit your needs.

    Once you've done that, you can start exploring, configuring and tinkering to
    make Neovim your own! That might mean leaving Kickstart just the way it is for a while
    or immediately breaking it into modular pieces. It's up to you!

    If you don't know anything about Lua, I recommend taking some time to read through
    a guide. One possible example which will only take 10-15 minutes:
      - https://learnxinyminutes.com/docs/lua/

    After understanding a bit more about Lua, you can use `:help lua-guide` as a
    reference for how Neovim integrates Lua.
    - :help lua-guide
    - (or HTML version): https://neovim.io/doc/user/lua-guide.html

Kickstart Guide:

  TODO: The very first thing you should do is to run the command `:Tutor` in Neovim.

    If you don't know what this means, type the following:
      - <escape key>
      - :
      - Tutor
      - <enter key>

    (If you already know the Neovim basics, you can skip this step.)

  Once you've completed that, you can continue working through **AND READING** the rest
  of the kickstart init.lua.

  Next, run AND READ `:help`.
    This will open up a help window with some basic information
    about reading, navigating and searching the builtin help documentation.

    This should be the first place you go to look when you're stuck or confused
    with something. It's one of my favorite Neovim features.

    MOST IMPORTANTLY, we provide a keymap "<space>sh" to [s]earch the [h]elp documentation,
    which is very useful when you're not exactly sure of what you're looking for.

  I have left several `:help X` comments throughout the init.lua
    These are hints about where to find more information about the relevant settings,
    plugins or Neovim features used in Kickstart.

   NOTE: Look for lines like this

    Throughout the file. These are for you, the reader, to help you understand what is happening.
    Feel free to delete them once you know what you're doing, but they should serve as a guide
    for when you are first encountering a few different constructs in your Neovim config.

If you experience any errors while trying to install kickstart, run `:checkhealth` for more info.
--]]
local function is_file_readable(path)
    local file = io.open(path, "r")
    if file then
        file:close()
        return true
    else
        return false
    end
end

local function is_directory_writable(dir_path)
    local temp_file = dir_path .. "/test_writable.tmp"
    local file, err = io.open(temp_file, "w")
    if file then
        file:close()
        os.remove(temp_file)
        return true
    else
        -- If opening failed, it likely means the directory is not writable.
        -- (This approach also covers cases where the directory doesn't exist)
        return false
    end
end

local dpc = false
local file = io.open("/proc/mounts", "r")
if file then
    for line in file:lines() do
        if string.match(line, "anvil_release.*ro,") then
            dpc = true
            break
        end
    end
    file:close()
end

-- Set <space> as the leader key
-- See `:help mapleader`
--  NOTE: Must happen before plugins are loaded (otherwise wrong leader will be used)
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- From nvim-tree install help. disable netrw at the very start of your init.lua
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- Set to true if you have a Nerd Font installed and selected in the terminal
vim.g.have_nerd_font = true

-- [[ Setting options ]]
-- See `:help vim.o`
-- NOTE: You can change these options as you wish!
--  For more options, you can see `:help option-list`

-- Make line numbers default
-- vim.o.number = true
-- You can also add relative line numbers, to help with jumping.
--  Experiment for yourself to see if you like it!
-- vim.o.relativenumber = true

-- Enable mouse mode, can be useful for resizing splits for example!
-- vim.o.mouse = 'a'

-- Don't show the mode, since it's already in the status line
vim.o.showmode = false

-- Sync clipboard between OS and Neovim.
--  Schedule the setting after `UiEnter` because it can increase startup-time.
--  Remove this option if you want your OS clipboard to remain independent.
--  See `:help 'clipboard'`
-- vim.schedule(function()
--   vim.o.clipboard = 'unnamedplus'
-- end)

-- Save undo history
-- vim.o.undofile = true

-- Case-insensitive searching UNLESS \C or one or more capital letters in the search term
vim.o.smartcase = true

-- Keep signcolumn on by default
vim.o.signcolumn = "yes"

-- Decrease update time
vim.o.updatetime = 250

-- Decrease mapped sequence wait time
vim.o.timeoutlen = 300

-- Configure how new splits should be opened
vim.o.splitright = true
vim.o.splitbelow = true

-- Sets how neovim will display certain whitespace characters in the editor.
--  See `:help 'list'`
--  and `:help 'listchars'`
--
--  Notice listchars is set using `vim.opt` instead of `vim.o`.
--  It is very similar to `vim.o` but offers an interface for conveniently interacting with tables.
--   See `:help lua-options`
--   and `:help lua-options-guide`
vim.o.list = true
vim.opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }

-- Preview substitutions live, as you type!
vim.o.inccommand = "split"

-- Show which line your cursor is on
vim.o.cursorline = true

-- Minimal number of screen lines to keep above and below the cursor.
-- vim.o.scrolloff = 10

-- if performing an operation that would fail due to unsaved changes in the buffer (like `:q`),
-- instead raise a dialog asking if you wish to save the current file(s)
-- See `:help 'confirm'`
vim.o.confirm = true

-- [[ Basic Keymaps ]]
--  See `:help vim.keymap.set()`

-- Clear highlights on search when pressing <Esc> in normal mode
--  See `:help hlsearch`
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>")

-- Diagnostic keymaps
vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Open diagnostic [Q]uickfix list" })

-- Exit terminal mode in the builtin terminal with a shortcut that is a bit easier
-- for people to discover. Otherwise, you normally need to press <C-\><C-n>, which
-- is not what someone will guess without a bit more experience.
--
-- NOTE: This won't work in all terminal emulators/tmux/etc. Try your own mapping
-- or just use <C-\><C-n> to exit terminal mode
vim.keymap.set("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

-- TIP: Disable arrow keys in normal mode
-- vim.keymap.set('n', '<left>', '<cmd>echo "Use h to move!!"<CR>')
-- vim.keymap.set('n', '<right>', '<cmd>echo "Use l to move!!"<CR>')
-- vim.keymap.set('n', '<up>', '<cmd>echo "Use k to move!!"<CR>')
-- vim.keymap.set('n', '<down>', '<cmd>echo "Use j to move!!"<CR>')

-- Keybinds to make split navigation easier.
--  Use CTRL+<hjkl> to switch between windows
--
--  See `:help wincmd` for a list of all window commands
vim.keymap.set("n", "<C-h>", "<C-w><C-h>", { desc = "Move focus to the left window" })
vim.keymap.set("n", "<C-l>", "<C-w><C-l>", { desc = "Move focus to the right window" })
vim.keymap.set("n", "<C-j>", "<C-w><C-j>", { desc = "Move focus to the lower window" })
vim.keymap.set("n", "<C-k>", "<C-w><C-k>", { desc = "Move focus to the upper window" })

-- NOTE: Some terminals have colliding keymaps or are not able to send distinct keycodes
-- vim.keymap.set("n", "<C-S-h>", "<C-w>H", { desc = "Move window to the left" })
-- vim.keymap.set("n", "<C-S-l>", "<C-w>L", { desc = "Move window to the right" })
-- vim.keymap.set("n", "<C-S-j>", "<C-w>J", { desc = "Move window to the lower" })
-- vim.keymap.set("n", "<C-S-k>", "<C-w>K", { desc = "Move window to the upper" })

-- [[ Basic Autocommands ]]
--  See `:help lua-guide-autocommands`

-- Highlight when yanking (copying) text
--  Try it with `yap` in normal mode
--  See `:help vim.hl.on_yank()`
vim.api.nvim_create_autocmd("TextYankPost", {
    desc = "Highlight when yanking (copying) text",
    group = vim.api.nvim_create_augroup("kickstart-highlight-yank", { clear = true }),
    callback = function()
        vim.hl.on_yank()
    end,
})

-- [[ Install `lazy.nvim` plugin manager ]]
--    See `:help lazy.nvim.txt` or https://github.com/folke/lazy.nvim for more info
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
    local lazyrepo = "https://github.com/folke/lazy.nvim.git"
    local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
    if vim.v.shell_error ~= 0 then
        error("Error cloning lazy.nvim:\n" .. out)
    end
end

local function buf_smaller_than(threshold_mb)
    local filename = vim.api.nvim_buf_get_name(0)
    if filename == "" then
        -- Handle unsaved buffers or special cases where filename might be empty
        return true
    end
    local filesize_bytes = vim.fn.getfsize(filename)
    local threshold_bytes = threshold_mb * 1024 * 1024
    if filesize_bytes == -1 then
        -- File doesn't exist or other error, assume it's small enough or handle as needed
        return true
    end
    return filesize_bytes < threshold_bytes
end

---@type vim.Option
local rtp = vim.opt.rtp
rtp:prepend(lazypath)

-- [[ Configure and install plugins ]]
--
--  To check the current status of your plugins, run
--    :Lazy
--
--  You can press `?` in this menu for help. Use `:q` to close the window
--
--  To update plugins you can run
--    :Lazy update
--
-- NOTE: Here is where you install your plugins.
require("lazy").setup({
    checker = {
        enabled = not dpc, -- Disable periodic update checks
        notify = not dpc, -- Disable update notifications
    },
    {
        "ojroques/nvim-bufdel",
        lazy = false,
    },
    ui = {
        -- If you are using a Nerd Font: set icons to an empty table which will use the
        -- default lazy.nvim defined Nerd Font icons, otherwise define a unicode icons table
        icons = vim.g.have_nerd_font and {} or {
            cmd = "⌘",
            config = "🛠",
            event = "📅",
            ft = "📂",
            init = "⚙",
            keys = "🗝",
            plugin = "🔌",
            runtime = "💻",
            require = "🌙",
            source = "📄",
            start = "🚀",
            task = "📌",
            lazy = "💤 ",
        },
    },

    {
        "folke/tokyonight.nvim",
        lazy = false,
        priority = 1000,
        dependencies = {
            {
                "xiyaowong/transparent.nvim",
                lazy = false,
                opts = {
                    -- Optional configuration
                    extra_groups = { "NormalFloat", "NvimTreeNormal" }, -- Example for floating windows
                    exclude_groups = {}, -- Groups to exclude from transparency
                },
            },
        },
        config = function()
            require("tokyonight").setup({
                style = "moon",
                transparent = true,
                styles = {
                    sidebars = "transparent",
                    floats = "transparent",
                    comments = { italic = true },
                },
            })
            vim.cmd([[colorscheme tokyonight-night]])
            vim.api.nvim_set_hl(0, "Comment", { fg = "#EECC99" })
            vim.api.nvim_set_hl(0, "DiagnosticUnderlineError", { sp = "Red", undercurl = true })
            vim.api.nvim_set_hl(0, "DiagnosticUnderlineWarn", { sp = "Cyan", undercurl = true })
        end,
    },

    {
        "rcarriga/nvim-notify",
        lazy = false,
        priority = 999,
    },

    {
        "RRethy/vim-illuminate",
        lazy = false,
        config = function()
            require("illuminate").configure({
                providers = { "lsp", "treesitter", "regex" },
            })
        end,
    },

    -- {
    --   "hrsh7th/nvim-cmp",
    --   event = "InsertEnter",
    --   dependencies = {
    --     { "hrsh7th/cmp-buffer" },           -- source for text in buffer
    --     { "hrsh7th/cmp-path" },             -- source for file system paths
    --     { "L3MON4D3/LuaSnip" },             -- snippet engine
    --     { "saadparwaiz1/cmp_luasnip" },     -- for autocompletion
    --     { "rafamadriz/friendly-snippets" }, -- useful snippets
    --     { "onsails/lspkind.nvim" },         -- vs-code like pictograms
    --   },
    --   config = function()
    --     local cmp = require("cmp")
    --     local luasnip = require("luasnip")
    --     local lspkind = require("lspkind")
    --
    --     -- loads vscode style snippets from installed plugins (e.g. friendly-snippets)
    --     require("luasnip.loaders.from_vscode").lazy_load()
    --
    --     cmp.setup({
    --       completion = {
    --         completeopt = "menu,menuone,preview,noselect",
    --       },
    --       snippet = {   -- configure how nvim-cmp interacts with snippet engine
    --         expand = function(args)
    --           luasnip.lsp_expand(args.body)
    --         end,
    --       },
    --       mapping = cmp.mapping.preset.insert({
    --         ["<C-k>"] = cmp.mapping.select_prev_item(),     -- previous suggestion
    --         ["<C-j>"] = cmp.mapping.select_next_item(),     -- next suggestion
    --         ["<C-b>"] = cmp.mapping.scroll_docs(-4),
    --         ["<C-f>"] = cmp.mapping.scroll_docs(4),
    --         ["<C-Space>"] = cmp.mapping.complete(),     -- show completion suggestions
    --         ["<C-e>"] = cmp.mapping.abort(),            -- close completion window
    --         ["<Tab>"] = cmp.mapping.confirm({ select = true }),
    --       }),
    --       -- sources for autocompletion
    --       sources = cmp.config.sources({
    --         { name = "nvim_lsp" },
    --         { name = "luasnip" },     -- snippets
    --         { name = "buffer" },      -- text within current buffer
    --         { name = "path" },        -- file system paths
    --       }),
    --       -- configure lspkind for vs-code like pictograms in completion menu
    --       formatting = {
    --         format = lspkind.cmp_format({
    --           maxwidth = 50,
    --           ellipsis_char = "...",
    --         }),
    --       },
    --     })
    --   end,
    -- },
    -- NOTE: Plugins can be added with a link (or for a github repo: 'owner/repo' link).
    {
        "NMAC427/guess-indent.nvim", -- Detect tabstop and shiftwidth automatically
    },

    -- NOTE: Plugins can also be added by using a table,
    -- with the first argument being the link and the following
    -- keys can be used to configure plugin behavior/loading/etc.
    --
    -- Use `opts = {}` to automatically pass options to a plugin's `setup()` function, forcing the plugin to be loaded.
    --

    -- Alternatively, use `config = function() ... end` for full control over the configuration.
    -- If you prefer to call `setup` explicitly, use:
    --    {
    --        'lewis6991/gitsigns.nvim',
    --        config = function()
    --            require('gitsigns').setup({
    --                -- Your gitsigns configuration here
    --            })
    --        end,
    --    }
    --
    -- Here is a more advanced example where we pass configuration
    -- options to `gitsigns.nvim`.
    --
    -- See `:help gitsigns` to understand what the configuration keys do
    -- Adds git related signs to the gutter, as well as utilities for managing changes
    {
        "lewis6991/gitsigns.nvim",
        cond = buf_smaller_than(2),
        opts = {
            signs = {
                add = { text = "+" },
                change = { text = "~" },
                delete = { text = "_" },
                topdelete = { text = "‾" },
                changedelete = { text = "~" },
            },
        },
    },

    -- NOTE: Plugins can also be configured to run Lua code when they are loaded.
    --
    -- This is often very useful to both group configuration, as well as handle
    -- lazy loading plugins that don't need to be loaded immediately at startup.
    --
    -- For example, in the following configuration, we use:
    --  event = 'VimEnter'
    --
    -- which loads which-key before all the UI elements are loaded. Events can be
    -- normal autocommands events (`:help autocmd-events`).
    --
    -- Then, because we use the `opts` key (recommended), the configuration runs
    -- after the plugin has been loaded as `require(MODULE).setup(opts)`.

    { -- Useful plugin to show you pending keybinds.
        "folke/which-key.nvim",
        event = "VimEnter", -- Sets the loading event to 'VimEnter'
        opts = {
            -- delay between pressing a key and opening which-key (milliseconds)
            -- this setting is independent of vim.o.timeoutlen
            delay = 500,
            icons = {
                -- set icon mappings to true if you have a Nerd Font
                mappings = vim.g.have_nerd_font,
                -- If you are using a Nerd Font: set icons.keys to an empty table which will use the
                -- default which-key.nvim defined Nerd Font icons, otherwise define a string table
                keys = vim.g.have_nerd_font and {} or {
                    Up = "<Up> ",
                    Down = "<Down> ",
                    Left = "<Left> ",
                    Right = "<Right> ",
                    C = "<C-…> ",
                    M = "<M-…> ",
                    D = "<D-…> ",
                    S = "<S-…> ",
                    CR = "<CR> ",
                    Esc = "<Esc> ",
                    ScrollWheelDown = "<ScrollWheelDown> ",
                    ScrollWheelUp = "<ScrollWheelUp> ",
                    NL = "<NL> ",
                    BS = "<BS> ",
                    Space = "<Space> ",
                    Tab = "<Tab> ",
                    F1 = "<F1>",
                    F2 = "<F2>",
                    F3 = "<F3>",
                    F4 = "<F4>",
                    F5 = "<F5>",
                    F6 = "<F6>",
                    F7 = "<F7>",
                    F8 = "<F8>",
                    F9 = "<F9>",
                    F10 = "<F10>",
                    F11 = "<F11>",
                    F12 = "<F12>",
                },
            },

            -- Document existing key chains
            spec = {
                { "<leader>s", group = "[S]earch" },
                { "<leader>t", group = "[T]oggle" },
                { "<leader>h", group = "Git [H]unk", mode = { "n", "v" } },
            },
        },
    },

    -- NOTE: Plugins can specify dependencies.
    --
    -- The dependencies are proper plugin specifications as well - anything
    -- you do for a plugin at the top level, you can do for a dependency.
    --
    -- Use the `dependencies` key to specify the dependencies of a particular plugin

    { -- Fuzzy Finder (files, lsp, etc)
        "nvim-telescope/telescope.nvim",
        enabled = not dpc,
        event = "VimEnter",
        dependencies = {
            "nvim-lua/plenary.nvim",
            { -- If encountering errors, see telescope-fzf-native README for installation instructions
                "nvim-telescope/telescope-fzf-native.nvim",

                -- `build` is used to run some command when the plugin is installed/updated.
                -- This is only run then, not every time Neovim starts up.
                build = "make",

                -- `cond` is a condition used to determine whether this plugin should be
                -- installed and loaded.
                cond = function()
                    return vim.fn.executable("make") == 1
                end,
            },
            { "nvim-telescope/telescope-ui-select.nvim" },

            -- Useful for getting pretty icons, but requires a Nerd Font.
            { "nvim-tree/nvim-web-devicons", enabled = vim.g.have_nerd_font },
        },
        config = function()
            -- Telescope is a fuzzy finder that comes with a lot of different things that
            -- it can fuzzy find! It's more than just a "file finder", it can search
            -- many different aspects of Neovim, your workspace, LSP, and more!
            --
            -- The easiest way to use Telescope, is to start by doing something like:
            --  :Telescope help_tags
            --
            -- After running this command, a window will open up and you're able to
            -- type in the prompt window. You'll see a list of `help_tags` options and
            -- a corresponding preview of the help.
            --
            -- Two important keymaps to use while in Telescope are:
            --  - Insert mode: <c-/>
            --  - Normal mode: ?
            --
            -- This opens a window that shows you all of the keymaps for the current
            -- Telescope picker. This is really useful to discover what Telescope can
            -- do as well as how to actually do it!

            -- [[ Configure Telescope ]]
            -- See `:help telescope` and `:help telescope.setup()`
            require("telescope").setup({
                -- You can put your default mappings / updates / etc. in here
                --  All the info you're looking for is in `:help telescope.setup()`
                --
                -- defaults = {
                --   mappings = {
                --     i = { ['<c-enter>'] = 'to_fuzzy_refine' },
                --   },
                -- },
                -- pickers = {}
                extensions = {
                    ["ui-select"] = {
                        require("telescope.themes").get_dropdown(),
                    },
                },
            })

            -- Enable Telescope extensions if they are installed
            pcall(require("telescope").load_extension, "fzf")
            pcall(require("telescope").load_extension, "ui-select")

            -- See `:help telescope.builtin`
            local builtin = require("telescope.builtin")
            vim.keymap.set("n", "<leader>sh", builtin.help_tags, { desc = "[S]earch [H]elp" })
            vim.keymap.set("n", "<leader>sk", builtin.keymaps, { desc = "[S]earch [K]eymaps" })
            vim.keymap.set("n", "<leader>sf", builtin.find_files, { desc = "[S]earch [F]iles" })
            vim.keymap.set("n", "<leader>ss", builtin.builtin, { desc = "[S]earch [S]elect Telescope" })
            vim.keymap.set("n", "<leader>sw", builtin.grep_string, { desc = "[S]earch current [W]ord" })
            vim.keymap.set("n", "<leader>sg", builtin.live_grep, { desc = "[S]earch by [G]rep" })
            vim.keymap.set("n", "<leader>sd", builtin.diagnostics, { desc = "[S]earch [D]iagnostics" })
            vim.keymap.set("n", "<leader>sr", builtin.resume, { desc = "[S]earch [R]esume" })
            vim.keymap.set("n", "<leader>s.", builtin.oldfiles, { desc = '[S]earch Recent Files ("." for repeat)' })
            vim.keymap.set("n", "<leader><leader>", builtin.buffers, { desc = "[ ] Find existing buffers" })

            -- Slightly advanced example of overriding default behavior and theme
            vim.keymap.set("n", "<leader>/", function()
                -- You can pass additional configuration to Telescope to change the theme, layout, etc.
                builtin.current_buffer_fuzzy_find(require("telescope.themes").get_dropdown({
                    winblend = 10,
                    previewer = false,
                }))
            end, { desc = "[/] Fuzzily search in current buffer" })

            -- It's also possible to pass additional configuration options.
            --  See `:help telescope.builtin.live_grep()` for information about particular keys
            vim.keymap.set("n", "<leader>s/", function()
                builtin.live_grep({
                    grep_open_files = true,
                    prompt_title = "Live Grep in Open Files",
                })
            end, { desc = "[S]earch [/] in Open Files" })

            -- Shortcut for searching your Neovim configuration files
            vim.keymap.set("n", "<leader>sn", function()
                builtin.find_files({ cwd = vim.fn.stdpath("config") })
            end, { desc = "[S]earch [N]eovim files" })
        end,
    },

    -- LSP Plugins
    {
        -- `lazydev` configures Lua LSP for your Neovim config, runtime and plugins
        -- used for completion, annotations and signatures of Neovim apis
        "folke/lazydev.nvim",
        ft = "lua",
        opts = {
            library = {
                -- Load luvit types when the `vim.uv` word is found
                { path = "${3rd}/luv/library", words = { "vim%.uv" } },
            },
        },
    },

    -- Fidget is an unintrusive window in the corner of your editor that manages its own lifetime.
    -- https://github.com/j-hui/fidget.nvim
    { "j-hui/fidget.nvim", enabled = false, opts = {} },

    { -- Autoformat
        "stevearc/conform.nvim",
        event = { "BufWritePre", "BufNewFile", "InsertLeave" },
        cmd = { "ConformInfo" },
        keys = {
            {
                "<leader>f",
                function()
                    require("conform").format({ async = true, lsp_format = "fallback" })
                end,
                mode = "",
                desc = "[f]ormat buffer",
            },
        },
        opts = {
            notify_on_error = true,
            format_on_save = function(bufnr)
                -- Disable "format_on_save lsp_fallback" for languages that don't
                -- have a well standardized coding style. You can add additional
                -- languages here or re-enable it for the disabled ones.
                local disable_filetypes = { c = true, cpp = true }
                if disable_filetypes[vim.bo[bufnr].filetype] then
                    return nil
                else
                    return {
                        timeout_ms = 500,
                        lsp_format = "fallback",
                    }
                end
            end,
            formatters_by_ft = {
                lua = { "stylua" },
                -- Conform can also run multiple formatters sequentially
                python = { "ruff_format", "ruff_organize_imports" },
                -- You can use 'stop_after_first' to run the first available formatter from the list
                javascript = { "prettierd", "prettier", stop_after_first = true },
                bash = { "beautysh" },
                sh = { "beautysh" },
            },
            formatters = {
                stylua = { prepend_args = { "--indent-type", "Spaces" } },
            },
        },
    },

    { -- Autocompletion
        "saghen/blink.cmp",
        cond = buf_smaller_than(10),
        event = "VimEnter",
        version = "1.*",
        dependencies = {
            { "rafamadriz/friendly-snippets" },
            { "folke/lazydev.nvim" },
            -- Snippet Engine
            -- {
            --     "L3MON4D3/LuaSnip",
            --     version = "2.*",
            --     build = (function()
            --         -- Build Step is needed for regex support in snippets.
            --         -- This step is not supported in many windows environments.
            --         -- Remove the below condition to re-enable on windows.
            --         if vim.fn.has("win32") == 1 or vim.fn.executable("make") == 0 then
            --             return
            --         end
            --         return "make install_jsregexp"
            --     end)(),
            --     dependencies = {
            --         -- `friendly-snippets` contains a variety of premade snippets.
            --         --    See the README about individual language/framework/plugin snippets:
            --         --    https://github.com/rafamadriz/friendly-snippets
            --         {
            --             "rafamadriz/friendly-snippets",
            --             config = function()
            --                 require("luasnip.loaders.from_vscode").lazy_load()
            --             end,
            --         },
            --     },
            --     opts = {},
            -- },
        },

        --- @module 'blink.cmp'
        --- @type blink.cmp.Config
        opts = {
            keymap = {
                -- 'default' (recommended) for mappings similar to built-in completions
                --   <c-y> to accept ([y]es) the completion.
                --    This will auto-import if your LSP supports it.
                --    This will expand snippets if the LSP sent a snippet.
                -- 'super-tab' for tab to accept
                -- 'enter' for enter to accept
                -- 'none' for no mappings
                --
                -- For an understanding of why the 'default' preset is recommended,
                -- you will need to read `:help ins-completion`
                --
                -- No, but seriously. Please read `:help ins-completion`, it is really good!
                --
                -- All presets have the following mappings:
                -- <tab>/<s-tab>: move to right/left of your snippet expansion
                -- <c-space>: Open menu or open docs if already open
                -- <c-n>/<c-p> or <up>/<down>: Select next/previous item
                -- <c-e>: Hide menu
                -- <c-k>: Toggle signature help
                --
                -- See :h blink-cmp-config-keymap for defining your own keymap
                preset = "super-tab",

                -- For more advanced Luasnip keymaps (e.g. selecting choice nodes, expansion) see:
                --    https://github.com/L3MON4D3/LuaSnip?tab=readme-ov-file#keymaps
            },

            appearance = {
                -- 'mono' (default) for 'Nerd Font Mono' or 'normal' for 'Nerd Font'
                -- Adjusts spacing to ensure icons are aligned
                nerd_font_variant = "mono",
            },

            completion = {
                -- By default, you may press `<c-space>` to show the documentation.
                -- Optionally, set `auto_show = true` to show the documentation after a delay.
                documentation = { auto_show = true, auto_show_delay_ms = 500 },
            },

            sources = {
                -- default = { "path", "lsp", "snippets", "lazydev", "buffer", "omni" },
                default = { "path", "lsp", "lazydev", "buffer", "omni" },
                providers = {
                    lazydev = { module = "lazydev.integrations.blink", score_offset = 100 },
                },
            },

            -- snippets = { preset = "luasnip" },

            -- Blink.cmp includes an optional, recommended rust fuzzy matcher,
            -- which automatically downloads a prebuilt binary when enabled.
            --
            -- By default, we use the Lua implementation instead, but you may enable
            -- the rust implementation via `'prefer_rust_with_warning'`
            --
            -- See :h blink-cmp-config-fuzzy for more information
            fuzzy = { implementation = "lua" },

            -- Shows a signature help window while you type arguments for a function
            signature = { enabled = true },
        },
    },

    -- Had to disable. Causing infinite log lines that look like this
    -- DBG 2025-10-02T09:03:42.209 nvim.1510898.0 state_enter:97: input: K_EVENT
    -- DBG 2025-10-02T09:03:42.209 nvim.1510898.0 inbuf_poll:514: blocking... events=false
    -- DBG 2025-10-02T09:03:42.209 nvim.1510898.0 inbuf_poll:514: blocking... events=true
    -- DBG 2025-10-02T09:03:42.225 nvim.1510898.0 state_enter:97: input: K_EVENT
    -- DBG 2025-10-02T09:03:42.225 nvim.1510898.0 inbuf_poll:514: blocking... events=false
    -- DBG 2025-10-02T09:03:42.225 nvim.1510898.0 inbuf_poll:514: blocking... events=true
    {
        "nvim-lualine/lualine.nvim",
        enabled = false,
        event = "VeryLazy",
        dependencies = { "nvim-tree/nvim-web-devicons" },
        opts = {
            theme = "gruvbox",
            extensions = { "nvim-tree", "lazy", "fzf" },
        },
    },

    {
        "nvim-tree/nvim-tree.lua",
        enabled = false,
    },

    -- Highlight todo, notes, etc in comments
    {
        "folke/todo-comments.nvim",
        cond = buf_smaller_than(10),
        event = "VimEnter",
        dependencies = { "nvim-lua/plenary.nvim" },
        opts = { signs = true },
    },

    {
        "nvim-mini/mini.trailspace",
        lazy = false,
        cond = buf_smaller_than(5),
        opts = {
            -- Highlight only in normal buffers (ones with empty 'buftype'). This is
            -- useful to not show trailing whitespace where it usually doesn't matter.
            only_in_normal_buffers = true,
        },
        keys = {
            {
                "<leader>dtw",
                function()
                    local mts = require("mini.trailspace")
                    mts.trim()
                    mts.trim_last_lines()
                end,
                mode = "",
                desc = "Trim Whitespace",
            },
        },
    },

    -- { -- Collection of various small independent plugins/modules
    --     "echasnovski/mini.nvim",
    --     enabled = true,
    --     lazy = false,
    --     config = function()
    --         -- Better Around/Inside textobjects
    --         --
    --         -- Examples:
    --         --  - va)  - [V]isually select [A]round [)]paren
    --         --  - yinq - [Y]ank [I]nside [N]ext [Q]uote
    --         --  - ci'  - [C]hange [I]nside [']quote
    --         -- require("mini.ai").setup({ n_lines = 500 })
    --
    --         -- Add/delete/replace surroundings (brackets, quotes, etc.)
    --         --
    --         -- - saiw) - [S]urround [A]dd [I]nner [W]ord [)]Paren
    --         -- - sd'   - [S]urround [D]elete [']quotes
    --         -- - sr)'  - [S]urround [R]eplace [)] [']
    --         -- require("mini.surround").setup()
    --         -- require("mini.trailspace").setup({
    --         --     -- Highlight only in normal buffers (ones with empty 'buftype'). This is
    --         --     -- useful to not show trailing whitespace where it usually doesn't matter.
    --         --     only_in_normal_buffers = true,
    --         -- })
    --
    --         -- Simple and easy statusline.
    --         --  You could remove this setup call if you don't like it,
    --         --  and try some other statusline plugin
    --         -- local statusline = require("mini.statusline")
    --         -- set use_icons to true if you have a Nerd Font
    --         -- statusline.setup({ use_icons = vim.g.have_nerd_font })
    --
    --         -- You can configure sections in the statusline by overriding their
    --         -- default behavior. For example, here we set the section for
    --         -- cursor location to LINE:COLUMN
    --         ---@diagnostic disable-next-line: duplicate-set-field
    --         -- statusline.section_location = function()
    --         --     return "%2l:%-2v"
    --         -- end
    --
    --         -- ... and there is more!
    --         --  Check out: https://github.com/echasnovski/mini.nvim
    --     end,
    --     keys = {
    --         {
    --             "<leader>dtw",
    --             function()
    --                 local mts = require("mini.trailspace")
    --                 mts.trim()
    --                 mts.trim_last_lines()
    --             end,
    --             mode = "",
    --             desc = "Trim Whitespace",
    --         },
    --     },
    -- },

    { -- Highlight, edit, and navigate code
        "nvim-treesitter/nvim-treesitter",
        build = ":TSUpdate",
        main = "nvim-treesitter.configs", -- Sets main module to use for opts
        cond = buf_smaller_than(10),
        -- [[ Configure Treesitter ]] See `:help nvim-treesitter`
        config = function()
            local treesitter = require("nvim-treesitter")

            local parser_install_dir = vim.fn.stdpath("data") .. "/lazy/nvim-treesitter"
            if not is_directory_writable(parser_install_dir) then
                -- vim.notify("parser dir " .. parser_install_dir .. " is NOT writable")
                -- Defines a read-write directory for treesitters in nvim's cache dir
                local new_parser_install_dir = vim.fn.stdpath("cache") .. "/nvim-treesitter"
                vim.fn.mkdir(parser_install_dir .. "/parser", "p")
                vim.fn.system("rsync " .. parser_install_dir .. "/parser/* " .. new_parser_install_dir .. "/parser")
                parser_install_dir = new_parser_install_dir
                vim.opt.runtimepath:append(parser_install_dir)
                -- else
                --   vim.notify("parser dir " .. parser_install_dir .. " is writable")
            end

            treesitter.setup({
                -- Autoinstall languages that are not installed
                auto_install = not dpc,
                highlight = {
                    enable = true,
                    -- Some languages depend on vim's regex highlighting system (such as Ruby) for indent rules.
                    --  If you are experiencing weird indenting issues, add the language to
                    --  the list of additional_vim_regex_highlighting and disabled languages for indent.
                    disable = { "verilog" },
                    additional_vim_regex_highlighting = { "ruby" },
                },
                parser_install_dir = parser_install_dir,
                sync_install = not dpc,
                indent = {
                    enable = true,
                    disable = { "tcl", "ruby" },
                },
                -- enable autotagging (w/ nvim-ts-autotag plugin)
                autotag = { enable = true },
                ensure_installed = {
                    "angular",
                    "asm",
                    "awk",
                    "bash",
                    "c",
                    "c3",
                    "c_sharp",
                    "cairo",
                    "clojure",
                    "cmake",
                    "cpp",
                    "crystal",
                    "css",
                    "csv",
                    "cuda",
                    "d",
                    "dart",
                    "diff",
                    "dockerfile",
                    "doxygen",
                    "editorconfig",
                    "elixir",
                    "elisp",
                    "elm",
                    "elvish",
                    "fennel",
                    "fish",
                    "fortran",
                    "forth",
                    "fsharp",
                    "func",
                    "git_commit",
                    "git_config",
                    "git_rebase",
                    "gitignore",
                    "glimmer",
                    "glimmer_javascript",
                    "glimmer_typescript",
                    "gnuplot",
                    "go",
                    "gomod",
                    "gosum",
                    "gotmpl",
                    "gowork",
                    "gpg",
                    "graphql",
                    "gren",
                    "groovy",
                    "hack",
                    "haskell",
                    "haskell_persistent",
                    "haxe",
                    "hjson",
                    "html",
                    "htmldjango",
                    "http",
                    "java",
                    "javadoc",
                    "javascript",
                    "jinja2",
                    "jq",
                    "jpp",
                    "jsdoc",
                    "json",
                    "json_schema",
                    "julia",
                    "just",
                    "kcl",
                    "koto",
                    "kotlin",
                    "latex",
                    "llvm",
                    "llvm_mir",
                    "lua",
                    "luadoc",
                    "luau",
                    "make",
                    "markdown",
                    "markdown_inline",
                    "math",
                    "matlab",
                    "monkey",
                    "nasm",
                    "nginx",
                    "nim",
                    "nim_format_string",
                    "ninja",
                    "nix",
                    "ocaml",
                    "ocamllex",
                    "odin",
                    "ohm",
                    "p4",
                    "pascal",
                    "perl",
                    "php",
                    "phpdoc",
                    "pony",
                    "powershell",
                    "printf",
                    "prolog",
                    "python",
                    "query",
                    "ruby",
                    "strace",
                    "toml",
                    "verilog",
                    "vim",
                    "vimdoc",
                    "yaml",
                    "zig",
                },
                -- Incremental selection based on the named nodes from the grammar.
                incremental_selection = {
                    enable = true,
                    keymaps = {
                        init_selection = "<C-space>",
                        node_incremental = "<C-space>",
                        scope_incremental = false,
                        node_decremental = "<bs>",
                    },
                },
            })
        end,
        -- There are additional nvim-treesitter modules that you can use to interact
        -- with nvim-treesitter. You should go explore a few and see what interests you:
        --
        --    - Incremental selection: Included, see `:help nvim-treesitter-incremental-selection-mod`
        --    - Show your current context: https://github.com/nvim-treesitter/nvim-treesitter-context
        --    - Treesitter + textobjects: https://github.com/nvim-treesitter/nvim-treesitter-textobjects
    },

    -- The following comments only work if you have downloaded the kickstart repo, not just copy pasted the
    -- init.lua. If you want these files, they are in the repository, so you can just download them and
    -- place them in the correct locations.

    -- NOTE: Next step on your Neovim journey: Add/Configure additional plugins for Kickstart
    --
    --  Here are some example plugins that I've included in the Kickstart repository.
    --  Uncomment any of the lines below to enable them (you will need to restart nvim).
    --
    -- require 'kickstart.plugins.debug',
    -- require 'kickstart.plugins.indent_line',
    -- require 'kickstart.plugins.lint',
    -- require 'kickstart.plugins.autopairs',
    -- require 'kickstart.plugins.neo-tree',
    -- require 'kickstart.plugins.gitsigns', -- adds gitsigns recommend keymaps

    -- NOTE: The import below can automatically add your own plugins, configuration, etc from `lua/custom/plugins/*.lua`
    --    This is the easiest way to modularize your config.
    --
    --  Uncomment the following line and add your plugins to `lua/custom/plugins/*.lua` to get going.
    -- { import = 'custom.plugins' },
    --
    -- For additional information with loading, sourcing and examples see `:help lazy.nvim-🔌-plugin-spec`
    -- Or use telescope!
    -- In normal mode type `<space>sh` then write `lazy.nvim-plugin`
    -- you can continue same window with `<space>sr` which resumes last telescope search

    { -- Add indentation guides even on blank lines
        "lukas-reineke/indent-blankline.nvim",
        -- Enable `lukas-reineke/indent-blankline.nvim`
        -- See `:help ibl`
        -- cond = function()
        --     local filename = vim.api.nvim_buf_get_name(0)
        --     if filename == "" then
        --         -- Handle unsaved buffers or special cases where filename might be empty
        --         return true
        --     end
        --     local filesize_bytes = vim.fn.getfsize(filename)
        --     -- Define your size threshold (e.g., 5 MB)
        --     local threshold_mb = 1
        --     local threshold_bytes = threshold_mb * 1024 * 1024
        --
        --     if filesize_bytes == -1 then
        --         -- File doesn't exist or other error, assume it's small enough or handle as needed
        --         return true
        --     end
        --
        --     return filesize_bytes < threshold_bytes
        -- end,
        main = "ibl",
        config = function()
            local hooks = require("ibl.hooks")
            -- create the highlight groups in the highlight setup hook, so they are reset
            -- every time the colorscheme changes
            hooks.register(hooks.type.HIGHLIGHT_SETUP, function()
                vim.api.nvim_set_hl(0, "RainbowRed", { fg = "#E06C75" })
                vim.api.nvim_set_hl(0, "RainbowYellow", { fg = "#E5C07B" })
                vim.api.nvim_set_hl(0, "RainbowBlue", { fg = "#61AFEF" })
                vim.api.nvim_set_hl(0, "RainbowOrange", { fg = "#D19A66" })
                vim.api.nvim_set_hl(0, "RainbowGreen", { fg = "#98C379" })
                vim.api.nvim_set_hl(0, "RainbowViolet", { fg = "#C678DD" })
                vim.api.nvim_set_hl(0, "RainbowCyan", { fg = "#56B6C2" })
            end)

            require("ibl").setup({
                indent = {
                    highlight = {
                        "RainbowRed",
                        "RainbowYellow",
                        "RainbowBlue",
                        "RainbowOrange",
                        "RainbowGreen",
                        "RainbowViolet",
                        "RainbowCyan",
                    },
                    char = "▎", -- default char
                    -- char = "▏" -- a thinner version
                },
                scope = {
                    enabled = true,
                    show_start = false,
                    show_end = false,
                    show_exact_scope = true,
                },
            })
        end,
    },

    { -- Faster.nvim will selectively disable some features when big file is opened or macro is executed.
        "pteroctopus/faster.nvim",
        opts = {
            -- Behaviour table contains configuration for behaviours faster.nvim uses
            behaviours = {
                -- Bigfile configuration controls disabling and enabling of features when
                -- big file is opened
                bigfile = {
                    -- Behaviour can be turned on or off. To turn on set to true, otherwise
                    -- set to false
                    on = true,
                    -- Table which contains names of features that will be disabled when
                    -- bigfile is opened. Feature names can be seen in features table below.
                    -- features_disabled can also be set to "all" and then all features that
                    -- are on (on=true) are going to be disabled for this behaviour
                    features_disabled = {
                        "illuminate",
                        "matchparen",
                        "lsp",
                        "treesitter",
                        "indent_blankline",
                        "vimopts",
                        "syntax",
                        "filetype",
                    },
                    -- Files larger than `filesize` are considered big files. Value is in MB.
                    filesize = 2,
                },
            },
        },
    },

    -- Show window (after configurable delay) with clues. It lists available next keys along with their descriptions
    -- (auto generated from descriptions present keymaps and user-supplied clues; preferring the former).
    {
        "nvim-mini/mini.clue",
    },
    {
        "nat-418/tcl.nvim",
    },
    {
        "mfussenegger/nvim-lint",
    },
    {
        "greggh/claude-code.nvim",
        dependencies = {
            "nvim-lua/plenary.nvim", -- Required for git operations
        },
        config = function()
            require("claude-code").setup()
        end,
    },
})

-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
local options = {
    cmdheight = 1, -- more space in the neovim command line for displaying messages
    encoding = "utf-8", -- Myles: handle things like table lines
    fileencoding = "utf-8", -- file-content encoding for the current buffer
    tabstop = 4, -- insert 4 spaces for a tab
    softtabstop = 4,
    shiftwidth = 4, -- the number of spaces inserted for each indentation
    expandtab = true, -- In Insert mode: convert tabs to spaces
    autoindent = true,
    guicursor = "i:block",
    foldmethod = "manual",
    foldlevel = 99,
    startofline = false, -- When "on", certain cmds, such as gg and G, move the cursor to the first non-blank of the line.
    hidden = true, -- allows you to move around files quickly w/out worrying about whether they're written to disk
    mouse = "", -- enables mouse support
    mousefocus = true,
    mousehide = true,
    mousemodel = "extend",
    textwidth = 130,
    backspace = "indent,eol,start", -- allow backspace on indent, end of line or insert mode start position
    completeopt = { "menuone", "preview" }, -- A comma-separated list of options for Insert mode completion
    conceallevel = 0, -- so that `` is visible in markdown files
    hlsearch = true, -- Highlight all matches on previous search pattern. Use <leader>nh to un-highlight.
    ignorecase = true, -- ignore case in search patterns
    smartindent = false,
    pumheight = 10, -- max number of items to show in the popup menu
    showmode = false, -- we don't need to see things like -- INSERT -- anymore
    showtabline = 1, -- default value
    scrolloff = 999, -- Keep cursor centered vertically
    cursorline = true, -- highlight the current line
    termguicolors = true, -- set term gui colors to enable highlight groups (most terminals support this)
    swapfile = true, -- creates a swapfile for the buffer
    backup = false, -- creates a backup file
    writebackup = true,
    directory = "/tmp/" .. os.getenv("USER") .. "/vim", -- list of dir names for the swap file
    wildmenu = true,
    wildmode = "longest:full,full", -- Better control over file name completion when using :e <file>
    timeoutlen = 1000, -- Time in milliseconds to wait for a mapped sequence to complete.
    updatetime = 300, -- faster completion (4000ms default)
    number = false, -- set numbered lines
    relativenumber = false, -- set relative numbered lines
    numberwidth = 2, -- set number column width to 2 (default 4)
    signcolumn = "yes", -- show sign column so that text doesn't shift
    wrap = true, -- When on, lines longer than the width of the window will wrap and displaying continues on the next line.
    splitright = true, -- split vertical window to the right
    splitbelow = true, -- split horizontal window to the bottom
    viewoptions = "folds,cursor",
    sessionoptions = "folds",
    visualbell = false,
    errorbells = false,
    laststatus = 2,
    cpoptions = "ceFs", -- Compatibility (with vi) options (':h cpo' for more info)
    sidescrolloff = 8,
    -- This was causing deleted text to go into the system clipboard. This is not normally the
    -- way I work.
    -- vim.opt.clipboard:append("unnamedplus") -- allows neovim to access the system clipboard
    -- I think this is the default
    clipboard = "",
    -- guifont = "",
}

for k, v in pairs(options) do
    pcall(function()
        vim.opt[k] = v
    end)
end

vim.cmd([[
    "let &t_Cs = "\e[4:3m"
    "let &t_Ce = "\e[4:0m"
    highlight DiagnosticUnderlineError guisp='Red' gui=undercurl
    highlight DiagnosticUnderlineWarn guisp='Cyan' gui=undercurl
]])

vim.api.nvim_set_hl(0, "DiagnosticUnnecessary", { fg = "#00FFFF" })

-- Note: vim.opt:remove()
-- Remove a value from string-style options. See ":h set-="
-- These are equivalent:
-- vim.opt.wildignore:remove('*.pyc')
-- vim.opt.wildignore = vim.opt.wildignore - '*.pyc'

vim.opt.formatoptions:remove("t")

local my_augroup1 = vim.api.nvim_create_augroup("my_augroup1", { clear = true })

-- Jump to the last position when reopening a file
vim.api.nvim_create_autocmd("BufReadPost", {
    group = my_augroup1,
    callback = function(args)
        local line = vim.fn.line
        local valid_line = line([['"]]) >= 1 and line([['"]]) <= line("$")
        local not_commit = vim.b[args.buf].filetype ~= "commit" -- ~= means not equal to

        if valid_line and not_commit then
            vim.cmd([[normal! g`"zz]])
        end
    end,
})

vim.api.nvim_create_autocmd("BufWinEnter", {
    group = my_augroup1,
    callback = function()
        vim.opt.incsearch = buf_smaller_than(50)
    end,
})

-- Jump to the last position when reopening a file
vim.api.nvim_create_autocmd("BufReadPost", {
    group = my_augroup1,
    callback = function(args)
        local line = vim.fn.line
        local valid_line = line([['"]]) >= 1 and line([['"]]) <= line("$")
        local not_commit = vim.b[args.buf].filetype ~= "commit" -- ~= means not equal to

        if valid_line and not_commit then
            vim.cmd([[normal! g`"zz]])
        end
    end,
})

-- Python debug parentheses
vim.cmd([[
    function! PyAddParensToDebugs()
        execute "normal! mZ"
        execute "%s/^\\(\\s*\\)\\(ic\\)\\( \\(.*\\)\\)\\{-}$/\\1\\2(\\4)/"
        execute "%s/^\\(\\s*\\)\\(ice\\)\\( \\(.*\\)\\)\\{-}$/\\1ic(\\4)\\r\\1exit()/"
        execute "%s/^\\(\\s*\\)\\(exit\\|e\\)$/\\1exit()/"
        execute "normal! `Z"
    endfunction

    filetype plugin indent on
    " The autocmds MUST come after 'filetype plugin indent on' in order to
    " override settings that come from the <install_dir>/runtime/* filetype and indent files.
    augroup my_au_group | autocmd!
        autocmd BufWritePre * if count(['python'],&filetype)
            \ |                   silent! call PyAddParensToDebugs()
            \ |               endif

        " Equalize pane sizes after terminal resize
        autocmd BufWinEnter,VimResized * wincmd =
    augroup end
]])

vim.cmd([[
    function! s:ZoomToggle() abort
        if exists('t:zoomed') && t:zoomed
            execute t:zoom_winrestcmd
            let t:zoomed = 0
        else
            let t:zoom_winrestcmd = winrestcmd()
            resize
            vertical resize
            let t:zoomed = 1
        endif
    endfunction
    command! ZoomToggle call s:ZoomToggle()
]])

vim.notify = require("notify")

vim.lsp.enable({ "lua_ls", "ruff", "ty" })
vim.lsp.config("*", {
    root_markers = { ".git" },
})
vim.lsp.config("*", {
    capabilities = {
        textDocument = {
            semanticTokens = {
                multilineTokenSupport = true,
            },
        },
    },
})
vim.lsp.log.set_level(vim.log.levels.WARN)

-- Diagnostic Config
-- See :help vim.diagnostic.Opts
vim.diagnostic.config({
    severity_sort = true,
    float = { border = "rounded", source = "if_many" },
    underline = { severity = vim.diagnostic.severity.ERROR },
    signs = vim.g.have_nerd_font and {
        text = {
            [vim.diagnostic.severity.ERROR] = "󰅚 ",
            [vim.diagnostic.severity.WARN] = "󰀪 ",
            [vim.diagnostic.severity.INFO] = "󰋽 ",
            [vim.diagnostic.severity.HINT] = "󰌶 ",
        },
    } or {},
    virtual_text = {
        source = "if_many",
        spacing = 2,
        format = function(diagnostic)
            local diagnostic_message = {
                [vim.diagnostic.severity.ERROR] = diagnostic.message,
                [vim.diagnostic.severity.WARN] = diagnostic.message,
                [vim.diagnostic.severity.INFO] = diagnostic.message,
                [vim.diagnostic.severity.HINT] = diagnostic.message,
            }
            return diagnostic_message[diagnostic.severity]
        end,
    },
})

vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("kickstart-lsp-attach", { clear = true }),
    callback = function(event)
        -- NOTE: Remember that Lua is a real programming language, and as such it is possible
        -- to define small helper and utility functions so you don't have to repeat yourself.
        --
        -- In this case, we create a function that lets us more easily define mappings specific
        -- for LSP related items. It sets the mode, buffer and description for us each time.
        local map = function(keys, func, desc, mode)
            mode = mode or "n"
            vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
        end

        -- Rename the variable under your cursor.
        --  Most Language Servers support renaming across files, etc.
        map("grn", vim.lsp.buf.rename, "[R]e[n]ame")

        -- Execute a code action, usually your cursor needs to be on top of an error
        -- or a suggestion from your LSP for this to activate.
        map("gra", vim.lsp.buf.code_action, "[G]oto Code [A]ction", { "n", "x" })

        if not dpc then
            -- Find references for the word under your cursor.
            map("grr", require("telescope.builtin").lsp_references, "[G]oto [R]eferences")

            -- Jump to the implementation of the word under your cursor.
            --  Useful when your language has ways of declaring types without an actual implementation.
            map("gri", require("telescope.builtin").lsp_implementations, "[G]oto [I]mplementation")

            -- Jump to the definition of the word under your cursor.
            --  This is where a variable was first declared, or where a function is defined, etc.
            --  To jump back, press <C-t>.
            map("grd", require("telescope.builtin").lsp_definitions, "[G]oto [D]efinition")

            -- WARN: This is not Goto Definition, this is Goto Declaration.
            --  For example, in C this would take you to the header.
            map("grD", vim.lsp.buf.declaration, "[G]oto [D]eclaration")

            -- Fuzzy find all the symbols in your current document.
            --  Symbols are things like variables, functions, types, etc.
            map("gO", require("telescope.builtin").lsp_document_symbols, "Open Document Symbols")

            -- Fuzzy find all the symbols in your current workspace.
            --  Similar to document symbols, except searches over your entire project.
            map("gW", require("telescope.builtin").lsp_dynamic_workspace_symbols, "Open Workspace Symbols")

            -- Jump to the type of the word under your cursor.
            --  Useful when you're not sure what type a variable is and you want to see
            --  the definition of its *type*, not where it was *defined*.
            map("grt", require("telescope.builtin").lsp_type_definitions, "[G]oto [T]ype Definition")
        end

        -- The following two autocommands are used to highlight references of the
        -- word under your cursor when your cursor rests there for a little while.
        --    See `:help CursorHold` for information about when this is executed
        --
        -- When you move your cursor, the highlights will be cleared (the second autocommand).
        local client = vim.lsp.get_client_by_id(event.data.client_id)
        if client then
            local highlight_augroup = vim.api.nvim_create_augroup("kickstart-lsp-highlight", { clear = false })
            vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
                buffer = event.buf,
                group = highlight_augroup,
                callback = vim.lsp.buf.document_highlight,
            })

            vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
                buffer = event.buf,
                group = highlight_augroup,
                callback = vim.lsp.buf.clear_references,
            })

            vim.api.nvim_create_autocmd("LspDetach", {
                group = vim.api.nvim_create_augroup("kickstart-lsp-detach", { clear = true }),
                callback = function(event2)
                    vim.lsp.buf.clear_references()
                    vim.api.nvim_clear_autocmds({ group = "kickstart-lsp-highlight", buffer = event2.buf })
                end,
            })
        end

        -- The following code creates a keymap to toggle inlay hints in your
        -- code, if the language server you are using supports them
        --
        -- This may be unwanted, since they displace some of your code
        map("<leader>th", function()
            vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = event.buf }))
        end, "[T]oggle Inlay [H]ints")
    end,
})

if not vim.api.nvim_get_option_value("diff", { win = 0 }) then
    vim.cmd("silent! sball")
    vim.cmd("silent! only")
end

ToggleStuff = function()
    -- sort of a "ternary" operator in lua
    vim.o.signcolumn = vim.o.signcolumn == "yes" and "no" or "yes"
    vim.cmd(":IBLToggle")
    vim.diagnostic.enable(not vim.diagnostic.is_enabled())
end
ToggleWrap = function()
    vim.o.wrap = not vim.o.wrap
end

local noremap_silent = { noremap = true, silent = true }
local keymap = vim.keymap.set

-- Modes
--   normal_mode = "n",
--   insert_mode = "i",
--   visual_mode = "v",
--   visual_block_mode = "x",
--   term_mode = "t",
--   command_mode = "c",
keymap("n", "<c-d>", "dd", { noremap = true, silent = true, desc = "Delete line" })
keymap("i", "kj", "<Esc>", { noremap = true, silent = true, desc = "Exit insert mode with kj" })
keymap("i", "jk", "<Esc>", { noremap = true, silent = true, desc = "Exit insert mode with kj" })
keymap("i", "jj", "<Esc>", { noremap = true, silent = true, desc = "Exit insert mode with kj" })
keymap("i", "kk", "<Esc>", { noremap = true, silent = true, desc = "Exit insert mode with kj" })
keymap("n", "<c-l>", ":nohl<cr>", { noremap = true, silent = true, desc = "Clear search highlights" })
keymap("n", "<c-n>", "<c-w><c-w>", { noremap = true, silent = true, desc = "Move to next window" })
--keymap("n", "<leader>cc", "<cmd>ClaudeCode<CR>", { desc = "Toggle Claude Code" })

-- Remapping v -> V and V -> v
keymap("n", "v", "V", noremap_silent)
keymap("n", "V", "v", noremap_silent)
keymap("n", "e", ":e<space>", { noremap = true, desc = "Open file" })
keymap("n", "<leader>s", ":w<cr>", { noremap = true, silent = true, desc = "Save changes to file" })
keymap("n", "<leader>w", ":set wrap<cr>", { noremap = true, silent = true, desc = "Enable line wrap" })
keymap("n", "<leader>nw", ":set nowrap<cr>", { noremap = true, silent = true, desc = "Disable line wrap" })
keymap("n", "<leader>it", ":IBLToggle<cr>", { noremap = true, silent = true, desc = "Toggle indent lines" })
keymap("n", "<leader>h", ":TSToggle highlight<cr>", { desc = "Toggle NVIM Treesitter Highlight" })
keymap("n", "<leader>z", ":ZoomToggle<cr>", { noremap = true, silent = true, desc = "Toggle Zen Mode" })
keymap("n", "<leader>wsq", 'ysiw"', { desc = "Word Surround Quotes" })
keymap("n", "<leader>f", "zR", { desc = "Open all folds" })

-- Stay in indent mode in visual line mode
keymap("v", "<", "<gv", noremap_silent)
keymap("v", ">", ">gv", noremap_silent)

-- Navigate buffers
keymap("n", "<c-j>", ":bnext<cr>", noremap_silent)
keymap("n", "<c-k>", ":bprevious<cr>", noremap_silent)
keymap("n", "<leader>q", ":BufDelAll<cr>", {
    noremap = true,
    silent = true,
    desc = "Close all buffers and exit. Prompt for save if needed.",
})
keymap("n", "<leader>d", ":BufDel<cr>", { noremap = true, silent = true, desc = "Close the current buffer." })
keymap("n", "<leader>D", ":BufDelOthers<cr>", {
    noremap = true,
    silent = true,
    desc = "Close all buffers except the current one.",
})
keymap("n", "<leader>Q", ":BufDelAll!<cr>", { noremap = true, silent = true, desc = "Full exit, discard all changes" })
keymap("n", "<leader>x", ":xa<cr>", { noremap = true, desc = "Full exit, save all changes." })
-- splits
keymap("n", "<leader>v", ":vsplit<cr>:bn<cr>", noremap_silent)
keymap("n", "<leader>h", ":split<cr>:bn<cr>", noremap_silent)
keymap("n", "<leader>c", ":q<cr>", { noremap = true, silent = true, desc = "Close the current window" })

keymap("n", "<leader>ts", ToggleStuff, { noremap = true, silent = true, desc = "Toggle prepare for copy selection" })
keymap("n", "<leader>tw", ToggleWrap, { noremap = true, silent = true, desc = "Toggle line wrap" })
keymap("n", "Q", "@q", noremap_silent)
keymap("n", ">", ">>", noremap_silent)
keymap("n", "<", "<<", noremap_silent)
keymap("n", "-", "<c-w>-", noremap_silent)
--vim.cmd([[map  -       <c-w>-]])

-- Myles keymaps to change to lua later
vim.cmd([[map  +       <c-w><]])
vim.cmd([[map <leader>rt :%s/\\t/  /g<cr>]])
vim.cmd([[map <leader>a  :wa<cr>]])
vim.cmd([[map <leader>=  <c-w>=]])
vim.cmd([[vmap <leader>y :w! /tmp/vitmp_$USER<CR>]])
vim.cmd([[nmap <leader>p :r! cat /tmp/vitmp_$USER<CR>]])
vim.cmd([[map <leader># :windo set invnumber<CR>]])
-- Enable fold-toggle with ctrl-spacebar
-- This is how you map ctrl-space in vim
vim.cmd([[noremap <c-@> za]])
vim.cmd([[noremap <BS> <<]])
vim.cmd([[map <leader>ms :mksession! ~/.session.vim<CR>]])
vim.cmd([[map <leader>ls :source ~/.session.vim<CR>]])

-- vim: tabstop=4 softtabstop=4 shiftwidth=4 expandtab
