local Layout = require "layout"
local Components = Layout.Components

-- Print contents of `tbl`, with indentation.
-- `indent` sets the initial level of indentation.
function tprint(tbl, indent)
  if not indent then indent = 0 end
  for k, v in pairs(tbl) do
    formatting = string.rep("  ", indent) .. k .. ": "
    if type(v) == "table" then
      print(formatting)
      tprint(v, indent + 1)
    elseif type(v) == 'boolean' then
      print(formatting .. tostring(v))
    else
      print(formatting .. v)
    end
  end
end

local root = Components.Stack {
  modifiers = {
    width = "100%",
    height = "100%",
    direction = "horizontal",
    justify_content = "center",
    align_items = "center"
  },
  children = {
    Components.Text {
      text = "Test"
    },
    Components.Text {
      text = "Test2"
    }
  }
}

local calculated = Layout.calculate_layouts(
  { width = 100, height = 100 },
  root,
  {
    x = 0,
    y = 0
  }
)

tprint(calculated, 2)
