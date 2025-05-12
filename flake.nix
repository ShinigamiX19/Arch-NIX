{
  description = "Full Arch + Nix Dev Environment with KDE + GPU ML + Home Manager";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs-aur.url = "github:traxys/nixpkgs-aur";

    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nixpkgs-aur.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, home-manager, flake-utils, nixpkgs-aur, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };

        aurPkgs = import nixpkgs-aur { inherit pkgs system; };
      in {
        devShells = {
          default = pkgs.mkShell {
            packages = with pkgs; [
              gcc clang gnumake cmake
              nodejs yarn
              python3 openjdk maven
            ];
            shellHook = ''
              echo "Default Dev Shell Loaded"
            '';
          };

          pytorch = pkgs.mkShell {
            packages = with pkgs; [ pkgs.python3 venvShellHook ];
            shellHook = ''
              echo "Setting up PyTorch venv with CUDA support"
              python3 -m venv .venv
              source .venv/bin/activate
              pip install --upgrade pip
              pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128
              echo "PyTorch with CUDA is ready in .venv"
            '';
          };

          tensorflow = pkgs.mkShell {
            packages = with pkgs; [ pkgs.python3 venvShellHook ];
            shellHook = ''
              echo "Setting up TensorFlow venv with CUDA support"
              python3 -m venv .venv
              source .venv/bin/activate
              pip install --upgrade pip
              pip install tensorflow==2.19
              echo "TensorFlow with CUDA is ready in .venv"
            '';
          };
        };

        homeConfigurations.Leon = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [
            {
              home.stateVersion = "24.05";
              programs.home-manager.enable = true;
              programs.git.enable = true;
              programs.neovim.enable = true;
              programs.zsh.enable = true;

              home.packages = with pkgs; [
                gcc clang gnumake cmake
                openjdk maven
                nodejs yarn
                texliveFull
                docker
                nixfmt
                python3 wget curl unzip jq
                dotnet-sdk vscode
                bat exa btop dolphin konsole unzip zip
              ] ++ [
                aurPkgs.brave-bin
              ];

              xdg.configFile."Code/User/settings.json".text = builtins.toJSON {
                "editor.formatOnSave" = true;
                "python.venvPath" = "${builtins.getEnv "PWD"}/.venv";
                "python.defaultInterpreterPath" = "${builtins.getEnv "PWD"}/.venv/bin/python";
                "terminal.integrated.defaultProfile.linux" = "zsh";
                "workbench.startupEditor" = "newUntitledFile";
                "files.autoSave" = "onFocusChange";
              };

              programs.vscode.extensions = with pkgs.vscode-extensions; [
                ms-python.python
                ms-toolsai.jupyter
                ms-dotnettools.dotnet-interactive-vscode
                ms-vscode.cpptools
                ms-vscode.cmake-tools
                eamodio.gitlens
                esbenp.prettier-vscode
                ritwickdey.liveserver
                github.vscode-pull-request-github
                ms-azuretools.vscode-docker
                ms-dotnettools.vscode-dotnet-runtime
              ];

              services.gpg-agent.enable = true;
            }
          ];
          username = "Leon";
          homeDirectory = "/home/Leon";
        };
      });
}
