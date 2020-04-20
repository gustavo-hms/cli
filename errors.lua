local iter = require "iterators"
local tr = require "translations"

local arg = arg
local panic_with_error = error
local exit = os.exit
local ipairs = ipairs
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

local function write(err)
	stderr:write(tostring(err))
end

function exit_with(err)
	write(err)
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

-- This module defines an `error` interface, containing the following fields:
--
--     - __error: signaling this is an error type; used for introspection;
--
--     - __tostring: all errors can be printed;
--
--     - error_with_code(<a code>): a debug function that returns an `error`
--       value in one of the following cases:
--
--         * if the method's receiver is an error with the specified code; in
--           this case, the method returns `self`;
--
--         * if the method's receiver holds an error with the specified code
--           (used for the `validation_error` type).
--
-- The module has 3 types implementing this interface:
--
--     - `error`;
--     - `validation_error`;
--     - `validation_item`.


local function show_list(list)
	return iter.sequence(list):map(function(cmd) return string.format("    - %s\n", cmd) end):concat()
end

local error = { __error = true }
error.__index = error

function error:error_with_code(code)
	if self.code == code then return self end
end

function error:__tostring()
	local message = tr[self.code](table.unpack(self.extra_info))
	if self.tip then message = string.format("%s\n%s", message, tr.tip(arg[0])) end
	return message
end

local function new_error(code, ...)
	local err = { code = code, extra_info = {...}, tip = true }
	return setmetatable(err, error)
end

function command_not_provided(available_commands)
	local commands = show_list(available_commands)
	return new_error("command_not_provided", commands)
end

function unknown_command(name, available_commands)
	local commands = show_list(available_commands)
	return new_error("unknown_command", name, commands)
end


local function new_validation_item(code, ...)
	local err = { code = code, extra_info = {...} }
	return setmetatable(err, error)
end

function unknown_arg(name)
	return new_validation_item("unknown_arg", name)
end

function missing_value(name)
	return new_validation_item("missing_value", name)
end

function not_expecting(arg, value)
	return new_validation_item("not_expecting", value, arg)
end

function not_a_number(arg, value)
	return new_validation_item("not_a_number", arg, value)
end

function unexpected_positional(value)
	return new_validation_item("unexpected_positional", value)
end


local validation_error = { __error = true }
validation_error.__index = validation_error

function validation_error:__tostring()
	local messages = { tr.holder() }

	for _, error_list in pairs(self.errors) do
		for _, err in ipairs(error_list) do
			messages[#messages+1] = "    - " .. tostring(err)
		end
	end

	messages[#messages+1] = tr.tip(arg[0])

	return table.concat(messages, "\n")
end

function validation_error:error_with_code(code)
	return self.errors[code] and self.errors[code][1]
end

local function new_validation_error(items)
	local t = { errors = items }
	return setmetatable(t, validation_error)
end


local list_prototype = {}
list_prototype.__index = list_prototype

function list_prototype:add(err)
	self.empty = false
	local list = self.errs[err.code] or {}
	list[#list+1] = err
	self.errs[err.code] = list
end

function list_prototype:toerror()
	if self.empty then return end
	return new_validation_error(self.errs)
end

function list()
	local v = { empty = true, errs = {} }
	return setmetatable(v, list_prototype)
end

return _ENV
