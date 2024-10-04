---@alias align "start"|"end"|"center"
---@alias justify "start"|"end"|"center"

---@class Position
---@field x integer
---@field y integer

---@class Size
---@field width integer
---@field height integer

---@class Modifiers
---@field backgroundColor ccTweaked.colors.color?
---@field alignItems align?
---@field justifyContent justify?
---@field width (string | integer)?
---@field height (string | integer)?

---@class Component
---@field text string?
---@field modifiers Modifiers?
---@field children Component[]?

---@class LayoutCalculatedComponent: Component
---@field position Position

---@type Component
local root = {
  modifiers = {
    justifyContent = "center",
    alignItems = "center"
  },
  children = {
    {
      modifiers = {
        backgroundColor = colors.pink,
        width = "100%",
        height = "50%",
      }
    }
  }
}

---@type Component
local root = {
  modifiers = {
    justifyContent = "center",
    alignItems = "center"
  },
  children = {
    {
      modifiers = {
        backgroundColor = colors.pink,
        width = "100%",
        height = "50%",
      }
    }
  }
}

---comment Takes the percentage and returns a fraction
---@param percentage string
---@return number
local function parse_percentage(percentage)
  local digits = string.gsub(
    percentage,
    "%%",
    ""
  )

  local parsed_number = tonumber(digits)

  if type(parsed_number) ~= 'number' then
    error(string.format("Faulty percentage passed to parse_percentage: %s", percentage), 1)
  end

  return parsed_number
end

---@param calculations LayoutCalculatedComponent[]
---@param current_component Component
---@param start_position Position
---@param parent_size Size
local function calculate_layouts(calculations, current_component, start_position, parent_size)
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

  for _, child in pairs(current_component.children) do
    table.insert(calculations, calculate_layouts(calculations, child,))
    calculated_child = calculations[#calculations]
  end

  return calculations
end

---Side effects baby!
---@param monitor ccTweaked.peripherals.Monitor
---@param component Component
---@param start_position Position
---@param size Size
local function draw(monitor, component, start_position, size)
end
