-- Explore and edit files on a remote machine over SSH (mounts via sshfs).
-- Hosts are read from ~/.ssh/config; the picker UI is provided by snacks.nvim.
return {
  "nosduco/remote-sshfs.nvim",
  dependencies = {
    "folke/snacks.nvim",
    "nvim-lua/plenary.nvim",
  },
  opts = {
    ui = {
      picker = "snacks",
      select_prompts = false,
      confirm = {
        connect = true, -- ask before connecting to the selected host
        change_dir = false, -- on_connect.change_dir below already switches cwd; no extra prompt
      },
    },
    connections = {
      ssh_configs = {
        vim.fn.expand "$HOME" .. "/.ssh/config",
      },
      ssh_known_hosts = vim.fn.expand "$HOME" .. "/.ssh/known_hosts",
      sshfs_args = {
        "-o reconnect", -- survive network drops instead of leaving a dead mount
        "-o ConnectTimeout=5",
      },
    },
    mounts = {
      base_dir = vim.fn.expand "$HOME" .. "/.sshfs/", -- mount points live under here
      unmount_on_exit = true, -- sshfs runs in the foreground and unmounts when vim exits
    },
    handlers = {
      on_connect = {
        change_dir = true, -- cd into the mount point once connected
      },
      on_disconnect = {
        clean_mount_folders = false, -- keep empty mount dirs for faster reconnects
      },
      on_edit = {},
    },
    log = {
      enabled = false,
      truncate = false,
      types = {
        all = false,
        util = false,
        handler = false,
        sshfs = false,
      },
    },
  },
}
