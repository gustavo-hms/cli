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

		unknown_command = "Erro: o comando “%s” não existe. Os comandos disponíveis são:\n\n%s\n",

		help_options = "[opções]",

		help_with_subcommands = [[%s

Uso:

%s
Você pode rodar

    %s <comando> --help

para obter maiores detalhes sobre um comando específico.

]],

		help_subcommand_with_options_and_arguments = [[%s

Uso:
%s

Opções:
%s

Argumentos:
%s

]]
	},
	en_US = {
		holder = "Errors were found in the program execution.",

		not_expecting = "The value “%s” was passed to the option “%s”, which doesn't expect any value.",

		not_a_number = "The option “%s” expects a number, but the given value was “%s”.",

		missing_value = "No value given to the option “%s”.",

		unknown_arg = "Unknown option: “%s”.",

		unexpected_positional = "The given value “%s” and the program doesn't know what to do with it.",

		command_not_provided = "Error: no command given. Available commands are:\n\n%s\n",

		unknown_command = "Error: the command “%s” doesn't exist. Available commands are:\n\n%s\n",

		help_options = "[options]",

		help_with_subcommands = [[%s

Usage:

%s
You can run

    %s <command> --help

to get more details about a specific command.

]],

		help_subcommand_with_options_and_arguments = [[%s

Usage:
%s

Options:
%s

Arguments:
%s

]]
	}
}

local selected = translations.pt_BR

function locale(l)
	selected = translations[l] or selected
end

-- The following code block will allow using the `translations` module as a
-- collection of functions, each one being named after a key in the
-- `translations` table above.  So, for instance, we will have a
-- `not_expecting` function with 2 arguments corresponding to each of the "%s"
-- placeholders inside the translation string. One uses it like this:
--
--     local translations = require "translations"
--
--     local text = translations.not_expecting("0", "non-zero")
--
-- The performance penalties involved in this metaprogramming is mitigated by
-- the fact that the `translations` module is only used for help and error
-- messages.
local meta = {
	__index = function(_, index)
		return function(...)
			return selected[index]:format(...)
		end
	end
}
setmetatable(_ENV, meta)

return _ENV
