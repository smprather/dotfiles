local function is_directory_writable(dir_path)
    -- Create a temporary file name within the directory
    local temp_file = dir_path .. "/test_writable.tmp"

    -- Attempt to open the file in write mode
    local file, err = io.open(temp_file, "w")

    if file then
        -- If successful, the directory is writable. Close and remove the temporary file.
        file:close()
        os.remove(temp_file)
        return true
    else
        -- If opening failed, it likely means the directory is not writable.
        -- (This approach also covers cases where the directory doesn't exist)
        return false
    end
end

return {
    "nvim-treesitter/nvim-treesitter",
    version = nil,
    event = { "BufReadPre", "BufNewFile" },
    build = ":TSUpdate",
    dependencies = {
        "windwp/nvim-ts-autotag",
    },
    config = function()
        local treesitter = require("nvim-treesitter.configs")

        local parser_install_dir = vim.fn.stdpath("data") .. "/lazy/nvim-treesitter"
        if not is_directory_writable(parser_install_dir) then
            -- Defines a read-write directory for treesitters in nvim's cache dir
            local new_parser_install_dir = vim.fn.stdpath("cache") .. "/nvim-treesitter"
            vim.fn.mkdir(parser_install_dir .. "/parser", "p")
            vim.fn.system("rsync " .. parser_install_dir .. "/parser/* " .. new_parser_install_dir .. "/parser")
            parser_install_dir = new_parser_install_dir
        end
        vim.opt.runtimepath:append(parser_install_dir)

        treesitter.setup({
            parser_install_dir = parser_install_dir,
            additional_vim_regex_highlighting = false,
            sync_install = false,
            highlight = { -- enable syntax highlighting
                enable = true,
                disable = { "verilog" },
            },
            indent = {
                enable = true,
                disable = { "tcl" },
            },
            auto_install = false,
            -- enable autotagging (w/ nvim-ts-autotag plugin)
            autotag = { enable = true },
            ensure_installed = {
                "python",
                "bash",
                "yaml",
                "json",
                "lua",
                "html",
                "vim",
                "vimdoc",
                "gitignore",
                "markdown",
                "markdown_inline",
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
}
