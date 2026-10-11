-- Busted tests for the VolumeStep Spoon using the shared hs_mock from spoon-tools.

local hs_mock = require("hs_mock")

local ctl
local VolumeStep

before_each(function()
	local hs
	hs, ctl = hs_mock.new()
	_G.hs = hs

	VolumeStep = dofile("init.lua")
end)

after_each(function() VolumeStep:stop() end)

local function tap() return ctl.taps[#ctl.taps] end

local function wakeWatcher() return ctl.caffeinateWatchers[#ctl.caffeinateWatchers] end

-- Calls the tap's callback directly, as macOS would, whatever the tap's state.
local function press(key, down, flags)
	return tap()._fn(ctl.newEvent({
		type = hs.eventtap.event.types.systemDefined,
		systemKey = { key = key, down = down ~= false },
		flags = flags,
	}))
end

describe("start/stop", function()
	it("is not running until started", function() assert.is_false(VolumeStep:isRunning()) end)

	it("start() taps system-defined events", function()
		VolumeStep:start()
		assert.is_true(VolumeStep:isRunning())
		assert.are.same({ 14 }, tap()._types)
	end)

	it("stop() stops the tap", function()
		VolumeStep:start():stop()
		assert.is_false(VolumeStep:isRunning())
	end)
end)

describe("tap recovery", function()
	it("re-enables a tap that macOS disabled when the system wakes", function()
		VolumeStep:start()
		tap()._enabled = false
		wakeWatcher()._fn(hs.caffeinate.watcher.systemDidWake)
		assert.is_true(VolumeStep:isRunning())
	end)

	it("re-enables the tap when the screen unlocks", function()
		VolumeStep:start()
		tap()._enabled = false
		wakeWatcher()._fn(hs.caffeinate.watcher.screensDidUnlock)
		assert.is_true(VolumeStep:isRunning())
	end)

	it("leaves a healthy tap alone", function()
		VolumeStep:start()
		local current = tap()
		wakeWatcher()._fn(hs.caffeinate.watcher.systemDidWake)
		assert.are.equal(current, VolumeStep._tap)
	end)

	it("ignores unrelated power events", function()
		VolumeStep:start()
		tap()._enabled = false
		wakeWatcher()._fn(hs.caffeinate.watcher.systemWillSleep)
		assert.is_false(VolumeStep:isRunning())
	end)

	it("stop() stops the wake watcher so the keys aren't reclaimed", function()
		VolumeStep:start():stop()
		assert.is_false(wakeWatcher()._running)
		wakeWatcher()._fn(hs.caffeinate.watcher.systemDidWake)
		assert.is_false(VolumeStep:isRunning())
	end)
end)

describe("volume keys", function()
	before_each(function() VolumeStep:start() end)

	it("swallows a volume key and reposts it with Shift+Option", function()
		assert.is_true(press("SOUND_UP"))
		assert.are.equal(1, #ctl.posted)
		local posted = ctl.posted[1]
		assert.are.equal("SOUND_UP", posted:systemKey().key)
		assert.is_true(posted:systemKey().down)
		assert.are.same({ shift = true, alt = true }, posted:getFlags())
	end)

	it("reposts key-up too", function()
		press("SOUND_DOWN", false)
		assert.is_false(ctl.posted[1]:systemKey().down)
	end)

	it("passes through keys already carrying Shift+Option, including its own reposts", function()
		assert.is_false(press("SOUND_UP", true, { shift = true, alt = true }))
		assert.are.equal(0, #ctl.posted)
	end)

	it("sends extra quarter steps on key-down when steps > 1", function()
		VolumeStep.steps = 2
		press("SOUND_UP")
		assert.are.equal(3, #ctl.posted)
		assert.are.same({ true, false, true }, {
			ctl.posted[1]:systemKey().down,
			ctl.posted[2]:systemKey().down,
			ctl.posted[3]:systemKey().down,
		})
		press("SOUND_UP", false)
		assert.are.equal(4, #ctl.posted)
		assert.is_false(ctl.posted[4]:systemKey().down)
	end)

	it("passes through other system keys", function()
		assert.is_false(press("PLAY"))
		assert.are.equal(0, #ctl.posted)
	end)
end)

describe("configure", function()
	it("sets steps and returns self", function()
		assert.are.equal(VolumeStep, VolumeStep:configure({ steps = 2 }))
		assert.are.equal(2, VolumeStep.steps)
	end)

	it("rejects invalid steps", function()
		assert.has_error(function() VolumeStep:configure({ steps = 0 }) end)
		assert.has_error(function() VolumeStep:configure({ steps = 1.5 }) end)
		assert.are.equal(1, VolumeStep.steps)
	end)

	it("rejects unknown options", function()
		assert.has_error(function() VolumeStep:configure({ stpes = 2 }) end)
	end)
end)

describe("init", function()
	it("logs the loaded version", function()
		assert.are.equal(VolumeStep, VolumeStep:init())
		assert.are.same({ "Loaded VolumeStep vdev" }, ctl.logged("info"))
	end)
end)
