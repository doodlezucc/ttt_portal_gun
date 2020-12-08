ENT.Base = 'base_brush'
ENT.Type = 'brush'

function ENT:Initialize()
    self:SetCollisionGroup(COLLISION_GROUP_DEBRIS_TRIGGER)
end

function ENT:Fizzle(ent)
    if ent:IsPlayer() and self:HasPortals(ent) then
        ent:EmitSound('weapons/portalgun/portal_fizzle_0' .. math.random(1, 2) .. '.wav')

        if ent:GetActiveWeapon() and ent:GetActiveWeapon():GetClass() == 'weapon_portalgun' then
            ent:GetActiveWeapon():PlayFizzleAnimation()
        end
    end

    if ent:IsPlayer() then
        self:FizzlePortals(ent)
    elseif IsValid(ent) then
        self:FizzleProp(ent)
    end
end

function ENT:FizzlePortals(ply)
    for i, v in pairs(ents.GetAll()) do
        if IsValid(v) and ply:GetNWEntity('PORTALGUN_PORTALS_RED') == v then
            SafeRemoveEntity(v)
        elseif IsValid(v) and ply:GetNWEntity('PORTALGUN_PORTALS_BLUE') == v then
            SafeRemoveEntity(v)
        end
    end
end

function ENT:FizzleProp(ent)
    if ent:GetNWBool('P2_FIZZLED') then return end
    local pobj = ent:GetPhysicsObject()
    pobj:EnableDrag(false)
    pobj:EnableGravity(false)
    local val = 0

    timer.Create('fizzle_object__' .. ent:EntIndex(), 0.01, 100, function()
        val = val + 1

        if IsValid(pobj) then
            pobj:SetVelocity(VectorRand() * 50)
        end

        local effectdata = EffectData()
        effectdata:SetStart(ent:GetPos())
        effectdata:SetOrigin(ent:GetPos())
        effectdata:SetScale(4)
        effectdata:SetMagnitude(5)
        effectdata:SetRadius(4)
        effectdata:SetEntity(ent)
        util.Effect('TeslaHitboxes', effectdata)

        if val == 80 then
            ent:EmitSound('ambient/levels/citadel/weapon_disintegrate4.wav')
        end

        if val == 100 then
            SafeRemoveEntity(ent)
        end
    end)

    ent:SetMoveType(MOVETYPE_VPHYSICS)
    ent:SetMaterial('models/props_combine/portalball001_sheet')
    ent:EmitSound('ambient/levels/citadel/zapper_warmup4.wav')
    ent:SetNWBool('P2_FIZZLED', true)
end

function ENT:StartTouch(ent)
    self:Fizzle(ent)
end

function ENT:HasPortals(ply)
    local out = false

    for i, v in pairs(ents.GetAll()) do
        if IsValid(v) and ply:GetNWEntity('PORTALGUN_PORTALS_RED') == v then
            out = true
        elseif IsValid(v) and ply:GetNWEntity('PORTALGUN_PORTALS_BLUE') == v then
            out = true
        end
    end

    return out
end