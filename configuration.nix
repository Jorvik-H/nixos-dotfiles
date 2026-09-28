{ config, lib, pkgs, ... }:

{
  imports =
    [ 
      /etc/nixos/hardware-configuration.nix
    ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "HP-OfficeJet-Pro-1869"; 
  networking.networkmanager.enable = true;

  time.timeZone = "America/Edmonton";
 
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;  
  };

  services.displayManager.ly.enable = true;

  services.printing.enable = true;
  
  services.udisks2.enable = true;

  services.pipewire = {
    enable = true;
    pulse.enable = true;
  };

  services.libinput.enable = true;

  users.users.jorvik = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networking" ]; 
    packages = with pkgs; [
      
    ];
  }; 

  environment.systemPackages = with pkgs; [
    #window manager shit
    awww
    hyprlock
    hypridle
    hyprcursor
    hyprpolkitagent
    waybar
    mako
    rofi
    kitty

    #shit ima never think abt
    libnotify
    pipewire
    openssh
    ffmpeg
    bluez
    udiskie
    udisks2
    nemo

    #settings type shit
    hyprsunset
    nwg-look
    nwg-displays
    pavucontrol
    impala
    blueman

    #regular ass aplications
    neovim
    yazi
    librewolf
    vesktop
    htop
    ferdium
    spotify
    musescore
    gimp
    libreoffice
    prismlauncher
    obsidian
    
    #command line utilities
    fastfetch
    eza
    cowsay
    fortune
    hyprpicker
    tree
    wl-clipboard
    cursor-clip
    p7zip
    cava
    tty-clock
    mpv


  ];

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  system.stateVersion = "26.05"; 


  nixpkgs.config.allowUnfree = true;
}

