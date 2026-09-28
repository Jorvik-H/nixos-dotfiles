
{ config, pkgs, ... }:

{
  home.username = "jorvik";
  home.homeDirectory = "/home/jorvik";
  home.stateVersion = "26.05";
  
  services.udiskie = {
      enable = true;
      settings = {
          program_options = {
              file_manager = "${pkgs.nemo-with-extensions}/bin/nemo";
          };
      };
  };

    programs.git = {
    enable = true;
    settings.user = {
      name  = "Jorvik-H";
      email = "jorvik.halgensboeurgner@gmail.com";
    };
  };



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
