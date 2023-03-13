local M = {}

local root_folder = debug.getinfo(1, "S").source:sub(2):match("(.*[/\\])"):sub(1, -2):match("(.*[/\\])")

-- local command = root_folder .. "scripts/jet"
local jl_exec = [[julia --project=~/.julia/environments/nvim-null-ls]]
-- local jl_exec = root_folder .. "scripts/jet"
local jl_source = root_folder .. 'scripts/jet.jl'
-- local command = jl_exec .. " " .. jl_source
local command = function()
    os.execute(jl_exec .. " " .. jl_source)
end

function M.setup(opts)
  opts = opts or {}
  local timeout = opts.timeout or 20000
  -- setup_lspconfig = opts.setup_lspconfig or true
  local null_ls = require("null-ls")
  local helpers = require("null-ls.helpers")
  local builtins = null_ls.builtins
  local generator = null_ls.generator

  local jet_julia = {
    method = null_ls.methods.DIAGNOSTICS,
    filetypes = { "julia" },
    generator = null_ls.generator({
      command = 'julia',
      args = { '--project=~/.julia/environments/nvim-null-ls', jl_source, "$FILENAME", },
      to_stdin = true,
      from_stderr = true,
      timeout = timeout,
      format = "line",
      check_exit_code = function(code, stderr)
        local success = code <= 1
        if not success then
            print(stderr)
        end
        return success
      end,
      on_output = helpers.diagnostics.from_patterns({
        {
          pattern = [[(%d+):([EIW]):(.*)]],
          groups = { "row", "severity", "message" },
          overrides = {
            severities = {
              E = helpers.diagnostics.severities["error"],
              W = helpers.diagnostics.severities["warning"],
              I = helpers.diagnostics.severities["information"],
            },
          },
        },
      }),
    }),
  }

  null_ls.register(jet_julia)
end

print(jl_source)
return M
