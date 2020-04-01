local options = require "options"

insulate("The #parse_args function", function()
	it("should set all the flags", function()
		_G.arg = { "--um", "=", "1", "--dois=doze", "--tres", "-q=4", "-c=cinco" }

		local command = require "command"

    	local um = options.flag "um" { type = options.number }
    	local dois = options.flag "d,dois" { type = options.string }
    	local tres = options.flag "tres" { type = options.boolean }
    	local quatro = options.flag "q,quatro" { type = options.number }
    	local cinco = options.flag "c" { type = options.string }
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
		package.loaded.parser = nil
		package.loaded.command = nil

		local command = require "command"

		local um = options.flag "um" { type = options.number }
		local dois = options.flag "d,dois" { type = options.string }
		local tres = options.flag "tres" { type = options.boolean }
		local input = options.positional "input" { type = options.string }
		local output = options.positional "output" { type = options.string }
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
		package.loaded.parser = nil
		package.loaded.command = nil

		local command = require "command"

		local um = options.flag "um" { type = options.number }
		local dois = options.flag "d,dois" { type = options.string }
		local tres = options.flag "tres" { type = options.boolean }
		local files = options.positional "files" { type = options.string, many = true }
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
		package.loaded.parser = nil
		package.loaded.command = nil

		local command = require "command"

		local um = options.flag "um" { type = options.string }
		local tres = options.flag "tres" { type = options.boolean }
		local quatro = options.flag "q,quatro" { type = options.number }
		local cinco = options.flag "c" { type = options.string }
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
		package.loaded.parser = nil
		package.loaded.command = nil

		local command = require "command"

		local um = options.flag "um" { type = options.number }
		local dois = options.flag "d,dois" { type = options.string }
		local tres = options.flag "tres" { type = options.boolean }
		local quatro = options.flag "q,quatro" { type = options.boolean }
		local cinco = options.positional "cinco" { type = options.string }
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

			options.flag "f,first" {
				"The first flag",

				type = options.string,
				default = "the first"
			},

			options.positional "second" {
				"The positional option",

				type = options.number,
				default = 17
			}
		}

		local opts = cmd.options

		assert.is.not_nil(opts)
		assert.is.not_nil(opts.named_flags.first)
		assert.is.not_nil(opts.named_flags.f)
		assert.are.equal(1, #opts.ordered_positionals)
	end)
end)

insulate("The #load function", function()
	it("should find the correct command", function()
		_G.arg = {"that", "--aflag", "=", "1"}
		package.loaded.parser = nil
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

	it("should #detect a #global `help` flag", function()
		_G.arg = {"--help"}
		package.loaded.parser = nil
		package.loaded.command = nil
		local command = require "command"

		_G.this = command.command {
			"This",

			options.flag "a-flag" {
				type = options.string
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
