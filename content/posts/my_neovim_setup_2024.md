---
title: "My Neovim setup 2024"
date: 2024-06-16T13:34:47+09:00
slug: 2024-06-16-my_neovim_setup_2024
type: posts
draft: false
categories:
  - Information
tags:
  - Neovim
---
I like tools that stay out of the way and are easy to inspect when something breaks. That is what pulled me toward Neovim in the first place, and at this point it has become the setup I reach for everywhere.

# Neovim
Vim-style editing looks hostile at first, but once it clicks it is hard to go back. Moving around code, editing text, and jumping between files without leaving the keyboard feels much faster than the usual IDE workflow. Running inside a terminal also keeps the whole thing lightweight and responsive.

![Neovim Startup](/images/neovim_startup.png)*Neovim startup only takes 52ms!*

Another reason I like terminal-based editors is that you can usually tell what is happening. If completion is broken, it is an LSP problem. If syntax highlighting is weird, it is probably Tree-sitter. If debugging fails, you know which adapter is involved. That sounds obvious, but it is a lot nicer than staring at a giant GUI app and guessing which hidden layer failed.

## Lazy.nvim
[Lazy.nvim](https://github.com/folke/lazy.nvim) is the plugin manager I use. It fetches plugins from GitHub, handles lazy loading, and keeps startup time low. I do not run a huge plugin list, but there are a few that I use every day:

### Vim-lumen
[vim-lumen](https://github.com/vimpostor/vim-lumen) syncs my colorscheme with the system dark mode. I also keep a terminal alias around for quickly toggling it:
```sh
alias dark="osascript -e 'tell app \"System Events\" to tell appearance preferences to set dark mode to not dark mode'"
```

It is a tiny thing, but I use it enough that it earned a place here.

### Lsp-zero
[Lsp-zero](https://lsp-zero.netlify.app) is my shortcut for getting completion, formatting, linting, and the rest of the usual editor features without wiring every piece together from scratch. It sits on top of language servers like `rust-analyzer`, `ruff`, `clangd`, and `lua-lsp`.

Keymaps, completion behavior, snippets, format-on-save, rename, and jump-to-definition are all there with relatively little setup.

### Telescope.nvim
[Telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) is the picker I use for almost everything: files, grep results, buffers, branches, and random bits of editor state. It is one of those plugins that quickly stops feeling optional.

### Im-select.nvim
[Im-select.nvim](https://github.com/keaising/im-select.nvim) solves a very practical problem: modal editing is annoying if your input method is not set to English. This plugin switches to English in normal mode and restores the previous input method in insert mode.

### And Many More
[ToggleTerm.nvim](https://github.com/akinsho/toggleterm.nvim) gives me embedded terminals that still feel like Neovim. [LuaLine.nvim](https://github.com/nvim-lualine/lualine.nvim) keeps the statusline clean. [Codeium.vim](https://github.com/Exafunction/codeium.vim) was a decent free Copilot alternative when I was using it. [Gruvbox.nvim](https://github.com/ellisonleao/gruvbox.nvim) is still one of my favorite colorschemes, and it is also what this blog uses.

One nice side effect of all of this is that my config is easy to copy across machines. If you want to take a look, my setup is on [GitHub](https://github.com/gmmyung/nvim). If you have plugins or workflows I should try, feel free to open an issue.
