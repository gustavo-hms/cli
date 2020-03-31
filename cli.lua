local option = require "option"
local cmd = require "command"
local errors = require "errors"
local text = require "text"
local translations = require "translations"

local _G = _G
local arg = arg
local format = string.format
local ipairs = ipairs
local next = next
local pairs = pairs
local print = print
local table = table

local _ENV = {}

-- Re-exports
flag = option.flag
positional = option.positional
boolean = option.boolean
number = option.number
string = option.string
command = cmd.command
locale = translations.locale

local function parse_commands(global_cmd)
	local names = {}

	for name, value in pairs(_G) do
		if cmd.is_command(value) then
			names[#names+1] = name
		end
	end

	table.sort(names)
	local commands = {}

	for _, name in ipairs(names) do
		local command = _G[name]
		command.name = text.underscores_to_hyphens(name)
		commands[#commands+1] = command
	end

	global_cmd.name = arg[0]

	local parsed = {
		global = global_cmd,
		subcommands = commands
	}

	function parsed:help()
		local cmd_text = {}

		for _, command in ipairs(self.subcommands) do
			cmd_text[#cmd_text+1] = self:inline_help_for(command)
		end

		return translations.help_with_subcommands(self.global.description, table.concat(cmd_text, "\n"), self.global.name)
	end

	function parsed:exec_line(subcommand)
		local elements = { self.global.name, subcommand.name }
		local options = cmd.merge_options(self.global, subcommand)

		if next(options.flags) then
			elements[#elements+1] = translations.help_options()
		end

		for _, positional in ipairs(options.positionals) do
			local name = positional.name_with_hyphens

			if positional.many then
				name = name .. "..."
			end

			elements[#elements+1] = name
		end

		return table.concat(elements, " ")
	end

	function parsed:help_for(command)
		local options = cmd.merge_options(self.global, command) -- TODO otimizar uso do merge_options
		local flags_lines = {}

		for _, flag in ipairs(options.ordered_flags) do
			flags_lines[#flags_lines+1] = flag:help()
		end

		local positionals_lines = {}

		for _, positional in ipairs(options.positionals) do
			positionals_lines[#positionals_lines+1] = positional:help()
		end

		return translations.help_subcommand_with_options_and_arguments(
			command.description,
			"    " .. self:exec_line(command),
			table.concat(flags_lines, "\n"),
			table.concat(positionals_lines, "\n")
		)
	end

	function parsed:inline_help_for(command)
		local exec = self:exec_line(command)
		return format("    %s\n        %s\n", exec, command.description)
	end

	return parsed
end

local function program_with_options(program_cmd)
	local options = program_cmd.options
	errors.assert(options:parse_args())

	if program_cmd:help_requested() then return --[[ TODO ]] end

	if program_cmd.fn then
		local values = errors.assert(options:extract_values())
		program_cmd.fn(values)
	end
end

local function program_with_commands(global_cmd)
	local subcommand, help = errors.assert(cmd.load(global_cmd))

	if help then
		local cmd_info = parse_commands(global_cmd)

		if subcommand then
			print(cmd_info:help_for(subcommand))
		else
			print(cmd_info:help())
		end

		return
	end

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
