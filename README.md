# NeoVim configurations 

## Install External Dependencies

External Requirements:
- Basic utils: `git`, `make`, `unzip`, C Compiler (`gcc`)
- [ripgrep](https://github.com/BurntSushi/ripgrep#installation), [fd-find](https://github.com/sharkdp/fd#installation)
- [tree-sitter CLI](https://github.com/tree-sitter/tree-sitter/blob/master/crates/cli/README.md#installation)
- Clipboard tool (xclip/xsel/win32yank or other depending on platform)
- A [Nerd Font](https://www.nerdfonts.com/): optional, provides various icons
  - if you have it set `vim.g.have_nerd_font` in `init.lua` to true
- Emoji fonts (Ubuntu only, and only if you want emoji!) sudo apt install fonts-noto-color-emoji
- Language Setup:
  - If you want to write Typescript, you need `npm`
  - If you want to write Golang, you will need `go`
  - etc.

> **NOTE**
> Backup your previous configuration (if any exists)

Neovim's configurations are located under the following path, by default:

| OS | PATH |
| :- | :--- |
| Linux, MacOS | `$XDG_CONFIG_HOME/nvim`, `~/.config/nvim` |
| Windows | %localappdata%\nvim\ |

## References

### Inspired By

I checked these resources and used some of the configurations and/or the plugins used by them

- https://github.com/ThePrimeagen/init.lua
- https://github.com/tjdevries/config.nvim
- https://github.com/m1chaelwilliams/my-nvim-config
- https://github.com/JazzyGrim/dotfiles

