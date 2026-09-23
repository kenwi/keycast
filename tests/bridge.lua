local payloads = {}
local handlers = {}

local binds = {}

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
dofile((os.getenv("KEYCAST_ROOT") or ".") .. "/bridge.lua")
assert(#binds == before_binds + 14, "pointer binds install once when missing")

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

print("bridge ok")
