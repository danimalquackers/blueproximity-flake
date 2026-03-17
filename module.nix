{ self }:
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.services.blueproximity;
in
{

  options.services.blueproximity = {
    enable = mkEnableOption "BlueProximity service";

    package = mkOption {
      type = types.package;
      default = self.packages.${pkgs.system}.default;
      description = "The BlueProximity package to use.";
    };

    profiles = mkOption {
      type = types.attrsOf (
        types.submodule {
          options = {
            address = mkOption {
              type = types.str;
              description = "The Bluetooth address of the device to monitor.";
            };

            channel = mkOption {
              type = types.int;
              default = 7;
              description = "The Bluetooth channel to connect to the device on.";
            };

            lockCommand = mkOption {
              type = types.str;
              default = "loginctl lock-session";
              description = "Command to execute when the device goes out of range.";
            };

            unlockCommand = mkOption {
              type = types.str;
              default = "loginctl unlock-session";
              description = "Command to execute when the device comes in range.";
            };

            lockDistance = mkOption {
              type = types.int;
              default = 10;
              description = "The maximum distance in meters.";
            };

            lockDuration = mkOption {
              type = types.int;
              default = 5;
              description = "The duration in seconds for the device to be out of range before locking.";
            };

            unlockDistance = mkOption {
              type = types.int;
              default = 5;
              description = "The minimum distance in meters.";
            };

            unlockDuration = mkOption {
              type = types.int;
              default = 3;
              description = "The duration in seconds for the device to be in range before unlocking.";
            };

            proximityCommand = mkOption {
              type = types.str;
              default = "xset dpms force on";
              description = "Command to execute when the device is in range.";
            };

            proximityInterval = mkOption {
              type = types.int;
              default = 60;
              description = "The interval in seconds between distance checks.";
            };

            bufferSize = mkOption {
              type = types.int;
              default = 1;
              description = "The number of samples to average for the device distance.";
            };

            syslogFacility = mkOption {
              type = types.str;
              default = "local7";
              description = "The syslog facility to use.";
            };

            logFile = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = "The file to log to.";
            };
          };
        }
      );
      default = [ ];
      description = "Bluetooth device profiles.";
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    systemd.user.services.blueproximity = {
      Unit = {
        Description = "BlueProximity daemon";
        After = [
          "network.target"
          "bluetooth.target"
        ];
      };

      Service = {
        Environment = [
          "GDK_BACKEND=x11"
        ];
        ExecStart = "${cfg.package}/bin/blueproximity";
        ExecStartPre =
          let
            logDirs = lib.mapAttrsToList (name: profile: dirOf profile.logFile) cfg.profiles;
          in
          map (logDir: "${pkgs.coreutils}/bin/mkdir -p ${logDir}") (lists.unique logDirs);
        Restart = "on-failure";
      };

      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
    };

    home.file = lib.mapAttrs' (
      name: profile:
      nameValuePair ".blueproximity/${name}.conf" {
        text = generators.toINIWithGlobalSection { } {
          globalSection = {
            device_mac = profile.address;
            device_channel = profile.channel;

            # Lock
            lock_distance = profile.lockDistance;
            lock_duration = profile.lockDuration;
            lock_command = profile.lockCommand;

            # Unlock
            unlock_distance = profile.unlockDistance;
            unlock_duration = profile.unlockDuration;
            unlock_command = profile.unlockCommand;

            # Keep-awake
            proximity_command = profile.proximityCommand;
            proximity_interval = profile.proximityInterval;

            # Ringbuffer for approximating distance
            buffer_size = profile.bufferSize;

            # Logging
            log_to_syslog = profile.syslogFacility != null;
            log_syslog_facility = lib.optionalString (profile.syslogFacility != null) profile.syslogFacility;
            log_to_file = profile.logFile != null;
            log_filelog_filename = lib.optionalString (profile.logFile != null) profile.logFile;
          };
        };
      }
    ) cfg.profiles;
  };
}
