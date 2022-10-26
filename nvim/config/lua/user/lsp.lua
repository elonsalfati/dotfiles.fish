local cmp_nvim_lsp = require("cmp_nvim_lsp")

local capabilities = cmp_nvim_lsp.default_capabilities()

-- Use an on_attach function to only map the following keys
-- after the language server attaches to the current buffer
local on_attach = function(client, bufnr)
	local function buf_set_keymap(...)
		vim.api.nvim_buf_set_keymap(bufnr, ...)
	end

	-- Mappings.
	local opts = { noremap = true, silent = true }
	buf_set_keymap("n", "gd", "<cmd>Telescope lsp_definitions<CR>", opts)
	buf_set_keymap("n", "gr", "<cmd>Telescope lsp_references<CR>", opts)
	buf_set_keymap("n", "<C-j>", "<cmd>Telescope lsp_document_symbols<CR>", opts)
	buf_set_keymap("n", "<C-h>", "<cmd>Telescope lsp_dynamic_workspace_symbols<CR>", opts)
	buf_set_keymap("n", "<C-k>", "<cmd>lua vim.lsp.buf.signature_help()<CR>", opts)
	buf_set_keymap("n", "gi", "<cmd>Telescope lsp_implementations<CR>", opts)
	buf_set_keymap("n", "gD", "<cmd>lua vim.lsp.buf.declaration()<CR>", opts)
	buf_set_keymap("n", "K", "<cmd>lua vim.lsp.buf.hover()<CR>", opts)
	buf_set_keymap("n", "<leader>D", "<cmd>Telescope lsp_type_definitions<CR>", opts)
	buf_set_keymap("n", "<leader>rn", "<cmd>lua vim.lsp.buf.rename()<CR>", opts)
	buf_set_keymap("n", "<leader>ca", "<cmd>lua vim.lsp.buf.code_action()<CR>", opts)
	buf_set_keymap("n", "<leader>gl", "<cmd>lua vim.diagnostic.open_float()<CR>", opts)
	buf_set_keymap("n", "<leader>lr", "<cmd>LspRestart<CR>", opts)
	buf_set_keymap("n", "[d", "<cmd>lua vim.diagnostic.goto_next({ float = false })<CR>", opts)
	buf_set_keymap("n", "]d", "<cmd>lua vim.diagnostic.goto_prev({ float = false })<CR>", opts)

	vim.api.nvim_create_autocmd({ "BufWritePre" }, {
		pattern = "<buffer>",
		callback = function()
			Format(client)
			OrganizeImports(client, bufnr, 1500)
		end,
		group = vim.api.nvim_create_augroup("LSPFormat", { clear = true }),
	})

	if client.server_capabilities.documentHighlightProvider then
		local group = vim.api.nvim_create_augroup("LSPHighlight", { clear = true })
		vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
			pattern = "<buffer>",
			callback = function()
				if vim.lsp.buf.server_ready() then
					vim.lsp.buf.document_highlight()
				end
			end,
			group = group,
		})
		vim.api.nvim_create_autocmd({ "CursorMoved" }, {
			pattern = "<buffer>",
			callback = function()
				if vim.lsp.buf.server_ready() then
					vim.lsp.buf.clear_references()
				end
			end,
			group = group,
		})
	end
end

local lspconfig = require("lspconfig")
lspconfig.gopls.setup({
	capabilities = capabilities,
	on_attach = on_attach,
	settings = {
		gopls = {
			gofumpt = true,
		},
	},
	flags = {
		debounce_text_changes = 150,
	},
})

local schemas = {}
schemas["https://goreleaser.com/static/schema-pro.json"] = ".goreleaser.yaml"

lspconfig.yamlls.setup({
	capabilities = capabilities,
	on_attach = on_attach,
	settings = {
		yaml = {
			schemaStore = {
				url = "https://www.schemastore.org/api/json/catalog.json",
				enable = true,
			},
			schemas = schemas,
		},
	},
})

