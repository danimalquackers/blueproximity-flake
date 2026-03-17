{
  description = "A declarative Nix flake for BlueProximity";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
      in
      {
        packages.default = pkgs.python3Packages.buildPythonApplication rec {
          pname = "blueproximity";
          version = "1.3.3";

          src = pkgs.fetchFromGitHub {
            owner = "tiktaalik-dev";
            repo = "blueproximity";
            rev = "v${version}";
            sha256 = "sha256-QTrJJgtgI5c2bUub6G9o+ujHvqgCqYG1+pvvnjcsvMU=";
          };

          patches = [
            ./patches/fix-gobject.patch
            ./patches/fix-config.patch
          ];

          nativeBuildInputs = with pkgs; [
            gobject-introspection
            libappindicator-gtk3
            wrapGAppsHook3
          ];

          propagatedBuildInputs =
            with pkgs.python3Packages;
            [
              configobj
              pygobject3
              pybluez
              python-xapp
            ]
            ++ (with pkgs; [
              bluez
              gtk3
              libnotify
            ]);

          pyproject = false;

          installPhase = ''
            mkdir -p $out/bin
            cp proximity.py $out/bin/blueproximity
            chmod +x $out/bin/blueproximity

            sed -i "s|dist_path = './'|dist_path = '$out/share/blueproximity/'|" $out/bin/blueproximity

            mkdir -p $out/share/blueproximity
            cp -r addons LANG proximity3.glade *.svg $out/share/blueproximity/

            install -Dm644 addons/blueproximity.desktop $out/share/applications/blueproximity.desktop
            install -Dm644 addons/blueproximity.xpm $out/share/pixmaps/blueproximity.xpm

            substituteInPlace $out/share/applications/blueproximity.desktop \
              --replace "/usr/bin/blueproximity" "$out/bin/blueproximity" \
              --replace "/usr/share/pixmaps/blueproximity.xpm" "$out/share/pixmaps/blueproximity.xpm"
          '';

          meta = with pkgs.lib; {
            description = "Locks/unlocks your desktop tracking a bluetooth device";
            homepage = "https://github.com/tiktaalik-dev/blueproximity";
            license = licenses.gpl2;
            maintainers = [ ];
            platforms = platforms.linux;
          };
        };
        packages.blueproximity = self.packages.${system}.default;
      }
    )
    // {
      homeModules.blueproximity = import ./module.nix { inherit self; };
    };
}
