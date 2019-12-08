local errors = require "errors"

local error = error
local format = string.format
local ipairs = ipairs
local tonumber = tonumber
local type = type

local _ENV = {}

boolean = "boolean"
number = "number"
string = "string"

local function split_at_comma(text)
	local left, right = text:match("([^,]+),?(.*)")

	if not right or #right == 0 then
		return left
	end

	return left, right
end

local function hyphens_to_underscores(name)
	return (name:gsub("-", "_"))
end

local function underscores_to_hyphens(name)
	return (name:gsub("_", "-"))
end

-- Both `flag` and `positional` have this common structure:
-- {
--    name_with_hyphens = …,
--    name_with_underscores = …,
--    description = …,
--    type = …,
--    value = …
-- }
function flag(name)
	return function(data)
		-- All flags without a default value are mandatory except for boolean flags,
		-- which are false by default
		local value

		if data.type == boolean then
			value = false

		elseif data.default then
			if data.type == number and type(data.default) ~= "number" then
				error(format("The type of the flag “%s” is set to be a number, but its default value is not a number", name))
			end

			value = data.default
		end

		local short, long = split_at_comma(name)
		long = long or short

		local flg = {
			__flag = true,

			short_name = short,
			name_with_hyphens = underscores_to_hyphens(long),
			name_with_underscores = hyphens_to_underscores(long),
			description = type(data[1]) ~= "string" and "" or data[1],
			type = data.type or string,
			value = value
		}

		function flg:set(value)
			if self.type == boolean then
				if value then
					return errors.not_expecting(self.name_with_hyphens, value)
				end

				self.value = true

			else
				if not value then
					return errors.missing_value(self.name_with_hyphens)
				end

				if self.type == number then
					self.value = tonumber(value)

					if not self.value then
						return errors.not_a_number(self.name_with_hyphens, value)
					end

				else
					self.value = value
				end
			end
		end

		return flg
	end
end

function is_flag(t)
	return type(t) == "table" and t.__flag
end

function positional(name)
	return function(data)
		if data.many and data.default then
			if type(data.default) ~= "table" then
				error(format("Positional argument “%s” is set to receive multiple arguments, but its default value is not a table", name))
			end

			for k, _ in ipairs(data.default) do
				if type(data.default[k]) ~= "number" then
					error(format("The type of the positional argument “%s” is set to be a number, but some of its default values are not a number", name))
				end
			end

		elseif data.default and data.type == number then
			if type(data.default) ~= "number" then
				error(format("The type of the positional argument “%s” is set to be a number, but its default value is not a number", name))
			end
		end

		local pos = {
			__positional = true,

			name_with_hyphens = underscores_to_hyphens(name),
			name_with_underscores = hyphens_to_underscores(name),
			description = type(data[1]) ~= "string" and "" or data[1],
			type = data.type or string,
			many = data.many,
			value = data.default
		}

		function pos:add(value)
			local input_number = value

			if self.type == number then
				input_number = tonumber(value)

				if not input_number then
					return errors.not_a_number(self.name_with_hyphens, value)
				end
			end

			if self.many then
				self.value = self.value or {}
				self.value[#self.value + 1] = input_number
			else
				self.value = input_number
			end
		end

		return pos
	end
end

function is_positional(t)
	return type(t) == "table" and t.__positional
end

return _ENV
