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
            aarch64-darwin = "73d9bcb835d8f9ce891422d6f354cc4a0c8e6286e2fdf404169a9051e0909adf";
            aarch64-linux = nixpkgs.lib.fakeHash;  # not built yet
            i686-linux = nixpkgs.lib.fakeHash;  # not built yet
            x86_64-darwin = "nixpkgs.lib.fakeHash";  # not built yet
            x86_64-linux = "5cb5aba4e83b77ea1f969aa7bcd6d2e04509485ba4fb76e7ae4895daa7cf7527";
          };
          expectedOutputHash = outputHashes."${system}";
        in {
          trtool = with pkgs; buildGoModule {
            name = "trtool";
            src = ./.;
            ldflags = [ "-s" "-w" ];
            subPackages = [ "cmd/trtool" ];
            vendorHash = "sha256-Hqx2hrdc7mDub2MPFJtcZV8Z7PX5foMN5mgq5NFBN7E=";
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

