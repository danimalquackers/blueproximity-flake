{
  pkgs ? import <nixpkgs> { },
}:
with pkgs;

mkShell {
  buildInputs = [
    # Nix LSP
    nil
  ];
}
