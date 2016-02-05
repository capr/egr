
local gc = {}
gc.__index = gc

function gc:new(store, reg)
	self.store = store
	self.reg = reg
	self.reg:get('gc',
	self.store:get_string(')
end

function gc:register(getrefs)
	table.insert(self.holders, getrefs)
end

function gc:run()
	for i,holder in ipairs(self.holders) do
		--holder:
	end
end


return gc
