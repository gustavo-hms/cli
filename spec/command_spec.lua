insulate("The #parse_args function", function()
	local option = require "option"

	it("should set all the flags", function()
		_G.arg = { "--um", "=", "1", "--dois=doze", "--tres", "-q=4", "-c=cinco" }

		local command = require "command"

    	local um = option.flag "um" { type = option.number }
    	local dois = option.flag "d,dois" { type = option.string }
    	local tres = option.flag "tres" { type = option.boolean }
    	local quatro = option.flag "q,quatro" { type = option.number }
    	local cinco = option.flag "c" { type = option.string }
		local cmd = command.anonymous { um, dois, tres, quatro, cinco }

		local help, err = cmd.options:parse_args()

		assert.is_nil(help)
		assert.is_nil(err)
		assert.are.same(1, um.value)
		assert.are.same("doze", dois.value)
		assert.are.same(true, tres.value)
		assert.are.same(4, quatro.value)
		assert.are.same("cinco", cinco.value)
	end)

	it("should detect a `help` flag", function()
		_G.arg = { "--um", "=", "1", "--dois=doze", "--help", "-q=4", "-c=cinco" }
		package.loaded.command = nil

		local command = require "command"

		local um = option.flag "um" { type = option.number }
		local dois = option.flag "d,dois" { type = option.string }
		local quatro = option.flag "q,quatro" { type = option.number }
		local cinco = option.flag "c" { type = option.string }
		local cmd = command.anonymous { um, dois, tres, quatro, cinco }

		local help, err = cmd.options:parse_args()

		assert.are.same("help", help)
		assert.is_nil(err)
	end)

	it("should set the flags and the positional arguments", function()
		_G.arg = { "--um", "=", "1", "--dois=doze", "entrada", "saida", "--tres" }
		package.loaded.command = nil

		local command = require "command"

		local um = option.flag "um" { type = option.number }
		local dois = option.flag "d,dois" { type = option.string }
		local tres = option.flag "tres" { type = option.boolean }
		local input = option.positional "input" { type = option.string }
		local output = option.positional "output" { type = option.string }
		local cmd = command.anonymous { um, dois, tres, input, output }

		local help, err = cmd.options:parse_args()

		assert.is_nil(help)
		assert.is_nil(err)
		assert.are.same(1, um.value)
		assert.are.same("doze", dois.value)
		assert.are.same(true, tres.value)
		assert.are.same("entrada", input.value)
		assert.are.same("saida", output.value)
	end)

	it("should set #many values for a positional argument", function()
		_G.arg = { "--um", "=", "1", "--dois=doze", "doc1", "doc2", "doc3", "--tres" }
		package.loaded.command = nil

		local command = require "command"

		local um = option.flag "um" { type = option.number }
		local dois = option.flag "d,dois" { type = option.string }
		local tres = option.flag "tres" { type = option.boolean }
		local files = option.positional "files" { type = option.string, many = true }
		local cmd = command.anonymous { um, dois, tres, files }

		local help, err = cmd.options:parse_args()

		assert.is_nil(help)
		assert.is_nil(err)
		assert.are.same(1, um.value)
		assert.are.same("doze", dois.value)
		assert.are.same(true, tres.value)
		assert.are.same({"doc1", "doc2", "doc3"}, files.value)
	end)

	it("should parses successfully a misbehaved input", function()
		_G.arg = { "--um", "=", "", "--dois=", "--tres", "-q=", "4", "-c=cinco" }
		package.loaded.command = nil

		local command = require "command"

		local um = option.flag "um" { type = option.string }
		local dois = option.flag "d,dois" { type = option.string }
		local tres = option.flag "tres" { type = option.boolean }
		local quatro = option.flag "q,quatro" { type = option.number }
		local cinco = option.flag "c" { type = option.string }
		local cmd = command.anonymous { um, dois, tres, quatro, cinco }

		local help, err = cmd.options:parse_args()

		assert.is_nil(help)
		assert.is_nil(err)
		assert.are.same("", um.value)
		assert.are.same("", dois.value)
		assert.are.same(true, tres.value)
		assert.are.same(4, quatro.value)
		assert.are.same("cinco", cinco.value)
	end)

	it("should detect a positional argument following a boolean flag", function()
		_G.arg = { "--um", "=", "1", "--dois=doze", "--tres", "-q", "quinto" }
		package.loaded.command = nil

		local command = require "command"

		local um = option.flag "um" { type = option.number }
		local dois = option.flag "d,dois" { type = option.string }
		local tres = option.flag "tres" { type = option.boolean }
		local quatro = option.flag "q,quatro" { type = option.boolean }
		local cinco = option.positional "cinco" { type = option.string }
		local cmd = command.anonymous { um, dois, tres, quatro, cinco }

		local help, err = cmd.options:parse_args()

		assert.is_nil(help)
		assert.is_nil(err)
		assert.are.same(1, um.value)
		assert.are.same("doze", dois.value)
		assert.are.same(true, tres.value)
		assert.are.same(true, quatro.value)
		assert.are.same("quinto", cinco.value)
	end)
end)

describe("The #command function", function()
    local cmd = require "command"
    local option = require "option"

	describe("when setting an argument", function()
		it("should put a flag on the right place in the table", function()
			local command = cmd.command {
				"Documentação in loco",

				option.flag "first-flag" {
					"Explicação da primeira flag",

					type = option.boolean
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

				option.flag "s,second-flag" {
					"O que faz",

					type = option.number,
					default = 7
				}
			}

			assert.is_not_nil(command.args["second-flag"])
			assert.is.equal("O que faz", command.args["second-flag"].description)
		end)

		it("should deal with a positional argument", function()
			local command = cmd.command {
				"Documentação in loco",

				option.positional "file" {
					"The file to be edited",

					type = option.string
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

				option.flag "first-flag" {
					"Primeira",

					type = option.string
				},

				option.flag "second-flag" {
					"Segunda",

					type = option.number
				},

				option.flag "third-flag" {
					"Terceira",

					type = option.boolean
				},

				option.positional "file" {
					"Arquivo",

					type = option.string
				}
			}

			local input_args = {
				{ positional = "code.lua" },
				{ name = "third-flag" },
				{ name = "first-flag", value = "valoroso" },
				{ name = "second-flag", value = 17 }
			}

			local unknown, unset = command:set_arguments(input_args)

			assert.is_nil(unknown)
			assert.is_nil(unset)
			assert.is.equal("code.lua", command.values.file)
			assert.is.equal(true, command.values.third_flag)
			assert.is.equal("valoroso", command.values.first_flag)
			assert.is.equal(17, command.values.second_flag)
		end)

		it("should detect a `help` flag", function()
			local command = cmd.command {
				"Documentação",

				option.flag "first-flag" {
					"Primeira",

					type = option.string
				},

				option.flag "second-flag" {
					"Segunda",

					type = option.number
				},

				option.flag "third-flag" {
					"Terceira",

					type = option.boolean
				},

				option.positional "file" {
					"Arquivo",

					type = option.string
				}
			}

			local input_args = {
				{ positional = "code.lua" },
				{ name = "third-flag" },
				{ name = "help" },
				{ name = "first-flag", value = "valoroso" },
				{ name = "second-flag", value = 17 }
			}

			local help, unset = command:set_arguments(input_args)

			assert.is_nil(unset)
			assert.is.equal("help", help)
		end)
	end)
end)
