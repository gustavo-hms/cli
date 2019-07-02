local tr = require("translations").tr

local table = table
local setmetatable = setmetatable
local ipairs = ipairs
local stderr = io.stderr
local tostring = tostring
local exit = os.exit

local _ENV = {}

local codes = {
	missing_value = 100,
	not_expecting = 101,
	not_a_number = 102,

	command_not_provided = 200,
	unknown_command = 201
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

	if last.__type == "error" then
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
	local meta = {
		__tostring = function()
			local cmds = list(available_commands)
			return tr.command_not_provided(cmds)
		end
	}

	local err = {
		__type = "error",
		code = codes.command_not_provided
	}

	return setmetatable(err, meta)
end

function unknown_command(name, available_commands)
	local meta = {
		__tostring = function()
			local cmds = list(available_commands)
			return tr.unknown_command(name, cmds)
		end
	}

	local err = {
		__type = "error",
		code = codes.unknown_command
	}
	return setmetatable(err, meta)
end

return _ENV
