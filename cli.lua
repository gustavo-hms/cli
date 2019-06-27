local os = os
local ipairs = ipairs

local args = require "args"
local command = require "command"

local _ENV = {}

-- Re-exports

flag = args.flag
flag_named = args.flag_named
positional = args.positional
boolean = args.boolean
number = args.number
string = args.string
command = command.command

local function starts_with_hyphen(text)
	return text:sub(1,1) == "-"
end

function split_at_equal_sign(text)
	local left, right = text:match("-?-?([^=]+)=?(.*)")

	if not right or #right == 0 then
		return left
	end

	return left, right
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

local function program_name()
	return arg[0]:match("[^/]+$")
end

local function program(cmd)
	local unknown, unset = cmd:set_arguments(arguments()) -- TODO

	os.exit(cmd.fn and cmd.fn(cmd.values))
end

function run(data)
	local cmd = command.anonymous(data)

	if command.has_subcommands() then
		if cmd.flags then
			return program_with_options_and_commands(cmd)
		end

		return program_with_commands(cmd)
	end

	return program(cmd)
end

return _ENV
