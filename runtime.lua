local Events = require 'events'
local Layout = require 'layout'
---@class Runtime
local Runtime = {}

function Runtime.trigger_rerender()
  os.queueEvent("render")
end

---@param monitor ccTweaked.peripherals.Monitor
---@param Root fun(): Component
---@param log_rerenders boolean
---@param event_handler fun(event_name: ccTweaked.os.event, ...): nil
function Runtime.main_queue(monitor, Root, log_rerenders, event_handler)
  ---@type CallbackRecord[]
  local event_registry = {}

  -- initial render
  event_registry = Layout.mount(monitor, Root, event_registry)

  -- main loop
  while true do
    local event, side, x, y = os.pullEvent()
    ---@cast x integer
    ---@cast y integer
    if event == 'render' then
      if log_rerenders then
        print("rerender!")
      end

      event_registry = {}
      event_registry = Layout.mount(monitor, Root, event_registry)
    end

    if event == 'monitor_touch' then
      Events.handle_press(event_registry, {
        x = x,
        y = y
      })
    end

    event_handler(event, side, x, y)
  end
end

return Runtime
