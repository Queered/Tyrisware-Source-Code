

-- << Functions n stuffington >> --
local sayMessage = function(msg, target) replicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer(msg, target or "ALL") end


workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    camera = workspace.CurrentCamera
end)

client:GetPropertyChangedSignal("Character"):Connect(function()
    clientCharacter = client.Character
end)

--[[
    <vector2> WTS(<vector3> position)
]]--
local WTS = function(position)
    local screen = workspace.CurrentCamera:WorldToViewportPoint(position)
    return Vector2.new(screen.x, screen.y)
end

--[[
    <boolean> isAlive(<player> player)
]]--
local isAlive = function(player)
    return (player and player.Character and player.Character:FindFirstChild("Humanoid") and player.Character:FindFirstChild("HumanoidRootPart")) and true or false
end

--[[
    <boolean> isOnScreen(<vector2> position)
]]--
local isOnScreen = function(position)
    local vec, os = camera:WorldToScreenPoint(position)
    return os == true
end

--[[
    <boolean> isVisible(<player> player)
]]--
local isVisible = function(player)
    if not isAlive(player) or not isAlive(client) then return false end
    return #camera:GetPartsObscuringTarget({player.Character.HumanoidRootPart.Position, clientCharacter.HumanoidRootPart.Position}, {camera, clientCharacter, player.Character})
end

--[[
    <boolean> isInFov(<player> target)
]]--
local isInFov = function(target)
    local screenPoint = camera:WorldToScreenPoint(target.Character:WaitForChild("HumanoidRootPart", math.huge).Position)
    local vectorDistance = (Vector2.new(userInputService:GetMouseLocation().X, userInputService:GetMouseLocation().Y) - Vector2.new(screenPoint.X, screenPoint.Y)).Magnitude
    local charDistance = Vector3.new(clientCharacter:WaitForChild("HumanoidRootPart", math.huge).Position - target.Character:WaitForChild("HumanoidRootPart", math.huge).Position).Magnitude

    if vectorDistance < Flags['LegitAimAssist_FieldOfView']:Get() and isOnScreen(target.Character:WaitForChild("HumanoidRootPart", math.huge).Position) then
        return true
    end
    return false
end

--[[
    <player> getTarget()
]]--
local getTarget = function()

    local conditions = Flags['LegitAimAssist_Conditions']:Get()
    local targetSelection = Flags['LegitAimAssist_TargetPriority']:Get()
    local targets = {}

    for _, player in next, players:GetPlayers() do
        if player == client then continue end 

        if Find(conditions, "Friend") then
            if player:IsFriendsWith(client.UserId) then continue end
        end

        if Find(conditions, "Visible") then
            if not isVisible(player) then continue end
        end

        local screenPoint = camera:WorldToScreenPoint(player.Character:WaitForChild("HumanoidRootPart", math.huge).Position)
        local vectorDistance = (Vector2.new(userInputService:GetMouseLocation().X, userInputService:GetMouseLocation().Y) - Vector2.new(screenPoint.X, screenPoint.Y)).Magnitude
        local charDistance = Vector3.new(clientCharacter:WaitForChild("HumanoidRootPart", math.huge).Position - player.Character:WaitForChild("HumanoidRootPart", math.huge).Position).Magnitude

        if vectorDistance < Flags['LegitAimAssist_FieldOfView']:Get() and isOnScreen(player.Character:WaitForChild("HumanoidRootPart", math.huge).Position) then
            table.insert(targets, {player, vectorDistance, charDistance})
        end
    end

    local focusTarget = targets[1]

    if targetSelection == "Closest to Character" then

        for _, target in next, targets do
            if target[3] == focusTarget[3] then continue end

            if target[3] < focusTarget[3] then
                focusTarget = target
            end
        end

    elseif targetSelection == "Closest to Cursor" then
        for _, target in next, targets do 
            if target[2] == focusTarget[2] then continue end

            if target[2] < focusTarget[2] then
                focusTarget = target
            end
        end

    elseif targetSelection == "Is Priority" then 
        for _, target in next, targets do 
            if library.Relations[target.UserId] == "Priority" then
                return target
            end
        end
        return targets[1]
    else -- Lowest Health
        for _, target in next, targets do
            if target[1].Character:WaitForChild("Humanoid", math.huge).Health == focusTarget[1].Character:WaitForChild("Humanoid", math.huge).Health then continue end

            if target[1].Character:WaitForChild("Humanoid", math.huge).Health < focusTarget[1].Character:WaitForChild("Humanoid", math.huge).Health then
                focusTarget = target
            end
        end

    end    
    
    if focusTarget ~= nil then return focusTarget[1] else return nil end

