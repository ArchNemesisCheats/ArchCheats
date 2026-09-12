while not game:IsLoaded() do task.wait(0.1) end

local bc, ci, bx
do
    local done = 0
    local function load(url, slot)
        local ok, result = pcall(loadstring, game:HttpGet(url))
        if ok then
            local ok2, lib = pcall(result)
            if ok2 then slot(lib) end
        end
        done = done + 1
    end
    task.spawn(load, 'https://raw.githubusercontent.com/visnoukkk/Creep.cc/refs/heads/main/Source.lua',        function(v) bc = v end)
    task.spawn(load, 'https://raw.githubusercontent.com/visnoukkk/Creep.cc/refs/heads/main/addons/ThemeManager.lua', function(v) ci = v end)
    task.spawn(load, 'https://raw.githubusercontent.com/visnoukkk/Creep.cc/refs/heads/main/addons/SaveManager.lua',  function(v) bx = v end)
    repeat task.wait(0.05) until done >= 3
end

local Toggles = bc.Toggles
local Options  = bc.Options

local Window = bc:CreateWindow({
    Title       = 'arch',
    Center      = true,
    AutoShow    = true,
    TabPadding  = 8,
    MenuFadeTime= 0.2,
})

local function Notify(text)
    bc:Notify('arch — ' .. text)
end

-- Anti-cheat bypass (kept for safety)
pcall(function()
    local ACBypass = {}
    ACBypass.__index = ACBypass

    local PlayersAC           = cloneref(game:GetService('Players'))
    local ReplicatedStorageAC = cloneref(game:GetService('ReplicatedStorage'))
    local ReplicatedFirstAC   = cloneref(game:GetService('ReplicatedFirst'))
    local LocalPlayerAC       = PlayersAC.LocalPlayer
    local stateAC             = { bypassed = false }
    local kExpectedScripts    = {
        [1914481512]='Root', [1936447744]='ReplicatedController',
        [3892767096]='MiscellaneousController', [337076960]='LocalScript3', [2191862192]='ClientFighter'
    }

    local function SafeHook(hookfn, ...)
        local args={...}; local func,inst,metamethod,detour
        if hookfn==hookmetamethod then inst,metamethod,detour=args[1],args[2],args[3] else func,detour=args[1],args[2] end
        if hookfn==hookfunction and iscclosure(func) then detour=newcclosure(detour) end
        if not iscclosure(detour) then detour=newcclosure(detour) end
        local original; pcall(function()
            if hookfn==hookmetamethod then original=hookfn(inst,metamethod,detour) else original=hookfn(func,detour) end
        end); return original
    end
    local function SafeCall(func,...)
        if checkcaller() then return func(...) end
        local old=getthreadidentity(); if old~=2 then setthreadidentity(2) end
        local r={func(...)}; if old~=2 then setthreadidentity(old) end; return table.unpack(r)
    end
    local function VerifyScripts()
        local getscripts_fn=pcall(function() return getscripts or getsenv end)
        local getbytecode_fn=pcall(function() return getscriptbytecode end)
        if not getscripts_fn or not getbytecode_fn then return true end
        local found={}
        for _,script_instance in ipairs(getscripts_fn()) do
            local ok,bytecode=pcall(getbytecode_fn,script_instance)
            if ok and bytecode then
                for expected_id in pairs(kExpectedScripts) do
                    if not found[expected_id] then
                        local source_ok,source=pcall(debug.info,script_instance,'s')
                        if source_ok and source and source~='=[C]' then found[expected_id]=true end
                    end
                end
            end
        end
        for id in pairs(kExpectedScripts) do if not found[id] then return false end end
        return true
    end
    local function HookKickPrevention()
        for _,name in ipairs({'Kick','kick'}) do
            local f=LocalPlayerAC[name]
            if type(f)=='function' then
                local old; old=SafeHook(hookfunction,f,function(self,...)
                    if self==LocalPlayerAC and not checkcaller() then return end
                    return old(self,...)
                end)
            end
        end
    end
    local function HookACScript(ac_script)
        if not ac_script then return end
        local oldindex=SafeHook(hookmetamethod,ac_script,'__index',function(t,k)
            if t==ac_script and not checkcaller() and k=='Enabled' and not stateAC.bypassed then return false end
            if checkcaller() then return oldindex(t,k) end
            return SafeCall(oldindex,t,k)
        end)
        local oldnewindex=SafeHook(hookmetamethod,ac_script,'__newindex',function(t,k,v)
            if t==ac_script and not checkcaller() and k=='Enabled' and not stateAC.bypassed then return end
            if checkcaller() then return oldnewindex(t,k,v) end
            return SafeCall(oldnewindex,t,k,v)
        end)
    end
    if VerifyScripts() then
        local ac_script = ReplicatedFirstAC:WaitForChild('LocalScript3', 10)
        local ac_event  = ReplicatedStorageAC:WaitForChild('Remotes', 10):WaitForChild('RemoteEvent', 10)
        if ac_script and ac_event then
            HookACScript(ac_script)
            HookKickPrevention()
            ac_script.Enabled = false
            stateAC.bypassed  = true
        end
    end
end)

-- Core services
local Players            = game:GetService('Players')
local RunService         = game:GetService('RunService')
local UserInputService   = game:GetService('UserInputService')
local VirtualInputManager= game:GetService('VirtualInputManager')
local ReplicatedStorage  = game:GetService('ReplicatedStorage')
local Lighting           = game:GetService('Lighting')
local HttpService        = game:GetService('HttpService')
local LocalPlayer        = Players.LocalPlayer
local Camera             = workspace.CurrentCamera
local rs                 = ReplicatedStorage
local player             = LocalPlayer
local rng                = Random.new()

