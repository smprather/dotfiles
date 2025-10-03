return {
    { -- Add indentation guides even on blank lines
        'lukas-reineke/indent-blankline.nvim',
        -- Enable `lukas-reineke/indent-blankline.nvim`
        -- See `:help ibl`
        main = 'ibl',
        opts = {
            indent = {
                char = "▎" -- default char
                -- char = "▏" -- a thinner version
            },
            scope = {
                enabled = true,
                show_start = true, -- disable if KiTTY does not render underlines correctly with JetBrains Font
                show_end = true,   -- disable if KiTTY does not render underlines correctly with JetBrains Font
            },
        },
    },
}
