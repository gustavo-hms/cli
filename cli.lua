local option = require "option"
local cmd = require "command"
local errors = require "errors"
local translations = require "translations"

local _ENV = {}

-- Re-exports
flag = option.flag
positional = option.positional
boolean = option.boolean
number = option.number
string = option.string
command = cmd.command
locale = translations.locale

local function program_with_options(program_cmd)
	local options = program_cmd.options
	errors.assert(options:parse_args())

	if options.flags.help.value then return --[[ TODO ]] end

	if program_cmd.fn then
		local values = errors.assert(options:extract_values())
		program_cmd.fn(values)
	end
end

local function program_with_commands(global_cmd)
	local subcommand, help = errors.assert(cmd.load(global_cmd))

	if help then return --[[ TODO ]] end

	local options = cmd.merge_options(global_cmd, subcommand)
	errors.assert(options:parse_args())

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
		return program_with_commands(global_cmd)
	end

	return program_with_options(global_cmd)
end

return _ENV
