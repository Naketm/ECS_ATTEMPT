local ECS = require(script.EntityHandler)
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local world = ECS.new()

local playerPart = Instance.new("Part")
playerPart.Size = Vector3.new(2, 2, 2)
playerPart.Anchored = true
playerPart.Position = Vector3.new(0, 5, 0)
playerPart.Parent = workspace

local playerPart2 = Instance.new("Part")
playerPart2.Size = Vector3.new(2, 2, 2)
playerPart2.Anchored = true
playerPart2.Position = Vector3.new(0, 5, 0)
playerPart2.Parent = workspace
playerPart2.BrickColor = BrickColor.new("Really red")

local player = world:createEntity()
world:addComponent(player, "Position", { x = playerPart.Position.X+10, y = playerPart.Position.Y, z = playerPart.Position.Z })
world:addComponent(player, "Velocity", { x = 0, y = 30, z = 0 })
world:addComponent(player, "MovementEnabled", {playerPart, true})

local player2 = world:createEntity()
world:addComponent(player2, "Position", { x = playerPart.Position.X, y = playerPart.Position.Y, z = playerPart.Position.Z })
world:addComponent(player2, "Health", {current = 100, max = 100})



local MovementSystem = {}
function MovementSystem:update(world, dt)
	local moving = world:queryWith("Position", "Velocity", "MovementEnabled")
	for _, entityData in moving do
		local pos = entityData.Position
		local vel = entityData.Velocity
		local part = entityData.MovementEnabled[1]
		local isMoving = entityData.MovementEnabled[2]
		
		if isMoving == false then
			return
		end
		
		if pos.y >= 20 then
			vel.y = -vel.y
			pos.y = 20  
		elseif pos.y <= 5 then
			vel.y = -vel.y
			pos.y = 5
		end
		
		pos.x = pos.x + vel.x * dt
		pos.y = pos.y + vel.y * dt
		pos.z = pos.z + vel.z * dt

		part.Position = Vector3.new(pos.x, pos.y, pos.z)
	end
end

local goal = {
	Size = Vector3.new(0, 0, 0)
}

local tweenInfo = TweenInfo.new(
	0.5,
	Enum.EasingStyle.Exponential,
	Enum.EasingDirection.Out,
	0,
	false,
	0
)

local DamageSystem = {}
function DamageSystem:update(world)
	local health = world:queryWith("Health")
	for _, entityData in health do
		local current_health = entityData.Health.current
		local max_health = entityData.Health.max
		
		entityData.Health.current -= 1
		
		if current_health <= 0 then
			world:destroyEntity(entityData.entity)
			local tween = TweenService:Create(playerPart2, tweenInfo, goal)
			tween:Play()
			
			tween.Completed:Connect(function()
				task.wait()
				playerPart2:Destroy()
			end)
		end
	end
end

world:addSystem(MovementSystem, 1)
world:addSystem(DamageSystem, 0)

RunService.Heartbeat:Connect(function(dt)
	world:update(dt)
end)
