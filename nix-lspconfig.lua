return function(cfg)
  for name, lsp in pairs(cfg.servers) do
    local config = {
      on_attach = function(client, bufnr)
        for _, keymap in ipairs(cfg.keymaps) do
          vim.keymap.set(keymap.mode, keymap.lhs, keymap.rhs,
                         vim.tbl_extend('force', keymap.opts, {buffer = bufnr}))
        end

        for option, value in pairs(cfg.opts) do
          vim.api.nvim_buf_set_option(bufnr, option, value)
        end

        cfg.on_attach(client, bufnr)
      end,
      capabilities = cfg.capabilities,
    }
    if lsp.config ~= nil then
      config = vim.tbl_extend('force', config, lsp.config)
    end
    if lsp.pkg ~= nil then
      if config.cmd == nil then
        -- TODO: check if following PR may changed the interface:
        -- https://github.com/neovim/nvim-lspconfig/pull/1479
        config.cmd = require'lspconfig'[name].document_config.default_config.cmd
      end
      config.cmd[1] = lsp.pkg .. '/bin/' .. config.cmd[1]
    end
    require'lspconfig'[name].setup(config)
  end
end
