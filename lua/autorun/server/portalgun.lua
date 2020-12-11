-- ------------------------------------------------------------------------
-- WEAPON PORTALGUN FOR GARRY'S MOD 13 --
-- WRITEN BY WHEATLEY - http://steamcommunity.com/id/wheatley_wl/
-- ------------------------------------------------------------------------
-- LIST OF REQUIRED TO DOWNLOAD FILES & NET DEFENITION
-- ------------------------------------------------------------------------
resource.AddFile('materials/hud/portalgun_crosshair_full.png')
resource.AddFile('materials/hud/portalgun_crosshair_empty.png')
resource.AddFile('materials/hud/portalgun_crosshair_right.png')
resource.AddFile('materials/hud/portalgun_crosshair_left.png')
resource.AddFile('materials/entities/weapon_portalgun.png')
resource.AddFile('materials/models/portalblue.vmt')
resource.AddFile('materials/models/portalred.vmt')
util.AddNetworkString('NET_PORTALGUN_CHANGE_TYPE')

net.Receive('NET_PORTALGUN_CHANGE_TYPE', function()
    local ply = net.ReadEntity()
    local new = net.ReadFloat()
    ply:SetNWInt('PORTALGUNTYPE', new)
end)