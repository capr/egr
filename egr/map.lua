setfenv(1, require'egr.ns')

local map = class()

function map:init()
	self.t = {}
end

function map:set(k, v)
	self.t[k] = v
end

function map:get(k)
	return self.t[k]
end

function map:pairs()
	return pairs(self.t)
end

function map:freeze()
	return self.t
end

function map:unfreeze(t)
	self.t = t
end

return map

