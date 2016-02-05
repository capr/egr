setfenv(1, require'egr.ns')

local repo = class()

function repo:init()
	self.t = {}
	self._branch = '
end

function repo:tree()
	return self.t
end

function repo:commit(content_hash, message)
	local t = {}
	t.content = content_hash
	t.parent = self.cursor
	t.message = message
end

function repo:checkout(branch, head_offset)
	--
end

function repo:rollback()

end

function repo:tree()

end

function repo:freeze()
	local t = {}
	t.root = self._root
	t.branch = self._branch
	t.head_offset = self:head_offset()
	t.commit = self:current_commit()
	return t
end

function repo:unfreeze(t)

end