local char, root, hum
local conns = {}

local function killConn(key)
    if conns[key] then conns[key]:Disconnect(); conns[key]=nil end
end
local function getLocalRoot() return root end
local function getClosest()
    if not root then return nil end
    local best, bestDist = nil, math.huge
    for _,p in ipairs(Players:GetPlayers()) do
        if p==LocalPlayer or not p.Character then continue end
        local hrp = p.Character:FindFirstChild('HumanoidRootPart')
        if not hrp then continue end
        local d = (root.Position - hrp.Position).Magnitude
        if d < bestDist then bestDist=d; best=p end
    end
    return best
end

local excludeInput=''
local function isEnemy(p)
    if p==player then return false end
    local myTeam=player.Team; if myTeam and p.Team==myTeam then return false end
    if excludeInput~='' and p.Name:lower():find(excludeInput,1,true) then return false end
    return true
end
local shooting=false
local function setShooting(state)
    if state==shooting then return end; shooting=state
    if state then VirtualInputManager:SendMouseButtonEvent(0,0,0,true,nil,0)
    else VirtualInputManager:SendMouseButtonEvent(0,0,0,false,nil,0) end
end

-- Tabs: only Rage and Cosmetics
local Tabs = {
    Rage        = Window:AddTab('Rage'),
    Cosmetics   = Window:AddTab('Cosmetics'),
}

-- RAGE TAB
local rageTab = Tabs.Rage

-- Wallbang section
local wallbangGroup  = rageTab:AddLeftGroupbox('Wallbang')
local wallbangStatus = wallbangGroup:AddLabel('Status: Not activated')

local services=setmetatable({},{__index=function(_,v)
    local ok,r=pcall(function() return game:GetService(v) end); if r then return cloneref(r) end; return nil
end})
local WallbangPlayers=services.Players; local WallbangRunService=services.RunService
local WallbangReplicatedStorage=services.ReplicatedStorage; local WallbangWorkspace=services.Workspace
local WallbangUserInputService=services.UserInputService; local WallbangLocalPlayer=WallbangPlayers.LocalPlayer
local WallbangPlayerScripts=WallbangLocalPlayer.PlayerScripts; local WallbangCamera=WallbangWorkspace.CurrentCamera

local GunItem, Utility
pcall(function()
    GunItem  = require(WallbangPlayerScripts.Modules.ItemTypes.Gun)
    Utility  = require(WallbangReplicatedStorage.Modules.Utility)
end)
local WallbangController

if not GunItem or not Utility then
    wallbangStatus:SetText('Status: Missing modules – disabled')
