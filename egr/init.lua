io.stdout:setvbuf'no'
io.stderr:setvbuf'no'
require'strict'

local ns = require'egr.ns'

--lua modules

for k,v in pairs(_G) do
	ns[k] = v
end

setfenv(1, ns)

--luapower modules

_ = string.format
ffi = require'ffi'
nw = require'nw'
glue = require'glue'
pp = require'pp'
lfs = require'lfs'
sha2 = require'sha2'
stdio = require'stdio'
time = require'time'

function class()
	local c = {}
	c.__index = c
	function c:new(...)
		local self = setmetatable({}, self)
		if self.init then
			self:init(...)
		end
		return self
	end
	return c
end

--egr modules

registry = require'egr.registry'
objstore = require'egr.objstore'
fs = require'egr.fs'
map = require'egr.map'
filelist = require'filelist'
shell = require'egr.shell'
freezer = require'egr.freezer'
repo = require'egr.repo'

--singletons

config = registry:new'egr.config'
objstore = objstore:new('filesystem', config:get('objstore_path', '.objstore'))
freezer = freezer:new()

shell = shell:new()

--run shell

shell:run()
