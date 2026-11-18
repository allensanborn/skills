{
  description = "Dev shell for allensanborn/skills: the tools behind ci/check.sh and the release checks";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs = { nixpkgs, ... }:
    let
      systems = [ "aarch64-darwin" "x86_64-darwin" "aarch64-linux" "x86_64-linux" ];
      forAll = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
    in
    {
      # Dagger isn't in nixpkgs; install the version ci.yml pins (0.21.11) separately.
      devShells = forAll (pkgs: {
        default = pkgs.mkShell {
          packages = with pkgs; [
            nodejs_22 # ci/check.sh, npm test, changesets
            gh
            jq
            actionlint
            markdownlint-cli2
            vale
            gitleaks
            zizmor
            slsa-verifier # SECURITY.md, verifying a release
          ];
        };
      });
    };
}
