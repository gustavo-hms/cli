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

-- Parses the command line arguments
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

function flag(data)
	local flg = {
		__type = "flag",

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

	function flg:name(name)
		local short, long = split_at_comma(name)
		long = long or short

		self.short_name = short
		self.name_with_hyphens = underscores_to_hyphens(long)
		self.name_with_underscores = hyphens_to_underscores(long)
	end

	return flg
end

function flag_named(name)
	return function(data)
		local flg = flag(data)
		flg:name(name)

		return flg
	end
end

function is_flag(t)
	return type(t) == "table" and t.__type and t.__type == "flag"
end

function positional(name)
	return function(data)
		local pos = {
			__type = "positional",

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
	return type(t) == "table" and t.__type and t.__type == "positional"
end

return _ENV
