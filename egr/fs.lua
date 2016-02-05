setfenv(1, require'egr.ns')

local fs = {}

local script_path = lfs.currentdir() .. '/' .. glue.bin

function fs.script_path()
	return script_path
end

function fs.split_path(path)
	local dir, file = path:match'^(.-)[/]([^/]+)$'
	return dir, file
end

function fs.mkdir(path) --recursive mkdir
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
		path = fs.split_path(path)
	end
	error(err)
end

function fs.mkdir_for(path)
	local dir = fs.split_path(path)
	fs.mkdir(dir)
end

function fs.dir(path, func) --recursive dir
	if not func then
		return coroutine.wrap(function()
			fs.dir(path, coroutine.yield)
		end)
	end
	for file in lfs.dir(path) do
		local path = path .. '/' .. file
		local mode = lfs.attributes(path, 'mode')
		if mode == 'directory' then
			if file ~= '.' and file ~= '..' then
				func(path, mode)
				fs.dir(path, func)
			end
		else
			func(path, mode)
		end
	end
end

function fs.file_exists(path, type)
	return lfs.attributes(path, 'mode') == (type or 'file')
end

function fs.read_file(path, callback)
	local f = assert(io.open(path, 'rb'))
	local sz = 1024 * 16
	local buf = ffi.new('uint8_t[?]', sz)
	while true do
		local len = assert(stdio.read(f, buf, sz))
		if len > 0 then
			callback(buf, len)
		end
		if len < sz then break end
	end
	f:close()
end

--TODO: use sendfile(2) on Linux
function fs.copy_file(src_path, dst_path)
	local f = assert(io.open(dst_path, 'wb'))
	fs.read_file(src_path, function(buf, len)
		assert(stdio.write(f, buf, len))
	end)
	f:close()
end

return fs
