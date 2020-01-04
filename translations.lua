local setmetatable = setmetatable

local _ENV = {}

local translations = {
	pt_BR = {
		holder = "Foram encontrados erros na execução do programa.",

		not_expecting = "O valor “%s” foi passado para a opção “%s”, que não espera receber nenhum valor.",

		not_a_number = "A opção “%s” espera receber um número, mas o valor passado foi “%s”.",

		missing_value = "Nenhum valor informado para a opção “%s”.",

		unknown_arg = "Opção desconhecida: “%s”.",

		unexpected_positional = "O valor “%s” informado não era esperado e o programa não sabe o que fazer com ele.",

		command_not_provided = "Erro: não foi informado qual comando executar. Os comandos disponíveis são:\n\n%s\n",

		unknown_command = "Erro: o comando “%s” não existe. Os comandos disponíveis são:\n\n%s\n"
	}
}

local selected = translations.pt_BR

function locale(l)
	selected = translations[l] or selected
end

local meta = {
	__index = function(_, index)
		return function(...)
			return selected[index]:format(...)
		end
	end
}
setmetatable(_ENV, meta)

return _ENV
