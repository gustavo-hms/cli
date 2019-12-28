insulate("A #complete program", function()
	it("should run the `add` command", function()
		local errors = require "errors"
		-- Mock errors.exit_with
		errors.exit_with = function(err)
			assert.is_false(true) -- `exit_with` shouldn't be called
		end

		_G.arg = {"add", "17", "19", "1"}

		local cli = require "cli"

		_G.add = cli.command {
			"Add all the given numbers",

			function(args, inspect)
				local sum = 0

				for _, v in ipairs(args.numbers) do
					sum = sum + v
				end

				inspect.sum = sum
			end
		}

		_G.max = cli.command {
			"Find the maximum value",

			function(args, inspect)
				inspect.max = math.max(table.unpack(args.numbers))
			end
		}

		_G.all_above = cli.command {
			"Prints all numbers above the given value",

			cli.flag "c,cutoff" {
				"The value above which all numbers are retained",

				type = cli.number
			},

			function(args, inspect)
				for _, v in ipairs(args.numbers) do
					if v > args.cutoff then
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

		assert.stub(errors.exit_with).was_not_called()
		assert.are.equal(27, inspect.sum)
	end)
end)