local tr = require "translations"

local exit = os.exit
local ipairs = ipairs
local pairs = pairs
local setmetatable = setmetatable
local stderr = io.stderr
local table = table
local tostring = tostring
local type = type

local _ENV = {}

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
	local text = {}

	for _, command in ipairs(list) do
		text[#text + 1] = "    * " .. command .. "\n"
	end

	return table.concat(text)
end

local function new(code, ...)
	local extra_args = {...}
	local err = {
		__error = true,
		code = code
	}

	local meta = {
		__tostring = function()
			return tr[code](table.unpack(extra_args))
    	end
	}

	return setmetatable(err, meta)
end

function is_error(t)
	return type(t) == "table" and t.__error
end

function command_not_provided(available_commands)
	local commands = show_list(available_commands)
	return new("command_not_provided", commands)
end

function unknown_command(name, available_commands)
	local commands = show_list(available_commands)
	return new("unknown_command", name, commands)
end

function unknown_arg(name)
	return new("unknown_arg", name)
end

function missing_value(name)
	return new("missing_value", name)
end

function not_expecting(arg, value)
	return new("not_expecting", value, arg)
end

function not_a_number(arg, value)
	return new("not_a_number", arg, value)
end

function unexpected_positional(value)
	return new("unexpected_positional", value)
end

function holder()
	local h = {
		empty = true,
		errs = {}
	}

	function h:add(err)
		self.empty = false
		local list = self.errs[err.code] or {}
		list[#list+1] = err
		self.errs[err.code] = list
	end

	function h:errors()
		if self.empty then return nil end

		local errs = { __error = true }

		local meta = {
			__tostring = function()
				local messages = { tr.holder() }

				for _, error_list in pairs(h.errs) do
					for _, err in ipairs(error_list) do
						messages[#messages+1] = "    * " .. tostring(err)
					end
				end

				return table.concat(messages, "\n")
			end
		}

		return setmetatable(errs, meta)
	end

	return h
end

return _ENV
