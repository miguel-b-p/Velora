# Velora

![Velora Logo](./logo.png)

**Velora** is a collection of high-performance optimization modules for NixOS, designed to maximize hardware performance. It provides a modular and flexible framework for applying kernel configurations, GPU optimizations, custom udev rules, and performance-oriented services.

## Installation

Add Velora to your `flake.nix` inputs:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    velora.url = "github:yourusername/velora"; # Replace with actual URL or path
  };

  outputs = { self, nixpkgs, velora, ... }: {
    nixosConfigurations.mySystem = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        velora.nixosModules.default
        ./configuration.nix
      ];
    };
  };
}
```

## Configuration

Velora modules are designed with flexibility in mind. You can enable an entire category of optimizations with a single flag, or pick and choose specific features.

### General Pattern

For most modules, you have two ways to configure them:

1.  **Enable All**: Activates all features within the module.
    ```nix
    velora.moduleName = true;
    ```
2.  **Granular Control**: Activate only specific features.
    ```nix
    velora.moduleName = {
      featureA = true;
      featureB = false;
    };
    ```

---

## Modules

### 1. Kernel Optimizations (`velora.kernel`)

Tweak the Linux kernel for low latency and high throughput.

| Option | Description |
| :--- | :--- |
| `enable` | Enables all kernel optimizations. |
| `params` | Applies boot parameters (e.g. `preempt=full`). |
| `sysctl` | Applies runtime sysctl tweaks (networking, VM, scheduler). |
| `transparent_hugepage` | Optimizes THP settings (always enabled, defer+madvise). |

**Example:**
```nix
velora.kernel = {
  params = true;
  sysctl = true;
};
```

### 2. GPU Optimizations (`velora.gpu`)

Apply specific optimizations for your GPU vendor.

| Option | Description |
| :--- | :--- |
| `amd` | Optimizations for AMD GPUs (CoreCtrl, MESA cache, etc.). |
| `nvidia` | Optimizations for NVIDIA GPUs (Power management, PAT). |

**Example:**
```nix
velora.gpu = "amd"; # or "nvidia"
```

### 3. System Rules (`velora.rules`)

Custom udev rules and permissions for hardware access.

| Option | Description |
| :--- | :--- |
| `enable` | Enables all rules. |
| `cpu-dma-latency` | Permissions for `/dev/cpu_dma_latency`. |
| `hdparm` | Disk power management rules. |
| `ioschedulers` | Optimal I/O schedulers for SSD/NVMe/HDD. |
| `sata` | SATA Active Link Power Management. |
| `hpet-permissions` | Permissions for HPET and RTC. |
| `audio-pm` | Intel HDA power saving rules. |

**Example:**
```nix
velora.rules = {
  ioschedulers = true;
  audio-pm = true;
};
```

### 4. Performance Programs (`velora.programs`)

Services and daemons that actively manage system performance.

| Option | Description |
| :--- | :--- |
| `enable` | Enables all programs. |
| `ananicy` | `ananicy-cpp` with `cachyos` rules for process priority. |
| `scx` | `sched-ext` with `scx_lavd` scheduler (requires compatible kernel). |
| `preload` | Adaptive readahead daemon. |
| `irqbalance` | Distribute hardware interrupts across CPUs. |
| `earlyoom` | Early OOM killer to prevent system freezes. |

**Example:**
```nix
velora.programs = {
  ananicy = true;
  earlyoom = true;
};
```

---

## Full Example Configuration

Here is how a complete configuration might look in your `configuration.nix`:

```nix
{ config, pkgs, ... }:

{
  # Enable Velora modules
  velora = {
    # Kernel: Enable everything for maximum performance
    kernel = true;

    # GPU: Set to your specific vendor
    gpu = "amd";

    # Rules: Enable specific hardware tweaks
    rules = {
      ioschedulers = true;
      hpet-permissions = true;
    };

    # Programs: Enable active optimization services
    programs = {
      ananicy = true;
      irqbalance = true;
      earlyoom = true;
    };
  };
}
```
