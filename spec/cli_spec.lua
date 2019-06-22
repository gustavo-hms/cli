cli = require "cli"

describe("The #flag function", function()
	it("should build the prescribed object", function()
		local flag = cli.flag {
			"Descrição",

			type = cli.string,
			default = "opa!"
		}

		local expected = {
			description = "Descrição",
			type = cli.string,
			value = "opa!"
		}

		for k in pairs(expected) do
			assert.are.equal(expected[k], flag[k])
		end
	end)

	it("shouldn't set `value` if there isn't a default value", function()
		local flag = cli.flag {
			type = cli.number
		}

		assert.is_nil(flag.value)
	end)

	it("shouldn't build a flag when default value doesn't have the right type", function()
		local flag = cli.flag {
			type = cli.number,
			default = "dezessete"
		}

		assert.is_nil(flag)
	end)
end)

describe("The #flag_named function", function()
	it("should set the name of the flag", function()
		local flag = cli.flag_named "p,por-dia" {
			"Outra flag",

			type = cli.number,
			default = 17
		}

		local expected = {
			description = "Outra flag",
			type = cli.number,
			value = 17,
			short_name = "p",
			long_name_with_hyphens = "por-dia",
			long_name_with_underscores = "por_dia"
		}

		for k in pairs(expected) do
			assert.is.equal(expected[k], flag[k])
		end
	end)

	it("should allow prescribing short names only", function()
		local flag = cli.flag_named "p" {
			"Outra flag",

			type = cli.number,
			default = 17
		}

		local expected = {
			description = "Outra flag",
			type = cli.number,
			value = 17,
			short_name = "p",
			long_name_with_hyphens = "p",
			long_name_with_underscores = "p"
		}

		for k in pairs(expected) do
			assert.is.equal(expected[k], flag[k])
		end
	end)

	it("should allow prescribing long names only", function()
		local flag = cli.flag_named "por-dia" {
			"Outra flag",

			type = cli.number,
			default = 17
		}

		local expected = {
			description = "Outra flag",
			type = cli.number,
			value = 17,
			long_name_with_hyphens = "por-dia",
			long_name_with_underscores = "por_dia"
		}

		for k in pairs(expected) do
			assert.is.equal(expected[k], flag[k])
		end
	end)
end)

describe("The #positional function", function()
	it("should build the prescribed positional argument", function()
		local positional = cli.positional "este-aqui" {
			"Cada argumento...",

			type = cli.string,
			default = "nenhum"
		}

		local expected = {
			description = "Cada argumento...",
			type = cli.string,
			value = "nenhum",
			name_with_hyphens = "este-aqui",
			name_with_underscores = "este_aqui"
		}

		for k in pairs(expected) do
			assert.is.equal(expected[k], positional[k])
		end
	end)

	it("shouldn't set `value` if there isn't a default value", function()
		local positional = cli.positional "este-aqui" {
			"Cada argumento...",

			type = cli.string,
		}

		assert.is_nil(positional.value)
	end)

	it("should take into account the `many` option", function()
		local positional = cli.positional "este-aqui" {
			type = cli.number,
			default = 17,
			many = true
		}

		assert.is.equal({17}, positional.value)
	end)
end)

local function keys(t)
	local ks = {}

	for k in pairs(t) do
		ks[#ks + 1] = k
	end

	return ks
end

describe("The #command function", function()
	describe("when setting an argument", function()
		it("should put a flag on the right place in the table", function()
			local command = cli.command {
				"Documentação in loco",

				first_flag = cli.flag {
					"Explicação da primeira flag",

					type = cli.boolean
				}
			}

			assert.is_not_nil(command.args)
			assert.is.equal(1, #keys(command.args))

			assert.is_not_nil(command.args["first-flag"])
			assert.is.equal(
				"Explicação da primeira flag",
				command.args["first-flag"].description
			)
		end)

		it("should deal with a flag containing both a short and a long name", function()
			local command = cli.command {
				"Documentação in loco",

				["s,second-flag"] = cli.flag {
					"O que faz",

					type = cli.number,
					default = 7
				}
			}

			assert.is_not_nil(command.args["second-flag"])
			assert.is.equal("O que faz", command.args["second-flag"].description)
		end)

		it("should deal with a named flag", function()
			local command = cli.command {
				"Documentação in loco",

				["s,second-flag"] = cli.flag {
					"O que faz",

					type = cli.number,
					default = 7
				}
			}

			assert.is_not_nil(command.args["third-flag"])
			assert.is.equal("A ordem conta", command.args["third-flag"].description)
		end)

		it("should deal with a positional argument", function()
			local command = cli.command {
				"Documentação in loco",

				cli.positional "file" {
					"The file to be edited",

					type = cli.string
				},
			}

			assert.is_not_nil(command.args["file"])
			assert.is.equal("The file to be edited", command.args["file"].description)
		end)
	end)

	it("should set the commands' function", function()
		local command = cli.command {
			"Documentação in loco",

			function()
				return 17
			end
		}

		assert.is_not_nil(command.fn)
		assert.is.equal("function", type(command.fn))
		assert.is.equal(17, command.fn())
	end)
end)
