local args = require "args"
local command = require "command"

local os = os

local _ENV = {}

-- Re-exports

flag = args.flag
flag_named = args.flag_named
positional = args.positional
boolean = args.boolean
number = args.number
string = args.string
command = command.command

local function program_name()
	return arg[0]:match("[^/]+$")
end

local function program(cmd)
	local unknown, unset = cmd:set_arguments(args.input()) -- TODO

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
