insulate("A #program", function()
	local errors = require "errors"
	stub(errors, "exit_with")

	it("should fill the options' values", function()
		_G.arg = {"--value", "17"}
		local cli = require "cli"

		cli.program {
			cli.flag "v,value" {
				"A mandatory flag",
				type = cli.number
			},

			function(options)
				assert.are.equal(17, options.value)
			end
		}

		assert.stub(errors.exit_with).was_not.called()
	end)

	it("should fill the options' values when passed with a short name", function()
		_G.arg = {"-v", "19"}
		package.loaded.cli = nil
		package.loaded.command = nil
		local cli = require "cli"

		cli.program {
			cli.flag "v,value" {
				"A mandatory flag",
				type = cli.number
			},

			function(options)
				assert.are.equal(19, options.value)
			end
		}

		assert.stub(errors.exit_with).was_not.called()
	end)
end)

insulate("A #program", function()
	it("should complain if a #mandatory option is missing", function()
		local errors = require "errors"

		errors.exit_with = function(err)
			local expected = errors.missing_value("mandatory")
			assert.are.same(expected, err.error_with_code("missing_value"))
		end

		local spy_exit_with = spy.on(errors, "exit_with")

		_G.arg = {"--optional", "a-value"}

		local cli = require "cli"

		cli.program {
			cli.flag "mandatory" {
				"A mandatory flag"
			},

			cli.flag "optional" {
				"An optional flag",
				default = "filled"
			},

			function(options)
			end
		}

		assert.spy(spy_exit_with).was.called()
	end)
end)

insulate("A #complete #program", function()
	it("should run the `#add` command", function()
		local errors = require "errors"
		-- Mock errors.exit_with
		errors.exit_with = function(err)
			print(err)
			assert.is_false(true) -- `exit_with` shouldn't be called
		end

		_G.arg = {"add", "17", "19", "1"}

		local cli = require "cli"

		_G.add = cli.command {
			"Add all the given numbers",

			function(options, inspect)
				local sum = 0

				for _, v in ipairs(options.numbers) do
					sum = sum + v
				end

				inspect.sum = sum
			end
		}

		_G.max = cli.command {
			"Find the maximum value",

			function(options, inspect)
				inspect.max = math.max(table.unpack(options.numbers))
			end
		}

		_G.all_above = cli.command {
			"Prints all numbers above the given value",

			cli.flag "c,cutoff" {
				"The value above which all numbers are retained",

				type = cli.number
			},

			function(options, inspect)
				for _, v in ipairs(options.numbers) do
					if v > options.cutoff then
						inspect[#inspect+1] = v
					end
				end
			end
		}

		local inspect = {}

		cli.program {
			"A program to compute numbers",

			cli.positional "numbers" {
				"The numbers to operate upon",

				type = cli.number,
				many = true
			},

			function()
				return inspect
			end
		}

		assert.are.equal(37, inspect.sum)
	end)
end)

insulate("A #complete program", function()
	it("should understand subcommands and positionals", function()
		local errors = require "errors"
		errors.exit_with = function(err)
			print(err)
			assert.is_false(true) -- `exit_with` shouldn't be called
		end

		_G.arg = {"parse", "-o", "out.txt", "in.txt"}

		local cli = require "cli"

		_G.parse = cli.command {
			"Parses the input file",

			cli.flag "o,output" {
				"The name of the output file",
				type = cli.string
			},

			cli.positional "input" {
				"The file to parse",
				type = cli.string
			},

			function(options, inspect)
				inspect.output = options.output
				inspect.input = options.input
			end
		}

		_G.do_not = cli.command {
			"Shouldn't enter here",

			function(_, inspect)
				inspect.do_not = true
			end
		}

		local inspect = {}

		cli.program {
			"A program to compute numbers",

			function()
				return inspect
			end
		}

		assert.are.equal("in.txt", inspect.input)
		assert.are.equal("out.txt", inspect.output)
		assert.is_falsy(inspect.do_not)
	end)
end)

insulate("A #program", function()
	local new_printer = function()
		local printer = {
			output = {},
		}

		printer.print = function(str)
			printer.output[#printer.output + 1] = str
		end

		return printer
	end

	it("should generate a help message from the spec", function()
		local errors = require "errors"
		stub(errors, "exit_with")

		local printer = new_printer()
		_G.print = printer.print

		_G.arg = {
			[0] = "compute",
			[1] = "--help"
		}

		package.loaded.command = nil
		package.loaded.cli = nil
		local cli = require "cli"

		_G.add = cli.command {
			"Add all the given numbers"
		}

		_G.max = cli.command {
			"Find the maximum value"
		}

		_G.all_above = cli.command {
			"Print all numbers above the given value",

			cli.flag "c,cutoff" {
				"The value above which all numbers are retained",

				type = cli.number
			}
		}

		cli.program {
			"A program to compute numbers",

			cli.positional "numbers" {
				"The numbers to operate upon",

				type = cli.number,
				many = true
			}
		}

		assert.stub(errors.exit_with).was_not.called()

		local expected =
[[A program to compute numbers

Usage:

    compute add numbers...
        Add all the given numbers
  
    compute all-above [options] numbers...
        Print all numbers above the given value

    compute max numbers...
        Find the maximum value
  
You can run

    compute <command> --help

to get more details about a specific command.

]]

		assert.are.same(expected, table.concat(printer.output))	
	end)

	it("should generate a help message for the specified command", function()
		local errors = require "errors"
		stub(errors, "exit_with")

		local printer = new_printer()
		_G.print = printer.print

		_G.arg = {
			[0] = "compute",
			[1] = "all-above",
			[2] = "--help"
		}

		package.loaded.command = nil
		package.loaded.cli = nil
		local cli = require "cli"

		cli.program {
			"A program to compute numbers",

			cli.positional "numbers" {
				"The numbers to operate upon",

				type = cli.number,
				many = true
			}
		}

		assert.stub(errors.exit_with).was_not.called()

		local expected =
[[Print all numbers above the given value

Usage:
    compute all-above [options] numbers...

Options:
    -c, --cutoff <number>
	    The value above which all numbers are retained

Arguments:
    numbers...
	    The numbers to operate upon
]]

		assert.are.same(expected, table.concat(printer.output))	
	end)

	it("should accept a string as argument", function()
		local errors = require "errors"
		stub(errors, "exit_with")

		local printer = new_printer()
		_G.print = printer.print

		_G.arg = {
			[0] = "compute",
			[1] = "--help"
		}

		package.loaded.command = nil
		package.loaded.cli = nil
		local cli = require "cli"

		cli.program "A program to compute numbers"

		assert.stub(errors.exit_with).was_not.called()

		local expected =
[[A program to compute numbers

Usage:

    compute add
        Add all the given numbers
  
    compute max
        Find the maximum value
  
    compute all-above [options]
        Print all numbers above the given value

You can run

    compute <command> --help

to get more details about a specific command.

]]
	end)
end)
