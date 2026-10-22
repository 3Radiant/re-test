-- Server entry point. Each service owns one part of the game.
local Services = script:WaitForChild("Services")

local GunService = require(Services:WaitForChild("GunService"))
local ShifterService = require(Services:WaitForChild("ShifterService"))
local PlayerService = require(Services:WaitForChild("PlayerService"))

GunService.start()
ShifterService.start()
PlayerService.start()
