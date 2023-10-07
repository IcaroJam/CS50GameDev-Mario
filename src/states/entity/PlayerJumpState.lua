--[[
    GD50
    Super Mario Bros. Remake

    Author: Colton Ogden
    cogden@cs50.harvard.edu
]]

PlayerJumpState = Class{__includes = BaseState}

function PlayerJumpState:init(player, gravity)
    self.player = player
    self.gravity = gravity
    self.animation = Animation {
        frames = {3},
        interval = 1
    }
    self.player.currentAnimation = self.animation
end

function PlayerJumpState:enter(params)
    gSounds['jump']:play()
    self.player.dy = PLAYER_JUMP_VELOCITY
end

function PlayerJumpState:update(dt)
    self.player.currentAnimation:update(dt)
    self.player.dy = self.player.dy + self.gravity
    self.player.y = self.player.y + (self.player.dy * dt)

    -- go into the falling state when y velocity is positive
    if self.player.dy >= 0 then
        self.player:changeState('falling')
    end

    self.player.y = self.player.y + (self.player.dy * dt)

    -- look at two tiles above our head and check for collisions; 3 pixels of leeway for getting through gaps
    local tileLeft = self.player.map:pointToTile(self.player.x + 3, self.player.y)
    local tileRight = self.player.map:pointToTile(self.player.x + self.player.width - 3, self.player.y)

    -- if we get a collision up top, go into the falling state immediately
    if (tileLeft and tileRight) and (tileLeft:collidable() or tileRight:collidable()) then
        self.player.dy = 0
        self.player:changeState('falling')

    -- else test our sides for blocks
    elseif love.keyboard.isDown('left') then
        self.player.direction = 'left'
        self.player.x = self.player.x - PLAYER_WALK_SPEED * dt
        self.player:checkLeftCollisions(dt)
    elseif love.keyboard.isDown('right') then
        self.player.direction = 'right'
        self.player.x = self.player.x + PLAYER_WALK_SPEED * dt
        self.player:checkRightCollisions(dt)
    end

    -- check if we've collided with any collidable game objects
    for k, object in pairs(self.player.level.objects) do
        if object:collides(self.player) then
            if object.solid then
                if object.texture == "keylocks" then
                    object.onCollide(object, self.player)
                    if object.hit then
                        table.remove(self.player.level.objects, k)
                        SpawnPoleFlag(self.player.level)
                    end
                else
                    object.onCollide(object)
                end

                self.player.y = object.y + object.height
                self.player.dy = 0
                self.player:changeState('falling')
            elseif object.consumable then
                object.onConsume(self.player)
                table.remove(self.player.level.objects, k)
            end
        end
    end

    -- check if we've collided with any entities and die if so
    for k, entity in pairs(self.player.level.entities) do
        if entity:collides(self.player) then
            gSounds['death']:play()
            gStateMachine:change('start')
        end
    end
end

function SpawnPoleFlag(lvl)
    -- Delete the game objects occupying the region reserved for the flag
    local i = #lvl.objects
    while lvl.objects[i].x > (lvl.tileMap.width - 5) * TILE_SIZE do
        table.remove(lvl.objects, i)
        i = i - 1
    end
    -- Empty the last four columns of the level
    for x = lvl.tileMap.width - 3, lvl.tileMap.width do
        for y = 1, lvl.tileMap.height do
            lvl.tileMap.tiles[y][x] = nil
        end
    end
    -- Create a kind of ground stair to the pole
    local tileset = lvl.tileMap.tiles[1][1].tileset
    local topperset = lvl.tileMap.tiles[1][1].topperset
    local tileID
    for x = lvl.tileMap.width - 3, lvl.tileMap.width do
        for y = 1, lvl.tileMap.height do
            if (y > -x + lvl.tileMap.width + 3) and y > 4 then
                tileID = TILE_ID_GROUND
            else
                tileID = TILE_ID_EMPTY
            end
            lvl.tileMap.tiles[y][x] = Tile(x, y, tileID, (y > 1 and tileID == TILE_ID_GROUND and lvl.tileMap.tiles[y - 1][x].id == TILE_ID_EMPTY) and topperset or nil, tileset, topperset)
        end
    end
    -- add the pole object
    table.insert(lvl.objects, GameObject {
        texture = "polesNflags",
        quad = "poles",
        x = (lvl.tileMap.width - 1.5) * TILE_SIZE,
        y = 1 * TILE_SIZE,
        width = 16,
        height = 48,

        -- make it a random variant
        frame = 3, --math.random(#POLES),
        collidable = true,
        consumable = false,
        solid = false,

        onCollide = function()
        end
    })
    -- add the flag object
    table.insert(lvl.objects, GameObject {
        texture = "polesNflags",
        quad = "flags",
        x = (lvl.tileMap.width - 1) * TILE_SIZE,
        y = 1 * TILE_SIZE,
        width = 16,
        height = 16,

        -- make it a random variant
        frame = 1,--math.random(#POLES),
        collidable = true,
        consumable = false,
        solid = false,

		animation = Animation {
			frames = {1, 2},
			interval = 0.2
		},

        onCollide = function()
        end
    })
end
