-- Information about the program's command line interface

local command = require "command"
local iter = require "iterators"
local text = require "text"
local translations = require "translations"

local _G = _G
local arg = arg
local setmetatable = setmetatable
local string = string
local table = table

local _ENV = {}

local program = {}

function new(cmd)
	cmd.name = cmd.name or arg[0]
	return setmetatable({ command = cmd }, { __index = program })
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

	local name = iter.once(cmd.name)
	local help_has_options = iter.once(cmd:has_flags() and translations.help_has_options() or nil)
	local positionals =
		cmd:positionals():map(function(pos) return pos.many and pos.name .. "..." or pos.name end)

	return iter.chain(name, help_has_options, positionals):concat(" ")
end

function program:inline_help()
	local cmd = self.command
	return string.format("    %s\n        %s", self:usage(), cmd.description)
end

local program_with_commands = {}

function new_with_commands(global_cmd)
	local names = iter.pairs(_G)
		:filter(function(_,v) return command.is_command(v) end)
		:sort()

	local command_with_name = function(name)
		local cmd = _G[name]
		cmd.name = text.underscores_to_hyphens(name)
		return cmd
	end
	local commands = iter.sequence(names):map(command_with_name):array()

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
	return iter.sequence(self.subcommands)
		:map(function(cmd) return self.global:merge_with(cmd) end)
		:map(function(merged) return new(merged) end)
		:map(function(prog) return prog:inline_help() end)
		:concat("\n\n")
end

function program_with_commands:help_for(cmd)
	local merged = self.global:merge_with(cmd)
	return new(merged):help()
end

return _ENV
