{ isWSL, inputs, ... }:

{ config, lib, pkgs, ... }:

let
  sources = import ../../nix/sources.nix;
  isDarwin = pkgs.stdenv.isDarwin;
  isLinux = pkgs.stdenv.isLinux;

  shellAliases = {
    ga = "git add";
    gc = "git commit";
    gco = "git checkout";
    gcp = "git cherry-pick";
    gdiff = "git diff";
    gl = "git prettylog";
    gp = "git push";
    gs = "git status";
    gt = "git tag";

    jd = "jj desc";
    jf = "jj git fetch";
    jn = "jj new";
    jp = "jj git push";
    js = "jj st";

    wo = "cd ~/Developer/workspace";
  } // (if isLinux then {
    # Two decades of using a Mac has made this such a strong memory
    # that I'm just going to keep it consistent.
    pbcopy = "xclip";
    pbpaste = "xclip -o";
  } else {});

  # For our MANPAGER env var
  # https://github.com/sharkdp/bat/issues/1145
  manpager = (pkgs.writeShellScriptBin "manpager" (if isDarwin then ''
    sh -c 'col -bx | bat -l man -p'
    '' else ''
    cat "$1" | col -bx | bat --language man --style plain
  ''));
in {
  # Home-manager 22.11 requires this be set. We never set it so we have
  # to use the old state version.
  home.stateVersion = "18.09";

  xdg.enable = true;

  #---------------------------------------------------------------------
  # Packages
  #---------------------------------------------------------------------

  # Packages I always want installed. Most packages I install using
  # per-project flakes sourced with direnv and nix-shell, so this is
  # not a huge list.
  home.packages = [
    pkgs._1password-cli
    pkgs.asciinema
    pkgs.bat
    pkgs.eza
    pkgs.fd
    pkgs.fzf
    pkgs.gh
    pkgs.htop
    pkgs.chezmoi
    pkgs.jq
    pkgs.ripgrep
    pkgs.sentry-cli
    pkgs.tree
    pkgs.watch
    pkgs.starship

    pkgs.gopls
    pkgs.zigpkgs."0.14.0"

    # Node is required for Copilot.vim
    pkgs.nodejs
  ] ++ (lib.optionals isDarwin [
    # This is automatically setup on Linux
    pkgs.cachix
    pkgs.tailscale
  ]) ++ (lib.optionals (isLinux && !isWSL) [
    pkgs.chromium
    pkgs.firefox
    pkgs.rofi
    pkgs.valgrind
    pkgs.zathura
    pkgs.xfce.xfce4-terminal
  ]) ++ (lib.optionals isDarwin [
    # These are for me, chandy
    pkgs.nmap
    pkgs.awscli2
    pkgs.azure-cli
    pkgs.maven
    pkgs.pnpm_10
    pkgs.lsd
    pkgs.feh
    pkgs.doggo
    pkgs.mtr
    pkgs.rustscan
    pkgs.gdu
    pkgs.difftastic
    pkgs.lazygit
    pkgs.lazydocker
  ]);

  #---------------------------------------------------------------------
  # Env vars and dotfiles
  #---------------------------------------------------------------------

  home.sessionVariables = {
    LANG = "en_US.UTF-8";
    LC_CTYPE = "en_US.UTF-8";
    LC_ALL = "en_US.UTF-8";
    EDITOR = "nvim";
    PAGER = "less -FirSwX";
    MANPAGER = "${manpager}/bin/manpager";

    # OPENAI_API_KEY = "op://Private/OpenAPI_Personal/credential";
  } // (if isDarwin then {
    # See: https://github.com/NixOS/nixpkgs/issues/390751
    DISPLAY = "nixpkgs-390751";
  } else {});

  home.file = {
    ".gdbinit".source = ./gdbinit;
    ".inputrc".source = ./inputrc;
  };

  # xdg.configFile = {
  #   "i3/config".text = builtins.readFile ./i3;
  #   "jj/config.toml".source = ./jujutsu.toml;
  #   "rofi/config.rasi".text = builtins.readFile ./rofi;


    # tree-sitter parsers
    # "nvim/parser/proto.so".source = "${pkgs.tree-sitter-proto}/parser";
    # "nvim/queries/proto/folds.scm".source =
    #   "${sources.tree-sitter-proto}/queries/folds.scm";
    # "nvim/queries/proto/highlights.scm".source =
    #   "${sources.tree-sitter-proto}/queries/highlights.scm";
    # "nvim/queries/proto/textobjects.scm".source =
    #   ./textobjects.scm;
    # "nvim/init.lua.chandy".source = ./init.lua;
    # "nvim/lua/base.lua".source = ./base.lua;
  # } // (if isLinux then {
  #   "ghostty/config".text = builtins.readFile ./ghostty.linux;
  # } else {});

  #---------------------------------------------------------------------
  # Programs
  #---------------------------------------------------------------------

  programs.gpg.enable = !isDarwin;

  programs.bash = {
    enable = true;
    shellOptions = [];
    historyControl = [ "ignoredups" "ignorespace" ];
    initExtra = builtins.readFile ./bashrc;
    shellAliases = shellAliases;
  };

  programs.direnv= {
    enable = true;

    config = {
      whitelist = {
        prefix= [
          "$HOME/code/go/src/github.com/hashicorp"
          "$HOME/code/go/src/github.com/chandy"
        ];

        exact = ["$HOME/.envrc"];
      };
    };
  };

  programs.fish = {
    enable = true;
    shellAliases = shellAliases;
    # colors = {};
    interactiveShellInit = lib.strings.concatStrings (lib.strings.intersperse "\n" ([
    #   "source ${sources.theme-bobthefish}/functions/fish_prompt.fish"
    #   "source ${sources.theme-bobthefish}/functions/fish_right_prompt.fish"
    #   "source ${sources.theme-bobthefish}/functions/fish_title.fish"
      (builtins.readFile ./config.fish)
      # "set -g SHELL ${pkgs.fish}/bin/fish"
    ]));

    # plugins = map (n: {
    #   name = n;
    #   src  = sources.${n};
    # }) [
    #   "fish-fzf"
    #   "fish-foreign-env"
    #   "theme-bobthefish"
    # ];
  };

  programs.git = {
    enable = true;
    userName = "Chris Handy";
    userEmail = "chandy@peoplescout.com";
    aliases = {
      cleanup = "!git branch --merged | grep  -v '\\*\\|master\\|develop' | xargs -n 1 -r git branch -d";
      prettylog = "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(r) %C(bold blue)<%an>%Creset' --abbrev-commit --date=relative";
      root = "rev-parse --show-toplevel";
      # View abbreviated SHA, description, and history graph of the latest 20 commits
      l = "log --pretty=oneline -n 20 --graph --abbrev-commit";
      # View the current working tree status using the short formats
      s = "status -s";
      # Show the diff between the latest commit and the current state
      d = "!git diff-index --quiet HEAD -- || clear; git --no-pager diff --patch-with-stat";
      # `git di $number` shows the diff between the state `$number` revisions ago and the current state
      di = "!d() { git diff --patch-with-stat HEAD~$1; }; git diff-index --quiet HEAD -- || clear; d";
      # Using diff-so-fancy
      dsf = "!git diff --color $@ | diff-so-fancy";
      # Pull in remote changes for the current repository and all its submodules
      p = "!git pull; git submodule foreach git pull origin master";
      # Clone a repository including all submodules
      c = "clone --recursive";
      # Commit all changes
      ca = "!git add -A && git commit -av";
      # Switch to a branch, creating it if necessary
      go = "!f() { git checkout -b \"$1\" 2> /dev/null || git checkout \"$1\"; }; f";
      # Show verbose output about tags, branches or remote
      tags = "tag -l";
      branches = "branch -a";
      remotes = "remote -v";
      # Amend the currently staged files to the latest commit
      amend = "commit --amend --reuse-message=HEAD";
      # Credit an author on the latest commit
      credit = "!f() { git commit --amend --author \"$1 <$2>\" -C HEAD; }; f";
      # Interactive rebase with the given number of latest commits
      reb = "!r() { git rebase -i HEAD~$1; }; r";
      # Remove the old tag with this name and tag the latest commit with it.
      retag = "!r() { git tag -d $1 && git push origin :refs/tags/$1 && git tag $1; }; r";
      # Find branches containing commit
      fb = "!f() { git branch -a --contains $1; }; f";
      # Find tags containing commit
      ft = "!f() { git describe --always --contains $1; }; f";
      # Find commits by source code
      fc = "!f() { git log --pretty=format:'%C(yellow)%h  %Cblue%ad  %Creset%s%Cgreen  [%cn] %Cred%d' --decorate --date=short -S$1; }; f";
      # Find commits by commit message
      fm = "!f() { git log --pretty=format:'%C(yellow)%h  %Cblue%ad  %Creset%s%Cgreen  [%cn] %Cred%d' --decorate --date=short --grep=$1; }; f";
    };
    extraConfig = {
      branch.autosetuprebase = "always";
      color.ui = true;
      core.askPass = ""; # needs to be empty to use terminal for ask pass
      credential.helper = "store"; # want to make this more secure
      github.user = "chandy";
      push.default = "tracking";
      init.defaultBranch = "main";
    };
  };

  programs.go = {
    enable = true;
    goPath = "code/go";
    goPrivate = [ "github.com/chandy" "github.com/hashicorp" "rfc822.mx" ];
  };

  programs.jujutsu = {
    enable = true;

    # I don't use "settings" because the path is wrong on macOS at
    # the time of writing this.
  };

  programs.alacritty = {
    enable = !isWSL;

    settings = {
      env.TERM = "xterm-256color";

      key_bindings = [
        { key = "K"; mods = "Command"; chars = "ClearHistory"; }
        { key = "V"; mods = "Command"; action = "Paste"; }
        { key = "C"; mods = "Command"; action = "Copy"; }
        { key = "Key0"; mods = "Command"; action = "ResetFontSize"; }
        { key = "Equals"; mods = "Command"; action = "IncreaseFontSize"; }
        { key = "Subtract"; mods = "Command"; action = "DecreaseFontSize"; }
      ];
    };
  };

  programs.i3status = {
    enable = isLinux && !isWSL;

    general = {
      colors = true;
      color_good = "#8C9440";
      color_bad = "#A54242";
      color_degraded = "#DE935F";
    };

    modules = {
      ipv6.enable = false;
      "wireless _first_".enable = false;
      "battery all".enable = false;
    };
  };

  programs.neovim = {
    enable = true;
    # package = inputs.neovim-nightly-overlay.packages.${pkgs.system}.default;

    withPython3 = true;
    viAlias = true;
    vimAlias = true;

    # plugins = with pkgs; [

    #   vimPlugins.which-key-nvim
    #   vimPlugins.plenary-nvim
    #   vimPlugins.popup-nvim
    #   vimPlugins.telescope-nvim
    #   vimPlugins.telescope-fzf-native-nvim
    #   vimPlugins.telescope-file-browser-nvim
    #   vimPlugins.nvim-treesitter
    #   vimPlugins.nvim-treesitter-textobjects
    #   vimPlugins.nvim-treesitter-refactor
    #   vimPlugins.nvim-treesitter-context
    #   vimPlugins.playground
    #   vimPlugins.nvim-lspconfig
    #   vimPlugins.lsp-status-nvim
    #   vimPlugins.none-ls-nvim
    #   vimPlugins.trouble-nvim
    #   vimPlugins.nvim-cmp
    #   vimPlugins.cmp-nvim-lsp
    #   vimPlugins.cmp-buffer
    #   vimPlugins.cmp-path
    #   vimPlugins.cmp-cmdline
    #   vimPlugins.cmp-treesitter
    #   vimPlugins.cmp-spell
    #   vimPlugins.cmp_luasnip
    #   vimPlugins.luasnip
    #   vimPlugins.lualine-nvim
    #   vimPlugins.kanagawa-nvim
    #   vimPlugins.nvim-web-devicons
    #   vimPlugins.vim-startify
    #   vimPlugins.neoformat
    # ];

    # # extraConfig = (import ./vim-config.nix) { inherit sources; };
    # extraConfig = ''
    #   lua require('base')
    # '';

    # extraPackages = with pkgs; [
    #   # Language server packages (executables)
    #   lua-language-server
    #   nodePackages.vim-language-server
    #   stylua
    #   nixfmt-rfc-style
    #   rustfmt
    # ];    
  };

  programs.atuin = {
    enable = true;
    enableFishIntegration = true;
    enableNushellIntegration = true;
    settings = {
      show_tabs = false;
      style = "compact";
      enter_accept = true;
    };
  };

  programs.nushell = {
    enable = true;
    configFile.source = ./config.nu;
    shellAliases = shellAliases;

    # This is appended at the end of the config file and we need to do
    # this to override OMP's transient prompt command.
    extraConfig = ''
      $env.TRANSIENT_PROMPT_COMMAND = null
    '';
  };

  programs.oh-my-posh = {
    enable = false;
    enableNushellIntegration = true;
    # settings = builtins.fromJSON (builtins.readFile ./omp.json);
  };

  services.gpg-agent = {
    enable = isLinux;
    pinentry.package = pkgs.pinentry-tty;

    # cache the keys forever so we don't get asked for a password
    defaultCacheTtl = 31536000;
    maxCacheTtl = 31536000;
  };

  xresources.extraConfig = builtins.readFile ./Xresources;

  # Make cursor not tiny on HiDPI screens
  home.pointerCursor = lib.mkIf (isLinux && !isWSL) {
    name = "Vanilla-DMZ";
    package = pkgs.vanilla-dmz;
    size = 128;
    x11.enable = true;
  };

  programs.zoxide = {
    enable = true;
  };

  programs.starship = {
    enable = true;
  };

  # # Htop
  # # https://rycee.gitlab.io/home-manager/options.html#opt-programs.htop.enable
  # # programs.htop.enable = true;
  # # programs.htop.settings.show_program_path = true;

  programs.starship.settings = {
    # See docs here: https://starship.rs/config/
    # Symbols config configured ./starship-symbols.nix.

    directory.fish_style_pwd_dir_length = 1; # turn on fish directory truncation
    directory.truncation_length = 2; # number of directories not to truncate
    gcloud.disabled = true; # annoying to always have on
    hostname.style = "bold green"; # don't like the default
    memory_usage.disabled = true; # because it includes cached memory it's reported as full a lot
    username.style_user = "bold blue"; # don't like the default
  };

  programs.zellij = { enable = true; };
  
}
