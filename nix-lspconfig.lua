return function(cfg)
  for name, lsp in pairs(cfg.servers) do
    local config = {
      on_attach = function(client, bufnr)
        for _, keymap in ipairs(cfg.keymaps) do
          vim.keymap.set(keymap.mode, keymap.lhs, keymap.rhs,
                         vim.tbl_extend('force', keymap.opts, {buffer = bufnr}))
        end

        for option, value in pairs(cfg.opts) do
          -- TODO: https://neovim.io/doc/user/deprecated.html#nvim_buf_set_option()
          vim.api.nvim_buf_set_option(bufnr, option, value)
        end

        cfg.on_attach(client, bufnr)
      end,
      capabilities = cfg.capabilities,
    }
    if lsp.config ~= nil then
      config = vim.tbl_extend('force', config, lsp.config)
    end
    require'lspconfig'[name].setup(config)
  end
end
