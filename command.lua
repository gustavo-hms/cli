local args = require "args"
local errors = require "errors"

local type = type
local ipairs = ipairs
local pairs = pairs
local setmetatable = setmetatable
local sort = table.sort
local _G = _G

local _ENV = {}

local function command_list()
	local cmds = {}

	for name, value in pairs(_G) do
		if is_command(value) then
			cmds[#cmds + 1] = name
		end
	end

	sort(cmds)

	return cmds
end

function load(input_args)
	local command_name

	for _, arg in ipairs(input_args) do
		if arg.positional then
			command_name = arg.positional
			break
		end
	end

	if not command_name then
		return nil, errors.command_not_provided(command_list())
	end

	local command = _G[command_name]

	if not is_command(command) then
		return nil, errors.unknown_command(command_name, command_list())
	end

	return command
end

local function command_args(cmd)
	local arguments = { positionals = {}, flags = {} }

	-- Flags will be stored as key,value pairs. Positional arguments will
	-- be stored as an array, ordered.
	for _, argument in ipairs(cmd) do
		if args.is_flag(argument) then
			arguments.flags[argument.short_name] = argument
			arguments.flags[argument.name_with_hyphens] = argument

		elseif args.is_positional(argument) then
			arguments.positionals[#arguments.positionals + 1] = argument
		end
	end

	return arguments
end

-- Flag to know whether the program has subcommands
local commands_defined = false

function has_subcommands()
    return commands_defined
end

local function anonymous(data)
	local cmd = {
		__command = true,
		args = command_args(data)
	}

	if type(data[1]) == "string" then
		cmd.description = data[1]
	end

	if type(data[#data]) == "function" then
		cmd.fn = data[#data]
	end

	function cmd:set_arguments()
		args.parse_input(self.args)
	end

	return cmd
end

function command(data)
	commands_defined = true

	local cmd = {
		__command = true
	}

	-- Commands are lazy-loaded. When they are first accessed, the following
	-- metatable is used, which builds the anonymous command and changes the
	-- metatable to it.
	local meta = {
		__index = function(t, index)
			local anon = anonymous(data)

			anon.__index = anon
			setmetatable(t, anon)

			return anon[index]
		end
	}

	setmetatable(cmd, meta)

	return cmd
end

function is_command(t)
	return type(t) == "table" and t.__command
end

return _ENV