end

--[[
    <part> closestPartToCursor(<player>)
]]--
local closestPartToCursor = function(player)

    local targetParts = {}

    for _, part in next, player.Character:GetChildren() do
        if part:IsA("MeshPart") or part:IsA("BasePart") then
            if Find(Flags["LegitAimAsisst_Aimbone"]:Get(), part.Name) and not Find(forbiddenParts, part.Name) then
                local screenPoint = camera:WorldToScreenPoint(part.Position)
                local vectorDistance = (Vector2.new(userInputService:GetMouseLocation().X, userInputService:GetMouseLocation().Y) - Vector2.new(screenPoint.X, screenPoint.Y)).Magnitude
                table.insert(targetParts, {part, vectorDistance})
            end

        end
    end 

    local focusTarget = targetParts[1]

    for _, part in next, targetParts do
        if focusTarget[2] > part[2] then
            focusTarget = part
        end
    end
    return focusTarget[1]

end

--[[
    <CFrame> getClosestPoint()
]]--
local getClosestPoint = function()
    local Transform = currentAimpart.CFrame:pointToObjectSpace(client:GetMouse().Hit.Position) -- Transform into local space
    local HalfSize = currentAimpart.Size * 0.5
    return currentAimpart.CFrame * Vector3.new( -- Clamp & transform into world space
        math.clamp(Transform.x, -HalfSize.x, HalfSize.x),
        math.clamp(Transform.y, -HalfSize.y, HalfSize.y),
        math.clamp(Transform.z, -HalfSize.z, HalfSize.z)
    )
end

--[[
    <void> clearTable(<table> tab)
]]--
local clearTable = function(tab)
    for _, ent in next, tab do
        ent = nil 
    end
end

-- stuffington
spawn(function()
    while true do
        if Flags["PredictionBreaker_Enabled"]:Get() then
            if isAlive(client) then
                fakeVelocity = Vector3.new(Flags["Velocity_X"]:Get(), Flags["Velocity_Y"]:Get(), Flags["Velocity_Z"]:Get())
                realVelocity = clientCharacter["HumanoidRootPart"].Velocity

                for index, part in next, clientCharacter:GetChildren() do
                    if part and part:IsA("BasePart") then 
                        lastVelocities[part] = part.Velocity
                        part.Velocity = fakeVelocity
    
                        if Flags['Desync_Enabled']:Get() == true and part == clientCharacter["HumanoidRootPart"] then 
                            lastCFrames[part] = part.CFrame 
                            part.CFrame = part.CFrame * CFrame.Angles(0,math.rad(0),0);
                            part.CFrame = part.CFrame * CFrame.Angles(0,math.rad(0.01),0)
                            part.AssemblyLinearVelocity = fakeVelocity
                            print(part.CFrame)
                        end
                    end
                end
                
                
                runService.RenderStepped:wait()
                
                for index, part in next, clientCharacter:GetChildren() do
                    if part and part:IsA("BasePart") then 
                        part.Velocity = lastVelocities[part];
    
                        if Flags['Desync_Enabled']:Get() == true and part == clientCharacter["HumanoidRootPart"] and lastCFrames[part] then 
                            part.CFrame = lastCFrames[part];
                        end
                    end
                end
                clearTable(lastVelocities);
                clearTable(lastCFrames);

                if Flags["PredictionBreakerPreset_Enabled"]:Get() == true then
                    if Flags["PredictionBreakerPreset_Type"]:Get() == "Random" then
                        Flags["Velocity_X"]:Set(math.random(-600, 600))
                        Flags["Velocity_Y"]:Set(math.random(-600, 600))
                        Flags["Velocity_Z"]:Set(math.random(-600, 600))
                    else
                        if Flags["Velocity_X"]:Get() >= 600 then
                            velocityDirection = true
                        elseif Flags["Velocity_X"]:Get() <= -600 then
                            velocityDirection = false
                        end
                        Flags["Velocity_X"]:Set(velocityAmount)
                        Flags["Velocity_Y"]:Set(velocityAmount)
                        Flags["Velocity_Z"]:Set(velocityAmount)

                        

                        if velocityDirection then
                            velocityAmount -= 1
                        else
                            velocityAmount += 1
                        end

                    end
                end
            end
        end
        
        runService.Heartbeat:Wait()
    end
end)

