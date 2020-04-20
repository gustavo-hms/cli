local global_ipairs = ipairs
local table = table
local global_pairs = pairs
local setmetatable = setmetatable

local _ENV = {}

local metatable = {}
metatable.__index = metatable

function metatable:__call()
	return self:next()
end

function wrap(generator)
	return function(...)
		local next_, invariant, control = generator(...)

		local iterator = {
			next = function()
				local a, b, c, d, e = next_(invariant, control)
				control = a
				return a, b, c, d, e
			end
		}

		return setmetatable(iterator, metatable)
	end
end

function new(next_)
	local iterator = { next = next_ }
	return setmetatable(iterator, metatable)
end

function metatable:map(fn)
	return new(function()
		local a, b, c, d, e = self:next()
		if a == nil then return nil end
		return fn(a, b, c, d, e)
	end)
end

function metatable:filter(predicate)
	return new(function()
		while true do
			local a, b, c, d, e = self:next()
			if a == nil then return nil end
			if predicate(a,b,c,d,e) then return a, b, c, d, e end
		end
	end)
end

function metatable:find(predicate)
	while true do
		local a, b, c, d, e = self:next()
		if a == nil then return end

		if predicate(a,b,c,d,e) then
			return a, b, c, d, e
		end
	end
end

function metatable:array()
	local t = {}

	while true do
		local value = self:next()
		if value == nil then break end
		t[#t+1] = value
	end

	return t
end

function metatable:sort(less_than)
	local t = self:array()
	table.sort(t, less_than)
	return t
end

function metatable:concat(separator)
	local t = self:array()
	return table.concat(t, separator)
end

ipairs = wrap(global_ipairs)
pairs = wrap(global_pairs)

function sequence(t)
	local i = 0
	return new(function()
		i = i + 1
		return t[i]
	end)
end

function chain(...)
	local iterators = {...}
	local current = 1
	return new(function()
		while current <= #iterators do
			local a, b, c, d, e = iterators[current]:next()
			if a == nil then
				current = current + 1
			else
				return a, b, c, d, e
			end
		end

		return nil
	end)
end

function once(element)
	local already_returned = false
	return new(function()
		if already_returned then return nil end
		already_returned = true
		return element
	end)
end

return _ENV
