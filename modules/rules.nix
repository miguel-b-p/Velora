{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.velora;

  # Normaliza cfg.rules para sempre retornar um atributo set
  # Se for true, ativa todas as opções. Se for false, desativa todas.
  # Se for um set, usa os valores específicos.
  rulesCfg =
    if isBool cfg.rules then
      {
        enable = cfg.rules;
        cpu-dma-latency = cfg.rules;
        hdparm = cfg.rules;
        ioschedulers = cfg.rules;
        sata = cfg.rules;
        hpet-permissions = cfg.rules;
        audio-pm = cfg.rules;
      }
    else
      cfg.rules;
in
{
  # Opções para custom-rules
  options.velora = {
    rules = mkOption {
      type = types.either types.bool (
        types.submodule {
          options = {
            enable = mkOption {
              type = types.bool;
              default = false;
              description = "Ativa todas as regras customizadas de udev ou permissões.";
            };
            cpu-dma-latency = mkOption {
              type = types.bool;
              default = false;
              description = "Ativa regras para latência de CPU DMA.";
            };

            hdparm = mkOption {
              type = types.bool;
              default = false;
              description = "Ativa regras hdparm para otimização de disco.";
            };

            ioschedulers = mkOption {
              type = types.bool;
              default = false;
              description = "Ativa regras para agendadores de I/O.";
            };

            sata = mkOption {
              type = types.bool;
              default = false;
              description = "Ativa regras para dispositivos SATA.";
            };

            hpet-permissions = mkOption {
              type = types.bool;
              default = false;
              description = "Ativa permissões para HPET.";
            };

            audio-pm = mkOption {
              type = types.bool;
              default = false;
              description = "Ativa regras para power management de áudio.";
            };
          };
        }
      );
      default = false;
      description = ''
        Regras customizadas de udev e permissões.

        Pode ser usado de duas formas:
        1. Boolean simples: `velora.rules = true;` (ativa todas as regras)
        2. Granular: `velora.rules.cpu-dma-latency = true;` (ativa apenas regras específicas)
      '';
    };
  };

  # Implementação das custom-rules
  config = mkMerge [
    {
      # Regras udev individuais
      services.udev.extraRules = ''
        ${optionalString (rulesCfg.enable || rulesCfg.cpu-dma-latency) ''
          DEVPATH=="/devices/virtual/misc/cpu_dma_latency", OWNER="root", GROUP="audio", MODE="0660"
        ''}

        ${optionalString (rulesCfg.enable || rulesCfg.hdparm) ''
          ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="1", \
          ATTRS{id/bus}=="ata", RUN+="${pkgs.hdparm}/bin/hdparm -B 254 -S 0 /dev/%k"
        ''}

        ${optionalString (rulesCfg.enable || rulesCfg.ioschedulers) ''
          # HDD
          ACTION=="add|change", KERNEL=="sd[a-z]*", ATTR{queue/rotational}=="1", \
              ATTR{queue/scheduler}="bfq"

          # SSD
          ACTION=="add|change", KERNEL=="sd[a-z]*|mmcblk[0-9]*", ATTR{queue/rotational}=="0", \
              ATTR{queue/scheduler}="mq-deadline"

          # NVMe SSD
          ACTION=="add|change", KERNEL=="nvme[0-9]*", ATTR{queue/rotational}=="0", \
              ATTR{queue/scheduler}="none"
        ''}

        ${optionalString (rulesCfg.enable || rulesCfg.sata) ''
          # SATA Active Link Power Management
          ACTION=="add", SUBSYSTEM=="scsi_host", KERNEL=="host*", \
          ATTR{link_power_management_policy}=="*", \
          ATTR{link_power_management_policy}="max_performance"
        ''}

        ${optionalString (rulesCfg.enable || rulesCfg.hpet-permissions) ''
          # HPET permissions
          KERNEL=="rtc0", GROUP="audio"
          KERNEL=="hpet", GROUP="audio"
        ''}

        ${optionalString (rulesCfg.enable || rulesCfg.audio-pm) ''
          # Audio power management
          ACTION=="add", SUBSYSTEM=="sound", KERNEL=="card*", DRIVERS=="snd_hda_intel", TEST!="/run/udev/snd-hda-intel-powersave", \
              RUN+="${pkgs.bash}/bin/bash -c 'touch /run/udev/snd-hda-intel-powersave; \
                  [[ $$(cat /sys/class/power_supply/BAT0/status 2>/dev/null) != \"Discharging\" ]] && \
                  echo $$(cat /sys/module/snd_hda_intel/parameters/power_save) > /run/udev/snd-hda-intel-powersave && \
                  echo 0 > /sys/module/snd_hda_intel/parameters/power_save'"

            SUBSYSTEM=="power_supply", ENV{POWER_SUPPLY_ONLINE}=="0", TEST=="/sys/module/snd_hda_intel", \
              RUN+="${pkgs.bash}/bin/bash -c 'echo $$(cat /run/udev/snd-hda-intel-powersave 2>/dev/null || \
                  echo 10) > /sys/module/snd_hda_intel/parameters/power_save'"

            SUBSYSTEM=="power_supply", ENV{POWER_SUPPLY_ONLINE}=="1", TEST=="/sys/module/snd_hda_intel", \
              RUN+="${pkgs.bash}/bin/bash -c '[[ $$(cat /sys/module/snd_hda_intel/parameters/power_save) != 0 ]] && \
                  echo $$(cat /sys/module/snd_hda_intel/parameters/power_save) > /run/udev/snd-hda-intel-powersave; \
                  echo 0 > /sys/module/snd_hda_intel/parameters/power_save'"
        ''}

        SUBSYSTEM=="input", MODE="0660", GROUP="input"
        SUBSYSTEM=="usb", ATTRS{idVendor}=="*", ATTRS{idProduct}=="*", MODE="0660", GROUP="input"
      '';
    }
  ];
}
