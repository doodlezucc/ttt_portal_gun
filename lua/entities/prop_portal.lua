AddCSLuaFile()
DEFINE_BASECLASS('base_anim')
ENT.Author = 'Wheatley'
ENT.Spawnable = false
ENT.AdminOnly = false
ENT.Editable = false
ENT.Enabled = false
ENT.PortalType = false
ENT.Portal = NULL

function ENT:UpdateTransmitState()
    return TRANSMIT_ALWAYS
end

function ENT:Draw()
end

function ENT:Use()
end

function ENT:Initialize()
    if CLIENT then return end
    self:SetMoveType(MOVETYPE_NONE)
    self:SetSolid(SOLID_NONE)
end

function ENT:SpawnFunction()
end

function ENT:RemoveSelectedPortal(type)
    local owner = player.GetAll()[1]

    for i, v in pairs(ents.GetAll()) do
        if IsValid(v) and type == true and owner:GetNWEntity('PORTALGUN_PORTALS_RED') == v then
            SafeRemoveEntity(v)
        elseif IsValid(v) and type == false and owner:GetNWEntity('PORTALGUN_PORTALS_BLUE') == v then
            SafeRemoveEntity(v)
        end
    end
end

function ENT:CreatePortal()
    if not self.Enabled then return end
    self:RemoveSelectedPortal(self.PortalType)
    local ent

    if (self.PortalType) then
        ent = ents.Create('portalgun_portal_red')
    else
        ent = ents.Create('portalgun_portal_blue')
    end

    ent:SetPos(self:GetPos())
    ent:SetAngles(self:GetAngles() - Angle(180, 0, 0))
    ent.RealOwner = player.GetAll()[1]
    ent.ParentEntity = NULL
    ent:Spawn()
    ent:Activate()

    ent.AllowedEntities = {'player',}

    if (self.PortalType) then
        player.GetAll()[1]:SetNWEntity('PORTALGUN_PORTALS_RED', ent)
    else
        player.GetAll()[1]:SetNWEntity('PORTALGUN_PORTALS_BLUE', ent)
    end

    self.Portal = ent
end

function ENT:Fizzle()
    if (self.PortalType) then
        player.GetAll()[1]:SetNWEntity('PORTALGUN_PORTALS_RED', NULL)
    else
        player.GetAll()[1]:SetNWEntity('PORTALGUN_PORTALS_BLUE', NULL)
    end

    if IsValid(self.Portal) then
        self.Portal:Remove()
        self.Portal = NULL
    end
end

function ENT:KeyValue(k, v)
    if k == 'Activated' then
        self.Enabled = tonumber(v) == 0
    end

    if k == 'PortalTwo' then
        if v == '0' then
            self.PortalType = false
        elseif v == '1' then
            self.PortalType = true
        end
    end
end

function ENT:AcceptInput(input, activator, called, data)
    if input == 'SetActivatedState' then
        self.Enabled = true
        self:CreatePortal()
    end

    if input == 'Fizzle' then
        self:Fizzle()
        self.Enabled = false
    end

    if input == 'Toggle' then
        self.Enabled = not self.Enabled
        self:CreatePortal()
    end
end