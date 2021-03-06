local new_printer = function()
	local printer = {
		output = {},
	}

	printer.write = function(_, str)
		printer.output[#printer.output + 1] = str
	end

	return printer
end

insulate("A #program", function()
	local errors = require "cli.errors"

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
		package.loaded["cli.parser"] = nil
		package.loaded["cli.command"] = nil
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
		package.loaded["cli.parser"] = nil
		package.loaded["cli.command"] = nil
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

insulate("A #complete #program", function()
	it("should run the `#add` command", function()
		local errors = require "cli.errors"
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
		local errors = require "cli.errors"
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
	it("should generate a #help message from the spec", function()
    	local errors = require "cli.errors"
    	errors.exit_with = function(err)
        	assert.is_nil(tostring(err))
    	end
    	
    	local printer = new_printer()
    	_G.io.stdout = printer
    	
    	_G.arg = {
        	[0] = "program",
        	[1] = "--help"
    	}
    	
    	package.loaded["cli.parser"] = nil
    	package.loaded["cli.command"] = nil
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
            	type = cli.string,
            	default = "segunda"
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

    Options and arguments without a default value are mandatory.

Options:

    --first <number>
        The first option

    -s, --second <string> (default: segunda)
        The second option

    -t
        Just another option

Arguments:

    fourth
        A positional argument

]]
    	
    	assert.are.same(expected, table.concat(printer.output))
	end)

	it("should generate a #help message for a program with #only positionals", function()
		local errors = require "cli.errors"
		errors.exit_with = function(err)
			assert.is_nil(tostring(err))
		end

		local printer = new_printer()
		_G.io.stdout = printer

		_G.arg = {
			[0] = "program",
			[1] = "--help"
		}

		package.loaded["cli.parser"] = nil
		package.loaded["cli.command"] = nil
		package.loaded.cli = nil
		local cli = require "cli"

		cli.locale "en_US"

		cli.program {
			"A program to test help messages",

			cli.positional "fourth" {
				"A positional argument",
				type = cli.number
			}
		}

		local expected =
[[A program to test help messages

Usage:

    program fourth

    Options and arguments without a default value are mandatory.

Arguments:

    fourth
        A positional argument

]]

		assert.are.same(expected, table.concat(printer.output))
	end)

	it("should generate a #help message for a program with only flags", function()
		local errors = require "cli.errors"
		errors.exit_with = function(err)
			assert.is_nil(tostring(err))
		end

		local printer = new_printer()
		_G.io.stdout = printer

		_G.arg = {
			[0] = "program",
			[1] = "--help"
		}

		package.loaded["cli.parser"] = nil
		package.loaded["cli.command"] = nil
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
            	type = cli.string,
            	default = "segunda"
        	},
        	
        	cli.flag "t" {
            	"Just another option",
            	type = cli.boolean
        	},
		}

		local expected =
[[A program to test help messages

Usage:

    program [options]

    Options and arguments without a default value are mandatory.

Options:

    --first <number>
        The first option

    -s, --second <string> (default: segunda)
        The second option

    -t
        Just another option

]]

		assert.are.same(expected, table.concat(printer.output))
	end)
end)

insulate("A #program with subcommands", function()

	it("should generate a #help message from the spec", function()
		local errors = require "cli.errors"
		stub(errors, "exit_with")

		local printer = new_printer()
		_G.io.stdout = printer

		_G.arg = {
			[0] = "compute",
			[1] = "--help"
		}

		package.loaded["cli.parser"] = nil
		package.loaded["cli.command"] = nil
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
		local errors = require "cli.errors"

		local printer = new_printer()
		_G.io.stdout = printer

		errors.exit_with = function(err)
			assert.is_nil(tostring(err))
		end

		_G.arg = {
			[0] = "compute",
			[1] = "all-above",
			[2] = "--help"
		}

		package.loaded["cli.parser"] = nil
		package.loaded["cli.command"] = nil
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
				many = true,
				default = {17, 19}
			}
		}

		local expected =
