local errors = require "errors"

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
--    type = …,
--    value = …,
--    name_with_hyphens = …,
--    name_with_underscores = …
-- }
function flag(name)
	return function(data)
		local flg = {
			__flag = true,

			type = data.type
		}

		-- All flags without a default value are mandatory except for boolean flags,
		-- which are false by default
		if data.type == boolean then
			flg.value = false
		else
			flg.value = data.default
		end

		if type(data[1]) == "string" then
			flg.description = data[1]
		end

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


		local short, long = split_at_comma(name)
		long = long or short

		flg.short_name = short
		flg.name_with_hyphens = underscores_to_hyphens(long)
		flg.name_with_underscores = hyphens_to_underscores(long)

		return flg
	end
end

function is_flag(t)
	return type(t) == "table" and t.__flag
end

function positional(name)
	return function(data)
		local pos = {
			__positional = true,

			name_with_hyphens = underscores_to_hyphens(name),
			name_with_underscores = hyphens_to_underscores(name),
			description = data[1],
			type = data.type,
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
