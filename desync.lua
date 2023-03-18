local players = game:GetService("Players")
local client = players.LocalPlayer
local clientCharacter = client.Character
local runservice = game:GetService("RunService")
local oldpos = nil
local oldtick = tick()
local oldvel = nil
local debounce = 0
local direction = true
local sleepnet = true
while true do
    debounce += 1
    oldpos = clientCharacter.HumanoidRootPart.CFrame
    oldvel = clientCharacter.HumanoidRootPart.Velocity
if not sleepnet then
        clientCharacter.HumanoidRootPart.CFrame = clientCharacter.HumanoidRootPart.CFrame + Vector3.new(555,0,5)
    end
    sethiddenproperty(clientCharacter.HumanoidRootPart, "NetworkIsSleeping", sleepnet)
        clientCharacter.HumanoidRootPart.CFrame = oldpos

    --clientCharacter.HumanoidRootPart.CFrame = clientCharacter.HumanoidRootPart.CFrame - Vector3.new(555,0,0)
    --clientCharacter.HumanoidRootPart.CFrame = clientCharacter.HumanoidRootPart.CFrame * CFrame.Angles(0,0.0005,0)



    runservice.RenderStepped:Wait()

    --clientCharacter.HumanoidRootPart.Velocity = oldvel
    if debounce >= 3 then
        sleepnet = false
        debounce = 0 
    else
        sleepnet = true
    end



    runservice.Heartbeat:Wait()


end