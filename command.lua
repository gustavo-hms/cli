local errors = require "errors"
local option = require "option"
local txt = require "text"

local arg = arg
local type = type
local ipairs = ipairs
local pairs = pairs
local setmetatable = setmetatable
local getmetatable = getmetatable
local table = table
local _G = _G

local _ENV = {}

local function command_list()
	local cmds = {}

	for name, value in pairs(_G) do
		if is_command(value) then
			cmds[#cmds + 1] = name
		end
	end

	table.sort(cmds)

	return cmds
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

-- State machine to parse command line arguments
local function parse_args(options)
	local flag_mode, flag_name_mode, flag_value_mode, unexpected_flag_mode, set_flag_mode
	local positional_mode, positional_value_mode, unexpected_positional_mode
	local missing_value_mode, wrong_value_mode

	local help = option.flag "h,help" {
		"Show the help",
		type = option.boolean
	}
	options.flags.help, options.flags.h = help, help

	local args = arguments()
	local positionals = slice(options.positionals, 1, #options.positionals)
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
		local left, right = txt.split_at_equal_sign(item)
		return flag_name_mode(left, right)
	end

	flag_name_mode = function(name, value)
		local flag = options.flags[name]

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
		local err = flag:set(value)

		if err then return wrong_value_mode(err) end

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

		local err = positional:add(value)

		if err then return wrong_value_mode(err) end

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

	wrong_value_mode = function(err)
		errors_holder:add(err)
		return new_arg_mode()
	end

	unexpected_positional_mode = function(value)
		errors_holder:add(errors.unexpected_positional(value))
		return new_arg_mode()
	end

	new_arg_mode()
	return errors_holder:errors()
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
		local errors_holder = errors.holder()

		for _, positional in ipairs(self.positionals) do
			if not positional.value then
				errors_holder:add(errors.missing_value(positional.name_with_hyphens))
			else
				values[positional.name_with_underscores] = positional.value
			end
		end

		for _, flag in pairs(self.flags) do
			if flag.value == nil then
				errors_holder:add(errors.missing_value(flag.name_with_hyphens))
			else
				values[flag.name_with_underscores] = flag.value
			end
		end

		return values, errors_holder:errors()
	end

	function options:parse_args()
		return parse_args(self)
	end

	return options
end

-- Flag to know whether the program has subcommands
local commands_defined = false

function has_subcommands()
    return commands_defined
end

-- A `command` table has this public structure:
-- {
--     options = *an options_table*
-- }
function command(data)
	commands_defined = true

	local cmd = {
		__command = true
	}

	-- Commands are lazy-loaded. When they are first accessed, the following
	-- metatable is used, which builds the anonymous command and changes the
	-- metatable to it.
	local anon
	local meta = {
		__index = function(t, index)
			if not anon then
				anon = anonymous(data)
			end

			return anon[index]
		end
	}

	setmetatable(cmd, meta)

	return cmd
end

function anonymous(data)
	local cmd

	if type(data) == "string" then
		cmd = {
			__command = true,

			options = options_table({}),
			description = data
		}

	else
		cmd = {
			__command = true,

			options = options_table(data),
			description = type(data[1]) == "string" and data[1] or "",
			fn = type(data[#data]) == "function" and data[#data] or nil
		}
	end

	-- Has the user entered a `--help` flag?
	function cmd:help_requested()
		return self.options.flags.help and self.options.flags.help.value
	end

	return cmd
end

function is_command(t)
	return type(t) == "table" and t.__command
end

function merge_options(cmd1, cmd2)
	local options1 = cmd1.options
	local options2 = cmd2.options
	local merged = {}

	for _, v in ipairs(options1.positionals) do
		merged[#merged + 1] = v
	end

	for _, v in ipairs(options2.positionals) do
		merged[#merged + 1] = v
	end

	for _, v in pairs(options1.flags) do
		merged[#merged + 1] = v
	end

	for _, v in pairs(options2.flags) do
		merged[#merged + 1] = v
	end

	return options_table(merged)
end

function load(global_cmd)
	-- We are going to use the `parse_args` function to retrieve the command
	-- name and, possibly, the `help` flag. To do so, we will define a fake
	-- command with a sole positional argument corresponding to the command
	-- name.
	local name = option.positional "==command-name==" { type = option.string }
	local fake_cmd = anonymous { name }
	parse_args(fake_cmd.options)

	if fake_cmd:help_requested() then
		return name.value, "help"
	end

	if not name.value then
		return errors.command_not_provided(command_list())
	end

	-- Since we need the command name's positional argument to parse the
	-- command line arguments correctly, we will insert it in the global
	-- command's options_table.
	global_cmd.options = merge_options(fake_cmd, global_cmd)

	local command = _G[name.value]

	if not is_command(command) then
		return errors.unknown_command(name.value, command_list())
	end

	return command
end

return _ENV
