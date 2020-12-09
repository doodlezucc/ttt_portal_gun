-- ------------------------------------------------------------------------
-- WEAPON PORTALGUN FOR GARRY'S MOD 13 --
-- WRITEN BY WHEATLEY - http://steamcommunity.com/id/wheatley_wl/
-- ------------------------------------------------------------------------
AddCSLuaFile()
DEFINE_BASECLASS('base_anim')
ENT.PrintName = 'PORTALGUN_PORTAL_BLUE'
ENT.Author = 'WHEATLEY'
ENT.Editable = false
ENT.Spawnable = false
ENT.AdminOnly = false
ENT.RealOwner = NULL
ENT.ParentEntity = NULL
ENT.next = 0
ENT.NextTeleportCool = 0.4
ENT.PlacedOnGroud = false
ENT.PlacedOnCeiling = false
ENT.Ambient = nil
ENT.RenderLocalPlayer = false
ENT.AllowedEntities = {}
ENT.RescaleTime = 0

--[[---------------------------------------------------------
   Name: Initialize
-----------------------------------------------------------]]
function ENT:Initialize()
    if SERVER then
        self:SetModel('models/XQM/panel360.mdl')

        hook.Add('Think', 'PortalSystem_ThinkingOnBlue_' .. self:EntIndex(), function()
            self:Thinking()
        end)
    end

    if CLIENT then
        print(self:EntIndex())
        self.rt_blue = GetRenderTarget('__rtPortalBlue_' .. self:EntIndex(), 512, 1024, true)
        self.rt_red = GetRenderTarget('__rtPortalRed_' .. self:EntIndex(), 512, 1024, true)
        print('w', self.rt_blue:GetMappingWidth())
        print('h', self.rt_blue:GetMappingHeight())

        local blue = {
            ['$basetexture'] = '__rtPortalBlue_' .. self:EntIndex()
        }

        blue['$model'] = 1

        local red = {
            ['$basetexture'] = '__rtPortalRed_' .. self:EntIndex()
        }

        red['$model'] = 1
        self.blue = CreateMaterial('__portalBlueRT' .. self:EntIndex(), 'UnlitGeneric', blue)
        self.red = CreateMaterial('__portalRedRT' .. self:EntIndex(), 'UnlitGeneric', red)
    end

    self.RescaleTime = 1
    self:EmitSound('weapons/portalgun/portal_open_blue_01.wav')
    self:DrawShadow(false)

    if self:GetNWBool('PORTALTYPE') then
        self:SetMaterial('__portalRedRT' .. self:EntIndex())
    else
        self:SetMaterial('__portalBlueRT' .. self:EntIndex())
    end

    self:SetPos(self:GetPos() - self:GetAngles():Forward() * 0.03)

    if CLIENT then
        self.ring = ClientsideModel('models/portals/portal1.mdl', RENDER_GROUP_VIEW_MODEL_OPAQUE)
        self.ring:SetPos(self:GetPos() - self:GetAngles():Forward() * 0.02)
        self.ring:SetAngles(self:GetAngles() - Angle(180, 0, 0))
        self.ring:SetParent(self)
        self.ring:SetNoDraw(true)
        self.ring:SetMaterial(Material('models/shiny'))
    end

    if self.Ambient then
        self.Ambient:Play()
        self.Ambient:ChangeVolume(0.5, 0)
    end
end

function ENT:OnRemove()
    if SERVER then
        if IsValid(self.ParentEntity) then
            self.ParentEntity:SetSkin(0)
        end

        hook.Remove('Think', 'PortalSystem_ThinkingOnBlue_' .. self:EntIndex())
    end

    if self.Ambient then
        self.Ambient:Stop()
        self.Ambient = nil
    end

    self:EmitSound('weapons/portalgun/portal_fizzle_0' .. math.random(1, 2) .. '.wav')
end

function ENT:GetLinkedPortal()
    local type = self:GetNWBool('PORTALTYPE')
    local e

    if type then
        e = self:GetNWEntity('portalowner'):GetNWEntity('PORTALGUN_PORTALS_BLUE')
    else
        e = self:GetNWEntity('portalowner'):GetNWEntity('PORTALGUN_PORTALS_RED')
    end
    -- local tp = type and 'PORTALGUN_PORTALS_BLUE' or 'PORTALGUN_PORTALS_RED'

    return e
end

function ENT:Draw()
    local type = self:GetNWBool('PORTALTYPE')
    render.SuppressEngineLighting(true)
    -- resize portal
    self.RescaleTime = self.RescaleTime - 0.1
    local pre = 1 - math.Clamp(self.RescaleTime, 0, 1)
    local matrix = Matrix()
    matrix:Scale(Vector(0.2, 1.1, 1.85) * pre)
    self:EnableMatrix('RenderMultiply', matrix)

    if type then
        render.MaterialOverride(self.red)
    else
        render.MaterialOverride(self.blue)
    end

    self:DrawModel()
    local fmatrix = Matrix()
    fmatrix:Scale(Vector(0.5, 0.93, 0.9) * pre)

    if type then
        render.MaterialOverride(Material('models/fakeportal_ring_red'))
    else
        render.MaterialOverride(Material('models/fakeportal_ring_blue'))
    end

    if IsValid(self.ring) then
        self.ring:EnableMatrix('RenderMultiply', fmatrix)
        self.ring:DrawModel()
    end

    render.MaterialOverride(Material(''))
    render.SuppressEngineLighting(false)