lspconfig.html.setup({
	capabilities = capabilities,
	on_attach = on_attach,
})

lspconfig.jsonls.setup({
	capabilities = capabilities,
	on_attach = on_attach,
})

lspconfig.bashls.setup({
	capabilities = capabilities,
	on_attach = on_attach,
})

lspconfig.golangci_lint_ls.setup({
	capabilities = capabilities,
	on_attach = on_attach,
})

lspconfig.terraformls.setup({
	capabilities = capabilities,
	on_attach = on_attach,
})

lspconfig.tflint.setup({
	capabilities = capabilities,
	on_attach = on_attach,
})

lspconfig.dockerls.setup({
	capabilities = capabilities,
	on_attach = on_attach,
})

lspconfig.sumneko_lua.setup({
	capabilities = capabilities,
	on_attach = on_attach,
	settings = {
		Lua = {
			diagnostics = {
				globals = { "vim", "require", "pcall", "pairs" },
			},
		},
	},
})

lspconfig.rust_analyzer.setup({
	capabilities = capabilities,
	on_attach = on_attach,
})

lspconfig.prosemd_lsp.setup({
	capabilities = capabilities,
	on_attach = on_attach,
})

lspconfig.taplo.setup({
	capabilities = capabilities,
	on_attach = on_attach,
})

-- format code
function Format(client)
	if not client.server_capabilities.documentFormattingProvider or not vim.lsp.buf.server_ready() then
		return
	end

	vim.lsp.buf.format({
		filter = function(c)
			return c.name ~= "sumneko_lua"
		end,
	})
end

-- organize imports
-- https://github.com/neovim/nvim-lspconfig/issues/115#issuecomment-902680058
function OrganizeImports(client, bufnr, timeoutms)
	-- If the organizeImports codeAction runs for lua files, depending on
	-- where the cursor is, it'll reorder the args and break stuff.
	-- This took me way too long to figure out.
	if not vim.lsp.buf.server_ready() or vim.bo.filetype == "lua" then
		return
	end

	local params = vim.lsp.util.make_range_params(nil, client.offset_encoding)
	params.context = { only = { "source.organizeImports" } }

	local result = vim.lsp.buf_request_sync(bufnr, "textDocument/codeAction", params, timeoutms)
	for _, res in pairs(result or {}) do
		for _, r in pairs(res.result or {}) do
			if r.edit then
				vim.lsp.util.apply_workspace_edit(r.edit, client.offset_encoding)
			else
				vim.lsp.buf.execute_command(r.command)
			end
		end
	end
end

local null_ls = require("null-ls")
null_ls.setup({
	sources = {
		null_ls.builtins.formatting.stylua,
	},
	capabilities = capabilities,
	on_attach = on_attach,
})

require("mason").setup()
require("mason-lspconfig").setup({
	automatic_installation = true,
})

local float_config = {
	focusable = false,
	style = "minimal",
	border = "rounded",
	source = "always",
	header = "",
	prefix = "",
}

-- setup diagnostics
vim.diagnostic.config({
	virtual_text = true,
	severity_sort = true,
	float = float_config,
})

vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, float_config)
vim.lsp.handlers["textDocument/signatureHelp"] = vim.lsp.with(vim.lsp.handlers.signature_help, float_config)

-- vim.api.nvim_create_autocmd({ "CursorHold" }, {
-- 	callback = function()
-- 		if vim.lsp.buf.server_ready() then
-- 			vim.diagnostic.open_float()
-- 		end
-- 	end,
-- 	group = vim.api.nvim_create_augroup("LSPDiagnosticsHold", { clear = true }),
-- })

-- set up diagnostic signs
for type, icon in pairs({
	Error = "",
	Warn = "",
	Hint = "",
	Info = "",
}) do
	local hl = "DiagnosticSign" .. type
	vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = "" })
end

-- change documentation to be rouded and non-focusable...
-- any time I focus into one of these, is by accident, and it always take me
-- a couple of seconds to figure out what I did.
vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, {
	border = "rounded",
	focusable = false,
})
