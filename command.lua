local args = require "args"

local type = type
local ipairs = ipairs
local pairs = pairs
local _ENV = {}

local function command_args(cmd)
	local arguments = {}

	-- Flags will be stored as key,value pairs. Positional arguments will
	-- be stored as an array, ordered.
	for name, argument in pairs(cmd) do
		if args.is_flag(argument) then
			if type(name) ~= "number" then
				argument:name(name)
			end

			arguments[argument.short_name] = argument
			arguments[argument.long_name_with_hyphens] = argument

		elseif args.is_positional(argument) then
			arguments[#arguments + 1] = argument
		end
	end

	return arguments
end

-- Flag to know whether the program has subcommands
local commands_defined = false

local function anonymous_command(data)
	local cmd = {
		__type = "command",
		args = command_args(data)
	}

	if type(data[1]) == "string" then
		cmd.description = data[1]
	end

	if type(data[#data]) == "function" then
		cmd.fn = data[#data]
	end

	return cmd
end

function command(data)
	commands_defined = true

	return anonymous_command(data)
end

return _ENV
