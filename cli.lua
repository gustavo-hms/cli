local os = os
local type = type
local pairs = pairs

local _ENV = {}

-- Flags

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

boolean = "boolean"
number = "number"
string = "string"

local split_at_comma = split_at("(.+),(.*)")

local function hyphens_to_underscores(name)
	return (name:gsub("-", "_"))
end

local function underscores_to_hyphens(name)
	return (name:gsub("_", "-"))
end

local mandatory_args = {}

function flag(data)
	data.__type = "flag"

	data.value = data.default
	data.description = data[1]

	function data:set(argument)
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

		mandatory_args[self.long_name_with_hyphens] = nil
	end

	function data:name(name)
		local short, long = split_at_comma(name)
		long = long or short

		self.short_name = short
		self.long_name_with_hyphens = long
		self.long_name_with_underscores = hyphens_to_underscores(long)

		if not self.default then
			-- If it doesn't have a default value, it's mandatory
			mandatory_args[self.long_name_with_hyphens] = true
		end
	end

	return data
end

function flag_named(name)
	return function(data)
		local flg = flag(data)
		flg:name(name)

		return flg
	end
end

local function is_flag(t)
	return t.__type and t.__type == "flag"
end

function positional(name)
	return function(data)
		data.__type = "positional"

		data.name_with_hyphens = name
		data.name_with_underscores = hyphens_to_underscores(name)
		data.description = data[0]

		if not data.default then
			-- If it doesn't have a default value, it's mandatory
			mandatory_args[data.name_with_hyphens] = true
		end

		function data:add(value)
			if self.many then
				self.value = self.value or {}
				self.value[#self.value + 1] = value
			else
				self.value = value
			end

			mandatory_args[self.name_with_hyphens] = nil
		end

		return data
	end
end

local function is_positional(t)
	return t.__type and t.__type == "positional"
end

-- Commands

local function command_args(cmd)
	local args = {}

	for _, argument in pairs(cmd) do
		-- Flags will be stored as key,value pairs. Positional arguments will
		-- be stored as an array, ordered.
		if is_flag(argument) then
			args[argument.short_name] = argument
			args[argument.long_name_with_hyphens] = argument

		elseif is_positional(argument) then
			args[#args + 1] = argument
		end
	end

	for name, argument in pairs(cmd) do
		if is_flag(argument) then
			argument:name(name)
			args[argument.short_name] = argument
			args[argument.long_name_with_hyphens] = argument
		end
	end

	return args
end

-- Flag to know whether the program has subcommands
local commands_defined = false

local function anonymous_command(data)
	data.__type = "command"

	local first = data[1]
	data.description = type(first) == "string" and first or nil
	data.args = command_args(data)
	local fn = data[#data]
	data.fn = type(fn) == "function" and fn or nil

	return data
end

function command(data)
	commands_defined = true

	return anonymous_command(data)
end

-- Programs

local function program_name()
	return arg[0]:match("[^/]+$")
end

local function program(cmd)
	local positional_index = 1

	for _, argument in ipairs(arguments()) do
		if argument.name then
			-- It's a flag

			if argument.name == "help" then
				help(cmd)
				os.exit(0)
			end

			local flg = cmd.flags[argument.name]

			if not flg then
				-- TODO decidir o que fazer com os erros
				errors.not_expecting("--" .. argument.name)

			else
				-- TODO aqui pode ter erro também
				flg:set(argument)
			end

		else
			-- It's a positional argument
			local positional = cmd.flags[positional_index]

			if not positional then
				errors.not_expecting("--" .. argument.name)
			else
				positional:add(argument.positional)

				if not positional.many then
					positional_index = positional_index + 1
				end
			end
		end
	end

	-- TODO verificar argumentos obrigatórios
	-- Não daria pra montar uma lista de argumentos obrigatórios no momento da
	-- definição deles?

	os.exit(cmd.fn and cmd.fn())
end

function run(data)
	local cmd = anonymous_command(data)

	if commands_defined then
		if cmd.flags then
			return program_with_options_and_commands(cmd)
		end

		return program_with_commands(cmd)
	end

	return program(cmd)
end

return _ENV
