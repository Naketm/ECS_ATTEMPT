local array = {}
array.__index = array

local function lookupSparse(self, id: number)
	return self.sparse[id]
end

function array.new()
	local self = setmetatable({}, array)

	self.sparse = {}
	self.dense = {}
	self.denseToEntity = {}
	self.count = 0
	
	return self
end


function array:has(id: number)
	local index = lookupSparse(self, id)
	
	return index ~= nil and index <= self.count
end

function array:get(id: number, component)
	local index = lookupSparse(self, id)
	
	if index and index <= self.count then
		return self.dense[index]
	end
	
	return nil
end

function array:set(id: number, component)
	local index = lookupSparse(self, id)
	
	if index and index <= self.count then
		self.dense[index] = component
	else
		
		self.count += 1
		self.sparse[id] = self.count
		self.dense[self.count] = component
		self.denseToEntity[self.count] = id
		
	end
end

function array:remove(id: number)
	local index = lookupSparse(self, id)
	if not index or index > self.count then return end

	local lastIndex = self.count
	local lastEntityId = self.denseToEntity[lastIndex]

	self.dense[index] = self.dense[lastIndex]
	self.denseToEntity[index] = lastEntityId
	self.sparse[lastEntityId] = index

	self.dense[lastIndex] = nil
	self.denseToEntity[lastIndex] = nil
	self.sparse[id] = nil

	self.count -= 1
	return id
end

function array:iterate()
	local i = 0
	return function()
		i += 1
		if i <= self.count then
			return self.denseToEntity[i], self.dense[i]
		end
	end
end

return array
