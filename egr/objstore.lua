setfenv(1, require'egr.ns')

--[[

content-addressable object store

	objstore:new(backend, backend_args...) -> store
	store:store_string(s) -> hash
	store:move_file(path) -> hash
	store:copy_file(path) -> hash
	store:get_string(hash) -> s | nil
	store:get_file(hash) -> filename | nil
	store:remove(hash)

upcoming features:

	- abort on I/O errors
	- async I/O queue
	- mirroring
		- async on backup mirrors even when sync op requested
	- spreading on multiple disks
		- spread policy based on free space
	- mysql backend
	- transparent encryption (dokan, osxfuse, fuse)
		- need dokan or pismo on Windows (dokan has problems with mmap)
			- see how maidsafe uses it

]]

local hash_digest = sha2.sha256_digest

--objstore

local objstore = class()

function objstore:init_filesystem(path)
	self._basepath = fs.script_path() .. '/' .. path
end

function objstore:init(backend, ...)
	self['init_'..backend](self, ...)
end

function objstore:get_path(hash)
	local hash = glue.tohex(hash)
	-- 3-level deep, up to 4096 files per directory and 2^36 directories.
	return self._basepath .. '/' ..
		hash:gsub('^(...)(...)(...)', '%1/%2/%3/')
end

function objstore:get_file(hash)
	local path = self:get_path(hash)
	return fs.file_exists(path) and path or nil
end

function objstore:store_string(s)
	local digest = hash_digest()
	digest(s)
	local hash = digest()
	local path = self:get_path(hash)
	if not fs.file_exists(path) then
		fs.mkdir_for(path)
		glue.writefile(path, s)
	end
	return hash
end

function objstore:get_string(hash)
	local path = self:get_file(hash)
	return path and glue.readfile(path)
end

function objstore:store_value(x)
	return self:store_string(pp.format(x, '\t'))
end

function objstore:get_value(hash)
	local s = self:get_string(hash)
	return s and loadstring('	return '..s)()
end

function objstore:hash_file(path)
	local digest = hash_digest()
	fs.read_file(path, digest)
	return digest()
end

function objstore:move_file(path)
	local hash = self:hash_file(path)
	local dst_path = self:get_path(hash)
	if not fs.file_exists(dst_path) then
 		fs.mkdir_for(dst_path)
		assert(os.rename(path, dst_path))
	end
	return hash
end

function objstore:copy_file(path)
	local hash = self:hash_file(path)
	local dst_path = self:get_path(hash)
	if not fs.file_exists(dst_path) then
		fs.mkdir_for(dst_path)
		fs.copy_file(path, dst_path)
	end
	return hash
end

function objstore:remove(hash)
	local path = self:get_path(hash)
	if fs.file_exists(path) then
		assert(os.remove(path))
	end
	local dir = fs.split_path(path)
	while dir and fs.file_exists(dir, 'directory') do
		lfs.rmdir(dir)
		dir = fs.split_path(dir)
	end
end


if not ... then

	local store = objstore:new('filesystem', '.objstore')

	local s = 'hello!'
	local hash = store:store_string(s)
	assert(store:get_string(hash) == s)
	store:remove(hash)

	local s = 'hello2!'
	local file = 'objstore-test'
	glue.writefile(file, s)
	local hash = store:move_file(file)
	assert(store:get_string(hash) == s)
	store:remove(hash)

	local s = 'hello3!'
	local file = 'objstore-test'
	glue.writefile(file, s)
	local hash = store:copy_file(file)
	assert(os.remove(file))
	assert(store:get_string(hash) == s)
	store:remove(hash)

end

return objstore
