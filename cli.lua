local option = require "option"
local cmd = require "command"
local errors = require "errors"

local _ENV = {}

-- Re-exports
flag = option.flag
positional = option.positional
boolean = option.boolean
number = option.number
string = option.string
command = cmd.command

local function program_with_options(program_cmd)
	program_cmd:set_arguments()

	if program_cmd.fn then
		program_cmd.fn(program_cmd.values)
	end
end

local function program_with_commands(global_cmd)
	local input_args = option.input()
	local subcommand = errors.assert(cmd.load(input_args))
	local unknown, unset = subcommand:set_arguments(input_args) -- TODO

	local global_data = nil

	if global_cmd.fn then
		global_data = global_cmd.fn()
	end

	if subcommand.fn then
		subcommand.fn(subcommand.values, global_data)
	end
end

local function program_with_options_and_commands(global_cmd)
	local subcommand, help = errors.assert(cmd.load(global_cmd.options))

	if help then --[[ TODO ]] end

	local options = cmd.merge_options(global_cmd, subcommand)
	help = errors.assert(options:parse_args())

	if help then end -- TODO

	local values = errors.assert(options:extract_values())

	if subcommand.fn then
		if global_cmd.fn then
			subcommand.fn(values, global_cmd.fn(values))
		else
			subcommand.fn(values)
		end
	end
end

function program(data)
	local global_cmd = cmd.anonymous(data)

	if cmd.has_subcommands() then
		if global_cmd.options then
			return program_with_options_and_commands(global_cmd)
		end

		return program_with_commands(global_cmd)
	end

	return program_with_options(global_cmd)
end

return _ENV
