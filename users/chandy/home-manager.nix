{ isWSL, inputs, ... }:

{ config, lib, pkgs, ... }:

let
  sources = import ../../nix/sources.nix;
  isDarwin = pkgs.stdenv.isDarwin;
  isLinux = pkgs.stdenv.isLinux;

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
    pkgs.bat
    pkgs.fd
    pkgs.firefox
    pkgs.fzf
    pkgs.git-crypt
    pkgs.htop
    pkgs.jq
    pkgs.ripgrep
    pkgs.rofi
    pkgs.tree
    pkgs.watch
    pkgs.zathura
    # pkgs._1password

    pkgs.go
    pkgs.gopls
    # pkgs.zig-master

    pkgs.tlaplusToolbox
    pkgs.tetex
    
    pkgs.bat
    pkgs.lsd
    pkgs.delta
    pkgs.du-dust
    pkgs.duf
    pkgs.broot
    pkgs.cheat
    pkgs.tldr
    pkgs.bottom
    pkgs.glances
    pkgs.gtop
    pkgs.gping
    pkgs.procs
    pkgs.zoxide
    pkgs.dogdns
    pkgs.neofetch
    pkgs.nmap
    pkgs.feh
    # pkgs.neovim-nightly
    pkgs.gcc
    pkgs.wget
    pkgs.unzip
    pkgs.luajit
    pkgs.luajitPackages.luacheck
    pkgs.luajitPackages.gitsigns-nvim
    pkgs.statix
    pkgs.nodejs
    pkgs.nerdfonts
    pkgs.diff-so-fancy
    pkgs.wezterm
    pkgs.nodePackages.yarn
    pkgs.nodePackages.eslint
    pkgs.nodePackages.prettier
    pkgs.tree-sitter
  ];

  #---------------------------------------------------------------------
  # Env vars and dotfiles
  #---------------------------------------------------------------------

  home.sessionVariables = {
    LANG = "en_US.UTF-8";
    LC_CTYPE = "en_US.UTF-8";
    LC_ALL = "en_US.UTF-8";
    EDITOR = "nvim";
    PAGER = "less -FirSwX";
    MANPAGER = "sh -c 'col -bx | ${pkgs.bat}/bin/bat -l man -p'";
  };

  home.file.".gdbinit".source = ./gdbinit;
  home.file.".inputrc".source = ./inputrc;

  xdg.configFile."i3/config".text = builtins.readFile ./i3;
  xdg.configFile."rofi/config.rasi".text = builtins.readFile ./rofi;
  xdg.configFile."devtty/config".text = builtins.readFile ./devtty;

  # tree-sitter parsers
  # xdg.configFile."nvim/parser/proto.so".source = "${pkgs.tree-sitter-proto}/parser";
  # xdg.configFile."nvim/queries/proto/folds.scm".source =
  #   "${sources.tree-sitter-proto}/queries/folds.scm";
  # xdg.configFile."nvim/queries/proto/highlights.scm".source =
  #   "${sources.tree-sitter-proto}/queries/highlights.scm";
  # xdg.configFile."nvim/queries/proto/textobjects.scm".source =
  #   ./textobjects.scm;
  xdg.configFile."nvim/init.lua.chandy".source = ./init.lua;

  #---------------------------------------------------------------------
  # Programs
  #---------------------------------------------------------------------

  # programs.gpg.enable = true;

  programs.bash = {
    enable = true;
    shellOptions = [];
    historyControl = [ "ignoredups" "ignorespace" ];
    initExtra = builtins.readFile ./bashrc;

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
    };
  };

  programs.direnv= {
    enable = true;
    nix-direnv.enable = true;

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
    interactiveShellInit = lib.strings.concatStrings (lib.strings.intersperse "\n" [
      # "source ${sources.theme-bobthefish}/functions/fish_prompt.fish"
      # "source ${sources.theme-bobthefish}/functions/fish_right_prompt.fish"
      # "source ${sources.theme-bobthefish}/functions/fish_title.fish"
      # (builtins.readFile ./conf.fish)
      "set -g SHELL ${pkgs.fish}/bin/fish"
      # set -gx fish_user_paths $HOME/go/bin $HOME/.cargo/bin                           
      # "set -g theme_nerd_fonts yes"                                                       
      # "set -g theme_newline_cursor yes"                                                   
      "set -gx FZF_DEFAULT_COMMAND 'fd --type file'"                                     
      "set -gx FZF_CTRL_T_COMMAND $FZF_DEFAULT_COMMAND"                                 
      "set -gx FZF_ALT_C_COMMAND fd -t d . $HOME"
      "set fzf_preview_dir_cmd eza --all --color=always"
      "set -gx EDITOR nvim"
      # To deal with fish not ordering the nix paths first https://github.com/LnL7/nix-darwin/issues/122
      "fish_add_path --move --prepend --path $HOME/.nix-profile/bin /run/wrappers/bin /etc/profiles/per-user/$USER/bin /nix/var/nix/profiles/default/bin /run/current-system/sw/bin"
      "fzf_configure_bindings"
    ]);

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

      # Two decades of using a Mac has made this such a strong memory
      # that I'm just going to keep it consistent.
      pbcopy = "xclip";
      pbpaste = "xclip -o";

      wo = "cd ~/Developer/workspace";
      ll = "eza -l -g --icons";
      la = "${pkgs.eza}/bin/eza -a";
      lt = "${pkgs.eza}/bin/eza --tree";
      lla = "${pkgs.eza}/bin/eza -la";
    };
    plugins = [
      {
        name = "fzf-fish";
        src = pkgs.fetchFromGitHub {
          owner = "PatrickF1";
          repo = "fzf.fish";
          rev = "c8c7d9903e0327b0d76e51ba4378ec8d5ef6477e";
          sha256 = "0v653v5g3fnnlbar8ljrclf0qpn4fp4r8flqi7pfypqm0nv8zf9q";
        };
      }
    ];
  };

  programs.git = {
    enable = true;
    userName = "Chris Handy";
    userEmail = "chrisjhandy@gmail.com";
    aliases = {
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

  # programs.tmux = {
  #   enable = true;
  #   terminal = "xterm-256color";
  #   shortcut = "l";
  #   secureSocket = false;

  #   extraConfig = ''
  #     set -ga terminal-overrides ",*256col*:Tc"

  #     set -g @dracula-show-battery false
  #     set -g @dracula-show-network false
  #     set -g @dracula-show-weather false

  #     bind -n C-k send-keys "clear"\; send-keys "Enter"

  #     run-shell ${sources.tmux-pain-control}/pain_control.tmux
  #     run-shell ${sources.tmux-dracula}/dracula.tmux
  #   '';
  # };

  # programs.alacritty = {
  #   enable = true;

  #   settings = {
  #     env.TERM = "xterm-256color";

  #     key_bindings = [
  #       { key = "K"; mods = "Command"; chars = "ClearHistory"; }
  #       { key = "V"; mods = "Command"; action = "Paste"; }
  #       { key = "C"; mods = "Command"; action = "Copy"; }
  #       { key = "Key0"; mods = "Command"; action = "ResetFontSize"; }
  #       { key = "Equals"; mods = "Command"; action = "IncreaseFontSize"; }
  #       { key = "Subtract"; mods = "Command"; action = "DecreaseFontSize"; }
  #     ];
  #   };
  # };

  programs.kitty = {
    enable = true;
    extraConfig = builtins.readFile ./kitty;
  };

  programs.i3status = {
    enable = true;

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

  xdg.configFile."nvim/lua/base.lua".source = ./base.lua;
  programs.neovim = {
    enable = true;
    package = pkgs.neovim-unwrapped;
    viAlias = true;
    vimAlias = true;

    plugins = with pkgs; [

      vimPlugins.which-key-nvim
      vimPlugins.plenary-nvim
      vimPlugins.popup-nvim
      vimPlugins.telescope-nvim
      vimPlugins.telescope-fzf-native-nvim
      vimPlugins.telescope-file-browser-nvim
      vimPlugins.nvim-treesitter
      vimPlugins.nvim-treesitter-textobjects
      vimPlugins.nvim-treesitter-refactor
      vimPlugins.nvim-treesitter-context
      vimPlugins.playground
      vimPlugins.nvim-lspconfig
      vimPlugins.lsp-status-nvim
      vimPlugins.null-ls-nvim
      vimPlugins.trouble-nvim
      vimPlugins.nvim-cmp
      vimPlugins.cmp-nvim-lsp
      vimPlugins.cmp-buffer
      vimPlugins.cmp-path
      vimPlugins.cmp-cmdline
      vimPlugins.cmp-treesitter
      vimPlugins.cmp-spell
      vimPlugins.cmp_luasnip
      vimPlugins.luasnip
      vimPlugins.lualine-nvim
      vimPlugins.kanagawa-nvim
      vimPlugins.nvim-web-devicons
      vimPlugins.vim-startify
      vimPlugins.neoformat
    ];

    # extraConfig = (import ./vim-config.nix) { inherit sources; };
    extraConfig = ''
      lua require('base')
    '';

    extraPackages = with pkgs; [
      # Language server packages (executables)
      lua-language-server
      nodePackages.vim-language-server
      stylua
      nixfmt
      rustfmt
    ];    
  };

  # services.gpg-agent = {
  #   enable = true;
  #   pinentryFlavor = "tty";

  #   # cache the keys forever so we don't get asked for a password
  #   defaultCacheTtl = 31536000;
  #   maxCacheTtl = 31536000;
  # };

  xresources.extraConfig = builtins.readFile ./Xresources;

  # Make cursor not tiny on HiDPI screens
  home.pointerCursor = {
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

  # Htop
  # https://rycee.gitlab.io/home-manager/options.html#opt-programs.htop.enable
  programs.htop.enable = true;
  programs.htop.settings.show_program_path = true;

  programs.fzf = {
    enable = true;
    enableFishIntegration = false;
  };

  programs.bat.enable = true;

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

  programs.eza.enable = true;
  programs.jq.enable = true;
  programs.lsd.enable = true;
  programs.feh.enable = true;
  
}