else
    wallbangStatus:SetText('Status: Modules loaded')

    local Character=setmetatable({},{__index=function(_,v)
        local ch=WallbangLocalPlayer.Character; if not ch then return nil end
        if v=='RootPart' then return ch:FindFirstChild('HumanoidRootPart')
        elseif v=='Head' then return ch:FindFirstChild('Head') end; return nil
    end})

    local DesyncController={}
    do
        function DesyncController:init() self.active=false; self.connection=nil; self.currentTarget=nil end
        function DesyncController:Start(target)
            self:Stop(); self.active=true
            self.connection=WallbangRunService.Heartbeat:Connect(function()
                if not self.active then return end
                local rootPart=Character.RootPart; if not rootPart then return end
                local targetRoot=target and target.Character and target.Character:FindFirstChild('HumanoidRootPart')
                if not targetRoot then self:Stop(); return end
                self.currentTarget=target
                local desyncCFrame=targetRoot.CFrame*CFrame.new(0,-5,0)
                local backupCFrame=rootPart.CFrame; local backupVelocity=rootPart.Velocity; local backupRotVelocity=rootPart.RotVelocity
                rootPart.CFrame=desyncCFrame
                WallbangRunService:BindToRenderStep('desync_fallback',101,function()
                    rootPart.CFrame=backupCFrame; rootPart.Velocity=backupVelocity; rootPart.RotVelocity=backupRotVelocity
                    WallbangRunService:UnbindFromRenderStep('desync_fallback')
                end)
            end)
        end
        function DesyncController:Stop() self.active=false; self.currentTarget=nil; if self.connection then self.connection:Disconnect(); self.connection=nil end end
        DesyncController:init()
    end

    local TargetController={}
    do
        function TargetController:init()
            self.active=true; self.target=nil
            self.connection=WallbangRunService.Heartbeat:Connect(function() if not self.active then return end; self.target=self:GetClosestTarget() end)
        end
        function TargetController:IsValidTarget(character)
            local rp=character:FindFirstChild('HumanoidRootPart'); local hd=character:FindFirstChild('Head')
            local hm=character:FindFirstChildWhichIsA('Humanoid'); return rp and hd and hm and hm.Health>0
        end
        function TargetController:IsValidTeam(p) return p:GetAttribute('TeamID')~=WallbangLocalPlayer:GetAttribute('TeamID') end
        function TargetController:GetClosestTarget()
            local closestTarget=nil; local maxDistance=math.huge; local mousePos=WallbangUserInputService:GetMouseLocation()
            for _,plr in next,WallbangPlayers:GetPlayers() do
                if plr==WallbangLocalPlayer then continue end
                if not self:IsValidTeam(plr) then continue end
                local ch=plr.Character; if not ch then continue end
                if not self:IsValidTarget(ch) then continue end
                local rp=ch.HumanoidRootPart; local screenPos,onScreen=WallbangCamera:WorldToViewportPoint(rp.Position)
                if not onScreen then continue end
                local rootPos=Vector2.new(screenPos.X,screenPos.Y); local targetDist=(mousePos-rootPos).magnitude
                if targetDist>maxDistance then continue end; maxDistance=targetDist; closestTarget=plr
            end; return closestTarget
        end
        function TargetController:Stop() self.active=false; if self.connection then self.connection:Disconnect(); self.connection=nil end end
        TargetController:init()
    end

    local function findShootRemote()
        for _,obj in ipairs(WallbangReplicatedStorage:GetDescendants()) do
            if obj:IsA('RemoteEvent') then
                local name=obj.Name:lower()
                if name:find('shoot') or name:find('fire') or name:find('attack') then return obj end
            end
        end; return nil
    end
    local ShootRemote=findShootRemote()
    if ShootRemote then Notify('Shoot remote: '..ShootRemote.Name)
    else Notify('No shoot remote — using mouse sim') end

    WallbangController={}
    do
        function WallbangController:init()
            self.active=false; self.startShootingRef=GunItem.StartShooting; self.desyncCleanup=nil
        end
        function WallbangController:Start()
            if self.active then return end; self.active=true
            GunItem.StartShooting=function(controller,...)
                local result={self.startShootingRef(controller,...)}
                local clientFighter=controller.ClientFighter; if not clientFighter.IsLocalPlayer then return unpack(result) end
                local cameraData=result[3]; if not cameraData or typeof(cameraData)~='table' then return unpack(result) end
                result[4]=true
                local targetPlayer=TargetController.target
                if not self.active or not targetPlayer or not targetPlayer.Character then return unpack(result) end
                if DesyncController.currentTarget~=targetPlayer then DesyncController:Start(targetPlayer); task.wait(0.1) end
                if self.desyncCleanup then task.cancel(self.desyncCleanup); self.desyncCleanup=nil end
                local targetHead=targetPlayer.Character.Head; local targetPos=targetHead.Position; local targetCFrame=targetHead.CFrame
                local shootingPos=targetPos-Vector3.new(0,5,0)
                local shootingOffset=targetCFrame:ToObjectSpace(CFrame.new(targetPos+Vector3.new(math.random(),math.random(),math.random())))
                cameraData[utf8.char(0)]=Utility:EncodeCFrame(CFrame.new(shootingPos,targetPos)*CFrame.Angles(CFrame.lookAt(shootingPos,targetPos):ToOrientation()))
                cameraData[utf8.char(1)]=Utility:EncodeCFrame(CFrame.new(targetPos)*CFrame.Angles(CFrame.lookAt(shootingPos,targetPos):ToOrientation()))
                cameraData[utf8.char(2)]=targetHead
                cameraData[utf8.char(3)]=Utility:EncodeCFrame(shootingOffset)
                self.desyncCleanup=task.delay(0.15,function() DesyncController:Stop() end)
                return unpack(result)
            end
            wallbangStatus:SetText('Status: Wallbang ACTIVE')
        end
        function WallbangController:Stop()
            self.active=false; GunItem.StartShooting=self.startShootingRef
            if self.desyncCleanup then task.cancel(self.desyncCleanup); self.desyncCleanup=nil end
            wallbangStatus:SetText('Status: Wallbang stopped')
        end
        WallbangController:init()
    end
end

local wallbangToggle=wallbangGroup:AddToggle('WallbangToggle', {
    Text='Wallbang', Default=false,
    Callback=function(v) if WallbangController then if v then WallbangController:Start() else WallbangController:Stop() end end end,
})

-- Auto Shoot (Rage)
local autoShootGroup   = rageTab:AddLeftGroupbox('Auto Shoot (Rage)')
local autoShootEnabled2, autoShootLoopConn2 = false, nil
local function startAutoShootLoop2()
    if autoShootLoopConn2 then return end
    autoShootLoopConn2=task.spawn(function()
        while autoShootEnabled2 do
            if WallbangController and WallbangController.active then
                local target=WallbangController.target or (TargetController and TargetController.target)
                if target and target.Character and target.Character:FindFirstChild('Head') then
                    if ShootRemote then pcall(function() ShootRemote:FireServer() end)
                    else setShooting(true) end
                else if not ShootRemote then setShooting(false) end end
            else if not ShootRemote then setShooting(false) end end
            task.wait(0.05)
        end; if not ShootRemote then setShooting(false) end
    end)
end
local function stopAutoShootLoop2()
    autoShootEnabled2=false
    if autoShootLoopConn2 then task.cancel(autoShootLoopConn2); autoShootLoopConn2=nil end
    if not ShootRemote then setShooting(false) end
end
autoShootGroup:AddToggle('AutoShootToggle', {
    Text='Auto Shoot', Default=false,
    Callback=function(v) if v then autoShootEnabled2=true; startAutoShootLoop2() else stopAutoShootLoop2() end end,
})

