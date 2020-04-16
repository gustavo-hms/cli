local iter = require "iterators"
local tr = require "translations"

local arg = arg
local error = error
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
	error(string.format(message, ...), 3)
end

local function write(err)
	stderr:write(tostring(err))
end

function exit_with(err)
	write(err)
	exit(101)
end

function assert(...)
	local args = {...}
	local last = args[#args]

	if is_error(last) then
		exit_with(last)
	end

	return ...
end

local function show_list(list)
	return iter.sequence(list):map(function(cmd) return string.format("    - %s\n", cmd) end):concat()
end

local error_prototype = {}

function error_prototype:error_with_code(code)
	if self.code == code then return self end
end

local function new_validation_item(code, ...)
	local extra_args = {...}
	local err = {
		__error = true,
		code = code,
		extra_info = extra_args
	}

	local meta = {
		__tostring = function()
			return tr[code](table.unpack(extra_args))
    	end,

		__index = error_prototype,
	}

	return setmetatable(err, meta)
end

local function new_with_tip(code, ...)
	local extra_args = {...}
	local err = {
		__error = true,
		code = code,
		extra_info = extra_args
	}

	local meta = {
		__tostring = function()
			return tr[code](table.unpack(extra_args)) .. tr.tip(arg[0])
    	end,

		__index = error_prototype,
	}

	return setmetatable(err, meta)
end

function is_error(t)
	return type(t) == "table" and t.__error
end

function command_not_provided(available_commands)
	local commands = show_list(available_commands)
	return new_with_tip("command_not_provided", commands)
end

function unknown_command(name, available_commands)
	local commands = show_list(available_commands)
	return new_with_tip("unknown_command", name, commands)
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

local validation_prototype = { __error = true }
validation_prototype.__index = validation_prototype

function validation_prototype:__tostring()
	local messages = { tr.holder() }

	for _, error_list in pairs(self.errors) do
		for _, err in ipairs(error_list) do
			messages[#messages+1] = "    - " .. tostring(err)
		end
	end

	messages[#messages+1] = tr.tip(arg[0])

	return table.concat(messages, "\n")
end

function validation_prototype:error_with_code(code)
	return self.errors[code] and self.errors[code][1]
end

local function new_validation(items)
	local t = { errors = items }
	return setmetatable(t, validation_prototype)
end

local list_prototype = {}
list_prototype.__index = list_prototype

function list_prototype:add(err)
	self.empty = false
	local list = self.errs[err.code] or {}
	list[#list+1] = err
	self.errs[err.code] = list
end

function list_prototype:errors()
	if self.empty then return end
	return new_validation(self.errs)
end

function list()
	local v = {
		empty = true,
		errs = {}
	}

	return setmetatable(v, list_prototype)
end

return _ENV
