{ config, lib, pkgs, ... }:

{
  imports =
    [ 
      ./config/hardware-configuration.nix
    ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "HP-OfficeJet-Pro-1869"; 
  networking.networkmanager.enable = true;
  networking.firewall.enable = true;

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

  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };
  
  services.blueman.enable = true;

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };


   virtualisation.virtualbox.host.enable = true;
   users.extraGroups.vboxusers.members = [ "jorvik" ];

  


programs.steam = {
  enable = true;
};

services.logind.settings.Login = {
  HandleLidSwitch = "lock";
  HandleLidSwitchExternalPower = "lock";
  HandleLidSwitchDocked = "ignore";
};

services.thermald.enable = true;

services.tlp.enable = true;

  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  services.libinput.enable = true;

  programs.kdeconnect.enable = true;

  services.upower.enable = true;

  users.users.jorvik = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networking" ]; 
    packages = with pkgs; [
      
    ];
  }; 
  
  services.gvfs.enable = true;

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
    wine
    usbutils

    #settings type shit
    hyprsunset
    nwg-look
    nwg-displays
    pavucontrol
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
    stockfish
    chessx

    #command line utilities
    fastfetch
    eza
    cowsay
    fortune
    hyprpicker
    tree
    wl-clipboard
    cursor-clip
    hyprshot
    p7zip
    cava
    tty-clock
    cbonsai
    mpv
    _7zz
    unzip
    uchess
    feh
    zathura
  ];

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  system.stateVersion = "26.05"; 


  nixpkgs.config.allowUnfree = true;
}

