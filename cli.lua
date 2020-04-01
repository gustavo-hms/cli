local cmd = require "command"
local errors = require "errors"
local info = require "info"
local options = require "options"
local translations = require "translations"

local print = print

local _ENV = {}

-- Re-exports
flag = options.flag
positional = options.positional
boolean = options.boolean
number = options.number
string = options.string
command = cmd.command
locale = translations.locale

local function program_with_options(program_cmd)
	errors.assert(program_cmd:parse_args())

	if program_cmd:help_requested() then
		local program_info = info.new(program_cmd)
		print(program_info:help())
		return
	end

	if program_cmd.fn then
		local values = errors.assert(program_cmd:options_values())
		program_cmd.fn(values)
	end
end

local function program_with_commands(global_cmd)
	local subcommand, help = errors.assert(cmd.load())

	if help then
		local program_info = info.new_with_commands(global_cmd)

		if subcommand then
			print(program_info:help_for(subcommand))
		else
			print(program_info:help())
		end

		return
	end

	local merged = global_cmd:merge_with(subcommand)
	errors.assert(merged:parse_args())

	local values = errors.assert(merged:options_values())

	if subcommand.fn then
		if global_cmd.fn then
			subcommand.fn(values, global_cmd.fn(values))
		else
			subcommand.fn(values)
		end
	end
end

function program(data)
	local global_cmd = cmd.global_command(data)

	if cmd.has_subcommands() then
		return program_with_commands(global_cmd)
	end

	return program_with_options(global_cmd)
end

return _ENV
