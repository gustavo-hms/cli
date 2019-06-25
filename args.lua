local type = type

local _ENV = {}

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

local function arguments()
	local flag_value = nil
	local new_arg = nil

	local new_flag = function(arg_index, args)
		local item = arg[arg_index]
		local left, right = split_at_equal_sign(item)
		args[#args + 1] = { name = left, value = right }

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

	return new_arg(1, {})
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

		type = data.type,
		value = data.default
	}

	if type(data[1]) == "string" then
		flg.description = data[1]
	end

	function flg:set(argument)
		if data.type == boolean then
			if argument.value then
				return errors.not_expecting(argument.value) -- TODO
			end

			self.value = true

		elseif data.type == number then
			if not argument.value then
				return errors.missing_value() -- TODO
			end

			self.value = tonumber(argument.value)

			if not self.value then
				return errors.not_a_number(argument.value) -- TODO
			end

		else
			if not argument.value then
				return errors.missing_value() -- TODO
			end

			self.value = argument.value
		end
	end

	function flg:name(name)
		local short, long = split_at_comma(name)
		long = long or short

		self.short_name = short
		self.long_name_with_hyphens = underscores_to_hyphens(long)
		self.long_name_with_underscores = hyphens_to_underscores(long)
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

			name_with_hyphens = name,
			name_with_underscores = hyphens_to_underscores(name),
			description = data[1],
			type = data.type,
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
