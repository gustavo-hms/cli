local errors = require "errors"
local option = require "option"
local text = require "text"
local translations = require "translations"

local _G = _G
local arg = arg
local coroutine = coroutine
local getmetatable = getmetatable
local ipairs = ipairs
local pairs = pairs
local setmetatable = setmetatable
local table = table
local type = type

local print = print -- TODO
local _ENV = {}

local function options_table(data)
	local options = { positionals = {}, flags = {}, ordered_flags = {} }

	function options:add_flag(flag)
		if not self.flags[flag.name_with_hyphens] then
			self.ordered_flags[#self.ordered_flags+1] = flag
			self.flags[flag.short_name] = flag
			self.flags[flag.name_with_hyphens] = flag
		end
	end

	function options:add_positional(positional)
		self.positionals[#self.positionals + 1] = positional
	end

	-- Options will be passed to the modules' user as a table whose keys are
	-- the names of the options with hyphens replaced with underscores, and
	-- whose values are already filled with the values provided at command line
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

	for _, argument in ipairs(data) do
		if option.is_flag(argument) then
			options:add_flag(argument)

		elseif option.is_positional(argument) then
			options:add_positional(argument)
		end
	end

	return options
end

local function command_list()
	local cmds = {}

	for name, value in pairs(_G) do
		if is_command(value) then
			cmds[#cmds + 1] = text.underscores_to_hyphens(name)
		end
	end

	table.sort(cmds)

	return cmds
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

	local args = arguments()
	local positionals = slice(options.positionals, 1, #options.positionals)
	local errors_holder = errors.holder()

	local new_arg_mode = function()
		local item = args:next()

		if not item then return end

		if text.starts_with_hyphen(item) then
			return flag_mode(item)
		end

		return positional_mode(item)
	end

	flag_mode = function(item)
		local left, right = text.split_at_equal_sign(item)
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

		if item and not text.starts_with_hyphen(item) then
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

		if positional.many and text.starts_with_hyphen(value) then
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

local function command_prototype(cmd)
	local prototype = { __command = true }

	function prototype:help_requested()
		return self.options.flags.help and self.options.flags.help.value
	end

	function prototype:parse_args()
		return parse_args(self.options)
	end

	function prototype:merge_with(other_cmd)
		local options = merge_options(self, other_cmd)

		local merged = {
			options = options,
			description = self.description,
			fn = self.fn
		}

		return setmetatable(merged, { __index = self })
	end

	function prototype:options_values()
		return self.options:extract_values()
	end

	function prototype:has_flags()
		local length = #self.options.ordered_flags

		if length == 0 then return false end

		if length == 1 then
			return self.options.ordered_flags[1].name_with_hyphens ~= "help"
		end

		return true
	end

	function prototype:flags()
		return coroutine.wrap(function()
			for _, flag in ipairs(self.options.ordered_flags) do
				coroutine.yield(flag)
			end
		end)
	end

	function prototype:positionals()
		return coroutine.wrap(function()
			for _, positional in ipairs(self.options.positionals) do
				coroutine.yield(positional)
			end
		end)
	end

	return setmetatable(cmd, { __index = prototype })
end

local function new_command(data)
	local cmd = {
		options = options_table(data),
		description = type(data[1]) == "string" and data[1] or "",
		fn = type(data[#data]) == "function" and data[#data] or nil
	}

	return command_prototype(cmd)
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
	local help_flag = option.flag "h,help" {
		translations.help_description(),
		type = option.boolean
	}

	if type(data) == "string" then
		cmd = new_command { data, help_flag }

	else
		table.insert(data, 2, help_flag)
		cmd = new_command(data)
	end

	function cmd:parse_args()
		if not has_subcommands() then
			return parse_args(self.options)
		end

		-- If we have subcommands defined, we need to add a fake first
		-- positional argument so that the parser can handle the command name
		-- correctly
		local command_name = option.positional "Este é o nome do comando" { type = option.string }
		local fake_options = options_table { command_name }
		local options = merge_options( { options = fake_options }, self )
		return parse_args(options)
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

	for _, v in ipairs(options1.ordered_flags) do
		merged[#merged + 1] = v
	end

	for _, v in ipairs(options2.ordered_flags) do
		merged[#merged + 1] = v
	end

	return options_table(merged)
end

function load()
	-- We are going to use the `parse_args` function to retrieve the command
	-- name and, possibly, the `help` flag. To do so, we will define a fake
	-- command with a sole positional argument corresponding to the command
	-- name.
	local name = option.positional "Este é o nome do comando" { type = option.string }
	local fake_cmd = global_command { name }
	parse_args(fake_cmd.options)

	local help = fake_cmd:help_requested()

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
