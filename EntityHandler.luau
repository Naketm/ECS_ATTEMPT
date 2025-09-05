local sparse = require(script.SparseHandler)

local ECS = {}
ECS.__index = ECS

function ECS:getComponent(entityId, componentType)
	local sparse = self.componentSets[componentType]
	if not sparse then
		return nil
	end

	return sparse:get(entityId)
end

function ECS.new()
	local self = setmetatable({}, ECS)
	
	self.nextId = 1
	self.freeIds = {}
	self.entities = {}	
	
	self.componentSets = {}
	self.componentTypes = {}
	
	self.systems = {}
	self.systemsOrder = {}
	
	self.queryCache = {}
	
	return self
end



function ECS:createEntity()
	local id
	
	local count = #self.freeIds
	if count > 0 then
		id = self.freeIds[count]
		self.freeIds[count] = nil
	else
		id = self.nextId
		self.nextId += 1
	end
	
	self.entities[id] = true
	
	return id
end

function ECS:destroyEntity(id: number): number
	if not self.entities[id] then return nil end
	
	for component, component_data in self.componentSets do
		component_data:remove(id)
	end
	
	self.entities[id] = nil
	self.freeIds[#self.freeIds + 1] = id
	
	self.queryCache = {}
	
	return id
end

function ECS:entityExists(id)
	return self.entities[id] == true
end

function ECS:registerComponent(componentType)
	if not self.componentSets[componentType] then
		self.componentSets[componentType]= sparse.new()
		table.insert(self.componentTypes, componentType)
	end
end

function ECS:addComponent(id, componentType, componentData)
	if not self.entities[id] then return end
	
	self:registerComponent(componentType)
	self.componentSets[componentType]:set(id, componentData or {})
	
	self.queryCache = {}
end


function ECS:query(...)
	local componentTypes = {...}
	local cacheKey = table.concat(componentTypes, ",")

	if self.queryCache[cacheKey] then
		return self.queryCache[cacheKey]
	end

	if #componentTypes == 0 then
		self.queryCache[cacheKey] = {}
		return {}
	end

	local smallestSet = nil
	for i = 1, #componentTypes do
		local count = componentTypes[i]
		local set = self.componentSets[count]
		
		if not set or set.count == 0 then
			self.queryCache[cacheKey] = {}
			return {}
		end
		
		if not smallestSet or set.count < smallestSet.count then
			smallestSet = set
		end
	end

	local results = {}
	for id, _ in smallestSet:iterate() do
		local hasAll = true
		
		for j = 1, #componentTypes do
			local count = componentTypes[j]
			local set = self.componentSets[count]
			
			if not set or not set:has(id) then
				
				hasAll = false
				break
			end
		end
		
		if hasAll then
			results[#results + 1] = id
		end
	end

	self.queryCache[cacheKey] = results
	return results
end

function ECS:queryWith(...)
	local componentTypes = {...}
	local entities = self:query(...)

	local results = {}
	for i = 1, #entities do
		local id = entities[i]
		local entityData = { entity = id }
		
		for j = 1, #componentTypes do
			
			local count = componentTypes[j]
			entityData[count] = self:getComponent(id, count)
		end
		
		results[#results + 1] = entityData
	end

	return results
end

function ECS:addSystem(system, priority: number)
	priority = priority or 0
	
	table.insert(self.systems, {
		system = system,
		priority = priority
	})
	
	table.sort(self.systems, function(a, b)
		return a.priority > b.priority
	end)
	
	self.systemOrder = {}
	for i, systemData in self.systems do
		self.systemOrder[i] = systemData.system
	end
end

function ECS:update(d_time)
	for _, system in self.systemOrder do
		if system.update then
			system:update(self, d_time)
		end
	end
end


return ECS
