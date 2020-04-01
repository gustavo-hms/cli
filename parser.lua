local errors = require "errors"
local options = require "options"
local text = require "text"

local arg = arg
local getmetatable = getmetatable
local setmetatable = setmetatable

local _ENV = {}

local function slice(t, first, last)
	if not last or last > #t then last = #t end

	if first > last then return { slice = slice } end

	local old = getmetatable(t)

	if old then
		first, last = first + old.first - 1, last + old.first - 1
		t = old.array
	end

	local meta = {
		first = first,
		last = last,
		array = t,
		__index = function(_, i) return t[first + i - 1] end,
		__len = function() return last - first + 1 end
	}

	return setmetatable({ slice = slice }, meta)
end

local function arguments()
	local args = { elements = slice(arg, 1, #arg) }

	function args:next()
		local elem = self.elements[1]
		self.elements = self.elements:slice(2, #self.elements)
		return elem
	end

	return args
end

-- State machine to parse command line arguments
function parse(opts)
	local flag_mode, flag_name_mode, flag_value_mode, unexpected_flag_mode, set_flag_mode
	local positional_mode, positional_value_mode, unexpected_positional_mode
	local missing_value_mode, wrong_value_mode

	-- We will insert a `help` flag automatically
	local help = options.flag "h,help" { type = options.boolean }
	opts:add_flag(help)

	local args = arguments()
	local positionals = slice(opts.ordered_positionals, 1, #opts.ordered_positionals)
	local errors_holder = errors.holder()

	local new_arg_mode = function()
		local item = args:next()

		if not item then return end

		if text.starts_with_hyphen(item) then
			return flag_mode(item)
		end

		return positional_mode(item)
	end

	flag_mode = function(item)
		local left, right = text.split_at_equal_sign(item)
		return flag_name_mode(left, right)
	end

	flag_name_mode = function(name, value)
		local flag = opts.named_flags[name]

		if not flag then return unexpected_flag_mode(name) end

		return flag_value_mode(flag, value)
	end

	flag_value_mode = function(flag, value)
		if value or flag.type == options.boolean then
			return set_flag_mode(flag, value)
		end

		local item = args:next()

		if item == "=" then
			item = args:next()
		end

		if item and not text.starts_with_hyphen(item) then
			return set_flag_mode(flag, item)
		end

		return missing_value_mode(flag)
	end

	set_flag_mode = function(flag, value)
		local err = flag:set(value)

		if err then return wrong_value_mode(err) end

		return new_arg_mode()
	end

	unexpected_flag_mode = function(name)
		errors_holder:add(errors.unknown_arg(name))
		return new_arg_mode()
	end

	positional_mode = function(value)
		local positional = positionals[1]

		if not positional then return unexpected_positional_mode(value) end

		return positional_value_mode(positional, value)
	end

	positional_value_mode = function(positional, value)
		if not value then return end

		if positional.many and text.starts_with_hyphen(value) then
			positionals = positionals:slice(2, #positionals)
			return flag_mode(value)
		end

		local err = positional:add(value)

		if err then return wrong_value_mode(err) end

		if positional.many then
			value = args:next()
			return positional_value_mode(positional, value)
		end

		positionals = positionals:slice(2, #positionals)
		return new_arg_mode()
	end

	missing_value_mode = function(arg)
		errors_holder:add(errors.missing_value(arg.name_with_hyphens))
		return new_arg_mode()
	end

	wrong_value_mode = function(err)
		errors_holder:add(err)
		return new_arg_mode()
	end

	unexpected_positional_mode = function(value)
		errors_holder:add(errors.unexpected_positional(value))
		return new_arg_mode()
	end

	new_arg_mode()
	return errors_holder:errors()
end

return _ENV
