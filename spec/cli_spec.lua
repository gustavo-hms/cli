cli = require "cli"

describe("The #flag function", function()
	it("should build the prescribed object", function()
		local flag = cli.flag {
			"Descrição",

			type = cli.boolean,
			default = true
		}

		local expected = {
			description = "Descrição",
			type = cli.boolean,
			value = true
		}

		for k in pairs(expected) do
			assert.are.equal(expected[k], flag[k])
		end
	end)

	it("shouldn't set `value` if there isn't a default value", function()
		local flag = cli.flag {
			type = cli.number
		}

		assert.is_nil(flag.value)
	end)

	it("shouldn't build a flag when default value doesn't have the right type", function()
		local flag = cli.flag {
			type = cli.number,
			default = "dezessete"
		}

		assert.is_nil(flag)
	end)
end)

describe("The #flag_named function", function()
	local scenarios = {
		{
			description = "should set the name of the flag",
			flag = cli.flag_named "p,por-dia" {
				"Outra flag",

				type = cli.number,
				default = 17
			},
			expected = {
				description = "Outra flag",
				type = cli.number,
				value = 17,
				short_name = "p",
				long_name_with_hyphens = "por-dia",
				long_name_with_underscores = "por_dia"
			}

		},
		{
			description = "should allow only short names",
			flag = cli.flag_named "p" {
				"Outra flag",

				type = cli.number,
				default = 17
			},
			expected = {
				description = "Outra flag",
				type = cli.number,
				value = 17,
				short_name = "p",
				long_name_with_hyphens = "p",
				long_name_with_underscores = "p"
			}

		},
		{
			description = "should allow only long names",
			flag = cli.flag_named "por-dia" {
				"Outra flag",

				type = cli.number,
				default = 17
			},
			expected = {
				description = "Outra flag",
				type = cli.number,
				value = 17,
				long_name_with_hyphens = "por-dia",
				long_name_with_underscores = "por_dia"
			}
		}
	}

	for _, scenario in ipairs(scenarios) do
		it(scenario.description, function()
			for k in pairs(scenario.expected) do
				assert.is.equal(scenario.expected[k], scenario.flag[k])
			end
		end)
	end
end)

describe("The #positional function", function()
	it("should build the prescribed positional argument", function()

	end)
end)
