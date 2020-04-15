-- Text manipulation tools

local _ENV = {}

local function split_at(pattern)
	return function(text)
		local left, right = text:match(pattern)

		if not right or #right == 0 then
			return left
		end

		return left, right
	end
end

split_at_comma = split_at("([^,]+),?(.*)")
split_at_equal_sign = split_at("-?-?([^=]+)=?(.*)")

function hyphens_to_underscores(name)
	return (name:gsub("-", "_"))
end

function underscores_to_hyphens(name)
	return (name:gsub("_", "-"))
end

function starts_with_hyphen(txt)
	return txt:sub(1,1) == "-"
end

function add_initial_hyphens(name)
	return #name == 1 and "-" .. name or "--" .. name
end

return _ENV