-- Delayed Auto Shoot
local delayedGroup   = rageTab:AddRightGroupbox('Delayed Auto Shoot')
local delayedEnabled, delayedDelay, delayedShooting = false, 0.8, false
delayedGroup:AddToggle('DelayedEnable', {
    Text='Enable Delayed Shoot', Default=false,
    Callback=function(v)
        delayedEnabled=v
        if v then setShooting(false); delayedShooting=false
        else setShooting(false) end
    end,
})
delayedGroup:AddSlider('DelayedDelay', {
    Text='Initial Delay', Min=0.1, Max=3, Default=0.8, Rounding=1, Suffix='s',
    Callback=function(v) delayedDelay=v end,
})
task.spawn(function()
    local lastCharacter=nil
    while task.wait(0.1) do
        if bc.Unloaded then break end; if not delayedEnabled then continue end
        local ch=player.Character
        if ch and ch~=lastCharacter then
            lastCharacter=ch; delayedShooting=false; setShooting(false)
            local start=tick()
            while tick()-start<delayedDelay do if not delayedEnabled or player.Character~=ch then break end; task.wait(0.1) end
            if not delayedEnabled or player.Character~=ch then continue end; delayedShooting=true
        elseif not ch then lastCharacter=nil; delayedShooting=false; setShooting(false) end
        if delayedShooting and ch then
            local rt=ch:FindFirstChild('HumanoidRootPart')
            if rt then
                local hasEnemy=false
                for _,p in ipairs(Players:GetPlayers()) do
                    if isEnemy(p) and p.Character then
                        local otherRoot=p.Character:FindFirstChild('HumanoidRootPart')
                        if otherRoot and (rt.Position-otherRoot.Position).Magnitude<15 then hasEnemy=true; break end
                    end
                end; setShooting(hasEnemy)
            else setShooting(false) end
        end
    end
end)

-- Auto Swap Weapon
local swapGroup  = rageTab:AddLeftGroupbox('Auto Swap Weapon')
local autoSwap   = false; local lastSwapTime=0
swapGroup:AddToggle('AutoSwapWeapon', { Text='Auto Swap Weapon', Default=false, Callback=function(v) autoSwap=v end })
task.spawn(function()
    while task.wait(0.2) do
        if bc.Unloaded then break end; if not autoSwap then continue end
        local ch=player.Character; if not ch then continue end
        local tool=ch:FindFirstChildOfClass('Tool'); if not tool then continue end
        local ammo=tool:GetAttribute('Ammo') or tool:GetAttribute('CurrentAmmo') or tool:GetAttribute('MagazineAmmo')
        if not ammo then
            local ammoObj=tool:FindFirstChild('Ammo') or tool:FindFirstChild('CurrentAmmo') or tool:FindFirstChild('MagazineAmmo')
            if ammoObj and (ammoObj:IsA('IntValue') or ammoObj:IsA('NumberValue')) then ammo=ammoObj.Value end
        end
        if ammo and ammo<=0 and (tick()-lastSwapTime)>0.5 then
            lastSwapTime=tick()
            VirtualInputManager:SendKeyEvent(true,Enum.KeyCode.Two,false,nil)
            task.wait(0.05)
            VirtualInputManager:SendKeyEvent(false,Enum.KeyCode.Two,false,nil)
        end
    end
end)

-- Simple Features
local simpleGroup = rageTab:AddLeftGroupbox('Simple Features')
local autoTPContinuousConn, noCooldownShootConn

function startAutoTPContinuous()
    if autoTPContinuousConn then return end
    autoTPContinuousConn=RunService.Heartbeat:Connect(function()
        local myHrp=root; if not myHrp then return end
        local closest=nil; local minDist=math.huge
        for _,p in ipairs(Players:GetPlayers()) do
            if isEnemy(p) and p.Character then
                local rt=p.Character:FindFirstChild('HumanoidRootPart')
                local hm=p.Character:FindFirstChild('Humanoid')
                if rt and hm and hm.Health>0 then
                    local dist=(myHrp.Position-rt.Position).Magnitude
                    if dist<minDist then minDist=dist; closest=rt end
                end
            end
        end
        if closest then myHrp.CFrame=CFrame.lookAt(closest.Position+Vector3.new(0,2,0),closest.Position) end
    end)
end
function stopAutoTPContinuous()
    if autoTPContinuousConn then autoTPContinuousConn:Disconnect(); autoTPContinuousConn=nil end
end

function startNoCooldownShoot()
    if noCooldownShootConn then return end
    noCooldownShootConn=RunService.Heartbeat:Connect(function()
        local tool=player.Character and player.Character:FindFirstChildOfClass('Tool')
        if tool then tool:Activate() end
    end)
end
function stopNoCooldownShoot()
    if noCooldownShootConn then noCooldownShootConn:Disconnect(); noCooldownShootConn=nil end
end

simpleGroup:AddToggle('AutoTPContinuous', {
    Text='Auto TP to Enemy (Continuous)', Default=false,
    Callback=function(v)
        if v then startAutoTPContinuous() else stopAutoTPContinuous() end
        Notify('Auto TP '..(v and 'enabled' or 'disabled'))
    end
})
simpleGroup:AddToggle('NoCooldownShoot', {
    Text='No Cooldown Shoot (AutoFire)', Default=false,
    Callback=function(v)
        if v then startNoCooldownShoot() else stopNoCooldownShoot() end
        Notify('No Cooldown '..(v and 'enabled' or 'disabled'))
    end
})

-- Auto Shoots Enemy
local autoShootEnemyGroup = rageTab:AddRightGroupbox('Auto Shoots Enemy')
local autoShootEnemyStatus = autoShootEnemyGroup:AddLabel('Status: Off')
local autoShootEnemyConn = nil

