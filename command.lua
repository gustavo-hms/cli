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

function load(global_cmd)
	-- We are going to define a fake arguments table with a sole positional argument to
	-- be able to use `args.parse_input` to load the command name from the
	-- input command line arguments. By the way `args.parse_input` is designed,
	-- the command name will be stored in the fake command's positional
	-- argument.
	
	local global_args = (global_cmd and global_cmd.args) and global_cmd.args or {}

	local fake_args = {
		flags = global_args.flags or {},
		positionals = { 
			args.positional "command-name" { type = args.string }
		}
	}
	
	local help = args.parse_input(fake_args)

	if help then return nil, help end

	local command_name = fake_args.positionals.command_name

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

function merge_arguments(cmd1, cmd2)
	local args1 = cmd1.args
	local args2 = cmd2.args

	for _, v in ipairs(args2.positionals) do
		args1.positionals[#args1.positionals + 1] = v
	end

	for k, v in pairs(args2.flags) do
		args1.flags[k] = v
	end

	return args1
end

return _ENV
