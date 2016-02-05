--[[

content-addressable versioned object store

	vstore:new(backend_args...) -> store
	store:store_string(s, hash) -> hash
	store:move_file(path) -> hash
	store:copy_file(path) -> hash
	store:get_string(hash) -> s | nil
	store:get_path(hash) -> filename | nil
	store:remove(hash)

upcoming features:

	- auto-pack old files using rsync deltas
	- auto-delete files based on various policies: old, easy-to-find-again, etc.
	-

]]

local pp = require'pp'

local vstore = {}
vstore.__index = vstore

function vstore:new(objstore)
	local self = setmetatable({}, self)
	self.store = objstore
	return self
end

function vstore:store_entry(content_hash, parent_hash)
	local t = {
		content = content_hash,
		parent = parent_hash,
	}
	return self.store(pp.format(t))
end

function vstore:get_entry(hash, level)
	if level then
		for i = 1, level do
			hash = self:get_entry(hash).parent
		end
		return hash
	end
	return assert(loadstring('return '..self.store:get_string(hash)))
end

function vstore:store_string(s, parent)
	local content = self.store:set_string(s)
	self:store_entry(content, parent)
end

function vstore:get_string(hash)
	return self.store:get_string(self:get_entry(hash).content)
end

function vstore:get_parent(hash)
	return self:get_entry().parent
end

--[[
store:move_file(path) -> hash
store:copy_file(path) -> hash
store:get_string(hash) -> s | nil
store:get_path(hash) -> filename | nil
store:remove(hash)
]]


if not ... then

	local store = vstore:new('filesystem', '.objstore')


end


return vstore
