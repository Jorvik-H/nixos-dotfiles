---------------------
---- MY PROGRAMS ----
---------------------

-- Set programs that you use
local terminal    = "kitty"
local fileManager = "kitty -e yazi"
local browser 	  = "librewolf"
local music       = "spotify"
local launcher    = "qs ipc call launcher apps"
local runner      = "qs ipc call launcher procs"
local gaps_on = true
local saved_in, saved_out = 3.5, 7




---------------------
---- KEYBINDINGS ----
---------------------

local mainMod = "SUPER" -- Sets "Windows" key as main modifier
local secondMod = "SUPER + SHIFT"

-- Apps
hl.bind(secondMod .. " + T", hl.dsp.exec_cmd(terminal))
hl.bind(secondMod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(secondMod .. " + SPACE", hl.dsp.exec_cmd(launcher))
hl.bind(secondMod .. " + F", hl.dsp.exec_cmd(browser))
hl.bind(secondMod .. " + C", hl.dsp.exec_cmd("chromium"))
hl.bind(secondMod .. " + D", hl.dsp.exec_cmd("ferdium"))
hl.bind(secondMod .. " + N", hl.dsp.exec_cmd("obsidian"))
hl.bind(mainMod .. " + SPACE", hl.dsp.exec_cmd(runner))
hl.bind(mainMod .. " + S", hl.dsp.exec_cmd("qs ipc call media toggle"))
hl.bind(secondMod .. " + P", hl.dsp.exec_cmd("hyprlock"))
hl.bind(mainMod .. " + P", hl.dsp.exec_cmd("pgrep hypridle && pkill hypridle && notify-send 'Hypridle deactivated' || hypridle"))
hl.bind(mainMod .. " + C", hl.dsp.exec_cmd("hyprpicker -a"))
hl.bind(mainMod .. " + V", hl.dsp.exec_cmd("cursor-clip"))
hl.bind(secondMod .. " + S", function()
	hl.dispatch(hl.dsp.exec_cmd("spotify"))
	hl.dispatch(hl.dsp.exec_cmd("kitty -e cava"))
end)

hl.bind(mainMod .. " + N", hl.dsp.exec_cmd("qs ipc call notifications toggle"))

--Nav functions
hl.bind(mainMod .. " + F", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + P + W", hl.dsp.window.pseudo())
hl.bind(secondMod .. " + M", hl.dsp.layout("togglesplit"))    -- dwindle only
hl.bind(secondMod .. " + BACKSPACE", hl.dsp.window.close())
hl.bind(mainMod .. " + M", hl.dsp.window.fullscreen({mode=fullscreen, action=toggle}))   

-- Move focus
hl.bind(mainMod .. " + J",  hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + L", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + I",    hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + K",  hl.dsp.focus({ direction = "down" }))

-- Swap position
hl.bind(secondMod .. " + J",  hl.dsp.window.swap({ direction = "left" }))
hl.bind(secondMod .. " + L", hl.dsp.window.swap({ direction = "right" }))
hl.bind(secondMod .. " + I",    hl.dsp.window.swap({ direction = "up" }))
hl.bind(secondMod .. " + K",  hl.dsp.window.swap({ direction = "down" }))

-- Switch workspaces with mainMod + [0-9]
-- Move active window to a workspace with mainMod + SHIFT + [0-9]
for i = 1, 10 do
    local key = i % 10 -- 10 maps to key 0
    hl.bind(mainMod .. " + " .. key,             hl.dsp.focus({ workspace = i}))
    hl.bind(secondMod .. " + " .. key,     hl.dsp.window.move({ workspace = i }))
end

-- Example special workspace (scratchpad)
hl.bind(mainMod .. " + Z",         hl.dsp.workspace.toggle_special("magic"))
hl.bind(secondMod .. " + Z", hl.dsp.window.move({ workspace = "special:magic" }))

--Focus mode

hl.bind(mainMod .. " + G", function()
    if gaps_on then
        hl.config({
            ["general.gaps_in"]  = 0,
            ["general.gaps_out"] = 0,
            ["animations.enabled"]   = false,
        })
    else
        hl.config({
            ["general.gaps_in"]  = saved_in,
            ["general.gaps_out"] = saved_out,
            ["animations.enabled"]   = true,            
        })
    end
    gaps_on = not gaps_on
end, { description = "Toggle window gaps" })


-- Scroll through existing workspaces 
hl.bind(mainMod .. " + O", hl.dsp.focus({ workspace = "r+1" }))
hl.bind(mainMod .. " + U",   hl.dsp.focus({ workspace = "r-1" }))

-- Move through existing workspaces 
hl.bind(secondMod .. " + O", hl.dsp.window.move({ workspace = "r+1" }))
hl.bind(secondMod .. " + U",   hl.dsp.window.move({ workspace = "r-1" }))

-- Move/resize windows with mainMod + LMB/RMB and dragging
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(secondMod .. " + mouse:272", hl.dsp.window.resize(), { mouse = true })

-- Laptop multimedia keys for volume and LCD brightness
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      { locked = true, repeating = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     { locked = true, repeating = true })
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp",  hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"),                  { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown",hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"),                  { locked = true, repeating = true })

-- Requires playerctl
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })



