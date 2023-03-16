local status_ok, telescope = pcall(require, "telescope")
if not status_ok then
  return
end

local actions = require "telescope.actions"

telescope.setup {
  defaults = {

  },
  pickers = {
        find_files = {
        theme = "dropdown",
        }
  },
  extensions = {
    -- Your extension configuration goes here:
  },
}



