-----------------------
---- LOOK AND FEEL ----
-----------------------

-- gaps in used to be 10 and out was 15 rounding used to be 5 with power 2
hl.config({
    general = {
        gaps_in  = 3.5,
        gaps_out = 7,

        border_size = 2,

        col = {
            active_border   = { colors = {"#83C092"}},
            inactive_border = "#333C43",
        },

        resize_on_border = false,

        allow_tearing = false,

        layout = "dwindle",
    },

    decoration = {
        rounding       =1,
        rounding_power = 1,

        -- Change transparency of focused and unfocused windows
        active_opacity   = 1.0,
        inactive_opacity = 1.0,

        shadow = {
            enabled      = false,
            range        = 4,
            render_power = 3,
            color        = 0xee1a1a1a,
        },

        blur = {
            enabled   = true,
            size      = 3,
            passes    = 1,
            vibrancy  = 0.1696,
        },
    },

    animations = {
        enabled = true,
    },
})
