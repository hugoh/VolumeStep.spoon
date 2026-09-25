-- Busted tests for the VolumeStep Spoon using a mock hs environment.

local mock_hs
local VolumeStep

local function makeLogger()
	local l = { _infos = {} }
	l.f = function(fmt, ...) table.insert(l._infos, string.format(fmt, ...)) end
	return l
end

local function makeEvent(key, down, flags)
	local e = { _key = key, _down = down, _flags = flags or {} }
	function e:systemKey() return { key = self._key, down = self._down } end
	function e:getFlags() return self._flags end
	function e:setFlags(f)
		self._flags = f
		return self
	end
	function e:post()
		table.insert(mock_hs._posted, self)
		return self
	end
	return e
end

before_each(function()
	mock_hs = { _posted = {} }
	mock_hs.logger = { new = function() return makeLogger() end }
	mock_hs.eventtap = {
		event = {
			types = { systemDefined = 14 },
			newSystemKeyEvent = function(key, down) return makeEvent(key, down) end,
		},
		new = function(types, fn)
			local t = { _types = types, _fn = fn, _running = false }
			function t:start()
				self._running = true
				return self
			end
			function t:stop()
				self._running = false
				return self
			end
			function t:isEnabled() return self._running end
			mock_hs._tap = t
			return t
		end,
	}

	package.loaded.hs = nil
	_G.hs = mock_hs

	VolumeStep = dofile("init.lua")
end)

after_each(function() VolumeStep:stop() end)

local function press(key, down, flags) return mock_hs._tap._fn(makeEvent(key, down ~= false, flags)) end

describe("start/stop", function()
	it("is not running until started", function() assert.is_false(VolumeStep:isRunning()) end)

	it("start() taps system-defined events", function()
		VolumeStep:start()
		assert.is_true(VolumeStep:isRunning())
		assert.are.same({ 14 }, mock_hs._tap._types)
	end)

	it("stop() stops the tap", function()
		VolumeStep:start():stop()
		assert.is_false(VolumeStep:isRunning())
	end)
end)

describe("volume keys", function()
	before_each(function() VolumeStep:start() end)

	it("swallows a volume key and reposts it with Shift+Option", function()
		assert.is_true(press("SOUND_UP"))
		assert.are.equal(1, #mock_hs._posted)
		local posted = mock_hs._posted[1]
		assert.are.equal("SOUND_UP", posted._key)
		assert.is_true(posted._down)
		assert.are.same({ shift = true, alt = true }, posted._flags)
	end)

	it("reposts key-up too", function()
		press("SOUND_DOWN", false)
		assert.is_false(mock_hs._posted[1]._down)
	end)

	it("passes through keys already carrying Shift+Option, including its own reposts", function()
		assert.is_false(press("SOUND_UP", true, { shift = true, alt = true }))
		assert.are.equal(0, #mock_hs._posted)
	end)

	it("sends extra quarter steps on key-down when steps > 1", function()
		VolumeStep.steps = 2
		press("SOUND_UP")
		assert.are.equal(3, #mock_hs._posted)
		assert.are.same({ true, false, true }, {
			mock_hs._posted[1]._down,
			mock_hs._posted[2]._down,
			mock_hs._posted[3]._down,
		})
		press("SOUND_UP", false)
		assert.are.equal(4, #mock_hs._posted)
		assert.is_false(mock_hs._posted[4]._down)
	end)

	it("passes through other system keys", function()
		assert.is_false(press("PLAY"))
		assert.are.equal(0, #mock_hs._posted)
	end)
end)

describe("init", function()
	it("logs the loaded version", function()
		assert.are.equal(VolumeStep, VolumeStep:init())
		assert.are.same({ "Loaded VolumeStep vdev" }, VolumeStep.log._infos)
	end)
end)
