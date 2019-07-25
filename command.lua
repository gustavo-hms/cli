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
	local arguments = {}

	-- Flags will be stored as key,value pairs. Positional arguments will
	-- be stored as an array, ordered.
	for _, argument in ipairs(cmd) do
		if args.is_flag(argument) then
			arguments[argument.short_name] = argument
			arguments[argument.name_with_hyphens] = argument

		elseif args.is_positional(argument) then
			arguments[#arguments + 1] = argument
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

	function cmd:set_arguments(input_args)
		local unknown_args = {}
		local current_positional = 1

		for _, input_arg in ipairs(input_args) do
			if input_arg.positional then
				local pos = self.args[current_positional]

				if not pos then
					unknown_args[#unknown_args + 1] = input_arg
				else
					local err = pos:add(input_arg.positional) -- TODO

					if not pos.many then
						current_positional = current_positional + 1
					end
				end

			else
				local flag = self.args[input_arg.name]

				if not flag then
					unknown_args[#unknown_args + 1] = input_arg
				else
					local err = flag:set(input_arg.value) -- TODO
				end
			end
		end

		local unset_args = {}

		for _, arg in pairs(self.args) do
			if not arg.value then
				unset_args[#unset_args + 1] = arg
			end
		end

		if #unset_args == 0 then
			unset_args = nil

			-- Build a table with all the values. This is the table the user of
			-- the module will receive after the arguments' parsing
			self.values = {}
			for _, arg in pairs(self.args) do
				self.values[arg.name_with_underscores] = arg.value
			end
		end

		if #unknown_args == 0 then
			unknown_args = nil
		end

		return unknown_args, unset_args
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