local function startAutoShootEnemy()
    if autoShootEnemyConn then return end
    autoShootEnemyConn = RunService.Heartbeat:Connect(function()
        pcall(function()
            local rs = cloneref(game:GetService("ReplicatedStorage"))
            local players = cloneref(game:GetService("Players"))
            local workspace = cloneref(game:GetService("Workspace"))
            local lplr = players.LocalPlayer
            local util = require(rs.Modules.Utility)
            local enums = require(rs.Modules.EnumLibrary)
            local fighter = require(lplr.PlayerScripts.Controllers.FighterController)

            if not lplr.Character or not lplr.Character:FindFirstChild("HumanoidRootPart") then return end
            local root = lplr.Character:FindFirstChild("HumanoidRootPart")
            if not fighter or not fighter.LocalFighter then return end
            local item = fighter.LocalFighter.EquippedItem
            if not item then return end

            local targetHead = nil
            local minDist = math.huge
            for _, v in ipairs(players:GetPlayers()) do
                if v ~= lplr and v.Character and v.Character:FindFirstChild("Head") then
                    local dist = (root.Position - v.Character.Head.Position).Magnitude
                    if dist < minDist then
                        minDist = dist
                        targetHead = v.Character.Head
                    end
                end
            end
            if not targetHead then return end

            local camPos = workspace.CurrentCamera and workspace.CurrentCamera.CFrame.Position or root.Position
            local aimCFrame = CFrame.lookAt(camPos, targetHead.Position)

            local cameradata = {}
            cameradata[utf8.char(1)] = {
                [utf8.char(0)] = util:EncodeCFrame(aimCFrame),
                [utf8.char(1)] = util:EncodeCFrame(CFrame.new(targetHead.Position) * CFrame.Angles(aimCFrame:ToOrientation())),
                [utf8.char(2)] = targetHead,
                [utf8.char(3)] = util:EncodeCFrame(targetHead.CFrame:ToObjectSpace(CFrame.new(targetHead.Position)))
            }

            rs.Remotes.Replication.Fighter.UseItem:FireServer(
                item:Get("ObjectID"),
                enums:ToEnum("StartShooting"),
                cameradata,
                nil
            )
        end)
    end)
    autoShootEnemyStatus:SetText('Status: On')
end

local function stopAutoShootEnemy()
    if autoShootEnemyConn then
        autoShootEnemyConn:Disconnect()
        autoShootEnemyConn = nil
    end
    autoShootEnemyStatus:SetText('Status: Off')
end

autoShootEnemyGroup:AddToggle('AutoShootEnemyToggle', {
    Text = 'Auto Shoots Enemy',
    Default = false,
    Callback = function(v)
        if v then
            startAutoShootEnemy()
        else
            stopAutoShootEnemy()
        end
    end
})

-- COSMETICS TAB
local cosmeticsTab = Tabs.Cosmetics

-- Cosmetic Changer
local newCosGroup = cosmeticsTab:AddLeftGroupbox('Cosmetic Options')
newCosGroup:AddLabel('Unified Cosmetic Changer (All types except finishers)')
local cosmeticChangerEnabled = false
newCosGroup:AddToggle('CosmeticChangerToggle', {
    Text = 'Enable Cosmetic Changer',
    Default = false,
    Callback = function(v)
        cosmeticChangerEnabled = v
        Notify('Cosmetic Changer ' .. (v and 'enabled' or 'disabled'))
    end
})
newCosGroup:AddButton('Reload Cosmetic Config', function()
    if _G.ReloadCosmeticConfig then _G.ReloadCosmeticConfig(); Notify('Cosmetic config reloaded!')
    else Notify('Cosmetic config not available') end
end)

