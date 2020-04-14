insulate("A #program", function()
	local errors = require "errors"

	it("should #fill the options' values", function()
		_G.arg = {"--value", "17"}
		errors.exit_with = function(err)
			assert.is_nil(tostring(err))
		end
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
	end)

	it("should fill the options' values when passed with a short name", function()
		_G.arg = {"-v", "19"}
		errors.exit_with = function(err)
			assert.is_nil(tostring(err))
		end
		package.loaded.cli = nil
		package.loaded.parser = nil
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
	end)

	it("should accept a flag with just a short variant", function()
		_G.arg = {"-v", "19"}
		errors.exit_with = function(err)
			assert.is_nil(tostring(err))
		end
		package.loaded.cli = nil
		package.loaded.parser = nil
		package.loaded.command = nil
		local cli = require "cli"

		cli.program {
			cli.flag "v" {
				"A mandatory flag",
				type = cli.number
			},

			function(options)
				assert.are.equal(19, options.v)
			end
		}
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

			function()
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
			print(tostring(err))
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

	it("should generate a #help message from the spec", function()
		local errors = require "errors"
		errors.exit_with = function(err)
			assert.is_nil(tostring(err))
		end

		local printer = new_printer()
		_G.print = printer.print

		_G.arg = {
			[0] = "program",
			[1] = "--help"
		}

		package.loaded.parser = nil
		package.loaded.command = nil
		package.loaded.cli = nil
		local cli = require "cli"

		cli.locale "en_US"

		cli.program {
			"A program to test help messages",

			cli.flag "first" {
				"The first option",
				type = cli.number
			},

			cli.flag "s,second" {
				"The second option",
				type = cli.string
			},

			cli.flag "t" {
				"Just another option",
				type = cli.boolean
			},

			cli.positional "fourth" {
				"A positional argument",
				type = cli.number
			}
		}

		local expected =
[[A program to test help messages

Usage:

    program [options] fourth

Options:

    --first <number>
        The first option

    -s, --second <string>
        The second option

    -t
        Just another option

Arguments:

    fourth
        A positional argument

]]

		assert.are.same(expected, table.concat(printer.output))
	end)
end)

insulate("A #program with subcommands", function()
	local new_printer = function()
		local printer = {
			output = {},
		}

		printer.print = function(str)
			printer.output[#printer.output + 1] = str
		end

		return printer
	end

	it("should generate a #help message from the spec", function()
		local errors = require "errors"
		stub(errors, "exit_with")

		local printer = new_printer()
		_G.print = printer.print

		_G.arg = {
			[0] = "compute",
			[1] = "--help"
		}

		package.loaded.parser = nil
		package.loaded.command = nil
		package.loaded.cli = nil
		local cli = require "cli"

		cli.locale "en_US"

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

	it("should generate a #help message for the specified command", function()
		local errors = require "errors"

		local printer = new_printer()
		_G.print = printer.print

		errors.exit_with = function(err)
			assert.is_nil(tostring(err))
		end

		_G.arg = {
			[0] = "compute",
			[1] = "all-above",
			[2] = "--help"
		}

		package.loaded.parser = nil
		package.loaded.command = nil
		package.loaded.cli = nil
		local cli = require "cli"

		cli.locale "en_US"

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

		package.loaded.parser = nil
		package.loaded.command = nil
		package.loaded.cli = nil
		local cli = require "cli"

		cli.locale "en_US"

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

		cli.program "A program to compute numbers"

		assert.stub(errors.exit_with).was_not.called()

		local expected =
[[A program to compute numbers

Usage:

    compute add
        Add all the given numbers

    compute all-above [options]
        Print all numbers above the given value

    compute max
        Find the maximum value

You can run

    compute <command> --help

to get more details about a specific command.

]]
		assert.are.same(expected, table.concat(printer.output))
	end)
end)

insulate("A #program, when finding an #error", function()
	local errors = require "errors"
	local cli = require "cli"

	local scenarios = {
		{
			description = "should deal with an #unknown_arg",
			program = { cli.flag "a-flag" { default = "" } },
			arg = { "--other-flag" },
			commands = {},
			error_code = "unknown_arg",
			expected = errors.unknown_arg("other-flag"),
		},
		{
			description = "should deal with an #unknown_arg when executing a subcommand",
			program = { cli.flag "a-flag" { default = "" } },
			arg = { "--other-flag" },
			commands = {
				subcommand = { cli.flag "second" { default = "" } }
			},
			error_code = "unknown_arg",
			expected = errors.unknown_arg("other-flag"),
		},
		{
			description = "should deal with a #not_expecting",
			program = {cli.flag "booleano" { type = cli.boolean }},
			arg = { "--booleano=algo" },
			commands = {},
			error_code = "not_expecting",
			expected = errors.not_expecting("booleano", "algo"),
		},
		{
			description = "should deal with a #missing_value",
			program = {cli.flag "a-flag" {}},
			arg = {},
			commands = {},
			error_code = "missing_value",
			expected = errors.missing_value("a-flag"),
		},
		{
			description = "should deal with a #missing_value even if flag's name appears on execution",
			program = {cli.flag "a-flag" {}},
			arg = { "--a-flag" },
			commands = {},
			error_code = "missing_value",
			expected = errors.missing_value("a-flag"),
		},
		{
			description = "should deal with a #missing_value when executing a subcommand",
			program = {cli.flag "a-flag" { default = "" }},
			arg = { "subcommand" },
			commands = {
				subcommand = { cli.flag "second" {} }
			},
			error_code = "missing_value",
			expected = errors.missing_value("second"),
		},
		{
			description = "should deal with a #not_a_number",
			program = {cli.flag "a-flag" { type = cli.number }},
			arg = {"--a-flag","=","dezessete"},
			commands = {},
			error_code = "not_a_number",
			expected = errors.not_a_number("a-flag", "dezessete"),
		},
		{
			description = "should deal with a #not_a_number when executing a subcommand",
			program = {cli.flag "a-flag" { default = "" }},
			arg = { "subcommand", "--second", "dezessete" },
			commands = {
				subcommand = { cli.flag "second" { type = cli.number } }
			},
			error_code = "not_a_number",
			expected = errors.not_a_number("second", "dezessete"),
		},
		{
			description = "should deal with an #unexpected_positional",
			program = {cli.flag "a-flag" { default = "" }},
			arg = {"dezessete"},
			commands = {},
			error_code = "unexpected_positional",
			expected = errors.unexpected_positional("dezessete"),
		},
		{
			description = "should deal with an #unexpected_positional if the positional is already set",
			program = { cli.positional "nome" {} },
			arg = { "primeiro", "dezessete" },
			commands = {},
			error_code = "unexpected_positional",
			expected = errors.unexpected_positional("dezessete"),
		},
		{
			description = "should deal with an #unexpected_positional when executing a subcommand",
			program = { cli.flag "primeira" { default = "" } },
			arg = { "subcommand", "dezessete" },
			commands = {
				subcommand = { cli.flag "nome" { default = "" } }
			},
			error_code = "unexpected_positional",
			expected = errors.unexpected_positional("dezessete"),
		},
	}

	for _, scenario in ipairs(scenarios) do
		insulate("on arguments,", function()
			it(scenario.description, function()
				errors.exit_with = function(err)
					err = err.error_with_code(scenario.error_code)
					assert.are.same(scenario.expected, err)
				end

				local exit_with = spy.new(errors.exit_with)

				_G.arg = scenario.arg
				package.loaded.parser = nil
				package.loaded.command = nil
				package.loaded.cli = nil
				cli = require "cli"

				for name, command in pairs(scenario.commands) do
					_G[name] = cli.command(command)
				end

				cli.program(scenario.program)

				assert.spy(exit_with).was.called()
			end)
		end)
	end
end)
