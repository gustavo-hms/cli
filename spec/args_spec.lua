local args = require "args"

describe("The #flag function", function()
	it("should build the prescribed object", function()
		local flag = args.flag {
			"Descrição",

			type = args.string,
			default = "opa!"
		}

		local expected = {
			description = "Descrição",
			type = args.string,
			value = "opa!"
		}

		for k in pairs(expected) do
			assert.are.equal(expected[k], flag[k])
		end
	end)

	it("shouldn't set `value` if there isn't a default value", function()
		local flag = args.flag {
			type = args.number
		}

		assert.is_nil(flag.value)
	end)

	it("shouldn't build a flag when default value doesn't have the right type", function()
		local flag = args.flag {
			type = args.number,
			default = "dezessete"
		}

		assert.is_nil(flag)
	end)
end)

describe("The #flag_named function", function()
	it("should set the name of the flag", function()
		local flag = args.flag_named "p,por-dia" {
			"Outra flag",

			type = args.number,
			default = 17
		}

		local expected = {
			description = "Outra flag",
			type = args.number,
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
		local flag = args.flag_named "p" {
			"Outra flag",

			type = args.number,
			default = 17
		}

		local expected = {
			description = "Outra flag",
			type = args.number,
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
		local flag = args.flag_named "por-dia" {
			"Outra flag",

			type = args.number,
			default = 17
		}

		local expected = {
			description = "Outra flag",
			type = args.number,
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
		local positional = args.positional "este-aqui" {
			"Cada argumento...",

			type = args.string,
			default = "nenhum"
		}

		local expected = {
			description = "Cada argumento...",
			type = args.string,
			value = "nenhum",
			name_with_hyphens = "este-aqui",
			name_with_underscores = "este_aqui"
		}

		for k in pairs(expected) do
			assert.is.equal(expected[k], positional[k])
		end
	end)

	it("shouldn't set `value` if there isn't a default value", function()
		local positional = args.positional "este-aqui" {
			"Cada argumento...",

			type = args.string,
		}

		assert.is_nil(positional.value)
	end)

	it("should take into account the `many` option", function()
		local positional = args.positional "este-aqui" {
			type = args.number,
			default = 17,
			many = true
		}

		assert.is.equal({17}, positional.value)
	end)
end)
