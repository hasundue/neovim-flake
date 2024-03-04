local lspconfig = require("lspconfig")

vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('UserLspConfig', {}),
  callback = function(ev)
    local function map(mode, lhs, rhs)
      vim.keymap.set(mode, lhs, rhs, { noremap = true, buffer = ev.buf })
    end

    map('n', '<M-k>', vim.diagnostic.open_float)
    map('n', '<M-n>', vim.diagnostic.goto_next)
    map('n', '<M-p>', vim.diagnostic.goto_prev)

    local client = vim.lsp.get_client_by_id(ev.data.client_id)
    assert(client, "client not found")

    if client.supports_method("hover") then
      map('n', 'K', vim.lsp.buf.hover)
    end

    if client.supports_method("rename") then
      map('n', '<M-r>', vim.lsp.buf.rename)
    end

    if client.supports_method("inlay_hint") then
      vim.cmd('highlight link LspInlayHint Comment')
      vim.lsp.inlay_hint.enable(ev.buf)
    end

    if client.supports_method("format") then
      vim.api.nvim_create_autocmd('BufWritePre', {
        buffer = ev.buf,
        group = vim.api.nvim_create_augroup("LspFormat", {}),
        callback = function()
          vim.cmd('silent! lua vim.lsp.buf.format({ async = false })')
        end,
      })
    end

    require("lsp_signature").on_attach(
      {
        bind = true,
        doc_lines = 0,
        floating_window = true,
        floating_window_off_y = 0,
        handler_opts = {
          border = "none",
        },
        hint_enable = false,
        padding = ' ',
        transparency = 30,
      },
      ev.buf
    )
  end
})

local servers = {
  lua_ls = {
    settings = {
      Lua = {
        hint = {
          enable = false,
        },
        workspace = {
          checkThirdParty = false,
          library = {
            vim.env.VIMRUNTIME .. "/lua",
            "${3rd}/luv/library",
            "${3rd}/busted/library",
            "${3rd}/luassert/library",
            vim.fn.stdpath("config") .. "/lua",
          },
        },
      },
    },
  },
  denols = {
    cmd = { "deno", "lsp" },
    root_dir = lspconfig.util.root_pattern("deno.json", "deno.jsonc"),
    settings = {
      deno = {
        enable = true,
        unstable = true,
      },
      typescript = {
        inlayHints = {
          enabled = "on",
          functionLikeReturnTypes = { enabled = true },
          parameterTypes = { enabled = true },
        },
      },
    },
    single_file_support = true,
  },
  nil_ls = {
    cmd = { "nil" },
  },
}

local capabilities = require("cmp_nvim_lsp").default_capabilities()

for server, config in pairs(servers) do
  lspconfig[server].setup(vim.tbl_deep_extend("force", config, {
    capabilities = capabilities,
  }))
end