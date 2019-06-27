cmd = require "command"
args = require "args"

describe("The #command function", function()
	describe("when setting an argument", function()
		it("should put a flag on the right place in the table", function()
			local command = cmd.command {
				"Documentação in loco",

				first_flag = args.flag {
					"Explicação da primeira flag",

					type = args.boolean
				}
			}

			assert.is_not_nil(command.args)
			assert.is_not_nil(command.args["first-flag"])
			assert.is.equal(
				"Explicação da primeira flag",
				command.args["first-flag"].description
			)
		end)

		it("should deal with a flag containing both a short and a long name", function()
			local command = cmd.command {
				"Documentação in loco",

				["s,second-flag"] = args.flag {
					"O que faz",

					type = args.number,
					default = 7
				}
			}

			assert.is_not_nil(command.args["second-flag"])
			assert.is.equal("O que faz", command.args["second-flag"].description)
		end)

		it("should deal with a named flag", function()
			local command = cmd.command {
				"Documentação in loco",

				args.flag_named "third-flag" {
					"A ordem conta",

					type = args.string,
					default = "terceira"
				},
			}

			assert.is_not_nil(command.args["third-flag"])
			assert.is.equal("A ordem conta", command.args["third-flag"].description)
		end)

		it("should deal with a positional argument", function()
			local command = cmd.command {
				"Documentação in loco",

				args.positional "file" {
					"The file to be edited",

					type = args.string
				},
			}

			assert.is_not_nil(command.args[1])
			assert.is.equal("The file to be edited", command.args[1].description)
		end)
	end)

	it("should set the commands' function", function()
		local command = cmd.command {
			"Documentação in loco",

			function()
				return 17
			end
		}

		assert.is_not_nil(command.fn)
		assert.is.equal("function", type(command.fn))
		assert.is.equal(17, command.fn())
	end)

	describe("when setting the arguments' values", function()
		it("should set all the values", function()
			local command = cmd.command {
				"Documentação",

				first_flag = args.flag {
					"Primeira",

					type = args.string
				},

				second_flag = args.flag {
					"Segunda",

					type = args.number
				},

				args.flag_named "third-flag" {
					"Terceira",

					type = args.boolean
				},

				args.positional "file" {
					"Arquivo",

					type = args.string
				}
			}

			local input_args = {
				{ positional = "code.lua" },
				{ name = "third-flag" },
				{ name = "first-flag", value = "valoroso" },
				{ name = "second-flag", value = 17 }
			}

			local unset, unknown = command:set_arguments(input_args)

			assert.is_nil(unset)
			assert.is_nil(unknown)
			assert.is.equal("code.lua", command.values.file)
			assert.is.equal(true, command.values.third_flag)
			assert.is.equal("valoroso", command.values.first_flag)
			assert.is.equal(17, command.values.second_flag)
		end)
	end)
end)
