local iter = require "iterators"
local translations = require "translations"

local arg = arg
local panic_with_error = error
local exit = os.exit
local ipairs = ipairs
local next = next
local pairs = pairs
local setmetatable = setmetatable
local stderr = io.stderr
local string = string
local table = table
local tostring = tostring
local type = type

local _ENV = {}

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
	local messages = iter.sequence(self.messages):map(function(i) return i.text end)
	return iter.chain(messages, iter.once(message("tip", arg[0]))):concat("\n")
end

function error:message_with_code(code)
	return iter.sequence(self.messages):find(function(i) return i.code == code end)
end

local function new_error(...)
	return setmetatable( { messages = {...} }, error )
end

local function show_list(list)
	local show_element = function(e) return string.format("    - %s", e) end
	return iter.sequence(list):map(show_element):concat("\n")
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
			local items_by_code = self.items[item.code] or {}
			items_by_code[#items_by_code+1] = item
			self.items[item.code] = items_by_code
		end
	}
end

function toerror(validation)
	if next(validation.items) == nil then return end

	local messages = { message "holder" }

	for _, items_by_code in pairs(validation.items) do
		for _, item in ipairs(items_by_code) do
			messages[#messages+1] = item
		end
	end

	return new_error(table.unpack(messages))
end

local function validation_item(code, ...)
	return { code = code, text = "    - " .. translations[code](...) }
end

function unknown_arg(name)
	return validation_item("unknown_arg", name)
end

function missing_value(name)
	return validation_item("missing_value", name)
end

function not_expecting(arg, value)
	return validation_item("not_expecting", value, arg)
end

function not_a_number(arg, value)
	return validation_item("not_a_number", arg, value)
end

function unexpected_positional(value)
	return validation_item("unexpected_positional", value)
end

return _ENV
