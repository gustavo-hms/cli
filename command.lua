local option = require "option"
local errors = require "errors"

local arg = arg
local type = type
local ipairs = ipairs
local pairs = pairs
local setmetatable = setmetatable
local getmetatable = getmetatable
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
			option.positional "command-name" { type = option.string }
		}
	}

	local help = option.parse_input(fake_args)

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

local function starts_with_hyphen(text)
	return text:sub(1,1) == "-"
end

local function slice(t, first, last)
	if not last or last > #t then last = #t end

	if first > last then return { slice = slice } end

	local old = getmetatable(t)

	if old then
		first, last = first + old.first - 1, last + old.first - 1
		t = old.array
	end

	local meta = {
		first = first,
		last = last,
		array = t,
		__index = function(_, i) return t[first + i - 1] end,
		__len = function() return last - first + 1 end
	}

	return setmetatable({ slice = slice }, meta)
end

local function arguments()
	local args = { elements = slice(arg, 1, #arg) }

	function args:next()
		local elem = self.elements[1]
		self.elements = self.elements:slice(2, #self.elements)
		return elem
	end

	return args
end

local function split_at_equal_sign(text)
	local left, right = text:match("-?-?([^=]+)=?(.*)")

	if not right or #right == 0 then
		return left
	end

	return left, right
end

local function options_table(cmd)
	local options = { positionals = {}, flags = {} }

	-- Flags will be stored as key,value pairs. Positional arguments will
	-- be stored as an array, ordered.
	for _, argument in ipairs(cmd) do
		if option.is_flag(argument) then
			options.flags[argument.short_name] = argument
			options.flags[argument.name_with_hyphens] = argument

		elseif option.is_positional(argument) then
			options.positionals[#options.positionals + 1] = argument
		end
	end

	--[[
		Options will be passed to the modules' user as a table whose keys are the names
		of the options with hyphens replaced with underscores, and whose values are already filled with the values provided at command line
	]]
	function options:extract_values()
		local values = {}

		for _, positional in ipairs(self.positionals) do
			values[positional.name_with_underscores] = positional.value
		end

		for _, flag in pairs(self.flags) do
			values[flag.name_with_underscores] = flag.value
		end

		return values
	end

	function options:parse_args()
		local flag_mode, flag_name_mode, flag_value_mode, unexpected_flag_mode, set_flag_mode
		local positional_mode, positional_value_mode, unexpected_positional_mode
		local missing_value_mode, wrong_value_mode

		local args = arguments()
		local positionals = slice(self.positionals, 1, #self.positionals)
		local errors_holder = errors.holder()

		local new_arg_mode = function()
			local item = args:next()

			if not item then return end

			if starts_with_hyphen(item) then
				return flag_mode(item)
			end

			return positional_mode(item)
		end

		flag_mode = function(item)
			local left, right = split_at_equal_sign(item)
			return flag_name_mode(left, right)
		end

		flag_name_mode = function(name, value)
			if name == "help" then return "help" end

			local flag = self.flags[name]

			if not flag then return unexpected_flag_mode(name) end

			return flag_value_mode(flag, value)
		end

		flag_value_mode = function(flag, value)
			if value or flag.type == option.boolean then
				return set_flag_mode(flag, value)
			end

			local item = args:next()

			if item == "=" then
				item = args:next()
			end

			if item and not starts_with_hyphen(item) then
				return set_flag_mode(flag, item)
			end

			return missing_value_mode(flag)
		end

		set_flag_mode = function(flag, value)
			local error = flag:set(value)

			if error then return wrong_value_mode(error) end

			return new_arg_mode()
		end

		unexpected_flag_mode = function(name)
			errors_holder:add(errors.unknown_arg(name))
			return new_arg_mode()
		end

		positional_mode = function(value)
			local positional = positionals[1]

			if not positional then return unexpected_positional_mode(value) end

			return positional_value_mode(positional, value)
		end

		positional_value_mode = function(positional, value)
			if not value then return end

			if positional.many and starts_with_hyphen(value) then
				positionals = positionals:slice(2, #positionals)
				return flag_mode(value)
			end

			local error = positional:add(value)

			if error then return wrong_value_mode(error) end

			if positional.many then
				value = args:next()
				return positional_value_mode(positional, value)
			end

			positionals = positionals:slice(2, #positionals)
			return new_arg_mode()
		end

		missing_value_mode = function(arg)
			errors_holder:add(errors.missing_value(arg.name_with_hyphens))
			return new_arg_mode()
		end

		wrong_value_mode = function(error)
			errors_holder:add(error)
			return new_arg_mode()
		end

		unexpected_positional_mode = function(value)
			errors_holder:add(errors.unexpected_positional(value))
			return new_arg_mode()
		end

		local help = new_arg_mode()
		return help, errors_holder:errors()
	end

	return options
end

-- Flag to know whether the program has subcommands
local commands_defined = false

function has_subcommands()
    return commands_defined
end

local function anonymous(data)
	local cmd = {
		__command = true,
		options = options_table(data)
	}

	if type(data[1]) == "string" then
		cmd.description = data[1]
	end

	if type(data[#data]) == "function" then
		cmd.fn = data[#data]
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

function merge_options(cmd1, cmd2)
	local options1 = cmd1.options
	local options2 = cmd2.options

	for _, v in ipairs(options2.positionals) do
		options1.positionals[#options1.positionals + 1] = v
	end

	for k, v in pairs(options2.flags) do
		options1.flags[k] = v
	end

	return options1
end

return _ENV
