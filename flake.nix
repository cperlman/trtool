{
  # Understanding this file: https://jameswillia.ms/posts/flake-line-by-line.html
  # Heavily inspired by: https://github.com/NixOS/nixpkgs/blob/nixos-24.05/pkgs/tools/security/yubikey-agent/default.nix

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/249fbde2a178a2ea2638b65b9ecebd531b338cf9";  # 24.05

  outputs = { self, nixpkgs }:
    let
      supportedSystems = [ "aarch64-darwin" "aarch64-linux" "i686-linux" "x86_64-darwin" "x86_64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
    in {
      packages = forAllSystems (system:
        let
          pkgs = nixpkgs.legacyPackages."${system}";
          outputHashes = {
            aarch64-darwin = "0b3772ee628b99a9c6d4f2767b50c941a3cf52992a9acf7000a6c1669750fd80";
            aarch64-linux = nixpkgs.lib.fakeHash;  # not built yet
            i686-linux = nixpkgs.lib.fakeHash;  # not built yet
            x86_64-darwin = "nixpkgs.lib.fakeHash";  # not built yet
            x86_64-linux = "900c4c5545c6e401bc0ea90ec8310094e2d320b7498c3cba9dd8f1ea633a5174";
          };
          expectedOutputHash = outputHashes."${system}";
        in {
          tuf = with pkgs; buildGoModule {
            name = "trtool";
            src = ./.;
            ldflags = [ "-s" "-w" ];
            subPackages = [ "cmd/trtool" ];
            vendorHash = "sha256-28QwhwUVJpUiO3dOuvgCNsUPwgVwzBUf46xfM1XcCmE=";
            buildInputs = lib.optional stdenv.isLinux (lib.getDev pcsclite)
              ++ lib.optional stdenv.isDarwin (darwin.apple_sdk.frameworks.PCSC);
            nativeBuildInputs = lib.optionals stdenv.isLinux [ pkg-config ];
            doCheck = false;  # don't run the unit test to save time
            postFixup = ''
              echo 'testing reproducibility (expected: sha256sum $out/bin/trtool: ${expectedOutputHash})'
              test "$(cat $out/bin/trtool | sha256sum)" = '${expectedOutputHash}  -'
            '';
          };
        });
    };
}
