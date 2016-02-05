setfenv(1, require'egr.ns')

local repo = class()

function repo:init()
	self.t = {}
	self.root_commit = nil
	self.current_commit = nil
end

function repo:tree()
	return self.t
end

function repo:create_commit(content_hash, message, parent_commit)
	local commit = {}
	commit.content = content_hash
	commit.message = message
	parent_commit = parent_commit or self.current_commit
	if parent_commit then
		table.insert(parent_commit, commit)
	else
		self.root_commit = commit
	end
	return commit
end

function repo:set_commit(commit)
	if self.current_commit then
		self.current_commit.current = nil
	end
	self.current_commit = commit
	commit.current = true
end

function repo:commit(...)
	local commit = self:create_commit(...)
	self:set_commit(commit)
end

function repo:freeze()
	local t = {}
	t.root_commit = self.root_commit
	return t
end

function repo:walk_commits(root_commit, func)
	if not func then
		return coroutine.wrap(function()
			self:walk_commits(root_commit, coroutine.yield)
		end)
	end
	root_commit = root_commit or self.root_commit
	for i,commit in ipairs(root_commit) do
		func(commit)
		self:walk_commits(commit, func)
	end
end

function repo:unfreeze(t)
	self.root_commit = t.root_commit
	self.current_commit = self.root_commit
	for commit in self:walk_commits() do
		if commit.current then
			self.current_commit = commit
		end
	end
end

return repo
