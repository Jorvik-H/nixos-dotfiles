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
  programs.xwayland.enable = true;

  services.displayManager.ly = {
    enable = true;
    settings = {
      session_log = "/dev/null";
    };
  };

  services.printing.enable = true;
  
  services.blueman.enable = true;

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };

  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
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
    kitty
    quickshell

    #shit ima never think abt
    libnotify
    pipewire
    openssh
    ffmpeg
    bluez
    brightnessctl
    upower

    #settings type shit
    hyprsunset
    nwg-look
    nwg-displays
    pavucontrol
    impala
    blueman
    networkmanagerapplet

    #regular ass aplications
    neovim
    yazi
    librewolf
    vesktop
    htop
    ferdium
    musescore
    gimp
    libreoffice
    prismlauncher
    obsidian
    chromium

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
    cbonsai
    mpv


  ];

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  system.stateVersion = "26.05"; 


  nixpkgs.config.allowUnfree = true;
}

