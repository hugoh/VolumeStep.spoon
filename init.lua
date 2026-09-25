-- vim: set ft=lua:

--- === VolumeStep ===
---
--- A Hammerspoon Spoon that makes the volume keys change the volume in quarter
--- steps (1/64, about 1.6%) instead of macOS's default 1/16, keeping the native
--- volume HUD.
---
--- macOS already does quarter steps when Shift+Option is held with a volume
--- key; VolumeStep swallows each volume key and re-sends it with those
--- modifiers held. For half steps (1/32, about 3.1%), set `VolumeStep.steps`
--- to 2 and each press sends two quarter steps.
---
--- Download: https://github.com/hugoh/VolumeStep.spoon/releases/latest

local obj = {}
obj.__index = obj

obj.name = "VolumeStep"
obj.version = "dev"
obj.author = "Hugo Haas"
obj.license = "MIT"
obj.homepage = "https://github.com/hugoh/VolumeStep.spoon"

obj.log = hs.logger.new("VolumeStep", "info")

--- VolumeStep:init()
--- Method
--- Called automatically by `hs.loadSpoon()`. Logs the loaded version.
function obj:init()
	self.log.f("Loaded %s v%s", self.name, self.version)
	return self
end

obj._tap = nil

--- VolumeStep.steps
--- Variable
--- Number of quarter steps (1/64) per volume key press. Defaults to 1 (quarter
--- steps); set to 2 for half steps (1/32).
obj.steps = 1

local VOLUME_KEYS = { SOUND_UP = true, SOUND_DOWN = true }
local QUARTER_STEP = { shift = true, alt = true }

function obj._handle(event)
	local key = event:systemKey()
	if not VOLUME_KEYS[key.key] then return false end
	local flags = event:getFlags()
	if flags.shift and flags.alt then return false end
	local function send(down) hs.eventtap.event.newSystemKeyEvent(key.key, down):setFlags(QUARTER_STEP):post() end
	if key.down then
		for _ = 2, obj.steps do
			send(true)
			send(false)
		end
	end
	send(key.down)
	return true
end

--- VolumeStep:isRunning() -> boolean
--- Method
--- Returns whether the volume keys are currently intercepted.
function obj:isRunning() return self._tap ~= nil and self._tap:isEnabled() end

--- VolumeStep:start() -> VolumeStep
--- Method
--- Starts intercepting the volume keys.
---
--- Returns:
---  * The VolumeStep object, for method chaining
function obj:start()
	if self:isRunning() then return self end
	self._tap = hs.eventtap.new({ hs.eventtap.event.types.systemDefined }, obj._handle):start()
	return self
end

--- VolumeStep:stop() -> VolumeStep
--- Method
--- Stops intercepting the volume keys, handing them back to macOS.
---
--- Returns:
---  * The VolumeStep object, for method chaining
function obj:stop()
	if self._tap then
		self._tap:stop()
		self._tap = nil
	end
	return self
end

return obj
