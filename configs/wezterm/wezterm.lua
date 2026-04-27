local wezterm = require 'wezterm'
local config = wezterm.config_builder()

config.font = wezterm.font 'Maple Mono NF CN'
config.font_size = 11.0
config.color_scheme = 'Tokyo Night'

config.window_padding = { left = 8, right = 8, top = 8, bottom = 8 }
config.hide_tab_bar_if_only_one_tab = false
config.window_close_confirmation = 'NeverPrompt'

config.keys = {
  {
    key = 'c',
    mods = 'CTRL',
    action = wezterm.action_callback(function(window, pane)
      if window:get_selection_text_for_pane(pane) ~= '' then
        window:perform_action(wezterm.action.CopyTo 'Clipboard', pane)
      else
        window:perform_action(wezterm.action.SendKey { key = 'c', mods = 'CTRL' }, pane)
      end
    end),
  },
  {
    key = 'v',
    mods = 'CTRL',
    action = wezterm.action.PasteFrom 'Clipboard',
  },
}

return config
