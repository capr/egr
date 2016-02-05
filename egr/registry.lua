setfenv(1, require'egr.ns')

local reg = class()

function reg:init(regfile)
	self.regfile = fs.script_path() .. '/' .. regfile
	self:load()
end

function reg:load()
	local s = glue.readfile(self.regfile)
	self.t = s and loadstring('return '..s)() or {}
end

function reg:save()
	local s = pp.format(self.t, '\t')
	fs.mkdir_for(self.regfile)
	glue.writefile(self.regfile, s)
end

function reg:get(key, default)
	local v = self.t[key]
	if v == nil then
		v = default
		self:set(key, v)
	end
	return v
end

function reg:set(key, val)
	self.t[key] = val
	self:save()
end

return reg