--[[
    <void> drawFov()
]]--
local drawFov = function()
    if Flags['FOV_Enabled']:Get() then
        fovCircle.Visible = true
        fovCircle.Thickness = Flags['FOV_Thickness']:Get() / 100
        fovCircle.NumSides = Flags['FOV_Numsides']:Get()
        fovCircle.Radius = Flags['LegitAimAssist_FieldOfView']:Get() 
        fovCircle.Filled = Flags['FOV_Filled']:Get() or false
        fovCircle.Position = Vector2.new(userInputService:GetMouseLocation().X, userInputService:GetMouseLocation().Y)
        fovCircle.Color = Flags['FOV_Color']:Get() or Color3.fromRGB(255,0,0)
        fovCircle.Transparency = Flags['FOV_Transparency']:Get() / 100
    else
        fovCircle.Visible = false
    end
end

--[[
    <void> drawAimpoint()
]]--
local drawAimpoint = function()
    if Flags['PredictionDot_Enabled']:Get() and currentAimpoint ~= nil and currentTarget ~= nil then
        if Flags['LegitAimAssist_DotType']:Get() == "Dot" then
            predLine.Visible = false
            predCircle.Visible = isOnScreen(currentAimpoint) 
            predCircle.Position = WTS(currentAimpoint)
            predCircle.Radius = Flags['PredictionDot_Size']:Get()
            predCircle.Filled = Flags['PredictionDot_Filled']:Get()
            predCircle.Color = Flags['PredictionDot_Color']:Get()
            predCircle.Thickness = Flags['PredictionDot_Thickness']:Get()
            predCircle.NumSides = Flags['PredictionDot_Numsides']:Get()
        else
            predCircle.Visible = false
            predLine.Visible = isOnScreen(currentAimpoint)
            predLine.From = WTS(currentAimpart.Position)
            predLine.To = WTS(currentAimpoint)
            predLine.Color = Flags['PredictionLine_Color']:Get()
            predLine.Thickness = Flags['PredictionLine_Thickness']:Get()
            predLine.Transparency = 1
            predLine.ZIndex = 1
        end
    else
        predLine.Visible = false
        predCircle.Visible = false
    end
end

--[[
    <void> drawEsp()
]]--
local drawEsp = function()
    for _, player in next, players:GetPlayers() do
        if player == client then continue end
        if not isAlive(player) then continue end
        if library.Relations[player.UserId] == "Priority" or library.Relations[player.UserId] == "Enemy" then

            if not player.Character:FindFirstChild("Highlight") then
                if library.Relations[player.UserId] == "Priority" then
                    wait()
                    local hl = Instance.new("Highlight", player.Character)
                    hl.OutlineColor = Color3.fromRGB(66, 30, 227)
                    hl.FillTransparency = 1
                elseif library.Relations[player.UserId] == "Enemy" then
                    wait()
                    local hl = Instance.new("Highlight", player.Character)
                    hl.OutlineColor = Color3.fromRGB(227, 30, 53)
                    hl.FillTransparency = 1
                end
            else
                if library.Relations[player.UserId] == "Priority" then
                    player.Character:FindFirstChild("Highlight").OutlineColor = Color3.fromRGB(66, 30, 227)
                    player.Character:FindFirstChild("Highlight").FillTransparency = 1
                elseif library.Relations[player.UserId] == "Enemy" then
                    player.Character:FindFirstChild("Highlight").OutlineColor = Color3.fromRGB(227, 30, 53)
                    player.Character:FindFirstChild("Highlight").FillTransparency = 1
                end
            end
        else
            if player.Character:FindFirstChild("Highlight") ~= nil then
                player.Character:FindFirstChild("Highlight"):Destroy()
            end
        end
    end
