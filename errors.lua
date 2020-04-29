local iter = require "iterators"
local translations = require "translations"

local arg = arg
local panic_with_error = error
local exit = os.exit
local setmetatable = setmetatable
local stderr = io.stderr
local string = string
local table = table
local tostring = tostring
local type = type

local _ENV = {}

local chain, once, sequence = iter.chain, iter.once, iter.sequence

function panic(message, ...)
	panic_with_error(string.format(message, ...), 3)
end

function exit_with(err)
	stderr:write(tostring(err))
	exit(101)
end

local function is_error(t)
	return type(t) == "table" and t.__error
end

function assert(...)
	local args = {...}
	local last = args[#args]

	if is_error(last) then
		exit_with(last)
	end

	return ...
end

local function message(code, ...)
	return { code = code, text = translations[code](...) }
end

local error = { __error = true }

error.__index = error

function error:__tostring()
	local messages = chain(sequence(self.messages), once{text=""}, once(message("tip", arg[0])))
	return messages:map(function(m) return m.text end):concat("\n")
end

function error:message_with_code(code)
	return sequence(self.messages):find(function(m) return m.code == code end)
end

local function new_error(...)
	return setmetatable( { messages = {...} }, error )
end

local function show_list(list)
	local show_element = function(e) return string.format("    ∙ %s", e) end
	return sequence(list):map(show_element):concat("\n")
end

function command_not_provided(available_commands)
	local commands = show_list(available_commands)
	return new_error(message("command_not_provided", commands))
end

function unknown_command(name, available_commands)
	local commands = show_list(available_commands)
	return new_error(message("unknown_command", name, commands))
end

function validation()
	return {
		items = {},

		add = function(self, item)
			self.items[#self.items+1] = item
		end
	}
end

function toerror(validation)
	if #validation.items == 0 then return end

	local messages =
		chain(once(message "validation"), once{text=""}, sequence(validation.items)):array()
	return new_error(table.unpack(messages))
end

local function validation_item(code, ...)
	return { code = code, text = "    ∙ " .. translations[code](...) }
end

function flag_unknown_arg(name)
	return validation_item("flag_unknown_arg", name)
end

function flag_missing_value(name)
	return validation_item("flag_missing_value", name)
end

function positional_missing_value(name)
	return validation_item("positional_missing_value", name)
end

function flag_not_expecting(arg, value)
	return validation_item("flag_not_expecting", value, arg)
end

function flag_not_a_number(arg, value)
	return validation_item("flag_not_a_number", arg, value)
end

function positional_not_a_number(arg, value)
	return validation_item("positional_not_a_number", arg, value)
end

function unexpected_positional(value)
	return validation_item("unexpected_positional", value)
end

return _ENV
