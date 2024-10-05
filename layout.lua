local colors = require "colors"
local Events = require "events"

---@class Components
local Components = {}

---@class Layout
local Layout = {}

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
---@field flex integer?
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
---@return LayoutCalculatedComponent
function Layout.calculate_layouts(parent_size, current_component)
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
    current_component.position = { x = 0, y = 0 }
    return current_component
  end

  ---@type LayoutCalculatedComponent[]
  local calculated_children = {}
  local total_flex_value = 0
  local total_children_width = 0
  local total_children_height = 0

  for _, child in pairs(current_component.children) do
    local latest_child = Layout.calculate_layouts({
        -- We know that it's an integer by now
        ---@diagnostic disable-next-line: assign-type-mismatch
        width = current_component.modifiers.width,
        -- We know that it's an integer by now
        ---@diagnostic disable-next-line: assign-type-mismatch
        height = current_component.modifiers.height,
      },
      child
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

    total_flex_value = total_flex_value + (latest_child.modifiers.flex or 0)

    table.insert(calculated_children, latest_child)
  end

  -- update self height and width if they are smaller than children
  if total_children_width > current_component.modifiers.width then
    current_component.modifiers.width = total_children_width
  end

  if total_children_height > current_component.modifiers.height then
    current_component.modifiers.height = total_children_height
  end

  -- Calculate flex

  local free_available_parent_space = 0
  if direction == 'vertical' then
    free_available_parent_space = current_component.modifiers.height - total_children_height
  else
    free_available_parent_space = current_component.modifiers.width - total_children_width
  end

  for _, child in pairs(calculated_children) do
    if child.modifiers.flex ~= nil and child.modifiers.flex > 0 then
      local relative_flex = child.modifiers.flex / total_flex_value
      local space_to_expand = math.ceil(free_available_parent_space * relative_flex)
      if direction == 'vertical' then
        child.modifiers.height = child.modifiers.height + space_to_expand
        total_children_height = current_component.modifiers.height
      else
        child.modifiers.width = child.modifiers.width + space_to_expand
        total_children_width = current_component.modifiers.width
      end
    end
  end

  -- Calculate justify

  ---@type LayoutCalculatedComponent[]
  local justified_children = {}
  local acc = 0
  for _, child in pairs(calculated_children) do
    if justify_content == 'end' then
      if direction == "vertical" then
        child.position.y = current_component.modifiers.height - total_children_height + acc
        acc = acc + child.modifiers.height
      else
        child.position.x = current_component.modifiers.width - total_children_width + acc
        acc = acc + child.modifiers.width
      end

      table.insert(justified_children, child)
    elseif justify_content == 'center' then
      if direction == "vertical" then
        child.position.y = (current_component.modifiers.height / 2) - (total_children_height / 2) +
            acc
        acc = acc + child.modifiers.height
      else
        child.position.x = (current_component.modifiers.width / 2) - (total_children_width / 2) + acc
        acc = acc + child.modifiers.width
      end

      table.insert(justified_children, child)
    else
      if direction == "vertical" then
        child.position.y = acc
        acc = acc + child.modifiers.height
      else
        child.position.x = acc
        acc = acc + child.modifiers.width
      end

      table.insert(justified_children, child)
    end
  end

  calculated_children = justified_children

  -- Calculate align

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
  current_component.position = { x = 0, y = 0 }
  return current_component
end

---@class Text: Component
---@field text string

---@param input Text
---@return Text
function Components.Text(input)
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

---@class Pressable: Component
---@field on_press function

---@param input Pressable
---@return Pressable
function Components.Pressable(input)
  local modifiers = input.modifiers or {}

  ---@type Pressable
  return {
    children = input.children,
    modifiers = modifiers,
    on_press = input.on_press
  }
end

---comment
---@param input Component
---@return Component
function Components.Stack(input)
  local modifiers = input.modifiers or {}

  ---@type Component
  return {
    children = input.children,
    modifiers = modifiers,
  }
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
---@param mounter fun(): Component
---@param event_registry CallbackRecord[]
---@return  CallbackRecord[]
function Layout.mount(monitor, mounter, event_registry)
  local width, height = monitor.getSize()

  local layout_calculated_component = Layout.calculate_layouts(
    {
      width = width,
      height = height
    },
    mounter()
  )

  draw_recursive(monitor, layout_calculated_component, colors.black)

  return Events.register_all_pressables_recursive(event_registry, layout_calculated_component)
end

Layout.Components = Components

return Layout

-- Text size
-- padding margin gap
-- svg like type