end

--[[
    <void> autoShoot()
]]--

local autoShoot = function()
    if Flags['RageSection_AutoShoot']:Get() == true then
        if currentTarget ~= nil and currentAimpoint ~= nil then
            if isVisible(currentTarget) then
                if clientCharacter:FindFirstChildOfClass("Tool") ~= nil then
                    local tool = clientCharacter:FindFirstChildOfClass("Tool") 
                    if isWeapon(tool) then
                        tool:Activate()
                    end
                end
            end
        end
    end
end

--[[
    <void> calculateAimpoint()
]]--

local calculateAimpoint = function()

    if currentTarget ~= nil then
        currentAimpart = closestPartToCursor(currentTarget)
        
        if Flags['LegitAimAssist_AimMethod']:Get() == "Closest Point" then
            currentAimpoint = getClosestPoint()
        else
            currentAimpoint = currentAimpart.Position
        end
    
        if Flags['Resolver_Enabled']:Get() == true then
            currentAimpoint = currentTarget.Character:GetPivot() + (velocities[currentTarget] * (Flags['LegitAimAssist_PredictionAmt']:Get()/100))
        else
            currentAimpoint = currentAimpoint + (currentAimpart.Velocity * (Flags['LegitAimAssist_PredictionAmt']:Get()/100))
        end
    
        if typeof(currentAimpoint) == "CFrame" then
            currentAimpoint = currentAimpoint.p 
        end


    end
end


--[[
    <boolean> isGun(<tool> tool)
]]--
local isGun = function(tool)
    return tool:IsA("Tool") -- temporary
end

--[[
    <void> teleportBuy(<model> weapon)
]]--
local teleportBuy = function(weapon)
    if clientCharacter.Humanoid.Health >= 1 then
        clientCharacter.HumanoidRootPart.CFrame = weapon:FindFirstChild("Head").CFrame
        wait(.2)
        if weapon.Name:match("Ammo") then
            for i=1, Flags['Autobuy_AmmoAmt']:Get() do
                fireclickdetector(weapon:FindFirstChild("ClickDetector"))
                wait(.5)
            end
        else
            fireclickdetector(weapon:FindFirstChild("ClickDetector"))
            wait(.2)
        end
    end
end

--[[
    <beam> misc:CreateBeam(<attachment> origin_att, <attachment> ending_att, <string> texture)
]]--
function misc:CreateBeam(origin_att, ending_att, texture)
    local beam = Instance.new("Beam")
    beam.Texture = texture or "http://www.roblox.com/asset/?id=446111271"
    beam.TextureMode = Enum.TextureMode.Wrap
    beam.TextureSpeed = 8
    beam.LightEmission = 1
    beam.LightInfluence = 1
    beam.TextureLength = 12
    beam.FaceCamera = true
    beam.Enabled = true
    beam.ZOffset = -1
    beam.Transparency = NumberSequence.new(Flags['BulletTracer_Transparency']:Get() / 100, Flags['BulletTracer_Transparency']:Get() / 100)
    beam.Color = ColorSequence.new(Flags['BulletTracer_Color']:Get(), Color3.new(0, 0, 0))
    beam.Attachment0 = origin_att
    beam.Attachment1 = ending_att
    debris:AddItem(beam, 3)
    debris:AddItem(origin_att, 3)
    debris:AddItem(ending_att, 3)
    
    local speedtween = TweenInfo.new(5, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out, 0, false, 0)
    tweenService:Create(beam, speedtween, { TextureSpeed = 2 }):Play()
    beam.Parent = Workspace
    table.insert(misc.beams, { beam = beam, time = tick() }) 
    return beam
