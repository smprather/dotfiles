local root_files = {
    ".luarc.json",
    ".luarc.jsonc",
    ".luacheckrc",
    ".stylua.toml",
    "stylua.toml",
    "selene.toml",
    "selene.yml",
    ".git",
    ".",
}

return {
    cmd = { "lua-language-server", "--logpath=/dev/shm/" .. os.getenv("USER") .. "/lua_language_server" },
    filetypes = { "lua" },
    root_markers = root_files,
    settings = {
        Lua = {
            runtime = {
                version = "LuaJIT",
                path = { "lua/?.lua", "lua/?/init.lua" },
            },
            diagnostics = {
                globals = { "vim" },
                disable = { "missing-fields" },
            },
            telemetry = {
                enable = false,
            },
            workspace = {
                checkThirdParty = false,
                library = {
                    vim.env.VIMRUNTIME,
                },
            },
            completion = {
                callSnippet = "Replace",
            },
        },
    },
}