end

if CLIENT then
    function ENT:RenderWaves()
        local rt = (self:GetNWBool('PORTALTYPE')) and self.rt_red or self.rt_blue
        local view = render.GetRenderTarget() -- old render target
        render.SetRenderTarget(rt)
        -- clear render buff
        render.Clear(0, 0, 0, 255)
        render.ClearDepth()
        render.ClearStencil()
        render.SetRenderTarget(view) -- restore player's view
    end

    function ENT:SimulatePortal(epos, eang)
        local rt = self:GetNWBool('PORTALTYPE') and self.rt_red or self.rt_blue
        local other = self:GetLinkedPortal()

        if not IsValid(other) then
            self:RenderWaves()

            return
        end

        local view = render.GetRenderTarget() -- old render target
        render.SetRenderTarget(rt)
        -- clear render buff
        render.Clear(0, 0, 0, 0)
        render.ClearDepth()
        render.ClearStencil()
        -- opposite portal pos/ang
        --local pos = self:TransformPosition(epos) + Vector(0, 0, 60)
        local pos = other:GetPos()
        --local dist = math.abs(self:WorldToLocal(epos).x)
        --local dist = pos:Distance(other:GetPos())
        --print(self:GetNWBool('PORTALTYPE'), dist)
        --local ang = other:GetAngles() - self:GetAngles() + Angle(180, 0, 0)
        --ang = other:LocalToWorldAngles(ang)
        local ang = self:WorldToLocalAngles(eang)
        ang = ang - Angle(0, 180, 0)
        ang = other:LocalToWorldAngles(ang)

        --print(self:GetNWBool('PORTALTYPE'), ang)
        -- dist=313: fov=10
        -- dist=625: fov=5
        -- render view data
        local vmd = {
            x = 0,
            y = 0,
            w = 512,
            h = 1024,
            origin = pos,
            angles = ang,
            drawhud = false,
            drawviewmodel = false,
        }

        --fov = (625 / dist) * 5
        -- portal clip plane
        PORTALRENDERING = true
        render.RenderView(vmd)
        render.UpdateScreenEffectTexture()
        PORTALRENDERING = false
        render.SetRenderTarget(view) -- restore player's view
    end

    function ENT:DebugPlayerPos()
        --if self:GetNWBool('PORTALTYPE') then return end
        render.DrawLine(self:GetPos(), self:GetPos() - self:GetAngles():Forward() * 50)
        local color = Color(240, 190, 80)

        if self:GetNWBool('PORTALTYPE') then
            color = Color(80, 120, 230)
        end

        local transformed = self:TransformPosition(LocalPlayer():EyePos())
        render.DrawWireframeSphere(transformed, 10, 18, 18, color, true)
        render.DrawLine(self:GetPos(), transformed, color, true)
    end
end

function ENT:TransformPosition(pos)
    local other = self:GetLinkedPortal()
    if not IsValid(other) then return pos end
    local diff = self:WorldToLocal(pos)
    diff = diff * Vector(-1, -1, 1)
    local transformed = other:LocalToWorld(diff)

    return transformed
end

function ENT:CreateIllusuion(pos, ang, mdl)
    local copy = ents.Create('prop_physics')
    copy:SetPos(pos)
    copy:SetAngles(ang)
    copy:SetModel(mdl)
    copy:Spawn()
    copy:Activate()
    copy:SetNWBool('DISABLE_PORTABLE', true)
    local phys = copy:GetPhysicsObject()

    if IsValid(phys) then
        phys:SetVelocity(self:GetForward() * 200)
        phys:EnableDrag(false)
        phys:EnableGravity(false)
        phys:EnableCollisions(false)
    end

    timer.Simple(0.2, function()
        copy:Remove()
    end)
end

function ENT:TeleportIfValid(v)
    local portal = self:GetLinkedPortal()

    if IsValid(portal) then
        if not v:IsPlayer() then
            local entsize = (v:OBBMaxs() - v:OBBMins()):Length() / 2
            local portalsize = (self:OBBMaxs() - self:OBBMins()):Length()
            if entsize > portalsize then return false end
        end

        if v:GetClass() == 'prop_physics' then
            self:CreateIllusuion(v:GetPos(), v:GetAngles(), v:GetModel())
        end

        portal:SetNext(CurTime() + self.NextTeleportCool * 1.2)
        --self:SetNext(CurTime() + self.NextTeleportCool)
        self:TeleportEntityToPortal(v, portal)

        return true
    end

    return false
end

