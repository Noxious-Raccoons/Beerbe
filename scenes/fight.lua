require "scenes/fight/enemies"
require "scene_manager"
require "commands"
require "animation"

local scene = {}

local sceneState = {
    current = 0,
    action = 0,
    target = 1,
    magic = 2,
    effect = 3,
    item = 4
}

local choose = 0

local enemies = {}

local characterAnimation = require "scenes/fight/character"

-- load effects
local effects = require "scenes/fight/effects"

-- load targeting
local target = require "scenes/fight/targeting"
--load menus
local chooseMagic = require "scenes/fight/choose_magic"
local chooseItem = require "scenes/fight/choose_item"

function scene.load()
    -- load character
    character = require "character"
    
    characterAnimation:load()
    
    -- load resources
    background = love.graphics.newImage("asserts/fight/background.png")

    local iconsFilenames = {
        "asserts/fight/sword.png",
        "asserts/fight/shield.png",
        "asserts/fight/magic.png",
        "asserts/fight/beer-bottle.png",
        "asserts/fight/run.png"
    }
    icons = love.graphics.newArrayImage(iconsFilenames)
    
    -- create enemies
    local type = 0
    local number = 3--love.math.random(3)
    for i=1, number do
        table.insert(enemies, newEnemy(2, i))
    end
    enemies.current = 0
    enemies.finished = true
end

function scene.unload()
    --characterAnimation:unload()
    background = nil
    icons = nil
    enemies = nil
    target = nil
    effects = nil
    chooseMagic = nil
    chooseItem = nil
end

function attackTarget(attackerId, targetId, skill)
    local attackerUnit = character
    if attackerId ~= target.character.id then
        attackerUnit = enemies[attackerId]
    end
    
    local targetUnit = character
    if targetId ~= target.character.id then
        targetUnit = enemies[targetId]
    end

    local damage = attackerUnit:useSkill(skill)
    targetUnit:takeDamage(damage)

    if targetUnit.health <= 0 and targetId ~= target.character.id then
        table.remove(enemies, targetId)
    end
end

function enemies:turn()
    local slots = require "scenes/fight/slots"
    self.current = self.current + 1
    if self.current <= #enemies then
        sceneState.current = sceneState.effect
        effects:start("hit", target.character.id)
        attackTarget(self.current, target.character.id, "hit")
    else
        sceneState.current = sceneState.action
        self.current = 0
        self.finished = true
    end

    if #enemies <= 0 then 
        Scene.GoBack()
    end
    if character.health <= 0 then
        Scene.Load("wasted")
    end
end

function scene.update(delta_time)
    characterAnimation:update(delta_time)
    if sceneState.current == sceneState.effect then
        effects:update(delta_time)
        if not effects:isPlaying() then
            characterAnimation:setState("stand")
            enemies:turn()
        end
    end
end

function scene.control_button(command)
    if sceneState.current == sceneState.action then
        if command == Command.Left then
            if choose > 0 then
                choose = choose - 1
            end
        elseif command == Command.Right then
            if choose < icons:getLayerCount()-1 then
                choose = choose + 1
            end
        elseif command == Command.Confirm then
            if choose == 0 then
                sceneState.current = sceneState.target
                target.spell = "attack"
                target.index = 1
            elseif choose == 1 then
                --characterAnimation:setState("protect")
            elseif choose == 2 then
                sceneState.current = sceneState.magic
                characterAnimation:setState("cast")
                target.spell = "magic"
                target.index = 1
            elseif choose == 3 then
                sceneState.current = sceneState.item
            elseif choose == 4 then
                love.event.quit()
            end
        elseif command == Command.Deny then
            --characterAnimation:setState("stand")
        end
    elseif sceneState.current == sceneState.target then
        if command == Command.Left then
            target:left(enemies)
        elseif command == Command.Right then
            target:right(enemies)
        elseif command == Command.Confirm then
            local id = enemies[target.index].slot
            if target.spell == "attack" then
                characterAnimation:setState("attack")
                effects:start("sword", id)
            else
                characterAnimation:setState("cast")
                effects:start(target.spell, id)
            end
            sceneState.current = sceneState.effect
            attackTarget(target.character.id, target.index, target.spell)
        elseif command == Command.Deny then
            sceneState.current = sceneState.action
            characterAnimation:setState("stand")
        end
    elseif sceneState.current == sceneState.magic then
        chooseMagic:control_button(command, sceneState, target)
    elseif sceneState.current == sceneState.item then
        chooseItem:control_button(command, sceneState)
    end
