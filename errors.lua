local tr = require("translations").tr

local table = table
local setmetatable = setmetatable
local ipairs = ipairs
local pairs = pairs
local stderr = io.stderr
local tostring = tostring
local exit = os.exit

local _ENV = {}

local codes = {
	command_not_provided = 100,
	unknown_command = 101,

	missing_value = 1 << 7,
	not_expecting = 1 << 8,
	not_a_number = 1 << 9
}

function print(err)
	stderr:write(tostring(err))
end

function exit_with(err)
	print(err)
	exit(err.code)
end

function assert(...)
	local args = {...}
	local last = args[#args]

	if last and last.__error then
		exit_with(last)
	end

	return ...
end

local function list(available_commands)
	local text = {}

	for _, command in ipairs(available_commands) do
		text[#text + 1] = "    * " .. command .. "\n"
	end

	return table.concat(text)
end

function command_not_provided(available_commands)
	local err = {
		code = codes.command_not_provided,

		__error = true,

		__tostring = function()
			local cmds = list(available_commands)
			return tr.command_not_provided(cmds)
		end
	}

	return setmetatable(err, err)
end

function unknown_command(name, available_commands)
	local err = {
		code = codes.unknown_command,

		__error = true,

		__tostring = function()
			local cmds = list(available_commands)
			return tr.unknown_command(name, cmds)
		end
	}

	return setmetatable(err, err)
end

local function new_arg_error(code, ...)
	local extra_args = {...}
	local err = {
		code = codes[code],
		__error = true,

		__tostring = function()
			return tr[code](table.unpack(extra_args))
		end
	}

	return setmetatable(err, err)
end

function unknown_arg(name)
	return new_arg_error("unknown_arg", name)
end

function missing_value(name)
	return new_arg_error("missing_value", name)
end

function not_expecting(arg, value)
	return new_arg_error("not_expecting", value, arg)
end

function not_a_number(arg, value)
	return new_arg_error("not_a_number", arg, value)
end

function unexpected_positional(value)
	return new_arg_error("unexpected_positional", value)
end

function holder()
	local h = {
		__error = true,

		missing_value = {},
		not_expecting = {},
		not_a_number = {},

		-- The holder's code is a bitflag of the individual errors it contains
		code = 0,
	}

	function h:add(err)
		for error_name, error_code in pairs(codes) do
			if err.code == error_code then
				local errs = self[error_name]
				errs[#errs + 1] = err
				self.code = self.code | error_code
			end
		end
	end

	function h:errors()
		if self.code == 0 then return nil end

		local err = {
			missing_value = self.missing_value,
			not_expecting = self.not_expecting,
			not_a_number = self.not_a_number,
			code = self.code
		}

		function err:__tostring()
			if self.code == 0 then return "" end
	
			local messages = { tr.holder() }
	
			local error_types = { "unknown_arg", "missing_value", "not_expecting", "not_a_number" }
	
			for _, error_type in ipairs(error_types) do
				if #self[error_type] > 0 then messages[#messages + 1] = "" end
	
				for _, err in ipairs(self[error_type]) do
					messages[#messages + 1] = "    * " .. tostring(err)
				end
			end
	
			return table.concat(messages, "\n")
		end

		return setmetatable(err, err)
	end

	return h
end

return _ENV
