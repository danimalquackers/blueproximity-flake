# BlueProximity Nix Flake

A declarative Nix flake for [BlueProximity](https://github.com/tiktaalik-dev/blueproximity), a tool that locks and unlocks your desktop based on the presence of a Bluetooth device (like your phone).

## Features

- **Declarative Configuration**: Manage your BlueProximity setup entirely within your NixOS or Home Manager configuration.
- **Service Management**: Automatically runs as a user systemd service.
- **Multiple Profiles**: Support for multiple device profiles with individual settings.

## Installation

Add this flake to your `flake.nix` inputs:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    blueproximity.url = "git+https://github.com/danimalquackers/blueproximity"; # Adjust URL as needed
  };

  outputs = { self, nixpkgs, blueproximity, ... }: {
    # Your configuration...

    home-manager.sharedModules = [
      inputs.blueproximity.homeModules.blueproximity
    ];

    # ...
  };
}
```

## Usage (Home Manager)

This flake provides a Home Manager module to easily configure the service.

### Enable the Module

Add a device to your Home Manager configuration:

```nix
services.blueproximity = {
  enable = true;

  profiles.my-phone = {
    address = "XX:XX:XX:XX:XX:XX";
    lockDistance = 10;
    unlockDistance = 5;
    # See Configuration section for more options
  };
};
```

## Configuration Options

The following options are available under `services.blueproximity.profiles.<name>`:

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `address` | string | | **Required**. The Bluetooth MAC address of the device. |
| `channel` | int | `7` | The Bluetooth channel to connect to. |
| `lockCommand` | string | `loginctl lock-session` | Command to run when device is out of range. |
| `unlockCommand` | string | `loginctl unlock-session` | Command to run when device is in range. |
| `lockDistance` | int | `10` | Maximum distance (approximate) before locking. |
| `lockDuration` | int | `5` | Seconds out of range before locking. |
| `unlockDistance` | int | `5` | Minimum distance (approximate) before unlocking. |
| `unlockDuration` | int | `3` | Seconds in range before unlocking. |
| `proximityCommand` | string | `xset dpms force on` | Command to run when device is in range. |
| `proximityInterval` | int | `60` | Interval in seconds between distance checks. |
| `syslogFacility` | string | `local7` | The syslog facility to use. |
| `logFile` | string | `null` | Optional path to a log file. |

## Known Issues

### UI Visibility Issues

There is a known issue where the BlueProximity GTK interface **does not open**, even when clicking the AppIndicator icon in the system tray. 

The daemon still runs in the background and processes lock/unlock events based on your configuration, but manual interaction via the GUI is currently unreliable or non-functional. Configuration should be managed primarily via the Nix module options.
