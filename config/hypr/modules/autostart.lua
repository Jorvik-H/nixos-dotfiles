-------------------
---- AUTOSTART ----
-------------------

hl.on("hyprland.start", function()
	hl.exec_cmd("qs")
	hl.exec_cmd("systemctl --usr start hyprpolkitagent")
	hl.exec_cmd("awww-daemon")
	hl.exec_cmd("awww img ~/nixos-dotfiles/icons/wallpaper/wallpaper5.jpg")
	hl.exec_cmd("hypridle")
	hl.exec_cmd("cursor-clip --daemon")
	hl.exec_cmd("hyprsunset --temperature 6200")
end)
