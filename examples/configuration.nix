{ pkgs, ... }:
{
  # Exemplo usando kernel = true (ativa TUDO)
  velora.kernel = true;

  # Você também pode usar:
  # velora.kernel = {
  #   params = true;
  #   sysctl = true;
  #   transparent_hugepage = true;
  # };

  velora.gpu = "amd";
  velora.rules = {
    cpu-dma-latency = true;
    hdparm = true;
    ioschedulers = true;
    sata = true;
    hpet-permissions = true;
    audio-pm = true;
  };
  velora.programs = true;

  # Minimum configuration to satisfy nix flake check
  fileSystems."/" = {
    device = "/dev/null";
    fsType = "ext4";
  };
  boot.loader.grub.devices = [ "nodev" ];
  system.stateVersion = "23.11";
}
