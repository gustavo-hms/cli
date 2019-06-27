local args = require "args"

local type = type
local ipairs = ipairs
local pairs = pairs
local _ENV = {}

local function command_args(cmd)
	local arguments = {}

	-- Flags will be stored as key,value pairs. Positional arguments will
	-- be stored as an array, ordered.
	for name, argument in pairs(cmd) do
		if args.is_flag(argument) then
			if type(name) ~= "number" then
				argument:name(name)
			end

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

function has_commands()
    return commands_defined
end

local function anonymous_command(data)
	local cmd = {
		__type = "command",
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

		local unset = {}

		for _, arg in pairs(self.args) do
			if not arg.value then
				unset[#unset + 1] = arg
			end
		end

		if #unset == 0 then
			unset = nil

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

		return unset, unknown_args
	end

	return cmd
end

function command(data)
	commands_defined = true

	return anonymous_command(data)
end

return _ENV
