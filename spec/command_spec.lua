local option = require "option"

insulate("The #parse_args function", function()
	it("should set all the flags", function()
		_G.arg = { "--um", "=", "1", "--dois=doze", "--tres", "-q=4", "-c=cinco" }

		local command = require "command"

    	local um = option.flag "um" { type = option.number }
    	local dois = option.flag "d,dois" { type = option.string }
    	local tres = option.flag "tres" { type = option.boolean }
    	local quatro = option.flag "q,quatro" { type = option.number }
    	local cinco = option.flag "c" { type = option.string }
		local cmd = command.command { um, dois, tres, quatro, cinco }

		local help, err = cmd:parse_args()

		assert.is_nil(help)
		assert.is_nil(err)
		assert.are.same(1, um.value)
		assert.are.same("doze", dois.value)
		assert.are.same(true, tres.value)
		assert.are.same(4, quatro.value)
		assert.are.same("cinco", cinco.value)
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
		local cmd = command.command { um, dois, tres, input, output }

		local help, err = cmd:parse_args()

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
		local cmd = command.command { um, dois, tres, files }

		local help, err = cmd:parse_args()

		assert.is_nil(help)
		assert.is_nil(err)
		assert.are.same(1, um.value)
		assert.are.same("doze", dois.value)
		assert.are.same(true, tres.value)
		assert.are.same({"doc1", "doc2", "doc3"}, files.value)
	end)

	it("should parses successfully a misbehaved input", function()
		_G.arg = { "--um", "=", "", "--tres", "-q=", "4", "-c=cinco" }
		package.loaded.command = nil

		local command = require "command"

		local um = option.flag "um" { type = option.string }
		local tres = option.flag "tres" { type = option.boolean }
		local quatro = option.flag "q,quatro" { type = option.number }
		local cinco = option.flag "c" { type = option.string }
		local cmd = command.command { um, tres, quatro, cinco }

		local help, err = cmd:parse_args()

		assert.is_nil(help)
		assert.is_nil(err)
		assert.are.same("", um.value)
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
		local cmd = command.command { um, dois, tres, quatro, cinco }

		local help, err = cmd:parse_args()

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
	local command = require "command"

	it("should load the table on the first access", function()
		local cmd = command.command {
			"A description",

			option.flag "f,first" {
				"The first flag",

				type = option.string,
				default = "the first"
			},

			option.positional "second" {
				"The positional option",

				type = option.number,
				default = 17
			}
		}

		local options = cmd.options

		assert.is.not_nil(options)
		assert.is.not_nil(options.flags.first)
		assert.is.not_nil(options.flags.f)
		assert.are.equal(1, #options.positionals)
	end)
end)

insulate("The #load function", function()
	it("should find the correct command", function()
		_G.arg = {"that", "--aflag", "=", "1"}
		package.loaded.command = nil
		local command = require "command"

		_G.this = command.command {
			"This"
		}

		_G.that = command.command {
			"That"
		}

		local cmd, help_or_error = command.load()
		assert.is_falsy(help_or_error)
		assert.is.not_nil(cmd)
		assert.are.equal("That", cmd.description)
	end)

	it("should detect a global `help` flag", function()
		_G.arg = {"--help"}
		package.loaded.command = nil
		local command = require "command"

		_G.this = command.command {
			"This",

			option.flag "a-flag" {
				type = option.string
			}
		}

		_G.that = command.command {
			"That"
		}

		local cmd, help = command.load()
		assert.is_nil(cmd)
		assert.is_true(help)
	end)
end)
