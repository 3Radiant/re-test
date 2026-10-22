-- Client entry point. Order matters: camera first, then the character controller
-- (which configures the camera), then everything that builds on them.
local Controllers = script:WaitForChild("Controllers")

local CameraController = require(Controllers:WaitForChild("CameraController"))
local CharacterController = require(Controllers:WaitForChild("CharacterController"))
local GunController = require(Controllers:WaitForChild("GunController"))
local ShifterController = require(Controllers:WaitForChild("ShifterController"))
local HudController = require(Controllers:WaitForChild("HudController"))

CameraController.start()
CharacterController.start()
GunController.start()
ShifterController.start()
HudController.start()
