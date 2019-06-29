local table = table
local setmetatable = setmetatable
local ipairs = ipairs
local stderr = io.stderr
local tostring = tostring

local _ENV = {}

local translations = {
	pt_BR = {
		not_expecting = "O valor “%s” foi passado para a opção “%s”, que não espera receber nenhum valor.",

		not_a_number = "A opção “%s” espera receber um número, mas o valor passado foi “%s”.",

		missing_value = "Nenhum valor informado para a opção “%s”.",

		command_not_provided = "Erro: não foi informado qual comando executar. As opções disponíveis são:\n\n%s\n",

		unknown_command = "Erro: o comando “%s” não existe. Os possíveis valores são:\n\n%s\n"
	}
}

local codes = {
	missing_value = 100,
	not_expecting = 101,
	not_a_number = 102,

	command_not_provided = 200,
	unknown_command = 201
}

local messages = translations.pt_BR

function locale(l)
	messages = translations[l]
end

function print(err)
	stderr:write(tostring(err))
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
			return messages.command_not_provided:format(cmds)
		end
	}

	local err = {
		code = codes.command_not_provided,
		print = print
	}

	return setmetatable(err, meta)
end

function unknown_command(name, available_commands)
	local meta = {
		__tostring = function()
			local cmds = list(available_commands)
			return messages.unknown_command:format(name, cmds)
		end
	}

	local err = {
		code = codes.unknown_command,
		print = print
	}

	return setmetatable(err, meta)
end

return _ENV
