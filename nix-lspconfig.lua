return function(cfg)
  for name, lsp in pairs(cfg.servers) do
    local config = {
      cmd = require'lspconfig'[name].document_config.default_config.cmd,
      on_attach = function(client, bufnr)
        for _, keymap in ipairs(cfg.keymaps) do
          vim.api.nvim_buf_set_keymap(bufnr, keymap.mode, keymap.lhs,
                                      keymap.rhs, keymap.opts)
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
    config.cmd[1] = lsp.pkg .. '/bin/' .. config.cmd[1]
    require'lspconfig'[name].setup(config)
  end
end
