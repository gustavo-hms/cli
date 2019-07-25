local args = require "args"

insulate("The #parse_input function", function()
	it("should set all the flags", function()
		args.arg = { "--um", "=", "1", "--dois=doze", "--tres", "-q=4", "-c=cinco" }

		local um = args.flag "um" { type = args.number }
		local dois = args.flag "d,dois" { type = args.string }
		local tres = args.flag "tres" { type = args.boolean }
		local quatro = args.flag "q,quatro" { type = args.number }
		local cinco = args.flag "c" { type = args.string }
		local cmd_args = {
			um = um,
			d = dois,
			dois = dois,
			tres = tres,
			q = quatro,
			quatro = quatro,
			c = cinco
		}

		local help = args.parse_input(cmd_args)

		assert.is_nil(help)
		assert.are.same(1, um.value)
		assert.are.same("doze", dois.value)
		assert.are.same(true, tres.value)
		assert.are.same(4, quatro.value)
		assert.are.same("cinco", cinco.value)
	end)

	it("should detect a `help` flag", function()
		args.arg = { "--um", "=", "1", "--dois=doze", "--help", "-q=4", "-c=cinco" }

		local um = args.flag "um" { type = args.number }
		local dois = args.flag "d,dois" { type = args.string }
		local quatro = args.flag "q,quatro" { type = args.number }
		local cinco = args.flag "c" { type = args.string }
		local cmd_args = {
			um = um,
			d = dois,
			dois = dois,
			q = quatro,
			quatro = quatro,
			c = cinco
		}

		local help = args.parse_input(cmd_args)

		assert.are.same("help", help)
	end)

	it("should set the flags and the positional arguments", function()
		args.arg = { "--um", "=", "1", "--dois=doze", "entrada", "saida", "--tres" }

		local um = args.flag "um" { type = args.number }
		local dois = args.flag "d,dois" { type = args.string }
		local tres = args.flag "tres" { type = args.boolean }
		local input = args.positional "input" { type = args.string }
		local output = args.positional "output" { type = args.string }
		local cmd_args = {
			input, output,

			um = um,
			d = dois,
			dois = dois,
			tres = tres,
		}

		local help = args.parse_input(cmd_args)

		assert.is_nil(help)
		assert.are.same(1, um.value)
		assert.are.same("doze", dois.value)
		assert.are.same(true, tres.value)
		assert.are.same("entrada", input.value)
		assert.are.same("saida", output.value)
	end)

	it("should set #many values for a positional argument", function()
		args.arg = { "--um", "=", "1", "--dois=doze", "doc1", "doc2", "doc3", "--tres" }

		local um = args.flag "um" { type = args.number }
		local dois = args.flag "d,dois" { type = args.string }
		local tres = args.flag "tres" { type = args.boolean }
		local files = args.positional "files" { type = args.string, many = true }
		local cmd_args = {
			files,

			um = um,
			d = dois,
			dois = dois,
			tres = tres,
		}

		local help = args.parse_input(cmd_args)

		assert.is_nil(help)
		assert.are.same(1, um.value)
		assert.are.same("doze", dois.value)
		assert.are.same(true, tres.value)
		assert.are.same({"doc1", "doc2", "doc3"}, files.value)
	end)

	it("should parses successfully a misbehaved input", function()
		args.arg = { "--um", "=", "", "--dois=", "--tres", "-q=", "4", "-c=cinco" }

		local um = args.flag "um" { type = args.string }
		local dois = args.flag "d,dois" { type = args.string }
		local tres = args.flag "tres" { type = args.boolean }
		local quatro = args.flag "q,quatro" { type = args.number }
		local cinco = args.flag "c" { type = args.string }
		local cmd_args = {
			um = um,
			d = dois,
			dois = dois,
			tres = tres,
			q = quatro,
			quatro = quatro,
			c = cinco
		}

		local help = args.parse_input(cmd_args)

		assert.is_nil(help)
		assert.are.same("", um.value)
		assert.are.same("", dois.value)
		assert.are.same(true, tres.value)
		assert.are.same(4, quatro.value)
		assert.are.same("cinco", cinco.value)
	end)

	it("should detect a positional argument following a boolean flag", function()
		args.arg = { "--um", "=", "1", "--dois=doze", "--tres", "-q", "quinto" }

		local um = args.flag "um" { type = args.number }
		local dois = args.flag "d,dois" { type = args.string }
		local tres = args.flag "tres" { type = args.boolean }
		local quatro = args.flag "q,quatro" { type = args.boolean }
		local cinco = args.positional "cinco" { type = args.string }
		local cmd_args = {
			cinco,

			um = um,
			d = dois,
			dois = dois,
			tres = tres,
			q = quatro,
			quatro = quatro
		}

		local help = args.parse_input(cmd_args)

		assert.is_nil(help)
		assert.are.same(1, um.value)
		assert.are.same("doze", dois.value)
		assert.are.same(true, tres.value)
		assert.are.same(true, quatro.value)
		assert.are.same("quinto", cinco.value)
	end)
end)

insulate("The #input function", function()
	it("should group args in a normal execution", function()
		args.arg = { "--um", "=", "1", "--dois=doze", "--tres", "-q=4", "cinco" }

		local result, help = args.input()

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
		args.arg = { "--um", "=", "1", "--dois=doze", "--tres", "-q", "cinco" }

		local result, help = args.input()

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
		args.arg = { "--um", "=", "--dois=", "--tres", "-q=", "4", "cinco" }

		local result, help = args.input()

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
		args.arg = { "--um", "=", "1", "--help", "--dois=doze", "--tres", "-q=4", "cinco" }

		local result, help = args.input()

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
		local flag = args.flag "name" {
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

	it("should set a boolean flag with `false` if there's no default value", function()
		local flag = args.flag "name" {
			type = args.boolean
		}

		assert.is_false(flag.value)
	end)

	it("shouldn't set `value` if there isn't a default value", function()
		local flag = args.flag "name" {
			type = args.number
		}

		assert.is_nil(flag.value)
	end)

	it("shouldn't build a flag when default value doesn't have the right type", function()
		local flag = args.flag "name" {
			type = args.number,
			default = "dezessete"
		}

		assert.is_nil(flag)
	end)

	it("should set the name of the flag", function()
		local flag = args.flag "p,por-dia" {
			"Outra flag",

			type = args.number,
			default = 17
		}

		local expected = {
			description = "Outra flag",
			type = args.number,
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
		local flag = args.flag "p" {
			"Outra flag",

			type = args.number,
			default = 17
		}

		local expected = {
			description = "Outra flag",
			type = args.number,
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
		local flag = args.flag "por-dia" {
			"Outra flag",

			type = args.number,
			default = 17
		}

		local expected = {
			description = "Outra flag",
			type = args.number,
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
