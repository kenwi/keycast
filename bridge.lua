-- Keycast's Hyprland input observer.
--
-- This file runs only after the user enables the plugin's managed bridge
-- block in hyprland.lua. It does not open /dev/input, evdev, sockets,
-- subprocesses, or network connections. Hyprland calls the callback with a
-- numeric key code and press/release state. The bridge keeps an in-memory
-- set of currently held codes and emits that snapshot as a custom event.
--
-- Nothing is written to disk. There is no history buffer. Repeat events are
-- ignored. The overlay decides whether to display the snapshot.
local STATE_NAME = "__keycast_bridge_state"
local PREFIX = "keycast:v1:held:"

local existing = rawget(_G, STATE_NAME)
if type(existing) == "table" then
  existing.held = {}
  existing.order = {}
  existing.last = nil
  existing.emitting = false
  return
end

local bridge = {
  held = {},
  order = {},
  last = nil,
  emitting = false,
}
_G[STATE_NAME] = bridge

local function event_value(event, key, fallback)
  if type(event) ~= "table" then return fallback end
  local value = event[key]
  if value == nil then return fallback end
  return value
end

local function snapshot()
  if #bridge.order == 0 then return PREFIX end
  return PREFIX .. table.concat(bridge.order, ",")
end

local function emit()
  local payload = snapshot()
  if payload == bridge.last or bridge.emitting then return end
  bridge.last = payload
  bridge.emitting = true
  pcall(function() hl.dispatch(hl.dsp.event(payload)) end)
  bridge.emitting = false
end

local function remove_code(code)
  if not bridge.held[code] then return false end
  bridge.held[code] = nil
  for i = #bridge.order, 1, -1 do
    if bridge.order[i] == code then
      table.remove(bridge.order, i)
      break
    end
  end
  return true
end

hl.on("input.keyboard.key", function(keycode, timestamp, event_state)
  local code, state
  if type(keycode) == "table" then
    code = tonumber(event_value(keycode, "keycode", event_value(keycode, "code", 0)))
    state = tonumber(event_value(keycode, "state", -1))
  else
    code = tonumber(keycode)
    state = tonumber(event_state)
  end
  -- 0 = release, 1 = press. Ignore repeats and malformed events.
  if not code or code < 1 or (state ~= 0 and state ~= 1) then return end

  if state == 1 then
    if bridge.held[code] then return end
    bridge.held[code] = true
    bridge.order[#bridge.order + 1] = code
  else
    if not remove_code(code) then return end
  end
  emit()
end)
