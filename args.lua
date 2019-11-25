local M = {}
setmetatable(M, {__index = _G})
local _ENV = M

local errors = require "errors"

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

local function input_arguments()
	local args = {
		elements = slice(arg, 1, #arg)
	}

	function args:next()
		local elem = self.elements[1]
		self.elements = self.elements:slice(2, #self.elements)
		return elem
	end

	return args
end

-- Parses the command line arguments
function parse_input(cmd_args)
	local flag_mode, flag_name_mode, flag_value_mode, unexpected_flag_mode, set_flag_mode
	local positional_mode, positional_value_mode, unexpected_positional_mode
	local missing_value_mode, wrong_value_mode

	local input = input_arguments()
	local positionals = slice(cmd_args.positionals, 1, #cmd_args.positionals)
	local errors_holder = errors.holder()

	local new_arg_mode = function()
		local item = input:next()

		if not item then return end

		if starts_with_hyphen(item) then
			return flag_mode(item)
		end

		return positional_mode(item)
	end

	flag_mode = function(item)
		local left, right = split_at_equal_sign(item)
		return flag_name_mode(left, right)
	end

	flag_name_mode = function(name, value)
		if name == "help" then return "help" end

		local flag = cmd_args.flags[name]

		if not flag then return unexpected_flag_mode(name) end

		return flag_value_mode(flag, value)
	end

	flag_value_mode = function(flag, value)
		if value or flag.type == boolean then
			return set_flag_mode(flag, value)
		end

		local item = input:next()

		if item == "=" then
			item = input:next()
		end

		if item and not starts_with_hyphen(item) then
			return set_flag_mode(flag, item)
		end

		return missing_value_mode(flag)
	end

	set_flag_mode = function(flag, value)
		local error = flag:set(value)

		if error then return wrong_value_mode(error) end

		return new_arg_mode()
	end

	unexpected_flag_mode = function(name)
		errors_holder:add(errors.unknown_arg(name))
		return new_arg_mode()
	end

	positional_mode = function(value)
		local positional = positionals[1]

		if not positional then return unexpected_positional_mode(value) end

		return positional_value_mode(positional, value)
	end

	positional_value_mode = function(positional, value)
		if not value then return end

		if positional.many and starts_with_hyphen(value) then
			positionals = positionals:slice(2, #positionals)
			return flag_mode(value)
		end

		local error = positional:add(value)

		if error then return wrong_value_mode(error) end

		if positional.many then
			value = input:next()
			return positional_value_mode(positional, value)
		end

		positionals = positionals:slice(2, #positionals)
		return new_arg_mode()
	end

	missing_value_mode = function(arg)
		errors_holder:add(errors.missing_value(arg.name_with_hyphens))
		return new_arg_mode()
	end

	wrong_value_mode = function(error)
		errors_holder:add(error)
		return new_arg_mode()
	end

	unexpected_positional_mode = function(value)
		errors_holder:add(errors.unexpected_positional(value))
		return new_arg_mode()
	end

	local help = new_arg_mode()
	return help, errors_holder:errors()
end

function find_subcommand_name(cmd_args)
	local fake_cmd = {
		args = {
			positionals = { positional "subcommand" { type = string } },
			flags = cmd_args.args.flags
		}
	}

	local help = parse_input(fake_cmd, true)

	if help then --[[ TODO ]] end

	return fake_cmd.args.positionals[1].value
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
				return errors.not_expecting(self.name_with_hyphens, value)
			end

			self.value = true

		else
			if not value then
				return errors.missing_value(self.name_with_hyphens)
			end

			if self.type == number then
				self.value = tonumber(value)

				if not self.value then
					return errors.not_a_number(self.name_with_hyphens, value)
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
