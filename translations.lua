local setmetatable = setmetatable

local _ENV = {}

local translations = {
	pt_BR = {
		not_expecting = "O valor “%s” foi passado para a opção “%s”, que não espera receber nenhum valor.",

		not_a_number = "A opção “%s” espera receber um número, mas o valor passado foi “%s”.",

		missing_value = "Nenhum valor informado para a opção “%s”.",

		command_not_provided = "Erro: não foi informado qual comando executar. Os comandos disponíveis são:\n\n%s\n",

		unknown_command = "Erro: o comando “%s” não existe. Os comandos disponíveis são:\n\n%s\n"
	}
}

local selected = translations.pt_BR

function locale(l)
	selected = translations[l] or selected
end

tr = {}
local meta = {
	__index = function(_, index)
		return function(...)
			return selected[index]:format(...)
		end
	end
}
setmetatable(tr, meta)

return _ENV
