-- Information about the program's command line interface

local command = require "command"
local text = require "text"
local translations = require "translations"

local _G = _G
local arg = arg
local ipairs = ipairs
local pairs = pairs
local setmetatable = setmetatable
local string = string
local table = table

local _ENV = {}

local program = {}

function new(cmd)
	cmd.name = cmd.name or arg[0]

	local info = { command = cmd }

	return setmetatable(info, { __index = program })
end

function program:help()
	local cmd = self.command

	local txt = {
		cmd.description,
		translations.help_usage(),
		"    " .. self:usage()
	}

	if cmd:has_flags() then
		txt[#txt+1] = translations.help_options()

		for flag in cmd:flags() do
			if flag.names[#flag.names] ~= "help" then
				txt[#txt+1] = flag:help()
			end
		end
	end

	if cmd:has_positionals() then
		txt[#txt+1] = translations.help_arguments()

		for positional in cmd:positionals() do
			txt[#txt+1] = positional:help()
		end
	end

	txt[#txt+1] = ""

	return table.concat(txt, "\n\n")
end

function program:usage()
	local cmd = self.command
	local usage = { cmd.name }

	if cmd:has_flags() then
		usage[#usage+1] = translations.help_has_options()
	end

	for positional in cmd:positionals() do
		local many = positional.many and "..." or ""
		usage[#usage+1] = positional.name .. many
	end

	return table.concat(usage, " ")
end

function program:inline_help()
	local cmd = self.command
	return string.format("    %s\n        %s", self:usage(), cmd.description)
end

local program_with_commands = {}

function new_with_commands(global_cmd)
	global_cmd.name = global_cmd.name or arg[0]
	local names = {}

	for name, value in pairs(_G) do
		if command.is_command(value) then
			names[#names+1] = name
		end
	end

	table.sort(names)
	local commands = {}

	for _, name in ipairs(names) do
		local cmd = _G[name]
		cmd.name = text.underscores_to_hyphens(name)
		commands[#commands+1] = cmd
	end

	global_cmd.name = arg[0]

	local info = {
		global = global_cmd,
		subcommands = commands
	}

	return setmetatable(info, { __index = program_with_commands })
end

function program_with_commands:help()
	local cmd = self.global

	local txt = {
		cmd.description,
		translations.help_usage(),
		self:usage(),
		translations.help_command_help_tip(self.global.name)
	}

	return table.concat(txt, "\n\n")
end

function program_with_commands:usage()
	local usages = {}

	for _, cmd in ipairs(self.subcommands) do
		local merged = self.global:merge_with(cmd)
		local prog = new(merged)
		usages[#usages+1] = prog:inline_help()
	end

	return table.concat(usages, "\n\n")
end

function program_with_commands:help_for(cmd)
	local merged = self.global:merge_with(cmd)
	return new(merged):help()
end

return _ENV
