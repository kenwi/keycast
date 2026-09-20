local payloads = {}
local handlers = {}

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

print("bridge ok")
