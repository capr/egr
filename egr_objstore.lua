
--content-addressable object store

local ffi = require'ffi'
local lfs = require'lfs'
local glue = require'glue'
local sha2 = require'sha2'
local stdio = require'stdio'
local _ = string.format

local objstore = {}
objstore.__index = objstore

local function splitpath(path)
	local dir, file = path:match'^(.-)[/]([^/]+)$'
	return dir, file
end

local function mkdir(path0) --recursive mkdir
	local path = path0
	local t = {}
	local ok, err
	if lfs.attributes(path, 'mode') == 'directory' then
		return
	end
	while path do
		ok, err = lfs.mkdir(path)
		if ok then
			for i=#t,1,-1 do
				assert(lfs.mkdir(t[i]))
			end
			return
		elseif err:find'^No such file' then
			table.insert(t, path)
		else
			break
		end
		path = splitpath(path)
	end
	error(_('%s for %s', err, path0))
end

function objstore:init_filesystem(path)
	self._basepath = glue.bin .. '/' .. path
end

function objstore:new(backend, ...)
	local self = setmetatable({}, self)
	self['init_'..backend](self, ...)
	return self
end

function objstore:hash(buf, len)
	return sha2.sha256(buf, len)
end

function objstore:hash_digest()
	return sha2.sha256_digest()
end

function objstore:hash_path(hash)
	local hash = glue.tohex(hash)
	-- 3-level deep, up to 4096 files per directory and 2^36 directories.
	return self._basepath .. '/' ..
		hash:gsub('^(...)(...)(...)', '%1/%2/%3/')
end

function objstore:store_string(s)
	local hash = self:hash(s)
	local path = self:hash_path(hash)
	local dir = splitpath(path)
	mkdir(dir)
	local f = assert(io.open(path, 'w'))
	f:write(s)
	f:close()
	return hash
end

function objstore:get_as_string(hash)
	local path = self:hash_path(hash)
	local f = assert(io.open(path, 'rb'))
	local s = assert(f:read'*a')
	f:close()
	return s
end

function objstore:move_file(path)
	local f = io.open(path, 'rb')
	local sz = 1024 * 16
	local buf = ffi.new('uint8_t[?]', sz)
	local digest = self:hash_digest()
	while true do
		local len = assert(stdio.read(f, buf, sz))
		if len > 0 then
			digest(buf, len)
		end
		if len < sz then break end
	end
	local hash = digest()
	f:close()
	local dst_path = self:hash_path(hash)
	if lfs.attributes(dst_path, 'mode') ~= 'file' then
		local dir = splitpath(dst_path)
		mkdir(dir)
		assert(os.rename(path, dst_path))
	end
	return hash
end

function objstore:copy_file(path)
	--
end

function objstore:get_as_file(hash)
	--
end

function objstore:get_as_mmap(hash)
	--
end

function objstore:remove(hash)
	local path = self:hash_path(hash)
	assert(os.remove(path))
	path = splitpath(path)
	while path do
		lfs.rmdir(path)
		path = splitpath(path)
	end
end


if not ... then

	local store = objstore:new('filesystem', '.objstore')

	local s = 'hello!'
	local hash = store:store_string(s)
	local s1 = store:get_as_string(hash)
	assert(s == s1)
	store:remove(hash)

	local s = 'hello2!'
	local file = 'objstore-test'
	local f = io.open(file, 'wb')
	f:write(s)
	f:close()
	local hash = store:move_file(file)
	local s1 = store:get_as_string(hash)
	assert(s == s1)
	store:remove(hash)

end


return objstore