-- Cosmetic changer implementation
task.spawn(function()
    pcall(function()
        local playerScripts = player.PlayerScripts
        local controllers = playerScripts.Controllers
        local EnumLibrary = require(ReplicatedStorage.Modules:WaitForChild("EnumLibrary", 10))
        if EnumLibrary then EnumLibrary:WaitForEnumBuilder() end
        local CosmeticLibrary = require(ReplicatedStorage.Modules:WaitForChild("CosmeticLibrary", 10))
        local ItemLibrary = require(ReplicatedStorage.Modules:WaitForChild("ItemLibrary", 10))
        local DataController = require(controllers:WaitForChild("PlayerDataController", 10))
        local equipped, favorites = {}, {}
        local constructingWeapon, viewingProfile = nil, nil
        local lastUsedWeapon = nil

        local function cloneCosmetic(name, cosmeticType, options)
            local base = CosmeticLibrary.Cosmetics[name]
            if not base then return nil end
            local data = {}
            for key, value in pairs(base) do data[key] = value end
            data.Name = name
            data.Type = data.Type or cosmeticType
            data.Seed = data.Seed or math.random(1, 1000000)
            if EnumLibrary then
                local success, enumId = pcall(EnumLibrary.ToEnum, EnumLibrary, name)
                if success and enumId then data.Enum, data.ObjectID = enumId, data.ObjectID or enumId end
            end
            if options then
                if options.inverted ~= nil then data.Inverted = options.inverted end
                if options.favoritesOnly ~= nil then data.OnlyUseFavorites = options.favoritesOnly end
            end
            return data
        end

        local saveFile = "unlockall/config.json"
        local function saveConfig()
            if not writefile then return end
            pcall(function()
                local config = {equipped = {}, favorites = favorites}
                for weapon, cosmetics in pairs(equipped) do
                    config.equipped[weapon] = {}
                    for cosmeticType, cosmeticData in pairs(cosmetics) do
                        if cosmeticData and cosmeticData.Name then
                            config.equipped[weapon][cosmeticType] = {
                                name = cosmeticData.Name, seed = cosmeticData.Seed, inverted = cosmeticData.Inverted
                            }
                        end
                    end
                end
                makefolder("unlockall")
                writefile(saveFile, HttpService:JSONEncode(config))
            end)
        end

        local function loadConfig()
            if not readfile or not isfile or not isfile(saveFile) then return end
            pcall(function()
                local config = HttpService:JSONDecode(readfile(saveFile))
                if config.equipped then
                    for weapon, cosmetics in pairs(config.equipped) do
                        equipped[weapon] = {}
                        for cosmeticType, cosmeticData in pairs(cosmetics) do
                            local cloned = cloneCosmetic(cosmeticData.name, cosmeticType, {inverted = cosmeticData.inverted})
                            if cloned then cloned.Seed = cosmeticData.seed equipped[weapon][cosmeticType] = cloned end
                        end
                    end
                end
                favorites = config.favorites or {}
            end)
        end

        _G.ReloadCosmeticConfig = loadConfig

        local function isNotFinisher(name)
            if not name then return false end
            local lower = name:lower()
            return not (lower:find("finisher") or lower:find("finish") or lower:find("execution"))
        end

        local originalOwnsCosmetic = CosmeticLibrary.OwnsCosmetic
        CosmeticLibrary.OwnsCosmetic = function(self, inventory, name, weapon)
            if not cosmeticChangerEnabled then return originalOwnsCosmetic(self, inventory, name, weapon) end
            if name:find("MISSING_") then return originalOwnsCosmetic(self, inventory, name, weapon) end
            local cosmetic = CosmeticLibrary.Cosmetics[name]
            if cosmetic and isNotFinisher(name) then return true end
            return originalOwnsCosmetic(self, inventory, name, weapon)
        end

        CosmeticLibrary.OwnsCosmeticNormally = function(self, inventory, name, weapon)
            if not cosmeticChangerEnabled then return false end
            local cosmetic = CosmeticLibrary.Cosmetics[name]
            if cosmetic and isNotFinisher(name) then return true end
            return false
        end

        CosmeticLibrary.OwnsCosmeticUniversally = function(self, inventory, name, weapon)
            if not cosmeticChangerEnabled then return false end
            local cosmetic = CosmeticLibrary.Cosmetics[name]
            if cosmetic and isNotFinisher(name) then return true end
            return false
        end

        CosmeticLibrary.OwnsCosmeticForWeapon = function(self, inventory, name, weapon)
            if not cosmeticChangerEnabled then return false end
            local cosmetic = CosmeticLibrary.Cosmetics[name]
            if cosmetic and isNotFinisher(name) then return true end
            return false
        end

        local originalGet = DataController.Get
        DataController.Get = function(self, key)
            if not cosmeticChangerEnabled then return originalGet(self, key) end
            local data = originalGet(self, key)
            if key == "CosmeticInventory" then
                local proxy = {}
                if data then
                    for k, v in pairs(data) do
                        local cosmetic = CosmeticLibrary.Cosmetics[k]
                        if cosmetic and isNotFinisher(k) then proxy[k] = v end
                    end
                end
                return setmetatable(proxy, {
                    __index = function(t, k)
                        local cosmetic = CosmeticLibrary.Cosmetics[k]
                        if cosmetic and isNotFinisher(k) then return true end
                        return nil
                    end
                })
            end
            if key == "FavoritedCosmetics" then
                local result = data and table.clone(data) or {}
                for weapon, favs in pairs(favorites) do
                    result[weapon] = result[weapon] or {}
                    for name, isFav in pairs(favs) do
                        if isNotFinisher(name) then result[weapon][name] = isFav end
                    end
                end
                return result
            end
            return data
        end

        local originalGetWeaponData = DataController.GetWeaponData
        DataController.GetWeaponData = function(self, weaponName)
            if not cosmeticChangerEnabled then return originalGetWeaponData(self, weaponName) end
            local data = originalGetWeaponData(self, weaponName)
            if not data then return nil end
            local merged = {}
            for key, value in pairs(data) do merged[key] = value end
            merged.Name = weaponName
            if equipped[weaponName] then
                for cosmeticType, cosmeticData in pairs(equipped[weaponName]) do
                    merged[cosmeticType] = cosmeticData
                end
            end
            return merged
        end

        local FighterController
        pcall(function() FighterController = require(controllers:WaitForChild("FighterController", 10)) end)

        if hookmetamethod then
            local remotes = ReplicatedStorage:FindFirstChild("Remotes")
            local dataRemotes = remotes and remotes:FindFirstChild("Data")
            local equipRemote = dataRemotes and dataRemotes:FindFirstChild("EquipCosmetic")
            local favoriteRemote = dataRemotes and dataRemotes:FindFirstChild("FavoriteCosmetic")
            local replicationRemotes = remotes and remotes:FindFirstChild("Replication")
            local fighterRemotes = replicationRemotes and replicationRemotes:FindFirstChild("Fighter")
            local useItemRemote = fighterRemotes and fighterRemotes:FindFirstChild("UseItem")

            if equipRemote then
                local oldNamecall
                oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
                    if getnamecallmethod() ~= "FireServer" then return oldNamecall(self, ...) end
                    local args = {...}
                    if useItemRemote and self == useItemRemote then
                        local objectID = args[1]
                        if FighterController and cosmeticChangerEnabled then
                            pcall(function()
                                local fighter = FighterController:GetFighter(player)
                                if fighter and fighter.Items then
                                    for _, item in pairs(fighter.Items) do
                                        if item:Get("ObjectID") == objectID then lastUsedWeapon = item.Name break end
                                    end
                                end
                            end)
                        end
                    end
                    if self == equipRemote and cosmeticChangerEnabled then
                        local weaponName, cosmeticType, cosmeticName, options = args[1], args[2], args[3], args[4] or {}
                        if cosmeticType and isNotFinisher(cosmeticType) and isNotFinisher(cosmeticName) then
                            if cosmeticName and cosmeticName ~= "None" and cosmeticName ~= "" then
                                local inventory = DataController:Get("CosmeticInventory")
                                if inventory and rawget(inventory, cosmeticName) then
                                    return oldNamecall(self, ...)
                                end
                            end
                            equipped[weaponName] = equipped[weaponName] or {}
                            if not cosmeticName or cosmeticName == "None" or cosmeticName == "" then
                                equipped[weaponName][cosmeticType] = nil
                                if not next(equipped[weaponName]) then equipped[weaponName] = nil end
                            else
                                local cloned = cloneCosmetic(cosmeticName, cosmeticType, {
                                    inverted = options.IsInverted,
                                    favoritesOnly = options.OnlyUseFavorites
                                })
                                if cloned then equipped[weaponName][cosmeticType] = cloned end
                            end
                            task.defer(function()
                                pcall(function() DataController.CurrentData:Replicate("WeaponInventory") end)
                                task.wait(0.2)
                                saveConfig()
                            end)
                            return
                        end
                    end
                    if self == favoriteRemote and cosmeticChangerEnabled then
                        local cosmetic = CosmeticLibrary.Cosmetics[args[2]]
                        if cosmetic and isNotFinisher(args[2]) then
                            favorites[args[1]] = favorites[args[1]] or {}
                            favorites[args[1]][args[2]] = args[3] or nil
                            saveConfig()
                            task.spawn(function() pcall(function() DataController.CurrentData:Replicate("FavoritedCosmetics") end) end)
                        end
                        return
                    end
                    return oldNamecall(self, ...)
                end)
            end
        end

        local ClientItem
        pcall(function() ClientItem = require(player.PlayerScripts.Modules.ClientReplicatedClasses.ClientFighter.ClientItem) end)

        if ClientItem and ClientItem._CreateViewModel then
            local originalCreateViewModel = ClientItem._CreateViewModel
            ClientItem._CreateViewModel = function(self, viewmodelRef)
                if not cosmeticChangerEnabled then return originalCreateViewModel(self, viewmodelRef) end
                local weaponName = self.Name
                local weaponPlayer = self.ClientFighter and self.ClientFighter.Player
                constructingWeapon = (weaponPlayer == player) and weaponName or nil
                if weaponPlayer == player and equipped[weaponName] and viewmodelRef then
                    local dataKey, skinKey, charmKey, wrapKey, nameKey = self:ToEnum("Data"), self:ToEnum("Skin"), self:ToEnum("Charm"), self:ToEnum("Wrap"), self:ToEnum("Name")
                    local cosmetics = equipped[weaponName]
                    if viewmodelRef[dataKey] then
                        if cosmetics.Skin then viewmodelRef[dataKey][skinKey] = cosmetics.Skin end
                        if cosmetics.Charm then viewmodelRef[dataKey][charmKey] = cosmetics.Charm end
                        if cosmetics.Wrap then viewmodelRef[dataKey][wrapKey] = cosmetics.Wrap end
                        if cosmetics.Skin then viewmodelRef[dataKey][nameKey] = cosmetics.Skin.Name end
                    elseif viewmodelRef.Data then
                        if cosmetics.Skin then viewmodelRef.Data.Skin = cosmetics.Skin end
                        if cosmetics.Charm then viewmodelRef.Data.Charm = cosmetics.Charm end
                        if cosmetics.Wrap then viewmodelRef.Data.Wrap = cosmetics.Wrap end
                        if cosmetics.Skin then viewmodelRef.Data.Name = cosmetics.Skin.Name end
                    end
                end
                local result = originalCreateViewModel(self, viewmodelRef)
                constructingWeapon = nil
                return result
            end
        end

        local viewModelModule = player.PlayerScripts.Modules.ClientReplicatedClasses.ClientFighter.ClientItem:FindFirstChild("ClientViewModel")
        if viewModelModule then
            local ClientViewModel = require(viewModelModule)
            local originalNew = ClientViewModel.new
            ClientViewModel.new = function(replicatedData, clientItem)
                if not cosmeticChangerEnabled then return originalNew(replicatedData, clientItem) end
                local weaponPlayer = clientItem.ClientFighter and clientItem.ClientFighter.Player
                local weaponName = constructingWeapon or clientItem.Name
                if weaponPlayer == player and equipped[weaponName] then
                    local ReplicatedClass = require(ReplicatedStorage.Modules.ReplicatedClass)
                    local dataKey = ReplicatedClass:ToEnum("Data")
                    replicatedData[dataKey] = replicatedData[dataKey] or {}
                    local cosmetics = equipped[weaponName]
                    if cosmetics.Skin then replicatedData[dataKey][ReplicatedClass:ToEnum("Skin")] = cosmetics.Skin end
                    if cosmetics.Charm then replicatedData[dataKey][ReplicatedClass:ToEnum("Charm")] = cosmetics.Charm end
                    if cosmetics.Wrap then replicatedData[dataKey][ReplicatedClass:ToEnum("Wrap")] = cosmetics.Wrap end
                end
                local result = originalNew(replicatedData, clientItem)
                if weaponPlayer == player and equipped[weaponName] and equipped[weaponName].Wrap and result._UpdateWrap then
                    result:_UpdateWrap()
                    task.delay(0.1, function() if not result._destroyed then result:_UpdateWrap() end end)
                end
                return result
            end
        end

        if viewModelModule then
            local ClientViewModel = require(viewModelModule)
            if ClientViewModel.GetCharm then
                local originalGetCharmFunc = ClientViewModel.GetCharm
                ClientViewModel.GetCharm = function(self)
                    if not cosmeticChangerEnabled then return originalGetCharmFunc(self) end
                    local weaponName = self.ClientItem and self.ClientItem.Name
                    local weaponPlayer = self.ClientItem and self.ClientItem.ClientFighter and self.ClientItem.ClientFighter.Player
                    if weaponName and weaponPlayer == player and equipped[weaponName] and equipped[weaponName].Charm then
                        return equipped[weaponName].Charm
                    end
                    return originalGetCharmFunc(self)
                end
            end
            if ClientViewModel.GetWrap then
                local originalGetWrapFunc = ClientViewModel.GetWrap
                ClientViewModel.GetWrap = function(self)
                    if not cosmeticChangerEnabled then return originalGetWrapFunc(self) end
                    local weaponName = self.ClientItem and self.ClientItem.Name
                    local weaponPlayer = self.ClientItem and self.ClientItem.ClientFighter and self.ClientItem.ClientFighter.Player
                    if weaponName and weaponPlayer == player and equipped[weaponName] and equipped[weaponName].Wrap then
                        return equipped[weaponName].Wrap
                    end
                    return originalGetWrapFunc(self)
                end
            end
        end

        local originalGetViewModelImage = ItemLibrary.GetViewModelImageFromWeaponData
        ItemLibrary.GetViewModelImageFromWeaponData = function(self, weaponData, highRes)
            if not cosmeticChangerEnabled then return originalGetViewModelImage(self, weaponData, highRes) end
            if not weaponData then return originalGetViewModelImage(self, weaponData, highRes) end
            local weaponName = weaponData.Name
            if equipped[weaponName] and equipped[weaponName].Skin then
                local skinInfo = self.ViewModels[equipped[weaponName].Skin.Name]
                if skinInfo then return skinInfo[highRes and "ImageHighResolution" or "Image"] or skinInfo.Image end
            end
            return originalGetViewModelImage(self, weaponData, highRes)
        end

        local EmoteController
        pcall(function()
            EmoteController = require(controllers:WaitForChild("EmoteController", 10))
            if EmoteController and EmoteController.GetEmotes then
                local originalGetEmotes = EmoteController.GetEmotes
                EmoteController.GetEmotes = function(self)
                    if not cosmeticChangerEnabled then return originalGetEmotes(self) end
                    local emotes = originalGetEmotes(self)
                    for name, cosmetic in pairs(CosmeticLibrary.Cosmetics) do
                        if cosmetic and isNotFinisher(name) and (cosmetic.Type == "Dance" or cosmetic.Type == "Emote" or name:lower():find("dance") or name:lower():find("emote")) then
                            if not emotes[name] then
                                emotes[name] = {
                                    Name = name,
                                    Type = cosmetic.Type,
                                    ObjectID = cosmetic.ObjectID,
                                    Enum = cosmetic.Enum
                                }
                            end
                        end
                    end
                    return emotes
                end
            end
        end)

        pcall(function()
            local ViewProfile = require(player.PlayerScripts.Modules.Pages.ViewProfile)
            if ViewProfile and ViewProfile.Fetch then
                local originalFetch = ViewProfile.Fetch
                ViewProfile.Fetch = function(self, targetPlayer)
                    if not cosmeticChangerEnabled then return originalFetch(self, targetPlayer) end
                    viewingProfile = targetPlayer
                    return originalFetch(self, targetPlayer)
                end
            end
        end)

        loadConfig()
    end)
