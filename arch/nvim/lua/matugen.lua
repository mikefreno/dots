 local M = {}

function M.setup()
  require('base16-colorscheme').setup({
    base00 = '#1c2518',
    base01 = '#2e3e28',
    base02 = '#293824',
    base03 = '#646f60',
    base04 = '#b1b6af',
    base05 = '#f2f3f2',
    base06 = '#f2f3f2',
    base07 = '#f2f3f2',
    base08 = '#fd4663',
    base09 = '#66ccb0',
    base0A = '#5cd677',
    base0B = '#8ae467',
    base0C = '#96e9d2',
    base0D = '#acec93',
    base0E = '#96e9a8',
    base0F = '#bef4ca',
  })

  local hi = function(group, opts)
    vim.api.nvim_set_hl(0, group, opts)
  end

  -- telescope.nvim
  hi('TelescopeNormal',         { fg = '#f2f3f2',          bg = '#1c2518' })
  hi('TelescopeBorder',         { fg = '#646f60',             bg = '#1c2518' })
  hi('TelescopePromptNormal',   { fg = '#f2f3f2',          bg = '#1c2518' })
  hi('TelescopePromptBorder',   { fg = '#646f60',             bg = '#1c2518' })
  hi('TelescopePromptPrefix',   { fg = '#8ae467',             bg = '#1c2518' })
  hi('TelescopePromptCounter',  { fg = '#b1b6af',  bg = '#1c2518' })
  hi('TelescopePromptTitle',    { fg = '#1c2518',             bg = '#8ae467' })
  hi('TelescopePreviewTitle',   { fg = '#1c2518',             bg = '#5cd677' })
  hi('TelescopeResultsTitle',   { fg = '#1c2518',             bg = '#66ccb0' })
  hi('TelescopeSelection',      { fg = '#f2f3f2',          bg = '#293824' })
  hi('TelescopeSelectionCaret', { fg = '#8ae467',             bg = '#293824' })
  hi('TelescopeMatching',       { fg = '#8ae467',             bold = true })

  -- mini.pick
  hi('MiniPickNormal',         { fg = '#f2f3f2',          bg = '#1c2518' })
  hi('MiniPickBorder',         { fg = '#646f60',             bg = '#1c2518' })
  hi('MiniPickPrompt',   { fg = '#f2f3f2',          bg = '#1c2518' })
  hi('MiniPickPromptPrefix',   { fg = '#8ae467',             bg = '#1c2518' })
  hi('MiniPickBorderText',    { fg = '#1c2518',             bg = '#8ae467' })
  hi('MiniPickMatchCurrent',      { fg = '#f2f3f2',          bg = '#293824' })
  hi('MiniPickPromptCaret', { fg = '#8ae467',             bg = '#293824' })
  hi('MiniPickMatchRanges',       { fg = '#8ae467',             bold = true })
end

-- Register a signal handler for SIGUSR1 (matugen updates).
-- The handler re-requires this module, which re-runs the code below, so the
-- previous handle is stopped first; otherwise handlers double on every signal.
if _G.__matugen_signal then
  _G.__matugen_signal:stop()
  _G.__matugen_signal:close()
end

local signal = vim.uv.new_signal()
_G.__matugen_signal = signal
signal:start(
  'sigusr1',
  vim.schedule_wrap(function()
    package.loaded['matugen'] = nil
    require('matugen').setup()
  end)
)

return M