function ENT:Thinking()
    if IsValid(self.RealOwner) and not self.RealOwner:Alive() then
        self:Remove()
    end

    if self.next < CurTime() then
        local right = self:GetAngles():Right()
        local up = self:GetAngles():Up()
        local forward = -self:GetAngles():Forward()

        -- Finds entities RIGHT IN FRONT of portal and teleports them
        for i, v in pairs(ents.FindInBox(self:GetPos() + (right * 10 + up * 35 + forward * 10), self:GetPos() - (right * 10 + up * 35))) do
            if v ~= self and v ~= self.ParentEntity and table.HasValue(self.AllowedEntities, v:GetClass()) and v:GetNWBool('DISABLE_PORTABLE') == false then
                local tpValid = self:TeleportIfValid(v)

                if tpValid then
                    print('teleported this bad boi')

                    return
                end
            end
        end

        for i, v in pairs(ents.FindInBox(self:GetPos() + (right * 10 + up * 35 + forward * 35), self:GetPos() - (right * 10 + up * 35))) do
            if v ~= self and v ~= self.ParentEntity and table.HasValue(self.AllowedEntities, v:GetClass()) and v:GetNWBool('DISABLE_PORTABLE') == false and v:GetVelocity():Length() > 250 then
                local tpValid = self:TeleportIfValid(v)

                if tpValid then
                    print('teleported this bad boi at high speed')

                    return
                end
            end
        end
    end
end

function ENT:TeleportEntityToPortal(ent, portal)
    if CLIENT then return end
    self:EmitSound('weapons/portalgun/portal_enter_0' .. math.random(1, 3) .. '.wav')
    ent:EmitSound('weapons/portalgun/portal_exit_0' .. math.random(1, 2) .. '.wav')

    if (not ent:IsPlayer()) then
        if IsValid(ent) and ent ~= portal.ParentEntity then
            local vel = ent:GetVelocity():Length()

            if vel <= 210 then
                vel = 210
            end

            local entsize = (ent:OBBMaxs() - ent:OBBMins()):Length() / 2
            ent:SetPos(portal:GetPos() + (portal:GetForward() * entsize))
            local phys = ent:GetPhysicsObject()

            if IsValid(phys) then
                phys:EnableCollisions(false)

                timer.Simple(0.2, function()
                    if IsValid(phys) and IsValid(ent) then
                        phys:EnableCollisions(true)
                        ent.InPortal = false
                    end
                end)
            end

            if IsValid(ent:GetPhysicsObject()) then
                ent:GetPhysicsObject():SetVelocity(-portal:GetForward() * (vel * 1.5))
            end

            if ent:GetClass() == 'portal_energy_pelet' then
                ent:SetLifeTime(CurTime() + 5)
            end

            local ang = ent:GetAngles()
            ang = self:WorldToLocalAngles(ang)
            ang:RotateAroundAxis(Vector(0, 0, 1), 180)
            ang = portal:LocalToWorldAngles(ang)
            ent:SetAngles(ang)
        end
    else
        local vel = ent:GetVelocity():Length()

        -- Gives the player a minimum amount of velocity after teleport
        --[[if vel <= 5 then
            vel = 50
        end]]
        timer.Simple(0, function()
            --[[ changes player fov back to normal in 1 second
            local fov = ent:GetFOV()
            ent:SetFOV(64, 0)
            ent:SetFOV(fov, 1)
            ]]
            if false and vel > 250 then
                ent:SetPos(portal:GetPos() + (-portal:GetForward() * 45) - Vector(0, 0, 25))
            else
                if portal.PlacedOnGroud then
                    ent:SetPos(portal:GetPos() + (-portal:GetForward() * 32) + Vector(0, 0, 5))
                elseif portal.PlacedOnCeiling then
                    ent:SetPos(portal:GetPos() - Vector(0, 0, 80))
                else
                    local tr = util.TraceLine({
                        start = portal:GetPos(),
                        endpos = portal:GetPos() + (-portal:GetForward() * 30),
                        filter = portal
                    })

                    local tr_down = util.TraceLine({
                        start = portal:GetPos() + (-portal:GetForward() * (30 * tr.Fraction)),
                        endpos = portal:GetPos() + (-portal:GetForward() * (30 * tr.Fraction)) - Vector(0, 0, 60),
                        filter = portal
                    })

                    ent:SetPos(tr_down.HitPos)
                end
            end

            local ang = ent:GetAngles()
            ang = self:WorldToLocalAngles(ang)
            ang:RotateAroundAxis(Vector(0, 0, 1), 180)
            ang = portal:LocalToWorldAngles(ang)

            if self.PlacedOnGroud or self.PlacedOnCeiling then
                --print('watdefok')
                --ent:SetEyeAngles((-portal:GetForward()):Angle())
            else
                ent:SetEyeAngles(Angle(0, ang.y, 0))
            end

            ent:SetVelocity(-portal:GetForward() * (vel * 1.8) + (Vector(0, 0, 10) * 6))
        end)
        --ent:SetVelocity(-portal:GetForward() * vel)
        --weirdly transforms
    end
end

function ENT:SetNext(next)
    print('set next on', self:GetNWBool('PORTALTYPE'))
    self.next = next
end