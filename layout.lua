---@generic T
---@param t1 T[]
---@param t2 T[]
---@return T[]
local function table_concat(t1, t2)
  for i = 1, #t2 do
    t1[#t1 + 1] = t2[i]
  end
  return t1
end

---@alias align "start"|"end"|"center"
---@alias justify "start"|"end"|"center"
---@alias direction "horizontal"|"vertical"

---@class Position
---@field x integer
---@field y integer

---@class Size
---@field width integer
---@field height integer

---@class Modifiers
---@field backgroundColor ccTweaked.colors.color?
---@field alignItems align?
---@field justify_content justify?
---@field direction direction?
---@field width (string | integer)?
---@field height (string | integer)?

---@class Component
---@field text string?
---@field modifiers Modifiers?
---@field children Component[]?

---@class LayoutCalculatedComponent: Component
---@field position Position

---comment Takes the percentage and returns a fraction
---@param percentage string
---@return number
local function parse_percentage(percentage)
  local digits = string.gsub(
    percentage,
    "%%",
    ""
  )

  local parsed_number = tonumber(digits) / 100

  if type(parsed_number) ~= 'number' then
    error(string.format("Faulty percentage passed to parse_percentage: %s", percentage), 1)
  end

  return parsed_number
end

---@param parent_size Size
---@param current_component Component
---@param start_position Position
---@return LayoutCalculatedComponent
local function calculate_layouts(parent_size, current_component, start_position)
  local direction = current_component.modifiers.direction or "horizontal"
  local justify_content = current_component.modifiers.justify_content or "start"
  local width = current_component.modifiers.width or 0

  if width == 0 and current_component.text ~= nil then
    width = #current_component.text
  end

  if type(width) == "string" then
    width = parent_size.width * parse_percentage(width)
  end

  local height = current_component.modifiers.height or 0

  if type(height) == "string" then
    height = parent_size.height * parse_percentage(height)
  end

  current_component.modifiers.width = width
  current_component.modifiers.height = height


  if current_component.children == nil then
    ---@type LayoutCalculatedComponent
    return {
      children = nil,
      modifiers = current_component.modifiers,
      text = current_component.text,
      position = start_position
    }
  end

  ---@type LayoutCalculatedComponent[]
  local calculated_children = {}
  local x_acc = 0
  local y_acc = 0
  local total_children_width = 0
  local total_children_height = 0

  for _, child in pairs(current_component.children) do
    ---@type Position
    local pos = {
      x = start_position.x + x_acc,
      y = start_position.y + y_acc
    }

    local latest_child = calculate_layouts({
      width = current_component.modifiers.width,
      height = current_component.modifiers.height,
    }, child, pos)

    total_children_width = total_children_width + latest_child.modifiers.width
    total_children_height = total_children_height + latest_child.modifiers.height

    if direction == "vertical" then
      y_acc = y_acc + latest_child.position.y
    else
      x_acc = x_acc + latest_child.position.x
    end

    table.insert(calculated_children, latest_child)
  end

  -- update self height and width if they are smaller than children
  if total_children_width > current_component.modifiers.width then
    current_component.modifiers.width = total_children_width
  end

  if total_children_height > current_component.modifiers.height then
    current_component.modifiers.height = total_children_height
  end

  ---@type LayoutCalculatedComponent[]
  local justified_children = {}
  -- Handle the justify and align now
  if justify_content == 'end' then
    -- pretty easy, just use the self width/height, and update children positions
    local acc = 0
    for _, child in pairs(calculated_children) do
      if direction == "vertical" then
        child.position.y = start_position.y + current_component.modifiers.height - total_children_height + acc
        acc = acc + child.modifiers.height
      else
        child.position.x = start_position.x + current_component.modifiers.width - total_children_width + acc
        acc = acc + child.modifiers.width
      end

      table.insert(justified_children, child)
    end
  elseif justify_content == 'center' then
    local acc = 0
    for _, child in pairs(calculated_children) do
      if direction == "vertical" then
        child.position.y = start_position.y + (current_component.modifiers.height / 2) - (total_children_height / 2) +
            acc
        acc = acc + child.modifiers.height
      else
        child.position.x = start_position.x + (current_component.modifiers.width / 2) - (total_children_width / 2) + acc
        acc = acc + child.modifiers.width
      end

      table.insert(justified_children, child)
    end
  else
    justified_children = calculated_children
  end

  calculated_children = justified_children

  -- handle align now

  ---@type LayoutCalculatedComponent
  return {
    children = calculated_children,
    modifiers = current_component.modifiers,
    text = current_component.text,
    position = start_position
  }
end

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

---@type Component
local root = {
  modifiers = {
    justify_content = "center",
    alignItems = "center",
    direction = "horizontal",
    width = "100%",
    height = "100%"
  },
  children = {
    {
      modifiers = {
        backgroundColor = 3,
        width = 20,
        height = "50%",
      }
    },
    {
      modifiers = {
        backgroundColor = 3,
        width = 20,
        height = "50%",
      }
    }
  }
}

tprint(
  calculate_layouts(
    {
      width = 100,
      height = 100
    },
    root,
    {
      x = 0,
      y = 0
    }
  )
  , 2
)

---Side effects baby!
---@param monitor ccTweaked.peripherals.Monitor
---@param component Component
---@param start_position Position
---@param size Size
local function draw(monitor, component, start_position, size)
end
