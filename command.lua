local errors = require "errors"
local iter = require "iterators"
local options = require "options"
local parser = require "parser"
local text = require "text"

local _G = _G
local setmetatable = setmetatable
local string = string
local type = type

local _ENV = {}

local command_prototype = { __command = true }

function is_command(t)
	return type(t) == "table" and t.__command
end

function command_prototype:help_requested()
	return self.options:help_requested()
end

function command_prototype:has_flags()
	return #self.options.ordered_flags > 0
end

function command_prototype:has_positionals()
	return #self.options.ordered_positionals > 0
end

function command_prototype:flags()
	return self.options:flags()
end

function command_prototype:positionals()
	return self.options:positionals()
end

function command_prototype:parse_args()
	return parser.parse(self.options)
end

function command_prototype:options_values()
	return self.options:values()
end

function command_prototype:merge_with(other_cmd)
	local opts = self.options:merge_with(other_cmd.options)

	local merged = {
		options = opts,
		-- By defining the description as the other command's description and
		-- the name as the concatenation of the two names, we will be able to
		-- reduce the problem of generating a help message for a subcommand to
		-- the problem of generating a help message for a simple program
		-- without any subcommands, thus reducing the amount of code.
		description = other_cmd.description,
		name = string.format("%s %s", self.name, other_cmd.name),
		fn = other_cmd.fn,
	}

	return setmetatable(merged, { __index = self })
end

local function new_command(data)
	local cmd = {
		options = options.new(data),
		description = type(data[1]) == "string" and data[1] or "",
		fn = type(data[#data]) == "function" and data[#data] or nil,
	}

	return setmetatable(cmd, { __index = command_prototype })
end

local commands_defined = false

function has_subcommands()
	return commands_defined
end

function command(data)
	commands_defined = true

	return new_command(data)
end

function global_command(data)
	local cmd
	if type(data) == "string" then
		cmd = new_command { data }

	else
		cmd = new_command(data)
	end

	function cmd:parse_args()
		if not has_subcommands() then
			return parser.parse(self.options)
		end

		-- If we have subcommands defined, we need to add a fake first
		-- positional argument so that the parser can handle the command name
		-- correctly
		local command_name = options.positional "Este é o nome do comando" { type = options.string }
		local fake_options = options.new { command_name }
		local merged = fake_options:merge_with(self.options)
		return parser.parse(merged)
	end

	return cmd
end

local function command_list()
	return iter.pairs(_G)
		:filter(function(_,v) return is_command(v) end)
		:map(function(name) return text.underscores_to_hyphens(name) end)
		:sort()
end

function load()
	-- We are going to use the parser to retrieve the command name and,
	-- possibly, the `help` flag. To do so, we will define a fake command with
	-- a sole positional argument corresponding to the command name.
	local name = options.positional "Este é o nome do comando" { type = options.string }
	local fake_options = options.new { name }
	parser.parse(fake_options)
	local help = fake_options:help_requested()

	if not name.value then
		if help then
			return nil, true
		end

		return errors.command_not_provided(command_list())
	end

	local command = _G[text.hyphens_to_underscores(name.value)]

	if not is_command(command) then
		return errors.unknown_command(name.value, command_list())
	end

	return command, help
end

return _ENV
