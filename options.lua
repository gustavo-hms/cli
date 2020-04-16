local errors = require "errors"
local iter = require "iterators"
local text = require "text"
local translations = require "translations"

local format = string.format
local ipairs = ipairs
local setmetatable = setmetatable
local table = table
local tonumber = tonumber
local type = type

local _ENV = {}

boolean = "boolean"
number = "number"
string = "string"

local flag_prototype = { __flag = true }

function flag_prototype:set(value)
	local name = self:name_with_hyphens()

	if self.type == boolean then
		if value then
			return errors.not_expecting(name, value)
		end

		self.value = true
		return
	end

	if not value then
		return errors.missing_value(name)
	end

	if self.type == number then
		self.value = tonumber(value)

		if not self.value then
			return errors.not_a_number(name, value)
		end

		return
	end

	self.value = value
end

function flag_prototype:name_with_underscores()
	return text.hyphens_to_underscores(self.names[#self.names])
end

function flag_prototype:name_with_hyphens()
	return text.add_initial_hyphens(self.names[#self.names])
end

function flag_prototype:names_formated()
	return iter.sequence(self.names):map(text.add_initial_hyphens):concat(", ")
end

function flag_prototype:help()
	local line = { self:names_formated() }

	if self.type ~= boolean then
		line[2] = format("<%s>", self.type)
	end

	return format("    %s\n        %s", table.concat(line, " "), self.description)
end

function is_flag(t)
	return type(t) == "table" and t.__flag
end

function flag(name)
	return function(data)
		-- All flags without a default value are mandatory except for boolean flags,
		-- which are false by default
		local value

		if data.type == boolean then
			value = false

		elseif data.default then
			if data.type == number and type(data.default) ~= "number" then
				errors.panic(translations.panic_flag_type_mismatch(name, data.default))
			end

			value = data.default
		end

		local names = {}
		names[1], names[2] = text.split_at_comma(name)

		local flg = {
			description = type(data[1]) ~= "string" and "" or data[1],
			names = names,
			type = data.type or string,
			value = value,
		}

		return setmetatable(flg, { __index = flag_prototype })
	end
end

local positional_prototype = { __positional = true }

function positional_prototype:add(value)
	local input_number = value

	if self.type == number then
		input_number = tonumber(value)

		if not input_number then
			return errors.not_a_number(self.name, value)
		end
	end

	if self.many then
		self.value = self.value or {}
		self.value[#self.value + 1] = input_number
	else
		self.value = input_number
	end
end

function positional_prototype:name_with_underscores()
	return text.hyphens_to_underscores(self.name)
end

function positional_prototype:name_with_hyphens()
	return self.name
end

function positional_prototype:help()
	local line = self.name

	if self.many then
		line = line .. "..."
	end

	return format("    %s\n        %s", line, self.description)
end

function is_positional(t)
	return type(t) == "table" and t.__positional
end

function positional(name)
	return function(data)
		if data.many and data.default then
			if type(data.default) ~= "table" then
				errors.panic(translations.panic_not_a_table(name, data.default))
			end

			if data.type == number then
				for _, value in ipairs(data.default) do
					if type(value) ~= "number" then
						errors.panic(translations.panic_positional_type_mismatch_some(name, value))
					end
				end
			end

		elseif data.default and data.type == number then
			if type(data.default) ~= "number" then
				errors.panic(translations.panic_positional_type_mismatch(name, data.default))
			end
		end

		local pos = {
			description = type(data[1]) ~= "string" and "" or data[1],
			name = name,
			type = data.type or string,
			many = data.many,
			value = data.default,
		}

		return setmetatable(pos, { __index = positional_prototype })
	end
end

local options_prototype = {}

function options_prototype:add_flag(flg)
	if not self.named_flags[flg.names[1]] then
		self.ordered_flags[#self.ordered_flags+1] = flg

		for _, name in ipairs(flg.names) do
			self.named_flags[name] = flg
		end
	end
end

function options_prototype:add_positional(pos)
	self.ordered_positionals[#self.ordered_positionals+1] = pos
end

function options_prototype:positionals()
	return iter.sequence(self.ordered_positionals)
end

function options_prototype:flags()
	return iter.sequence(self.ordered_flags)
end

function options_prototype:values()
	local values = {}
	local holder = errors.holder()

	for pos in self:positionals() do
		if pos.value == nil then
			holder:add(errors.missing_value(pos.name))
		else
			values[pos:name_with_underscores()] = pos.value
		end
	end

	for flg in self:flags() do
		if flg.value == nil then
			holder:add(errors.missing_value(flg:name_with_hyphens()))
		else
			values[flg:name_with_underscores()] = flg.value
		end
	end

	return values, holder:errors()
end

function options_prototype:merge_with(other)
	local merged = iter.chain(self:positionals(), other:positionals(), self:flags(), other:flags()):array()
	return new(merged)
end

function options_prototype:help_requested()
	return self.named_flags.help and self.named_flags.help.value
end

function new(data)
	local options = {
		ordered_positionals = {},
		ordered_flags = {},
		named_flags = {},
	}

	setmetatable(options, { __index = options_prototype })

	for _, option in ipairs(data) do
		if is_flag(option) then
			options:add_flag(option)

		elseif is_positional(option) then
			options:add_positional(option)
		end
	end

	return options
end

return _ENV
