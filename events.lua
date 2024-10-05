---@class Events
local Events = {}

---@class Range
---@field range_start integer
---@field range_end integer

---@class CallbackRecord
---@field callback function
---@field x_range Range
---@field y_range Range

---@type CallbackRecord[]

---@class LayoutCalculatedPressable: LayoutCalculatedComponent
---@field on_press function

---comment side effects
---@param registry CallbackRecord[]
---@param component LayoutCalculatedPressable
---@return  CallbackRecord[]
function register_pressable(registry, component)
  ---@type Range
  local x_range = {
    range_start = component.position.x + 1,
    range_end = component.position.x + component.modifiers.width,
  }

  ---@type Range
  local y_range = {
    range_start = component.position.y + 1,
    range_end = component.position.y + component.modifiers.height + 1,
  }

  ---@type CallbackRecord
  local record = {
    x_range = x_range,
    y_range = y_range,
    callback = component.on_press
  }

  table.insert(registry, record)
  return registry
end

---comment
---@param registry CallbackRecord[]
---@param press_position Position
---@return boolean -- `true` if event is handled
function Events.handle_press(registry, press_position)
  for _, record in pairs(registry) do
    if press_position.x >= record.x_range.range_start and press_position.x < record.x_range.range_end then
      if press_position.y >= record.y_range.range_start and press_position.y < record.y_range.range_end then
        record.callback()
      end
    end
  end
end

---More side effects!
---@param registry CallbackRecord[]
---@param current_component LayoutCalculatedComponent
---@return  CallbackRecord[]
function Events.register_all_pressables_recursive(registry, current_component)
  if current_component.on_press ~= nil then
    ---@cast current_component LayoutCalculatedPressable
    registry = register_pressable(registry, current_component)

    return registry
  end

  if current_component.children == nil then
    return registry
  end

  for _, child in pairs(current_component.children) do
    registry = Events.register_all_pressables_recursive(registry, child)
  end

  return registry
end

return Events