end)

-- Device Spoof
local deviceGroup = cosmeticsTab:AddRightGroupbox('Device Spoof')
local function spoofDevice(device)
    game:GetService('ReplicatedStorage'):WaitForChild('Remotes'):WaitForChild('Replication'):WaitForChild('Fighter'):WaitForChild('SetControls'):FireServer(device)
end
deviceGroup:AddButton('Set PC Controls',     function() spoofDevice('MouseKeyboard'); Notify('Controls → PC') end)
deviceGroup:AddButton('Set Mobile Controls', function() spoofDevice('Touch');         Notify('Controls → Mobile') end)
deviceGroup:AddButton('Set VR Controls',     function() spoofDevice('VR');            Notify('Controls → VR') end)

-- Stretch Resolution
local stretchGroup = cosmeticsTab:AddRightGroupbox('Stretch Resolution')
stretchGroup:AddSlider('StretchAmount', {
    Text='Stretch Amount', Min=0.1, Max=1, Default=1, Rounding=2, Suffix='x',
    Callback=function(v) _G.stretchAmount=v end,
})
_G.stretchAmount=1
RunService.RenderStepped:Connect(function()
    if _G.stretchAmount~=1 then
        workspace.CurrentCamera.CFrame=workspace.CurrentCamera.CFrame*CFrame.new(0,0,0,1,0,0,0,_G.stretchAmount,0,0,0,1)
    end
end)

-- CHARACTER HANDLERS
local function bindChar(c)
    char=c; root=c:WaitForChild('HumanoidRootPart',5); hum=c:WaitForChild('Humanoid',5)
end
if LocalPlayer.Character then bindChar(LocalPlayer.Character) end

LocalPlayer.CharacterAdded:Connect(function(c)
    bindChar(c)
    task.wait(0.3)
    if autoTPContinuousToggle and autoTPContinuousToggle.Value then startAutoTPContinuous() end
    if noCooldownShootToggle and noCooldownShootToggle.Value then startNoCooldownShoot() end
    if wallbangToggle and wallbangToggle.Value and WallbangController then WallbangController:Start() end
    if autoShootEnabled2 then startAutoShootLoop2() end
    if autoShootEnemyConn then stopAutoShootEnemy(); startAutoShootEnemy() end
end)

LocalPlayer.CharacterRemoving:Connect(function()
    killConn('void'); killConn('orbit'); killConn('antiAim')
    stopNoCooldownShoot()
    stopAutoTPContinuous()
    if WallbangController then WallbangController:Stop() end
    stopAutoShootLoop2()
    stopAutoShootEnemy()
    root=nil; hum=nil; char=nil
end)

Notify('loaded')

return function() bc:Unload() end
