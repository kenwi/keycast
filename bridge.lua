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
local first = type(existing) ~= "table"
local bridge = first and {
  held = {},
  order = {},
  last = nil,
  emitting = false,
} or existing
if first then
  bridge.buttons = {}
  bridge.last_move = {}
  _G[STATE_NAME] = bridge
else
  bridge.held = {}
  bridge.order = {}
  bridge.last = nil
  bridge.emitting = false
  bridge.buttons = {}
  bridge.last_move = {}
end

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

local function emit_raw(payload)
  if bridge.emitting then return end
  bridge.emitting = true
  pcall(function() hl.dispatch(hl.dsp.event(payload)) end)
  bridge.emitting = false
end

local function emit()
  local payload = snapshot()
  if payload == bridge.last then return end
  bridge.last = payload
  emit_raw(payload)
end

local POINTER_BUTTONS = {
  { key = "mouse:272", id = "left" },
  { key = "mouse:273", id = "right" },
  { key = "mouse:274", id = "middle" },
  { key = "mouse:275", id = "back" },
  { key = "mouse:276", id = "forward" },
}
local POINTER_WHEELS = {
  { key = "mouse_up", id = "wheel-up" },
  { key = "mouse_down", id = "wheel-down" },
  { key = "mouse_left", id = "wheel-left" },
  { key = "mouse_right", id = "wheel-right" },
}

local function cursor_payload(phase, id)
  local x, y = 0, 0
  if type(hl.get_cursor_pos) == "function" then
    local pos = hl.get_cursor_pos()
    if type(pos) == "table" then
      x = math.floor(tonumber(pos.x) or 0)
      y = math.floor(tonumber(pos.y) or 0)
    end
  end
  return "keycast:v1:pointer:" .. phase .. ":" .. id .. ":" .. x .. "," .. y
end

local function bind_buttons()
  local opts = { non_consuming = true, ignore_mods = true }
  local up = { non_consuming = true, ignore_mods = true, release = true }
  for i = 1, #POINTER_BUTTONS do
    local id = POINTER_BUTTONS[i].id
    local key = POINTER_BUTTONS[i].key
    -- Replace only this exact button chord. Modifier chords such as
    -- Super+left click stay in place.
    if type(hl.unbind) == "function" then
      pcall(hl.unbind, key)
    end
    hl.bind(key, function()
      bridge.buttons[id] = true
      emit_raw(cursor_payload("down", id))
    end, opts)
    hl.bind(key, function()
      bridge.buttons[id] = nil
      emit_raw(cursor_payload("up", id))
    end, up)
  end
end

local function bind_wheels()
  local opts = { non_consuming = true, ignore_mods = true }
  local last_wheel = {}
  for i = 1, #POINTER_WHEELS do
    local id = POINTER_WHEELS[i].id
    local key = POINTER_WHEELS[i].key
    hl.bind(key, function()
      local now = os.clock()
      if last_wheel[id] and (now - last_wheel[id]) < 0.05 then return end
      last_wheel[id] = now
      emit_raw(cursor_payload("pulse", id))
    end, opts)
  end
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

if first then
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
end

bind_buttons()

if not bridge.pointerBound then
  bind_wheels()
  bridge.pointerBound = true
end

-- While a button is held, report cursor motion so the shell can slide the
-- ripple. This is the fastest rate the Mouse page offers. The shell drops
-- updates to match the follow rate. Held state comes from our own binds.
-- is_key_down does not accept mouse buttons and raises on every poll.
if bridge.dragTimer and type(bridge.dragTimer.set_enabled) == "function" then
  pcall(function() bridge.dragTimer:set_enabled(false) end)
end
if type(hl.timer) == "function" then
  bridge.dragTimer = hl.timer(function()
    for i = 1, #POINTER_BUTTONS do
      local item = POINTER_BUTTONS[i]
      if bridge.buttons[item.id] then
        local payload = cursor_payload("move", item.id)
        if bridge.last_move[item.id] ~= payload then
          bridge.last_move[item.id] = payload
          emit_raw(payload)
        end
      else
        bridge.last_move[item.id] = nil
      end
    end
  end, { timeout = 8, type = "repeat" })
end
