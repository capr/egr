setfenv(1, require'egr.ns')

local fl = class()

function fl:init()
	self.map = map:new()
end

function fl:add(path, content_hash)
	self.map:set(path, glue.tohex(content_hash))
end

function fl:remove(path)
	self.map:set(path)
end

function fl:list()
	return self.map:pairs()
end

function fl:freeze()
	return self.map:freeze()
end

function fl:unfreeze(t)
	return self.map:unfreeze(t)
end

function fl:checkout(dst_path)
	for path, hash in self:list() do
		local hash = glue.fromhex(hash)
		local dst_path = dst_path .. '/' .. path
		fs.mkdir_for(dst_path)
		local src_path = objstore:get_file(hash)
		fs.copy_file(src_path, dst_path)
	end
end

function fl:add_dir(src_path)
	for path, mode in fs.dir(src_path) do
		if mode == 'file' then
			local hash = objstore:copy_file(path)
			self:add(path:sub(#src_path+2), hash)
		end
	end
end

return fl
