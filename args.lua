local M = {}
setmetatable(M, {__index = _G})
local _ENV = M

boolean = "boolean"
number = "number"
string = "string"

local function split_at(pattern)
	return function(text)
		local left, right = text:match(pattern)

		if not right or #right == 0 then
			return left
		end

		return left, right
	end
end

local split_at_equal_sign = split_at("-?-?([^=]+)=?(.*)")
local split_at_comma = split_at("([^,]+),?(.*)")

local function starts_with_hyphen(text)
	return text:sub(1,1) == "-"
end

local function slice(t, first, last)
	if not last or last > #t then last = #t end

	if first > last then return { slice = slice } end

	local old = getmetatable(t)

	if old then
		first, last = first + old.first - 1, last + old.first - 1
		t = old.array
	end

	local meta = {
		first = first,
		last = last,
		array = t,
		__index = function(_, i) return t[first + i - 1] end,
		__len = function() return last - first + 1 end
	}

	return setmetatable({ slice = slice }, meta)
end

-- Parses the command line arguments
function parse_input(cmd_args)
	local arg = slice(arg, 1, #arg)
	local positionals = slice(cmd_args, 1, #cmd_args)

	local new_flag, flag_value, new_positional, positional_values

	local new_arg = function()
		local item = arg[1]

		if not item then return end

		if starts_with_hyphen(item) then
			return new_flag()
		end

		return new_positional()
	end

	new_flag = function()
		local item = arg[1]
		arg = arg:slice(2)

		local left, right = split_at_equal_sign(item)

		if left == "help" then
			return "help"
		end

		local flag = cmd_args[left]

		if not flag then
			-- TODO
			return new_arg()
		end

		if flag.type == boolean or right then
			flag:set(right) -- TODO
			return new_arg()
		end

		return flag_value(flag)
	end

	flag_value = function(flag)
		local item = arg[1]

		if item == "=" then
			arg = arg:slice(2)
			item = arg[1]
		end

		if item and not starts_with_hyphen(item) then
			flag:set(item) -- TODO
			arg = arg:slice(2)
		else
			-- TODO
		end

		return new_arg()
	end

	new_positional = function()
		local positional = positionals[1]

		if not positional then
			-- TODO
			arg = arg:slice(2)
			return new_arg()
		end

		positional:add(arg[1])
		arg = arg:slice(2)

		if positional.many then
			return positional_values()
		end

		positionals = positionals:slice(2)
		return new_arg()
	end

	positional_values = function()
		local item = arg[1]

		if not item then return end

		if starts_with_hyphen(item) then
			positionals = positionals:slice(2)
			return new_flag()
		end

		local positional = positionals[1]
		positional:add(item)
		arg = arg:slice(2)

		return positional_values()
	end

	return new_arg()
end

function input()
	local flag_value, new_arg
	local help = false

	local new_flag = function(arg_index, args)
		local item = arg[arg_index]
		local left, right = split_at_equal_sign(item)

		if left == "help" then
			help = true
		else
			args[#args + 1] = { name = left, value = right }
		end

		if right then
			return new_arg(arg_index + 1, args)
		end

		return flag_value(arg_index + 1, args)
	end

	flag_value = function(arg_index, args)
		local item = arg[arg_index]

		if item == "=" then
			arg_index = arg_index + 1
			item = arg[arg_index]
		end

		if item and not starts_with_hyphen(item) then
			args[#args].value = item
			arg_index = arg_index + 1
		end

		return new_arg(arg_index, args)
	end

	new_arg = function(arg_index, args)
		local item = arg[arg_index]

		if not item then return args end

		if starts_with_hyphen(item) then
			return new_flag(arg_index, args)
		end

		args[#args + 1] = { positional = item }

		return new_arg(arg_index + 1, args)
	end

	return new_arg(1, {}), help
end

local function hyphens_to_underscores(name)
	return (name:gsub("-", "_"))
end

local function underscores_to_hyphens(name)
	return (name:gsub("_", "-"))
end

local function anonymous_flag(data)
	local flg = {
		__flag = true,

		type = data.type
	}

	-- All flags without a default value are mandatory except for boolean flags,
	-- which are false by default
	if data.type == boolean then
		flg.value = false
	else
		flg.value = data.default
	end

	if type(data[1]) == "string" then
		flg.description = data[1]
	end

	function flg:set(value)
		if self.type == boolean then
			if value then
				return errors.not_expecting(value) -- TODO
			end

			self.value = true

		else
			if not value then
				return errors.missing_value() -- TODO
			end

			if self.type == number then
				self.value = tonumber(value)

				if not self.value then
					return errors.not_a_number(value) -- TODO
				end

			else
				self.value = value
			end
		end
	end

	return flg
end

function flag(name)
	return function(data)
		local flg = anonymous_flag(data)
		local short, long = split_at_comma(name)
		long = long or short

		flg.short_name = short
		flg.name_with_hyphens = underscores_to_hyphens(long)
		flg.name_with_underscores = hyphens_to_underscores(long)

		return flg
	end
end

function is_flag(t)
	return type(t) == "table" and t.__flag
end

function positional(name)
	return function(data)
		local pos = {
			__positional = true,

			name_with_hyphens = underscores_to_hyphens(name),
			name_with_underscores = hyphens_to_underscores(name),
			description = data[1],
			type = data.type,
			many = data.many,
			value = data.default
		}

		function pos:add(value)
			if self.many then
				self.value = self.value or {}
				self.value[#self.value + 1] = value
			else
				self.value = value
			end
		end

		return pos
	end
end

function is_positional(t)
	return type(t) == "table" and t.__positional
end

return _ENV
