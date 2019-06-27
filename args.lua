local type = type
local tonumber = tonumber

local _ENV = {}

boolean = "boolean"
number = "number"
string = "string"

function split_at_comma(text)
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

function flag(data)
	local flg = {
		__type = "flag",

		type = data.type,
		value = data.default
	}

	if type(data[1]) == "string" then
		flg.description = data[1]
	end

	function flg:set(value)
		if self.type == boolean then
			if value then
				return errors.not_expecting(value) -- TODO
			end

			self.value = true

		else
			if not value then
				return errors.missing_value() -- TODO
			end

			if self.type == number then
				self.value = tonumber(value)

				if not self.value then
					return errors.not_a_number(value) -- TODO
				end

			else
				self.value = value
			end
		end
	end

	function flg:name(name)
		local short, long = split_at_comma(name)
		long = long or short

		self.short_name = short
		self.name_with_hyphens = underscores_to_hyphens(long)
		self.name_with_underscores = hyphens_to_underscores(long)
	end

	return flg
end

function flag_named(name)
	return function(data)
		local flg = flag(data)
		flg:name(name)

		return flg
	end
end

function is_flag(t)
	return type(t) == "table" and t.__type and t.__type == "flag"
end

function positional(name)
	return function(data)
		local pos = {
			__type = "positional",

			name_with_hyphens = name,
			name_with_underscores = hyphens_to_underscores(name),
			description = data[1],
			type = data.type,
			many = data.many,
			value = data.default
		}

		function pos:add(value)
			if self.many then
				self.value = self.value or {}
				self.value[#self.value + 1] = value
			else
				self.value = value
			end
		end

		return pos
	end
end

function is_positional(t)
	return type(t) == "table" and t.__type and t.__type == "positional"
end

return _ENV
