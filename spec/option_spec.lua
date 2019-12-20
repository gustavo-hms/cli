local option = require "option"

insulate("The #parse_input function", function()
	it("should set all the flags", function()
		option.arg = { "--um", "=", "1", "--dois=doze", "--tres", "-q=4", "-c=cinco" }

		local um = option.flag "um" { type = option.number }
		local dois = option.flag "d,dois" { type = option.string }
		local tres = option.flag "tres" { type = option.boolean }
		local quatro = option.flag "q,quatro" { type = option.number }
		local cinco = option.flag "c" { type = option.string }
		local cmd_args = {
			positionals = {},

			flags = {
				um = um,
				d = dois,
				dois = dois,
				tres = tres,
				q = quatro,
				quatro = quatro,
				c = cinco
			}
		}

		local help, err = option.parse_input(cmd_args)

		assert.is_nil(help)
		assert.is_nil(err)
		assert.are.same(1, um.value)
		assert.are.same("doze", dois.value)
		assert.are.same(true, tres.value)
		assert.are.same(4, quatro.value)
		assert.are.same("cinco", cinco.value)
	end)

	it("should detect a `help` flag", function()
		option.arg = { "--um", "=", "1", "--dois=doze", "--help", "-q=4", "-c=cinco" }

		local um = option.flag "um" { type = option.number }
		local dois = option.flag "d,dois" { type = option.string }
		local quatro = option.flag "q,quatro" { type = option.number }
		local cinco = option.flag "c" { type = option.string }
		local cmd_args = {
			positionals = {},

			flags = {
				um = um,
				d = dois,
				dois = dois,
				q = quatro,
				quatro = quatro,
				c = cinco
			}
		}

		local help = option.parse_input(cmd_args)

		assert.are.same("help", help)
	end)

	it("should set the flags and the positional arguments", function()
		option.arg = { "--um", "=", "1", "--dois=doze", "entrada", "saida", "--tres" }

		local um = option.flag "um" { type = option.number }
		local dois = option.flag "d,dois" { type = option.string }
		local tres = option.flag "tres" { type = option.boolean }
		local input = option.positional "input" { type = option.string }
		local output = option.positional "output" { type = option.string }
		local cmd_args = {
			positionals = { input, output },

			flags = {
				um = um,
				d = dois,
				dois = dois,
				tres = tres,
			}
		}

		local help, err = option.parse_input(cmd_args)

		assert.is_nil(help)
		assert.is_nil(err)
		assert.are.same(1, um.value)
		assert.are.same("doze", dois.value)
		assert.are.same(true, tres.value)
		assert.are.same("entrada", input.value)
		assert.are.same("saida", output.value)
	end)

	it("should set #many values for a positional argument", function()
		option.arg = { "--um", "=", "1", "--dois=doze", "doc1", "doc2", "doc3", "--tres" }

		local um = option.flag "um" { type = option.number }
		local dois = option.flag "d,dois" { type = option.string }
		local tres = option.flag "tres" { type = option.boolean }
		local files = option.positional "files" { type = option.string, many = true }
		local cmd_args = {
			positionals = { files },

			flags = {
				um = um,
				d = dois,
				dois = dois,
				tres = tres
			}
		}


		local help, err = option.parse_input(cmd_args)

		assert.is_nil(help)
		assert.is_nil(err)
		assert.are.same(1, um.value)
		assert.are.same("doze", dois.value)
		assert.are.same(true, tres.value)
		assert.are.same({"doc1", "doc2", "doc3"}, files.value)
	end)

	it("should parses successfully a misbehaved input", function()
		option.arg = { "--um", "=", "", "--dois=", "--tres", "-q=", "4", "-c=cinco" }

		local um = option.flag "um" { type = option.string }
		local dois = option.flag "d,dois" { type = option.string }
		local tres = option.flag "tres" { type = option.boolean }
		local quatro = option.flag "q,quatro" { type = option.number }
		local cinco = option.flag "c" { type = option.string }
		local cmd_args = {
			positionals = {},

			flags = {
				um = um,
				d = dois,
				dois = dois,
				tres = tres,
				q = quatro,
				quatro = quatro,
				c = cinco
			}
		}


		local help, err = option.parse_input(cmd_args)

		assert.is_nil(help)
		assert.is_nil(err)
		assert.are.same("", um.value)
		assert.are.same("", dois.value)
		assert.are.same(true, tres.value)
		assert.are.same(4, quatro.value)
		assert.are.same("cinco", cinco.value)
	end)

	it("should detect a positional argument following a boolean flag", function()
		option.arg = { "--um", "=", "1", "--dois=doze", "--tres", "-q", "quinto" }

		local um = option.flag "um" { type = option.number }
		local dois = option.flag "d,dois" { type = option.string }
		local tres = option.flag "tres" { type = option.boolean }
		local quatro = option.flag "q,quatro" { type = option.boolean }
		local cinco = option.positional "cinco" { type = option.string }
		local cmd_args = {
			positionals = { cinco },

			flags = {
				um = um,
				d = dois,
				dois = dois,
				tres = tres,
				q = quatro,
				quatro = quatro
			}
		}


		local help, err = option.parse_input(cmd_args)

		assert.is_nil(help)
		assert.is_nil(err)
		assert.are.same(1, um.value)
		assert.are.same("doze", dois.value)
		assert.are.same(true, tres.value)
		assert.are.same(true, quatro.value)
		assert.are.same("quinto", cinco.value)
	end)
end)

insulate("The #input function", function()
	it("should group args in a normal execution", function()
		option.arg = { "--um", "=", "1", "--dois=doze", "--tres", "-q=4", "cinco" }

		local result, help = option.input()

		local expected = {
			{ name = "um", value = "1" },
			{ name = "dois", value = "doze" },
			{ name = "tres" },
			{ name = "q", value = "4" },
			{ positional = "cinco" }
		}

		assert.are.same(expected, result)
		assert.is_falsy(help)
	end)

	it("should detect a positional argument following a boolean flag", function()
		option.arg = { "--um", "=", "1", "--dois=doze", "--tres", "-q", "cinco" }

		local result, help = option.input()

		local expected = {
			{ name = "um", value = "1" },
			{ name = "dois", value = "doze" },
			{ name = "tres" },
			{ name = "q" },
			{ positional = "cinco" }
		}

		assert.are.same(expected, result)
		assert.is_falsy(help)
	end)

	it("should parses successfully a misbehaved input", function()
		option.arg = { "--um", "=", "--dois=", "--tres", "-q=", "4", "cinco" }

		local result, help = option.input()

		local expected = {
			{ name = "um" },
			{ name = "dois" },
			{ name = "tres" },
			{ name = "q", value = "4" },
			{ positional = "cinco" }
		}

		assert.are.same(expected, result)
		assert.is_falsy(help)
	end)

	it("should detect a help flag", function()
		option.arg = { "--um", "=", "1", "--help", "--dois=doze", "--tres", "-q=4", "cinco" }

		local result, help = option.input()

		local expected = {
			{ name = "um", value = "1" },
			{ name = "dois", value = "doze" },
			{ name = "tres" },
			{ name = "q", value = "4" },
			{ positional = "cinco" }
		}

		assert.are.same(expected, result)
		assert.is_true(help)
	end)
end)

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

	it("shouldn't build a flag when default value doesn't have the right type", function()
		local flag = option.flag "name" {
			type = option.number,
			default = "dezessete"
		}

		assert.is_nil(flag)
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
			short_name = "p",
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
			default = 17,
			many = true
		}

		assert.is.equal({17}, positional.value)
	end)
end)
