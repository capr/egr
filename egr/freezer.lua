setfenv(1, require'egr.ns')

local freezer = class()

function freezer:init()
end

function freezer:getclass(classname)
	--
end

function freezer:getclassname(obj)
	--
end

function freezer:freeze(obj)
	local pack = {}
	pack.content = obj:freeze()
	pack.class = self:getclassname(obj)
	return objstore:store_value(pack)
end

function freezer:unfreeze(hash)
	local pack = objstore:get_value(hash)
	local class = self:getclass(pack.class)
	return class:unfreeze(pack.content)
end

return freezer
