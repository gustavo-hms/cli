local iter = require "iterators"

describe("The #wrap function", function()
	it("should wrap a default lua iterator", function()
		local array = {9, 6, 3, 1}
		local iterator = iter.wrap(ipairs)(array)
		assert.are.same({1, 9}, {iterator:next()})
		assert.are.same({2, 6}, {iterator:next()})
		assert.are.same({3, 3}, {iterator:next()})
		assert.are.same({4, 1}, {iterator:next()})
		assert.is_nil(iterator:next())

		local dictionary = {um = 9, dois = 6, tres = 3, quatro = 1}
		iterator = iter.wrap(pairs)(dictionary)

		local counter = 0
		while true do
			local k,v = iterator:next()
			if k == nil then break end
			assert.are.same(dictionary[k], v)
			counter = counter + 1
		end

		assert.is.equal(4, counter)
	end)
end)

describe("The #sequence function", function()
	it("should iterate over all values of an array", function()
		local array = {9, 6, 3, 1}
		local iterator = iter.sequence(array)
		assert.are.same(9, iterator:next())
		assert.are.same(6, iterator:next())
		assert.are.same(3, iterator:next())
		assert.are.same(1, iterator:next())
		assert.is_nil(iterator:next())
	end)
end)

describe("The #array method", function()
	it("should generate an array from an ipairs", function()
		local array = {9, 6, 3, 1}
		local result = iter.ipairs(array):array()
		assert.are.same({1, 2, 3, 4}, result)
	end)

	it("should generate an array from a sequence", function()
		local array = {9, 6, 3, 1}
		local result = iter.sequence(array):array()
		assert.are.same(array, result)
	end)
end)

describe("The #__call method", function()
	it("should convert an iterator to a standard iterator", function()
		local array = {9, 6, 3, 1}
		local i = 0

		for v in iter.sequence(array) do
			i = i + 1
			assert.are.same(array[i], v)
		end
	end)
end)

describe("The #map method", function()
	it("should transform the original array", function()
		local t = {9, 6, 3, 1}
		local result = iter.sequence(t):map(function(e) return 2*e end):array()
		assert.are.same({18, 12, 6, 2}, result)
	end)

	it("should change the arity of the iterators", function()
		local t = {um = 9, dois = 6, tres = 3, quatro = 1}
		for k,v in iter.pairs(t):map(function(k, _) return k end) do
			assert.is_nil(v)
			assert.is.not_nil(t[k])
		end

		t = {um = 9, dois = 9, tres = 9, quatro = 9}
		local result = iter.pairs(t):map(function(_, v) return v end):array()
		assert.are.same({9,9,9,9}, result)
	end)
end)

describe("The #find method", function()
	it("should return the first found element", function()
		local t = {23, 7, 13, 20, 11, 15, 12}
		local result = iter.sequence(t):find(function(e) return e%2 == 0 end)
		assert.are.equal(20, result)
	end)

	it("should return nil if no element were found", function()
		local t = {23, 7, 13, 11, 15, 17}
		local result = iter.sequence(t):find(function(e) return e%2 == 0 end)
		assert.is_nil(result)
	end)
end)

describe("The #sort method", function()
	it("should generate a sorted array", function()
		local t = {9, 6, 3, 1, 7}
		local result = iter.sequence(t):sort()
		assert.are.same({1, 3, 6, 7, 9}, result)
	end)
end)

describe("The concat method", function()
	it("should concat all elements into a string", function()
		local t = {"um", "dois", "três", "quatro"}
		local result = iter.sequence(t):concat(", ")
		assert.are.equal("um, dois, três, quatro", result)
	end)
end)

describe("The #chain function", function()
	it("should build a new iterator chaining all the iterators together", function()
		local i1 = iter.sequence {3, 5, 7}
		local i2 = iter.sequence {4, 6, 8}
		local i3 = iter.sequence {1, 2, 3}
		local i4 = iter.sequence {2, 1, 7}

		local result = iter.chain(i1, i2, i3, i4):array()
		assert.are.same({3, 5, 7, 4, 6, 8, 1, 2, 3, 2, 1, 7}, result)
	end)

	it("should play well with a noop once()", function()
		local i1 = iter.sequence {3, 5, 7}
		local i2 = iter.sequence {4, 6, 8}
		local result = iter.chain(i1, iter.once(nil), i2):array()
		assert.are.same({3, 5, 7, 4, 6, 8}, result)
	end)
end)

describe("The #once function", function()
	it("should build an iterator that yields only once", function()
		local once = iter.once(7)
		assert.is.equal(7, once:next())
		assert.is_nil(once:next())
	end)
end)