end

--[[
    <void> misc:UpdateBeams()
]]--
function misc:UpdateBeams()
    local time = tick()
    for i = #self.beams, 1, -1 do
        if self.beams[i].beam  then
            local transp = 1 - (Flags['BulletTracer_Transparency']:Get() / 100)
            local transparency = transp + (((time - self.beams[i].time) - 2) * (1 - transp))
            self.beams[i].beam.Transparency = NumberSequence.new(transparency, transparency)
            if transparency >= 1 then
                table.remove(self.beams, i)
            end
        else
            table.remove(self.beams, i)
        end
    end
end

-- Aimviewer bypassington
client.CharacterAdded:Connect(function(char)
    char.ChildAdded:Connect(function(child)
        if isGun(child) then
            if toolConnection[1] == nil then
                toolConnection[1] = child 
            end
            if toolConnection[1] ~= child and toolConnection[2] ~= nil then 
                toolConnection[2]:Disconnect()
                toolConnection[1] = child
            end
    
            toolConnection[2] = child.Activated:Connect(function() 
                if Flags['BulletTracer_Enabled']:Get() == true then
                    local fromAttach = Instance.new("Attachment", workspace.Terrain)
                    fromAttach.Position = clientCharacter:FindFirstChildOfClass("Tool"):FindFirstChild("Handle").Position 
                    local toAttach = Instance.new("Attachment", workspace.Terrain)
                    local pPos = nil
                    if Flags['Prediction_EnabledKey']:Active() then 
                        pPos = currentAimpoint 
                    else 
                        pPos = mouse.Hit.p
                    end
                    toAttach.Position = pPos
                    local beam = misc:CreateBeam(fromAttach, toAttach)
                end
                if currentTarget ~= nil and currentAimpoint ~= nil and Flags['Prediction_EnabledKey']:Active() == true then
                    if Flags['LegitAimAssist_Miss']:Get() >= math.random(1, 100) then
                        currentAimpoint = currentAimpoint + Vector3.new(math.random(-5,5), math.random(-2,2), math.random(-1,3))
                    end
                    
                    shootRemote:FireServer(shootArgument, currentAimpoint)
                end
    
            end)
        end
    end)

    if Flags['Autobuy_Enabled']:Get() == true then
        while not isAlive(client) or clientCharacter:FindFirstChild("ForceField") do
            wait()
        end
        oldChar = clientCharacter.HumanoidRootPart.CFrame

        if Find(Flags['Item_Selection']:Get(), "Revolver") and not client.Backpack:FindFirstChild("[Revolver]") then
            teleportBuy(weaponShops["Revolver"])
            wait(Flags['Autobuy_AmmoAmt']:Get() * 0.5 + 0.6)
        end

        if Find(Flags['Item_Selection']:Get(), "Revolver Ammo") and not client.Backpack:FindFirstChild("[Revolver]") then
            teleportBuy(weaponShops["Revolver Ammo"])
            wait(Flags['Autobuy_AmmoAmt']:Get() * 0.5 + 0.6)
        end

        if Find(Flags['Item_Selection']:Get(), "Double-Barrel") and not client.Backpack:FindFirstChild("[Double-Barrel SG]") then
            teleportBuy(weaponShops["Double-Barrel SG"])
            wait(Flags['Autobuy_AmmoAmt']:Get() * 0.5 + 0.6)
        end

        if Find(Flags['Item_Selection']:Get(), "Double-Barrel Ammo") and not client.Backpack:FindFirstChild("[Double-Barrel SG]") then
            teleportBuy(weaponShops["Double-Barrel SG Ammo"])
            wait(Flags['Autobuy_AmmoAmt']:Get() * 0.5 + 0.6)
        end
        clientCharacter.HumanoidRootPart.CFrame = oldChar

    end



end)

