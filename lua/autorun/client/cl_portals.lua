print('Eventually, it all worked!')
-- ------------------------------------------------------------------------
-- WEAPON PORTALGUN FOR GARRY'S MOD 13 --
-- WRITEN BY WHEATLEY - http://steamcommunity.com/id/wheatley_wl/
-- ------------------------------------------------------------------------
-- PORTAL RENDERING SYSTEM
CreateClientConVar('portalmod_gun_clr', '1 1 1')

hook.Add('RenderScene', 'PortalSimulation_RenderPortals', function(pos, ang)
    for _, portal in pairs(ents.FindByClass('portalgun_portal')) do
        -- render portals
        if IsValid(portal) then
            portal:SimulatePortal(pos, ang)
        end
    end
end)

hook.Add('PostDrawTranslucentRenderables', 'DebugSpheres', function()
    -- Only paint sphere when not in portal render phase
    if PORTALRENDERING then return true end

    for _, portal in pairs(ents.FindByClass('portalgun_portal')) do
        -- render portals
        if IsValid(portal) then
            portal:DebugPlayerPos(pos, ang)
        end
    end
end)

hook.Add('PostDrawEffects', 'PortalSimulation_PlayerRenderFix', function()
    cam.Start3D(EyePos(), EyeAngles())
    cam.End3D()
end)

hook.Add('ShouldDrawLocalPlayer', 'PortalSimulation_RenderPlayer', function()
    if PORTALRENDERING then return true end
end)

-- example: ConvertStringToColor( '1 0.5 1' )
local function ConvertStringToColor(str)
    local s = string.Explode(' ', str)
    local r, g, b = s[1], s[2], s[3]
    r = tonumber(r)
    g = tonumber(g)
    b = tonumber(b)

    return Color(r * 255, g * 255, b * 255, 255)
end

-- example: ConvertColorToString( Color( 255, 255, 255 ) )
local function ConvertColorToString(clr)
    local r, g, b = clr.r, clr.g, clr.b

    return tostring(r / 255) .. ' ' .. tostring(g / 255) .. ' ' .. tostring(b / 255)
end

local function ChangePortalGunType(int)
    net.Start('NET_PORTALGUN_CHANGE_TYPE')
    net.WriteFloat(int)
    net.SendToServer()
end

local function Build_ToolPanel(_pnl)
    local skinlist = vgui.Create('DComboBox')
    skinlist:SetValue('Portalgun Skins')
    skinlist:AddChoice('Default')
    skinlist:AddChoice('Atlas')
    skinlist:AddChoice('Pbody')

    skinlist.OnSelect = function(panel, index, value)
        ChangePortalGunType(index - 1)
    end

    _pnl:AddPanel(skinlist)
    local colormixer = vgui.Create('DColorMixer')
    colormixer:SetPalette(true)
    colormixer:SetAlphaBar(true)
    colormixer:SetWangs(true)
    colormixer:SetColor(ConvertStringToColor(GetConVar('portalmod_gun_clr')))
    _pnl:AddPanel(colormixer)

    timer.Create('cl_portalgun_clr_update', 0.5, 0, function()
        if colormixer then
            local new = ConvertColorToString(colormixer:GetColor())
            RunConsoleCommand('portalmod_gun_clr', new)
        else
            timer.Remove('cl_portalgun_clr_update')
        end
    end)
end

hook.Add('PopulateToolMenu', 'BuildPortalgunOptions', function()
    spawnmenu.AddToolMenuOption('Options', 'Player', 'Portalgun', 'Portalgun Settings', '', '', Build_ToolPanel, {})
end)