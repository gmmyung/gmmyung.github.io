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
Everyone has a desire to customize their tools, and there is no exception when it comes to development setups. One might write flawless, beautiful code using VSCode, but the joy and experience of customizing your coding setup is what led me into this endless journey.
# Neovim
The idea of Vim/Neovim can be jarring for many people; navigating through code with only your keyboard seems extremely inefficient. However, the reality is quite the opposite. Being able to navigate, write, and edit text with only your keyboard is one of the greatest blessings Neovim provides. Additionally, everything is rendered on a GPU-accelerated terminal, making it extremely responsive. Many IDEs and text editors use native UI kits, custom UI frameworks, or even worse, Electron. On the other hand, Neovim's startup is instant—you can't even notice it loading up.
![Neovim Startup](/images/neovim_startup.png)*Neovim startup only takes 52ms!*

Another benefit of a terminal-based text editor is that you always know what is happening. I still remember the times when I had to wait for 10 minutes every time I opened VSCode for Python autocompletion because it somehow reinstalled the Python linter every time. I couldn't fix it on my own; the bug has been sitting on a VSCode issue tab for years. When using Neovim, even though it can be a burden to set up your own tools, you know there is an LSP (Language Server Protocol) server running, a TreeSitter parser highlighting your code, and a DAP server/client working together to debug your precious code. Running your code using the command line instead of a run button in your IDE makes you experiment and tinker with different options.
## Lazy.nvim
The Neovim community has built an amazing package manager that automatically fetches packages from GitHub and loads them asynchronously to ensure a fast initial load time. This has enabled many awesome community-built plugins, and I am using about a dozen of those plugins. Here are some plugins I use daily to make my life easier:
### Vim-lumen
Starting from the simple stuff, [vim-lumen](https://github.com/vimpostor/vim-lumen) is a plugin that enables me to synchronize the system dark mode to the Neovim colorscheme. I have made a terminal alias that toggles the system dark mode from the terminal:
```sh
alias dark="osascript -e 'tell app \"System Events\" to tell appearance preferences to set dark mode to not dark mode'"
```
Typing `dark` instantaneously toggles dark mode globally, allowing me to enjoy coding all night long.
### Lsp-zero
[Lsp-zero](https://lsp-zero.netlify.app) is an essential plugin used to configure autocompletion, autoformatting, and linting. It doesn't provide these functionalities itself, but it offers a common interface to connect with tools like `rust-analyzer`, `ruff`, `clangd`, and `lua-lsp`. After installing those language servers, Lsp-zero automatically provides IDE functionality with minimal setup.

Keymaps for tasks such as picking suggestions, cycling through suggestions, and filling snippets are all customizable. Advanced features like format on save, jump to definition/declaration, and renaming symbols are all supported.
### Telescope.nvim
[Telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) is a plugin that creates a floating panel offering multiple functionalities. It can browse files, grep files, view Git branches, and navigate multiple buffers. There are dozens of available commands, all equipped with icon support (every file shows its corresponding file icon just like VSCode). Additionally, anyone can create a plugin that integrates with Telescope.nvim, allowing you to view your active terminals, browse through your directories, and more.
### Im-select.nvim
[Im-select.nvim](https://github.com/keaising/im-select.nvim) is a must-have plugin for people who are not native English speakers. Vim/Neovim navigation doesn't work if your input method is set to a foreign language. When you exit the terminal to send a quick email and return to your Neovim session, things just don't work because you are mindlessly typing foreign characters at your command line. This plugin automatically switches your input method to English in normal mode and then switches back to your native language when insert mode is activated.

### And Many More
There are many more plugins that I use frequently. [ToggleTerm.nvim](https://github.com/akinsho/toggleterm.nvim) is a multiplexer within Neovim, allowing me to use use vim motions to select, search, and navigate through terminal outputs. [LuaLine.nvim](https://github.com/nvim-lualine/lualine.nvim) makes your neovim statusline more beautiful. [Codeium.vim](https://github.com/Exafunction/codeium.vim) provides a free alternative for Github Copilot. [Gruvbox.nvim](https://github.com/ellisonleao/gruvbox.nvim) offers a nice colorscheme that is pleasing to your eyes, which is also the colorscheme is used in this blog.

Another great feature of Neovim is the ability to share your configuration with multiple machines, and potentially other users too. Feel free to use [my neovim configuration](https://github.com/gmmyung/nvim), and leave an issue if you have recommendations for me to try out.