client.Character.ChildAdded:Connect(function(child)
    if isGun(child) then
        if toolConnection[1] == nil then
            toolConnection[1] = child 
        end
        if toolConnection[1] ~= child and toolConnection[2] ~= nil then 
            toolConnection[2]:Disconnect()
            toolConnection[1] = child
        end

        toolConnection[2] = child.Activated:Connect(function() 
            if Flags['BulletTracer_Enabled']:Get() == true then
                local fromAttach = Instance.new("Attachment", workspace.Terrain)
                fromAttach.Position = clientCharacter:FindFirstChildOfClass("Tool"):FindFirstChild("Handle").Position 
                local toAttach = Instance.new("Attachment", workspace.Terrain)
                local pPos = nil
                if Flags['Prediction_EnabledKey']:Active() then 
                    pPos = currentAimpoint 
                else 
                    pPos = mouse.Hit.p
                end
                toAttach.Position = pPos
                local beam = misc:CreateBeam(fromAttach, toAttach)
            end
            if currentTarget ~= nil and currentAimpoint ~= nil and Flags['Prediction_EnabledKey']:Active() == true then
                if Flags['LegitAimAssist_Miss']:Get() >= math.random(1, 100) then
                    currentAimpoint = currentAimpoint + Vector3.new(math.random(-5,5), math.random(-2,2), math.random(-1,3))
                end
                shootRemote:FireServer(shootArgument, currentAimpoint)
            end

        end)
    end
end)

-- thank you xaxa
runService.Heartbeat:Connect(function(step)

    pcall(function()
        currentPing = tonumber(string.format("%.3f", ping:GetValue()));
        
        for index, player in next, players:GetPlayers() do 
            local lastPosition = positions[player];
            if not lastPosition then 
                if not player.Character then continue end
                lastPosition =  player.Character["HumanoidRootPart"].Position    
            end 
            local character = player.Character 
            local rootPart = character and character:FindFirstChild("HumanoidRootPart");

            if rootPart then 
                local position = rootPart.Position 
                velocities[player] = (position - lastPosition) / step
                positions[player] = rootPart.Position
            else 
                velocities[player] = Vector3.new
                positions[player] = Vector3.new
            end
        end
    end)
    

    if Flags['RageSection_CFrameKeybind']:Active() then
        if isAlive(client) then 
            if clientCharacter.Humanoid.MoveDirection.Magnitude > 0 then
                for i=1, Flags['RageSection_CFrameSpeedMulti']:Get() do
                    clientCharacter:TranslateBy(clientCharacter.Humanoid.MoveDirection)
                end
            end
        end
    end

end)


-- main RS
runService.RenderStepped:Connect(function()

    currentTarget = getTarget() 

    if Flags['Locktarget_EnabledKey']:Active() == true then
        if lockedTarget ~= nil then
            if isInFov(lockedTarget) then
                currentTarget = lockedTarget
            else
                currentTarget = nil
                currentAimpoint = nil
            end
        else
            lockedTarget = currentTarget
        end
    else
        lockedTarget = nil
    end

    -- Visuals --
    drawFov()
    drawAimpoint()
    drawEsp()
    misc:UpdateBeams()

    -- Rage --
    autoShoot()

    -- Aim --
    calculateAimpoint()

end)



local __namecall -- cock ;)
__namecall = hookmetamethod(game, "__namecall", function(self, ...)
    local Args = {...}
    local Method = getnamecallmethod()

    if tostring(self.Name) == "MainEvent" and tostring(Method) == "FireServer" then
        if Args[1] == "TeleportDetect" or Args[1] == "CHECKER_1" or Args[1] == "OneMoreTime" then
            return
        end
    end

    return __namecall(self, ...)
end)

mt.__namecall = newcclosure(function(self, ...)
    local method = getnamecallmethod()
    local args = {...}

    
    if typeof(args[2]) == "Vector3" then
        shootArgument = args[1]
    end
    
    return backupnamecall(self, ...)
end)
