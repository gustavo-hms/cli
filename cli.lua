local os = os
local type = type
local pairs = pairs
local ipairs = ipairs

local args = require "args"
local command = require "command"

local _ENV = {}

-- Re-exports

flag = args.flag
flag_named = args.flag_named
positional = args.positional
boolean = args.boolean
number = args.number
string = args.string
command = command.command

-- Programs

local function program_name()
	return arg[0]:match("[^/]+$")
end

local function program(cmd)
	local positional_index = 1

	for _, argument in ipairs(arguments()) do
		if argument.name then
			-- It's a flag

			if argument.name == "help" then
				help(cmd)
				os.exit(0)
			end

			local flg = cmd.flags[argument.name]

			if not flg then
				-- TODO decidir o que fazer com os erros
				errors.not_expecting("--" .. argument.name)

			else
				-- TODO aqui pode ter erro também
				flg:set(argument)
			end

		else
			-- It's a positional argument
			local positional = cmd.flags[positional_index]

			if not positional then
				errors.not_expecting("--" .. argument.name)
			else
				positional:add(argument.positional)

				if not positional.many then
					positional_index = positional_index + 1
				end
			end
		end
	end

	-- TODO verificar argumentos obrigatórios
	-- Não daria pra montar uma lista de argumentos obrigatórios no momento da
	-- definição deles?

	os.exit(cmd.fn and cmd.fn())
end

function run(data)
	local cmd = anonymous_command(data)

	if commands_defined then
		if cmd.flags then
			return program_with_options_and_commands(cmd)
		end

		return program_with_commands(cmd)
	end

	return program(cmd)
end

return _ENV
