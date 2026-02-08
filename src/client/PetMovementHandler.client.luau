local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Player = Players.LocalPlayer
local PlayerPetsFolder = workspace:WaitForChild("Player_Pets")
local WildPetsFolder = workspace:WaitForChild("Wild_Pets")

-- Lokalne referencje dla wydajności (Szybszy dostęp niż do biblioteki math)
local math_sin = math.sin
local math_abs = math.abs
local math_rad = math.rad
local math_clamp = math.clamp
local os_clock = os.clock

-- KONFIGURACJA
local BASE_SCALE = 0.004
local IDLE_BREATH_SPEED = 3
local IDLE_BREATH_AMP = 0.04 
local WALK_BOUNCE_SPEED = 5
local WALK_BOUNCE_HEIGHT = 2 
local WALK_TILT_MAX = 8 
local ANIM_TRANSITION_SPEED = 10
local FOLLOW_LERP_SPEED = 0.12
local ROTATION_LERP_SPEED = 0.15

-- CACHE STANÓW (Zamiast wolnych Atrybutów w każdej klatce)
local petStates = {} 

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude

-- Funkcja bezpiecznego pobierania wysokości podłoża (zoptymalizowana)
local function getGroundHeight(position, model, state)
    if state.rayTimer and state.rayTimer > 0 then
        state.rayTimer -= 1
        return state.lastGroundY or position.Y
    end
    state.rayTimer = 3 -- Raycast tylko co 3 klatki

    rayParams.FilterDescendantsInstances = {model, Player.Character, WildPetsFolder, PlayerPetsFolder}
    local result = workspace:Raycast(position + Vector3.new(0, 5, 0), Vector3.new(0, -15, 0), rayParams)
    
    local hipHeight = (model:GetExtentsSize().Y / 2)
    state.lastGroundY = result and (result.Position.Y + hipHeight) or position.Y
    return state.lastGroundY
end

-- GŁÓWNA FUNKCJA ANIMUJĄCA (Płynne przejścia i brak błędów nil)
local function updatePetAnimation(model, dt, velocity, targetPos, lookDir)
    -- Bezpiecznik dla błędu "index nil with X"
    if not targetPos then return end 
    
    local t = os_clock()
    local state = petStates[model]
    if not state then
        petStates[model] = {weight = 0, lastGroundY = targetPos.Y, rayTimer = 0}
        state = petStates[model]
    end

    local isMoving = velocity > 0.5
    
    -- 1. Płynna waga animacji (Lerp dla WalkWeight)
    local targetWeight = isMoving and 1 or 0
    state.weight = state.weight + (targetWeight - state.weight) * math_clamp(dt * ANIM_TRANSITION_SPEED, 0, 1)

    -- 2. Pozycja i Orientacja
    local groundY = getGroundHeight(targetPos, model, state)
    local finalPos = Vector3.new(targetPos.X, groundY, targetPos.Z)
    
    local currentCF = model:GetPivot()
    local currentLook = (currentCF.LookVector * Vector3.new(1, 0, 1))
    if currentLook.Magnitude < 0.01 then currentLook = lookDir end
    
    local smoothLook = currentLook:Lerp(lookDir, ROTATION_LERP_SPEED).Unit
    local baseCF = CFrame.lookAt(finalPos, finalPos + smoothLook)
    
    -- 3. Efekty Bounce & Tilt (Tylko jeśli waga > 0.01)
    local bounce = 0
    local tilt = 0
    if state.weight > 0.01 then
        bounce = math_abs(math_sin(t * WALK_BOUNCE_SPEED)) * (WALK_BOUNCE_HEIGHT * state.weight)
        tilt = math_sin(t * WALK_BOUNCE_SPEED) * (math_rad(WALK_TILT_MAX) * state.weight)
    end

    -- 4. Oddychanie (Scale) - Zoptymalizowane
    if state.weight < 0.95 then
        local breathIntensity = 1 - state.weight
        local scale = BASE_SCALE * (1 + math_sin(t * IDLE_BREATH_SPEED) * (IDLE_BREATH_AMP * breathIntensity))
        model:ScaleTo(scale)
    end

    model:PivotTo(baseCF * CFrame.new(0, bounce, 0) * CFrame.Angles(tilt, 0, 0))
end

-- AKTUALIZACJA WSZYSTKICH GRACZY (Widoczność globalna)
local function updateAllPlayerPets(dt)
    for _, folder in ipairs(PlayerPetsFolder:GetChildren()) do
        local owner = Players:FindFirstChild(folder.Name)
        if not (owner and owner.Character and owner.Character.PrimaryPart) then continue end
        
        local char = owner.Character
        local charCF = char.PrimaryPart.CFrame
        local charVel = char.PrimaryPart.AssemblyLinearVelocity.Magnitude
        local pets = folder:GetChildren()

        for i, pet in ipairs(pets) do
            local side = (i % 2 == 0) and 1 or -1
            local slot = Vector3.new(3 * side, 0, 4 + (math.floor((i-1)/2) * 2))
            local worldTargetPos = (charCF * CFrame.new(slot)).Position
            
            local currentPos = pet:GetPivot().Position
            local lerpedPos = currentPos:Lerp(worldTargetPos, FOLLOW_LERP_SPEED)
            
            updatePetAnimation(pet, dt, charVel, lerpedPos, charCF.LookVector)
        end
    end
end

-- DZIKIE ZWIERZĘTA (Z bezpiecznikami nil)
local wildPetData = {}
local function updateWildPets(dt)
    for _, pet in ipairs(WildPetsFolder:GetChildren()) do
        local uuid = pet:GetAttribute("UUID")
        if not uuid then continue end

        local data = wildPetData[uuid]
        if not data then
            wildPetData[uuid] = { state = "Idle", timer = os_clock() + 2 }
            data = wildPetData[uuid]
        end

        local currentPivot = pet:GetPivot()
        local currentPos = currentPivot.Position

        if data.state == "Moving" and data.nextPos then
            local diff = (data.nextPos - currentPos) * Vector3.new(1, 0, 1)
            if diff.Magnitude > 0.5 then
                local moveDir = diff.Unit
                updatePetAnimation(pet, dt, 5, currentPos + (moveDir * 5 * dt), moveDir)
            else
                data.state = "Idle"
                data.timer = os_clock() + math.random(3, 6)
            end
        else
            updatePetAnimation(pet, dt, 0, currentPos, currentPivot.LookVector)
            if os_clock() > data.timer then
                -- Bezpieczne pobieranie Home (zapobiega błędowi nil)
                local hX = pet:GetAttribute("HomeX") or currentPos.X
                local hY = pet:GetAttribute("HomeY") or currentPos.Y
                local hZ = pet:GetAttribute("HomeZ") or currentPos.Z
                local home = Vector3.new(hX, hY, hZ)
                
                local radius = pet:GetAttribute("WanderRadius") or 20
                local angle = math_rad(math.random(0, 360))
                data.nextPos = home + Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
                data.state = "Moving"
            end
        end
    end
end

RunService.Heartbeat:Connect(function(dt)
    updateAllPlayerPets(dt)
    updateWildPets(dt)
end)