[[Print all numbers above the given value

Usage:

    compute all-above [options] numbers...

    Options and arguments without a default value are mandatory.

Options:

    -c, --cutoff <number>
        The value above which all numbers are retained

Arguments:

    numbers... (default: 17 19)
        The numbers to operate upon

]]

		assert.are.same(expected, table.concat(printer.output))
	end)

	it("should accept a string as argument", function()
		local errors = require "cli.errors"
		stub(errors, "exit_with")

		local printer = new_printer()
		_G.io.stdout = printer

		_G.arg = {
			[0] = "compute",
			[1] = "--help"
		}

		package.loaded["cli.parser"] = nil
		package.loaded["cli.command"] = nil
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

insulate("A #program, when finding a #validation #error", function()
	local errors = require "cli.errors"
	local cli = require "cli"

	local scenarios = {
		{
			description = "should deal with an #unknown_arg",
			program = { cli.flag "a-flag" { default = "" } },
			arg = { "--other-flag" },
			commands = {},
			error_code = "flag_unknown_arg",
			expected = errors.flag_unknown_arg("--other-flag"),
		},
		{
			description = "should deal with an #unknown_arg when executing a subcommand",
			program = { cli.flag "a-flag" { default = "" } },
			arg = {  "subcommand", "--another-flag" },
			commands = {
				subcommand = { cli.flag "second" { default = "" } }
			},
			error_code = "flag_unknown_arg",
			expected = errors.flag_unknown_arg("--another-flag"),
		},
		{
			description = "should deal with a #not_expecting",
			program = {cli.flag "booleano" { type = cli.boolean }},
			arg = { "--booleano=algo" },
			commands = {},
			error_code = "flag_not_expecting",
			expected = errors.flag_not_expecting("--booleano", "algo"),
		},
		{
			description = "should deal with a #missing_value for an #empty_arg",
			program = {
				cli.flag "empty-flag" {},
				function() end
			},
			arg = {},
			commands = {},
			error_code = "flag_missing_value",
			expected = errors.flag_missing_value("--empty-flag"),
		},
		{
			description = "should deal with a #missing_value even if flag's name appears on execution",
			program = {cli.flag "a-flag" {}},
			arg = { "--a-flag" },
			commands = {},
			error_code = "flag_missing_value",
			expected = errors.flag_missing_value("--a-flag"),
		},
		{
			description = "should deal with a #missing_value when executing a subcommand",
			program = {cli.flag "a-flag" { default = "" }},
			arg = { "subcommand" },
			commands = {
				subcommand = { cli.flag "second" {} }
			},
			error_code = "flag_missing_value",
			expected = errors.flag_missing_value("--second"),
		},
		{
			description = "should deal with a #missing_value for a positional",
			program = {cli.positional "a-positional" {}, function() end},
			arg = {},
			commands = {},
			error_code = "positional_missing_value",
			expected = errors.positional_missing_value("a-positional"),
		},
		{
			description = "should deal with a #not_a_number",
			program = {cli.flag "a-flag" { type = cli.number }},
			arg = {"--a-flag","=","dezessete"},
			commands = {},
			error_code = "flag_not_a_number",
			expected = errors.flag_not_a_number("--a-flag", "dezessete"),
		},
		{
			description = "should deal with a #not_a_number when executing a subcommand",
			program = {cli.flag "a-flag" { default = "" }},
			arg = { "subcommand", "--a-number", "dezessete" },
			commands = {
				subcommand = { cli.flag "a-number" { type = cli.number } }
			},
			error_code = "flag_not_a_number",
			expected = errors.flag_not_a_number("--a-number", "dezessete"),
		},
		{
			description = "should deal with a #not_a_number for a positional",
			program = {cli.positional "a-positional" { type = cli.number }},
			arg = {"quatro"},
			commands = {},
			error_code = "positional_not_a_number",
			expected = errors.positional_not_a_number("a-positional", "quatro")
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
					local found = err:message_with_code(scenario.error_code)

					if found == nil then print(err) end

					assert.are.same(scenario.expected, found)
					error("Terminate execution")
				end

				_G.arg = scenario.arg
				package.loaded["cli.parser"] = nil
				package.loaded["cli.command"] = nil
				package.loaded.cli = nil
				cli = require "cli"

				for name, command in pairs(scenario.commands) do
					_G[name] = cli.command(command)
				end

				assert.has_error(function() cli.program(scenario.program) end, "Terminate execution")
			end)
		end)
	end
end)

insulate("A #program, when dealing with #validation #error on arguments", function()
	it("should print an error #message", function()

		local expected =
[[The following errors were found during the program execution:

    ∙ the option “--number” expects a number, but the given value was “dezenove”
    ∙ unknown option: “--unexpected”

You can run:

    program --help

if you need some help.

]]

		_G.arg = {
			[0] = "program",
			[1] = "--number=dezenove",
			[2] = "--unexpected"
		}

		local errors = require "cli.errors"
		errors.exit_with = function(err)
			assert.are.same(expected, tostring(err))
			error("Terminate execution")
		end

		package.loaded["cli.parser"] = nil
		package.loaded["cli.command"] = nil
		package.loaded.cli = nil
		local cli = require "cli"

		cli.locale "en_US"

		assert.has_error(function() 
			cli.program {
				cli.flag "number" { type = cli.number }
			}
		end, "Terminate execution")
	end)
end)

insulate("A #program, when finding a #command #error", function()
	local errors = require "cli.errors"
	local cli = require "cli"

	local scenarios = {
		{
			description = "should deal with a #command_not_provided",
			program = { cli.flag "primeira" { default = "" } },
			arg = { "--primeira=valor" },
			commands = {
				subcommand = { cli.flag "nome" { default = "" } }
			},
			error_code = "command_not_provided",
			expected = errors.command_not_provided({"subcommand"}),
		},
		{
			description = "should deal with an #unknown_command",
			program = { cli.flag "primeira" { default = "" } },
			arg = {  "comando", "--primeira=valor" },
			commands = {
				subcommand = { cli.flag "nome" { default = "" } }
			},
			error_code = "unknown_command",
			expected = errors.unknown_command("comando", {"subcommand"}),
		},
	}

	for _, scenario in ipairs(scenarios) do
		insulate("on arguments,", function()
			it(scenario.description, function()
				errors.exit_with = function(err)
					assert.are.same(scenario.expected, err)
					error("Terminate execution")
				end

				_G.arg = scenario.arg
				package.loaded["cli.parser"] = nil
				package.loaded["cli.command"] = nil
				package.loaded.cli = nil
				cli = require "cli"

				for name, command in pairs(scenario.commands) do
					_G[name] = cli.command(command)
				end

				assert.has_error(function() cli.program(scenario.program) end, "Terminate execution")
			end)
		end)
	end
end)

insulate("A #program, when dealing with a #command #error on arguments", function()
	it("should print an error #message", function()

		local expected =
[[Error: no command given. Available commands are:

    ∙ nome
    ∙ outro

You can run:

    program --help

if you need some help.

]]

		_G.arg = {
			[0] = "program",
		}

		local errors = require "cli.errors"
		errors.exit_with = function(err)
			assert.are.same(expected, tostring(err))
			error("Terminate execution")
		end

		package.loaded["cli.parser"] = nil
		package.loaded["cli.command"] = nil
		package.loaded.cli = nil
		local cli = require "cli"

		cli.locale "en_US"

		_G.nome = cli.command {}
		_G.outro = cli.command {}

		assert.has_error(function() 
			cli.program {
				cli.flag "number" { type = cli.number, default = 17 }
			}
		end, "Terminate execution")
	end)
end)
