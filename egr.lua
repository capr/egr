
local reg = require'egr_registry'
local ost = require'egr_objstore'
local vst = require'egr_vobjstore'
local reg = require'egr_registry'

local nw = require'nw'

local conf = reg:new'.objstore/config'
local ost  = ost:new('filesystem', conf:get('objstore_path', '.objstore'))
local vst  = vst:new(ost)

local app = nw:app()

local t = conf:get('main_window', {})

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
	conf:set('main_window', {
		w = w, h = h, x = x, y = y,
		maximized = self:ismaximized(),
	})
end

win:show()

app:run()

