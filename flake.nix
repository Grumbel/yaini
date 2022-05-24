{
  description = "Yet another INI parser for C++";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-21.11";
    flake-utils.url = "github:numtide/flake-utils";

    tinycmmc.url = "gitlab:grumbel/cmake-modules";
    tinycmmc.inputs.nixpkgs.follows = "nixpkgs";
    tinycmmc.inputs.flake-utils.follows = "flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, tinycmmc }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        project_version_from_file = let
          version_file = pkgs.lib.fileContents ./VERSION;
          project_has_version = ((builtins.substring 0 1) version_file) == "v";
          project_version = if !project_has_version
                            then ("${nixpkgs.lib.substring 0 8 self.lastModifiedDate}-${self.shortRev or "dirty"}")
                            else (builtins.substring 1 ((builtins.stringLength version_file) - 2) version_file);
        in
          project_version;

      in rec {
        packages = flake-utils.lib.flattenTree {
          yaini = pkgs.stdenv.mkDerivation {
            pname = "yaini";
            version = project_version_from_file;
            src = ./.;
            postPatch = ''
              echo "v${project_version_from_file}" > VERSION
            '';
            cmakeFlags = [ "-DBUILD_TESTS=ON" ];
            doCheck = true;
            nativeBuildInputs = [
              pkgs.cmake
            ];
            buildInputs = [
              tinycmmc.defaultPackage.${system}

              pkgs.gtest
            ];
           };
        };
        defaultPackage = packages.yaini;
      });
}
