local enemy_ai = {}
enemy_ai.__index = enemy_ai

local points = {
    { x = 1, y = 2 }, -- top left
    { x = 1, y = 4 }, -- bottom left
    { x = 3, y = 4 }, -- bottom right
    { x = 3, y = 2 }  -- top right
}

enemy_ai.points = {}
for i1, point1 in ipairs(points) do
    for i2, point2 in ipairs(points) do
        table.insert(enemy_ai.points, {point1, point2})
    end
end

function enemy_ai:canSeePlayer(player)
	local distance, x1, y1, x2, y2 = love.physics.getDistance(player.fixture, self.movable.fixture)
	if distance > self.fov then
		return
	end

	local bound1 = { player.fixture:getBoundingBox() }
	local bound2 = { self.movable.fixture:getBoundingBox() }

	local all = 0

	for i, point in ipairs(self.points) do
		self.movable.body:getWorld():rayCast(
			bound1[point[1].x],
			bound1[point[1].y],
			bound2[point[2].x],
			bound2[point[2].y],
			function(fixture, x, y, xn, yn, fraction)
				local ud = fixture:getUserData()
				if fixture:isSensor() or (ud and ud.character) then
					return 1
				end
				all = all + 1
				return 0
			end
		)
	end

	return all < 12
end

function enemy_ai:act(player)
	local see = self:canSeePlayer(player)
	if see then
		local distance, x1, y1, x2, y2 = love.physics.getDistance(player.fixture, self.movable.fixture)
		local v = { 
			x = x1 - x2,
			y = y1 - y2,
		}
		local m = math.sqrt(v.x^2+v.y^2)
		v.x = v.x / m
		v.y = v.y / m

		self.movable:control_axis("x", v.x)
		self.movable:control_axis("y", v.y)
	end
end

return function(movable)
	local ai = setmetatable({}, enemy_ai)
	
	ai.movable = movable
	ai.fov = 150
	return ai
end