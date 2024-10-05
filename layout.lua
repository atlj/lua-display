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
---@field background_color ccTweaked.colors.color?
---@field foreground_color ccTweaked.colors.color?
---@field align_items align?
---@field justify_content justify?
---@field direction direction?
---@field width (string | integer)?
---@field height (string | integer)?

---@class Component
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
  local align_items = current_component.modifiers.align_items or "start"
  local width = current_component.modifiers.width or 0
  local height = current_component.modifiers.height or 0

  if type(width) == "string" then
    width = parent_size.width * parse_percentage(width)
  end

  if type(height) == "string" then
    height = parent_size.height * parse_percentage(height)
  end

  current_component.modifiers.width = width
  current_component.modifiers.height = height

  if current_component.children == nil then
    ---@cast current_component LayoutCalculatedComponent
    current_component.position = start_position
    return current_component
  end

  ---@type LayoutCalculatedComponent[]
  local calculated_children = {}
  local x_acc = 0
  local y_acc = 0
  local total_children_width = 0
  local total_children_height = 0

  for _, child in pairs(current_component.children) do
    local latest_child = calculate_layouts({
        -- We know that it's an integer by now
        ---@diagnostic disable-next-line: assign-type-mismatch
        width = current_component.modifiers.width,
        -- We know that it's an integer by now
        ---@diagnostic disable-next-line: assign-type-mismatch
        height = current_component.modifiers.height,
      },
      child,
      {
        x = x_acc,
        y = y_acc
      }
    )

    if direction == "vertical" then
      if latest_child.modifiers.width > total_children_width then
        -- We know that it's an integer by now
        ---@diagnostic disable-next-line: cast-local-type
        total_children_width = latest_child.modifiers.width
      end
    else
      -- We know that it's an integer by now
      ---@diagnostic disable-next-line: cast-local-type
      total_children_width = total_children_width + latest_child.modifiers.width
    end

    if direction == "horizontal" then
      if latest_child.modifiers.height > total_children_height then
        -- We know that it's an integer by now
        ---@diagnostic disable-next-line: cast-local-type
        total_children_height = latest_child.modifiers.height
      end
    else
      -- We know that it's an integer by now
      ---@diagnostic disable-next-line: cast-local-type
      total_children_height = total_children_height + latest_child.modifiers.height
    end

    if direction == "horizontal" then
      x_acc = x_acc + latest_child.modifiers.width
    else
      y_acc = y_acc + latest_child.modifiers.height
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

  ---@type LayoutCalculatedComponent[]
  local aligned_children = {}
  -- Handle the justify and align now
  if align_items == 'end' then
    for _, child in pairs(calculated_children) do
      if direction == "horizontal" then
        child.position.y = current_component.modifiers.height - child.modifiers.height
      else
        child.position.x = current_component.modifiers.width - child.modifiers.width
      end

      table.insert(aligned_children, child)
    end
  elseif align_items == 'center' then
    for _, child in pairs(calculated_children) do
      if direction == "horizontal" then
        child.position.y = (current_component.modifiers.height / 2) - (child.modifiers.height / 2)
      else
        child.position.x = (current_component.modifiers.width / 2) - (child.modifiers.width / 2)
      end

      table.insert(aligned_children, child)
    end
  else
    aligned_children = calculated_children
  end

  calculated_children = aligned_children

  ---@cast current_component LayoutCalculatedComponent
  current_component.children = calculated_children
  current_component.position = start_position
  return current_component
end

---@class Text: Component
---@field text string

---@param input Text
---@return Text
function Text(input)
  local modifiers = input.modifiers or {}

  if modifiers.foreground_color == nil then
    modifiers.foreground_color = colors.black
  end

  if modifiers.width == nil then
    modifiers.width = #input.text
  end

  if modifiers.height == nil then
    modifiers.height = 1
  end

  ---@type Text
  return {
    children = input.children,
    modifiers = modifiers,
    text = input.text
  }
end

---comment
---@param input Component
---@return Component
function Stack(input)
  local modifiers = input.modifiers or {}

  ---@type Component
  return {
    children = input.children,
    modifiers = modifiers,
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

---side effects but recursive x_x
---@param monitor ccTweaked.peripherals.Monitor
---@param component LayoutCalculatedComponent
---@param parent_color ccTweaked.colors.color
local function draw_recursive(monitor, component, parent_color)
  local background_color = component.modifiers.background_color or parent_color
  monitor.setBackgroundColor(background_color)

  for y = component.position.y, component.position.y + component.modifiers.height - 1 do
    local row = ""
    if component.text ~= nil then
      ---@cast component Text
      -- TODO: add text align stuff
      row = component.text
      monitor.setTextColor(component.modifiers.foreground_color)
    else
      for x = component.position.x, component.position.x + component.modifiers.width - 1 do
        row = row .. " "
      end
    end

    monitor.setCursorPos(component.position.x + 1, y + 1)
    monitor.write(row)
  end

  -- First draw the parent, and then call this on children
  if component.children == nil then
    return
  end

  for _, child in pairs(component.children) do
    ---@cast child LayoutCalculatedComponent
    child.position.x = child.position.x + component.position.x
    child.position.y = child.position.y + component.position.y
    draw_recursive(monitor, child, background_color)
  end
end

---Side effects baby!
---@param monitor ccTweaked.peripherals.Monitor
---@param component Component
---@param size Size
local function mount(monitor, component, size)
  local layout_calculated_component = calculate_layouts(
    size,
    component,
    {
      x = 0,
      y = 0
    }
  )

  draw_recursive(monitor, layout_calculated_component, colors.black)
end
