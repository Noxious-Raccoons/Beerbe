local scene = {}

function scene.load()
	local bigFont = love.graphics.newFont("assets/Arial.ttf", love.graphics.getHeight()/10)
	local smallFont = love.graphics.newFont("assets/Arial.ttf", love.graphics.getHeight()/20)

	wastedText = love.graphics.newText(bigFont, "WASTED")
	infoText = love.graphics.newText(smallFont, "Press Confirm to restart")
	
	local width, height = wastedText:getDimensions()
	wastedTransform = love.math.newTransform(love.graphics.getWidth()/2 - width/2, love.graphics.getHeight()/2 - height)

	local width, height = infoText:getDimensions()
	infoTransform = love.math.newTransform(love.graphics.getWidth()/2 - width/2, love.graphics.getHeight() - 2*height)

	love.graphics.setColor(1, 0, 0)
end

function scene.unload()
	love.graphics.setColor(1, 1, 1)
	infoText = nil
	wastedText = nil
	wastedTransform = nil
	infoTransform = nil
end

function scene.update(delta_time)
end

function scene.control_button(command)
	if command == Command.Confirm then
		character = love.filesystem.load("character.lua")()
		Scene.Load("world")
	elseif command == Command.Deny or command == Command.Menu then
		love.event.quit()
	end
end

function scene.control_axis(x_axis, y_axis)
end

function scene.draw()
	love.graphics.draw(wastedText, wastedTransform)
	love.graphics.draw(infoText, infoTransform)
end

return scene
