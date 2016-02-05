setfenv(1, require'egr.ns')

local shell = class()

function shell:load_objects()
	local workspace = config:get('workspace')
	--
end

function shell:init()

	local app = nw:app()

	local t = config:get('main_window', {})

	local w = t.w or 800
	local h = t.h or 500
	local d = app:active_display()
	local x = t.x or d.x + (d.w - w) / 2
	local y = t.y or d.y + (d.h - h) / 2

	local win = app:window{
		w = w,
		h = h,
		x = x,
		y = y,
		maximized = t.maximized,
		visible = false,
	}

	function win:repaint()
		local bmp = win:bitmap()
	end

	function win:keydown(key)
		if key == 'esc' then
			self:close()
		end
	end

	function win:closed()
		local x, y, w, h = self:normal_frame_rect()
		config:set('main_window', {
			w = w, h = h, x = x, y = y,
			maximized = self:ismaximized(),
		})
	end

	self.app = app
	self.win = win

	self:load_objects()
end

function shell:run()

	local fl = filelist:new()
	fl:checkin'../bin'
	fl:checkout'xx'
	local t = fl:freeze(fl)
	local hash = objstore:store_value(t)
	print(glue.tohex(hash))

	do return end

	self.win:show()
	self.app:run()
end

return shell
