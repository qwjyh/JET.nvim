local M = {}

local root_folder = debug.getinfo(1, "S").source:sub(2):match("(.*[/\\])"):sub(1, -2):match("(.*[/\\])")
local jl_source = root_folder .. 'scripts/jet.jl'

function M.setup(opts)
  opts = opts or {}
  local timeout = opts.timeout or 20000
  local debug = opts.debug or false
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

  null_ls.setup {
    debug = debug,
  }
  null_ls.register(jet_julia)


  -- close start utilities

  ---close JETls client
  local function close_jetls()
    local targets = vim.lsp.get_active_clients({
      name = 'null-ls'
    })
    for _, v in pairs(targets) do
      v.stop()
    end
    print("Closed " .. #targets .. " clients.")
  end

  ---start JETls client
  local function start_jetls()
    null_ls.setup {
      sources = { jet_julia },
    }
  end

  ---Dispatch commands based on the first argument `subcmd`
  ---@param argtb table
  local function dispatch_cmd(argtb)
    local subcmd = argtb.fargs[1]
    if subcmd == "stop" then
      close_jetls()
    elseif subcmd == "start" then
      start_jetls()
    elseif subcmd == "restart" then
      close_jetls()
      start_jetls()
      print("restarted JETls")
    else
      print("No methods matching:")
      print("start|stop|restart")
    end
  end

  vim.api.nvim_create_user_command('JETls', dispatch_cmd, {
    nargs = 1,
    ---custom complete
    ---@param _ArgLead any
    ---@param _CmdLine any
    ---@param _CursorPos any
    ---@return string[]
    complete = function(_ArgLead, _CmdLine, _CursorPos)
      return { "start", "stop", "restart", }
    end,
    desc = "start or stop JETls client",
  })

end

return M
