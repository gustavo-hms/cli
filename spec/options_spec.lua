local options = require "options"

describe("The #flag function", function()
	it("should build the prescribed object", function()
		local flag = options.flag "name" {
			"Descrição",

			type = options.string,
			default = "opa!"
		}

		local expected = {
			description = "Descrição",
			type = options.string,
			value = "opa!"
		}

		for k in pairs(expected) do
			assert.are.equal(expected[k], flag[k])
		end
	end)

	it("should set a boolean flag with `false` if there's no default value", function()
		local flag = options.flag "name" {
			type = options.boolean
		}

		assert.is_false(flag.value)
	end)

	it("shouldn't set `value` if there isn't a default value", function()
		local flag = options.flag "name" {
			type = options.number
		}

		assert.is_nil(flag.value)
	end)

	it("should set the name of the flag", function()
		local flag = options.flag "p,por-dia" {
			"Outra flag",

			type = options.number,
			default = 17
		}

		local expected = {
			description = "Outra flag",
			type = options.number,
			value = 17,
			names = {"p", "por-dia"},
		}

		for k in pairs(expected) do
			assert.are.same(expected[k], flag[k])
		end
	end)

	it("should allow prescribing short names only", function()
		local flag = options.flag "p" {
			"Outra flag",

			type = options.number,
			default = 17
		}

		local expected = {
			description = "Outra flag",
			type = options.number,
			value = 17,
			names = { "p" },
		}

		for k in pairs(expected) do
			assert.are.same(expected[k], flag[k])
		end
	end)

	it("should allow prescribing long names only", function()
		local flag = options.flag "por-dia" {
			"Outra flag",

			type = options.number,
			default = 17
		}

		local expected = {
			description = "Outra flag",
			type = options.number,
			value = 17,
			names = { "por-dia" },
		}

		for k in pairs(expected) do
			assert.are.same(expected[k], flag[k])
		end
	end)

	it("should type check default arguments", function()
		assert.has.errors(function()
			options.flag "nome" {
				type = options.number,
				default = "dezessete"
			}
		end)
	end)
end)

describe("The #positional function", function()
	it("should build the prescribed positional argument", function()
		local positional = options.positional "este-aqui" {
			"Cada argumento...",

			type = options.string,
			default = "nenhum"
		}

		local expected = {
			description = "Cada argumento...",
			type = options.string,
			value = "nenhum",
			name = "este-aqui",
		}

		for k in pairs(expected) do
			assert.is.equal(expected[k], positional[k])
		end
	end)

	it("shouldn't set `value` if there isn't a default value", function()
		local positional = options.positional "este-aqui" {
			"Cada argumento...",

			type = options.string,
		}

		assert.is_nil(positional.value)
	end)

	it("should take into account the `many` option", function()
		local positional = options.positional "este-aqui" {
			type = options.number,
			default = {17, 19},
			many = true
		}

		assert.are.same({17, 19}, positional.value)
	end)

	it("should type check a default argument", function()
		assert.has.errors(function()
			options.positional "nome" {
				type = options.number,
				default = "dezessete"
			}
		end)
	end)

	it("should type check a default argument when the `many` flag is set", function()
		assert.has.errors(function()
			options.positional "nome" {
				type = options.number,
				default = 17,
				many = true
			}
		end)

		assert.has.errors(function()
			options.positional "nome" {
				type = options.number,
				default = {17, "dezessete"},
				many = true
			}
		end)

		assert.has_no.errors(function()
			options.positional "nome" {
				type = options.string,
				default = {"um", "dois"},
				many = true
			}
		end)
	end)
end)

describe("The #positional #add method", function()
	it("should update its `value` attribute", function()
		local positional = options.positional "name" {
			type = options.string
		}

		local err = positional:add("nome")
		assert.is_nil(err)
		assert.are.equal("nome", positional.value)
	end)

	it("should set #many values", function()
		local positional = options.positional "name" {
			type = options.string,
			many = true
		}

		local err = positional:add("um")
		assert.is_nil(err)

		err = positional:add("dois")
		assert.is_nil(err)

		err = positional:add("três")
		assert.is_nil(err)

		assert.are.same({"um", "dois", "três"}, positional.value)
	end)

	it("shouldn't set #many values", function()
		local positional = options.positional "name" {
			type = options.string
		}

		local err = positional:add("um")
		assert.is_nil(err)

		err = positional:add("dois")
		assert.is_nil(err)

		err = positional:add("três")
		assert.is_nil(err)

		assert.are.equal("três", positional.value)
	end)
end)

local translations = require "translations"

describe("An #option should #panic", function()
	it("with a #flag type mismatch", function()
		local flag = function()
			options.flag "a-flag" {
				type = options.number,
				default = "treze",
			}
		end
		assert.has_error(flag, translations.panic_flag_type_mismatch("a-flag", "treze"))
	end)

	it("with a #positional default that is not a table", function()
		local positional = function()
			options.positional "posicional" {
				type = options.number,
				default = 17,
				many = true,
			}
		end
		assert.has_error(positional, translations.panic_not_a_table("posicional", 17))
	end)

	it("with a #positional type mismatch", function()
		local positional = function()
			options.positional "posicional" {
				type = options.number,
				default = "treze",
			}
		end
		assert.has_error(positional, translations.panic_positional_type_mismatch("posicional", "treze"))
	end)

	it("with a #positional type mismatch in one of its default values", function()
		local positional = function()
			options.positional "posicional" {
				type = options.number,
				default = {17, 19, "vinte", 13},
				many = true,
			}
		end
		assert.has_error(positional, translations.panic_positional_type_mismatch_some("posicional", "vinte"))
	end)
end)
