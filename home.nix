
{ config, pkgs, lib,  ... }:

{
  home.username = "jorvik";
  home.homeDirectory = "/home/jorvik";
  home.stateVersion = "26.05";
  
#GIT SETTINGS

  programs.git = {
    enable = true;
    settings.user = {
      name  = "Jorvik-H";
      email = "jorvik.halgensboeurgner@gmail.com";
    };
  };

#KEEP APPS FROM MAKING CAPITALIZED DIRETORIES IN HOME

  xdg.userDirs = {
    enable = true;
    createDirectories = true;
    desktop     = "${config.home.homeDirectory}/downloads";
    documents   = "${config.home.homeDirectory}/downloads";
    download    = "${config.home.homeDirectory}/downloads";
    music       = "${config.home.homeDirectory}/downloads";
    pictures    = "${config.home.homeDirectory}/downloads";
    publicShare = "${config.home.homeDirectory}/downloads";
    templates   = "${config.home.homeDirectory}/downloads";
    videos      = "${config.home.homeDirectory}/downloads";
    projects    = "${config.home.homeDirectory}/downloads";
  };

  xdg.configFile."user-dirs.conf".text = "enabled=False";
  
#DOTFILES 

  home.file.".config/yazi" = {
    source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nixos-dotfiles/config/yazi";
    recursive = true; 
  };

  home.file.".bashrc".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nixos-dotfiles/config/.bashrc";

  home.file.".config/mako" = {
    source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nixos-dotfiles/config/mako";
    recursive = true; 
  };

  home.file.".config/nvim" = {
    source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nixos-dotfiles/config/nvim";
    recursive = true; 
  };
  
  home.file.".config/hypr" = {
    source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nixos-dotfiles/config/hypr";
    recursive = true; 
  };
  
  home.file.".icons/Vimix-hypr" = {
    source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nixos-dotfiles/icons/cursor/Vimix-hypr";
    recursive = true; 
  };

  home.file.".config/waybar" = {
    source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nixos-dotfiles/config/waybar";
    recursive = true; 
  };

  home.file.".config/kitty" = {
    source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nixos-dotfiles/config/kitty";
    recursive = true; 
  };
  
  home.file.".config/rofi" = {
    source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nixos-dotfiles/config/rofi";
    recursive = true; 
  };
  
  home.file.".themes" = {
    source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nixos-dotfiles/config/.themes";
    recursive = true; 
  };
}
