local payloads = {}
local handlers = {}

local binds = {}
local timers = {}
local down_keys = {}

hl = {
  dsp = {
    event = function(payload) return payload end,
  },
  dispatch = function(payload)
    payloads[#payloads + 1] = payload
  end,
  on = function(name, fn)
    handlers[name] = fn
  end,
  bind = function(key, fn, opts)
    binds[#binds + 1] = { key = key, fn = fn, opts = opts or {} }
    return { remove = function() end }
  end,
  get_cursor_pos = function() return { x = 10, y = 20 } end,
  is_key_down = function(key) return down_keys[key] == true end,
  timer = function(fn, opts)
    timers[#timers + 1] = { fn = fn, opts = opts or {} }
    return { set_enabled = function() end, set_timeout = function() end }
  end,
  unbind = function(key)
    local kept = {}
    for i = 1, #binds do
      if binds[i].key ~= key then kept[#kept + 1] = binds[i] end
    end
    binds = kept
  end,
}

dofile((os.getenv("KEYCAST_ROOT") or ".") .. "/bridge.lua")

local function key(code, state)
  handlers["input.keyboard.key"]({ keycode = code, state = state })
end

key(37, 1)
key(38, 1)
assert(payloads[1] == "keycast:v1:held:37", "ctrl down")
assert(payloads[2] == "keycast:v1:held:37,38", "ctrl+a")

key(38, 0)
assert(payloads[3] == "keycast:v1:held:37", "a up")
key(37, 0)
assert(payloads[4] == "keycast:v1:held:", "all up")

-- Repeats and duplicate presses must not emit.
key(38, 1)
key(38, 1)
key(38, 2)
assert(payloads[5] == "keycast:v1:held:38", "single press")
assert(#payloads == 5, "no repeat/duplicate")

-- Reloading the file must not register a second callback.
local before = #payloads
dofile((os.getenv("KEYCAST_ROOT") or ".") .. "/bridge.lua")
key(9, 1)
assert(#payloads == before + 1, "single listener after reload")
assert(payloads[#payloads] == "keycast:v1:held:9", "esc after reload")

local function bind_for(key, release)
  for i = 1, #binds do
    local item = binds[i]
    local is_release = item.opts.release == true
    if item.key == key and is_release == release then return item.fn end
  end
  return nil
end

local before_binds = #binds
dofile((os.getenv("KEYCAST_ROOT") or ".") .. "/bridge.lua")
assert(#binds == before_binds, "mouse binds registered once")
_G["__keycast_bridge_state"].pointerBound = nil
local wheels_before = #binds
dofile((os.getenv("KEYCAST_ROOT") or ".") .. "/bridge.lua")
assert(#binds == wheels_before + 4, "wheel binds install once when missing")

local left_down = bind_for("mouse:272", false)
assert(type(left_down) == "function", "left press bind")
left_down()
assert(payloads[#payloads] == "keycast:v1:pointer:down:left:10,20", "left press payload")
local left_up = bind_for("mouse:272", true)
left_up()
assert(payloads[#payloads] == "keycast:v1:pointer:up:left:10,20", "left release payload")
local wheel = bind_for("mouse_down", false)
assert(type(wheel) == "function", "wheel bind")
wheel()
assert(payloads[#payloads] == "keycast:v1:pointer:pulse:wheel-down:10,20", "wheel payload")

local drag = timers[#timers]
assert(drag.opts.timeout == 50 and drag.opts.type == "repeat", "drag poll interval")
local before_move = #payloads
drag.fn()
assert(#payloads == before_move, "no move while buttons are up")
left_down()
drag.fn()
assert(payloads[#payloads] == "keycast:v1:pointer:move:left:10,20", "drag move payload")
local after_first = #payloads
drag.fn()
assert(#payloads == after_first, "drag move deduped")
hl.get_cursor_pos = function() return { x = 30, y = 40 } end
drag.fn()
assert(payloads[#payloads] == "keycast:v1:pointer:move:left:30,40", "drag move follows cursor")
local before_release = #payloads
left_up()
drag.fn()
assert(#payloads == before_release + 1, "no move after release")

print("bridge ok")
