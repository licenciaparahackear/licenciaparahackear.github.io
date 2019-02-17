with import /home/criptonauta/nixpkgs {};

python3Packages.Nikola.overrideAttrs (oldAttrs: rec {
  # src = ./.;
  # patches = [];
  checkPhase = "";
  installCheckPhase = "";
  propagatedBuildInputs = [ghp-import] ++ oldAttrs.propagatedBuildInputs;
  shellHook = ''
    unset SOURCE_DATE_EPOCH
  '';
})