end

function scene.draw()

    if sceneState.current == sceneState.magic then
        chooseMagic:draw()
        return
    elseif sceneState.current == sceneState.item then
        chooseItem:draw()
        return
    end

    local menuHeight = love.graphics.getHeight() / 6
    
    love.graphics.draw(background, 0, 0, 0, love.graphics.getWidth() / background:getWidth(), (love.graphics.getHeight() - menuHeight) / background:getHeight())

    for i = 1, #enemies do
        enemies[i]:draw()
    end

    characterAnimation:draw()

    if sceneState.current == sceneState.action then
        local menuItemSize = love.graphics.getHeight() / 7
        local offset = (menuHeight - menuItemSize)/2

        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", offset + choose *  menuHeight, offset + love.graphics.getHeight() - menuHeight, menuItemSize, menuItemSize, 10, 10)
        love.graphics.setLineWidth(1)

        for i = 1, icons:getLayerCount() do
            love.graphics.drawLayer(icons, i, offset + (i - 1) * menuHeight, offset + love.graphics.getHeight() - menuHeight, 0, menuItemSize / icons:getWidth())
        end
    elseif sceneState.current == sceneState.target then
        target:draw(enemies)
    elseif sceneState.current == sceneState.effect then
        effects:draw()
    end

    drawCharacterInfo()
end

function drawCharacterInfo()
    local menuHeight = love.graphics.getHeight() / 6
    local menuItemSize = love.graphics.getHeight() / 7
    local offset = (menuHeight - menuItemSize)/2
    
    local barSize = {}
    barSize.x = love.graphics.getWidth() - 8 * menuItemSize - offset
    barSize.y = menuHeight / 6 

    local healthPosition = {
        x = 8 * menuItemSize,
        y = love.graphics.getHeight() - menuHeight + 2 * barSize.y 
    }

    local manaPosition = {
        x = 8 * menuItemSize,
        y = love.graphics.getHeight() - menuHeight + 4 * barSize.y 
    }
    
    love.graphics.printf(character.name, healthPosition.x, love.graphics.getHeight() - menuHeight + 0.5 * barSize.y ,  barSize.x / (0.00125 * love.graphics.getHeight()), "center", 0, 0.00125 * love.graphics.getHeight())

    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", healthPosition.x, healthPosition.y, barSize.x, barSize.y )
    love.graphics.rectangle("line", manaPosition.x, manaPosition.y, barSize.x, barSize.y )
    love.graphics.setColor(1, 0, 0)
    love.graphics.rectangle("fill", healthPosition.x, healthPosition.y, character.health * barSize.x / character:getMaxHealth(), barSize.y )
    love.graphics.setColor(0, 0, 1)
    love.graphics.rectangle("fill", manaPosition.x, manaPosition.y, character.mana * barSize.x / character:getMaxMana(), barSize.y )
    love.graphics.setColor(1, 1, 1)
    love.graphics.setLineWidth(1)
    
    love.graphics.printf(character.health.."/"..character:getMaxHealth(), healthPosition.x, healthPosition.y,  barSize.x / (0.001 * love.graphics.getHeight()), "center", 0, 0.001 * love.graphics.getHeight())
    love.graphics.printf(character.mana.."/"..character:getMaxMana(), manaPosition.x, manaPosition.y,  barSize.x / (0.001 * love.graphics.getHeight()), "center", 0, 0.001 * love.graphics.getHeight())
end

function scene.control_axis(x_axis, y_axis)
end

return scene
