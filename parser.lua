local errors = require "errors"
local iter = require "iterators"
local options = require "options"
local text = require "text"

local arg = arg

local _ENV = {}

-- State machine to parse command line arguments
function parse(opts)
	local flag_mode, flag_name_mode, flag_value_mode, unexpected_flag_mode, set_flag_mode
	local positional_mode, positional_value_mode, unexpected_positional_mode
	local missing_value_mode, wrong_value_mode

	-- We will insert a `help` flag automatically
	local help = options.flag "h,help" { type = options.boolean }
	opts:add_flag(help)

	local args = iter.sequence(arg)
	local positionals = iter.sequence(opts.ordered_positionals)
	local error_list = errors.list()

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
		error_list:add(errors.unknown_arg(text.add_initial_hyphens(name)))
		return new_arg_mode()
	end

	positional_mode = function(value)
		local positional = positionals:next()

		if not positional then return unexpected_positional_mode(value) end

		return positional_value_mode(positional, value)
	end

	positional_value_mode = function(positional, value)
		if not value then return end

		if positional.many and text.starts_with_hyphen(value) then
			return flag_mode(value)
		end

		local err = positional:add(value)

		if err then return wrong_value_mode(err) end

		if positional.many then
			value = args:next()
			return positional_value_mode(positional, value)
		end

		return new_arg_mode()
	end

	missing_value_mode = function(arg)
		error_list:add(errors.missing_value(arg:name_with_hyphens()))
		return new_arg_mode()
	end

	wrong_value_mode = function(err)
		error_list:add(err)
		return new_arg_mode()
	end

	unexpected_positional_mode = function(value)
		error_list:add(errors.unexpected_positional(value))
		return new_arg_mode()
	end

	new_arg_mode()
	return error_list:toerror()
end

return _ENV
