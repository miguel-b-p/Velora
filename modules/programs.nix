{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.velora;

  # Normaliza cfg.programs para sempre retornar um atributo set
  # Se for true, ativa todas as opções. Se for false, desativa todas.
  # Se for um set, usa os valores específicos.
  programsCfg =
    if isBool cfg.programs then
      {
        enable = cfg.programs;
        ananicy = cfg.programs;
        scx = cfg.programs;
        preload = cfg.programs;
        irqbalance = cfg.programs;
        earlyoom = cfg.programs;
      }
    else
      cfg.programs;
in
{
  options.velora = {
    programs = mkOption {
      type = types.either types.bool (
        types.submodule {
          options = {
            enable = mkOption {
              type = types.bool;
              default = false;
              description = "Ativa todos os programas de otimização.";
            };
            ananicy = mkOption {
              type = types.bool;
              default = false;
              description = "Ativa ananicy-cpp com regras cachyos.";
            };
            scx = mkOption {
              type = types.bool;
              default = false;
              description = "Ativa sched-ext (scx) com scheduler lavd.";
            };
            preload = mkOption {
              type = types.bool;
              default = false;
              description = "Ativa preload daemon.";
            };
            irqbalance = mkOption {
              type = types.bool;
              default = false;
              description = "Ativa irqbalance.";
            };
            earlyoom = mkOption {
              type = types.bool;
              default = false;
              description = "Ativa earlyoom.";
            };
          };
        }
      );
      default = false;
      description = ''
        Programas de otimização de sistema.

        Pode ser usado de duas formas:
        1. Boolean simples: `velora.programs = true;` (ativa todos)
        2. Granular: `velora.programs.ananicy = true;` (ativa apenas ananicy)
      '';
    };
  };

  config = mkMerge [
    (mkIf (programsCfg.enable || programsCfg.ananicy) {
      services.ananicy = {
        enable = true;
        package = pkgs.ananicy-cpp;
        rulesProvider = pkgs.ananicy-rules-cachyos;
      };
    })

    (mkIf (programsCfg.enable || programsCfg.scx) {
      services.scx = {
        enable = true;
        # scx existe no nixpkg
        # package = pkgs.scx_git.full;
        scheduler = "scx_lavd";
        extraArgs = [ "--performance" ];
      };
    })

    (mkIf (programsCfg.enable || programsCfg.preload) {
      services.preload.enable = true;
    })

    (mkIf (programsCfg.enable || programsCfg.irqbalance) {
      services.irqbalance.enable = true;
    })

    (mkIf (programsCfg.enable || programsCfg.earlyoom) {
      services.earlyoom = {
        enable = true;
        freeSwapThreshold = 2;
        freeMemThreshold = 2;
        extraArgs = [
          "-g"
          "--avoid"
          "'^(packagekitd|gnome-shell|gnome-session-c|gnome-session-b|lightdm|sddm|sddm-helper|gdm|gdm-wayland-ses|gdm-session-wor|gdm-x-session|Xorg|Xwayland|systemd|systemd-logind|dbus-daemon|dbus-broker|cinnamon|cinnamon-sessio|kwin_x11|kwin_wayland|plasmashell|ksmserver|plasma_session|startplasma-way|sway|i3|xfce4-session|mate-session|marco|lxqt-session|openbox|cryptsetup)$'"
        ];
      };
    })
  ];
}
