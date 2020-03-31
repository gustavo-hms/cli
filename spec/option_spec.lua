local option = require "option"

describe("The #flag function", function()
	it("should build the prescribed object", function()
		local flag = option.flag "name" {
			"Descrição",

			type = option.string,
			default = "opa!"
		}

		local expected = {
			description = "Descrição",
			type = option.string,
			value = "opa!"
		}

		for k in pairs(expected) do
			assert.are.equal(expected[k], flag[k])
		end
	end)

	it("should set a boolean flag with `false` if there's no default value", function()
		local flag = option.flag "name" {
			type = option.boolean
		}

		assert.is_false(flag.value)
	end)

	it("shouldn't set `value` if there isn't a default value", function()
		local flag = option.flag "name" {
			type = option.number
		}

		assert.is_nil(flag.value)
	end)

	it("should set the name of the flag", function()
		local flag = option.flag "p,por-dia" {
			"Outra flag",

			type = option.number,
			default = 17
		}

		local expected = {
			description = "Outra flag",
			type = option.number,
			value = 17,
			short_name = "p",
			name_with_hyphens = "por-dia",
			name_with_underscores = "por_dia"
		}

		for k in pairs(expected) do
			assert.is.equal(expected[k], flag[k])
		end
	end)

	it("should allow prescribing short names only", function()
		local flag = option.flag "p" {
			"Outra flag",

			type = option.number,
			default = 17
		}

		local expected = {
			description = "Outra flag",
			type = option.number,
			value = 17,
			name_with_hyphens = "p",
			name_with_underscores = "p"
		}

		for k in pairs(expected) do
			assert.is.equal(expected[k], flag[k])
		end
	end)

	it("should allow prescribing long names only", function()
		local flag = option.flag "por-dia" {
			"Outra flag",

			type = option.number,
			default = 17
		}

		local expected = {
			description = "Outra flag",
			type = option.number,
			value = 17,
			name_with_hyphens = "por-dia",
			name_with_underscores = "por_dia"
		}

		for k in pairs(expected) do
			assert.is.equal(expected[k], flag[k])
		end
	end)

	it("should type check default arguments", function()
		assert.has.errors(function()
			option.flag "nome" {
				type = option.number,
				default = "dezessete"
			}
		end)
	end)
end)

describe("The #positional function", function()
	it("should build the prescribed positional argument", function()
		local positional = option.positional "este-aqui" {
			"Cada argumento...",

			type = option.string,
			default = "nenhum"
		}

		local expected = {
			description = "Cada argumento...",
			type = option.string,
			value = "nenhum",
			name_with_hyphens = "este-aqui",
			name_with_underscores = "este_aqui"
		}

		for k in pairs(expected) do
			assert.is.equal(expected[k], positional[k])
		end
	end)

	it("shouldn't set `value` if there isn't a default value", function()
		local positional = option.positional "este-aqui" {
			"Cada argumento...",

			type = option.string,
		}

		assert.is_nil(positional.value)
	end)

	it("should take into account the `many` option", function()
		local positional = option.positional "este-aqui" {
			type = option.number,
			default = {17, 19},
			many = true
		}

		assert.are.same({17, 19}, positional.value)
	end)

	it("should type check a default argument", function()
		assert.has.errors(function()
			option.positional "nome" {
				type = option.number,
				default = "dezessete"
			}
		end)
	end)

	it("should type check a default argument when the `many` flag is set", function()
		assert.has.errors(function()
			option.positional "nome" {
				type = option.number,
				default = 17,
				many = true
			}
		end)

		assert.has.errors(function()
			option.positional "nome" {
				type = option.number,
				default = {17, "dezessete"},
				many = true
			}
		end)
	end)
end)

describe("The #positional #add method", function()
	it("should update its `value` attribute", function()
		local positional = option.positional "name" {
			type = option.string
		}

		local err = positional:add("nome")
		assert.is_nil(err)
		assert.are.equal("nome", positional.value)
	end)

	it("should set #many values", function()
		local positional = option.positional "name" {
			type = option.string,
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
		local positional = option.positional "name" {
			type = option.string
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
