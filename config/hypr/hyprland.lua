--sources
require("monitors")
require("keybinds")
require("decorations")
require("animations")

------------------
---- MONITORS ----
------------------

hl.monitor({
    output   = "",
    mode     = "highres",
    position = "auto",
    scale    = "auto",
})

-------------------
---- AUTOSTART ----
-------------------

hl.on("hyprland.start", function()
	hl.exec_cmd("qs")
	hl.exec_cmd("systemctl --usr start hyprpolkitagent")
	hl.exec_cmd("awww-daemon")
	hl.exec_cmd("awww img ~/nixos-dotfiles/icons/wallpaper/wallpaper4.jpg")
	hl.exec_cmd("hypridle")
	hl.exec_cmd("cursor-clip --daemon")
	hl.exec_cmd("hyprsunset --temperature 6200")
end)

-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------

hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")

hl.env("HYPRCURSOR_THEME","Vimix-hypr")
hl.env("HYPRCURSOR_SIZE", "24")


---------------
---- INPUT ----
---------------

hl.config({
    input = {
        kb_layout  = "us",
        kb_variant = "",
        kb_model   = "",
        kb_options = "",
        kb_rules   = "",
	
	repeat_rate = 30,
	repeat_delay = 300,

        follow_mouse = 1,

        sensitivity = 0, -- -1.0 - 1.0, 0 means no modification.

        touchpad = {
            natural_scroll = false,
        },
    },
})
hl.gesture({
    fingers = 3,
    direction = "down",
    action = "close"
})

hl.gesture({
    fingers = 3,
    direction = "horizontal",
    action = "workspace"
})

hl.gesture({ fingers = 2, direction = "pinch", action = "cursor_zoom", zoom_level = 1, mode = "live" })

-- Example per-device config
-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Devices/ for more
hl.device({
    name        = "epic-mouse-v1",
    sensitivity = -0.5,
})


--------------------------------
---- WINDOWS AND WORKSPACES ----
--------------------------------



local suppressMaximizeRule = hl.window_rule({
    -- Ignore maximize requests from all apps. You'll probably like this.
    name  = "suppress-maximize-events",
    match = { class = ".*" },

    suppress_event = "maximize",
})
-- suppressMaximizeRule:set_enabled(false)

hl.window_rule({
    -- Fix some dragging issues with XWayland
    name  = "fix-xwayland-drags",
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },

    no_focus = true,
})

-- XWAYLAND SHIT

hl.config({ xwayland = { force_zero_scaling = true } })

hl.env("GDK_SCALE", "1.25")
hl.env("XCURSOR_SIZE", "32")
hl.env("XCURSOR_THEME", "Vimix-X")
-- Layer rules also return a handle.
-- local overlayLayerRule = hl.layer_rule({
--     name  = "no-anim-overlay",
--     match = { namespace = "^my-overlay$" },
--     no_anim = true,
-- })
-- overlayLayerRule:set_enabled(false)

-- Hyprland-run windowrule
hl.window_rule({
    name  = "move-hyprland-run",
    match = { class = "hyprland-run" },

    move  = "20 monitor_h-120",
    float = true,
})
