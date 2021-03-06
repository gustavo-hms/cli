local cmd = require "cli.command"
local errors = require "cli.errors"
local info = require "cli.info"
local options = require "cli.options"
local translations = require "cli.translations"

local stdout = io.stdout

local _ENV = {}

-- Re-exports
flag = options.flag
positional = options.positional
boolean = options.boolean
number = options.number
string = options.string
command = cmd.command
locale = translations.locale

local function simple_program(program_cmd)
	errors.assert(program_cmd:parse_args())

	if program_cmd:help_requested() then
		local program_info = info.new(program_cmd)
		stdout:write(program_info:help())
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
			stdout:write(program_info:help_for(subcommand))
		else
			stdout:write(program_info:help())
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

	return simple_program(global_cmd)
end

return _ENV
