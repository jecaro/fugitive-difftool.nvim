{
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";

  outputs = { self, nixpkgs }:
    let
      supportedSystems = [ "x86_64-linux" "x86_64-darwin" ];

      forAllSystems = f: nixpkgs.lib.genAttrs supportedSystems (system: f system);

      nixpkgsFor = forAllSystems (system: import nixpkgs {
        inherit system;
        overlays = [ self.overlays.default ];
      });
    in
    {
      packages = forAllSystems
        (system:
          {
            default = nixpkgsFor.${system}.vimPlugins.fugitive-difftool-nvim;
          });

      overlays.default = final: prev:
        {
          vimPlugins = prev.vimPlugins // {
            fugitive-difftool-nvim =
              prev.vimUtils.buildVimPlugin {
                pname = "fugitive-difftool-nvim";
                version = "0.0.1";
                src = ./.;
              };
          };
        };
    };
}

