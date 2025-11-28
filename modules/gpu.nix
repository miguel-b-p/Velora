{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.velora;
in
{
  options.velora = {
    gpu = mkOption {
      type = types.nullOr (
        types.enum [
          "amd"
          "nvidia"
        ]
      );
      default = null;
      description = "Ativa configurações otimizadas para GPU (AMD/NVIDIA).";
    };
  };

  config = mkMerge [
    (mkIf (cfg.gpu == "nvidia") {
      boot.kernelParams = [
        "nvidia.NVreg_UsePageAttributeTable=1"
        "nvidia.NVreg_InitializeSystemMemoryAllocations=0"
        "nvidia.NVreg_DynamicPowerManagement=0x02"
      ];
    })
    (mkIf (cfg.gpu == "amd") {
      boot.kernelParams = [
        "amdgpu.ppfeaturemask=0xffffffff"
      ];
      environment.sessionVariables = {
        MESA_SHADER_CACHE_MAX_SIZE = "12G";
        AMD_VULKAN_ICD = "RADV";
      };
    })
  ];
}
