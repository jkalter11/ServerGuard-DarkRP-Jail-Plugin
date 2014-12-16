--[[
	Maked by PC-Drivers (TrollFortress)
	- Idea from ULX
]]

plugin.unique = "jailplayers";

plugin.name = "[DarkRP] Jail Commands (!Jail/!Unjail/!JailTP)";
plugin.author = "PCDrivers";
plugin.version = "1.0";
plugin.description = "Jail Players.";
plugin.gamemodes = {"darkrp"};
plugin.permissions = {"Jail Permissions"};

-- File Download
resource.AddFile("materials/serverguard/icon16/icon_jail.png")

-- Local Variables
serverguard.jailLengths = {
	{"30 Seconds",		30},
	{"1 Minute",		60},
	{"5 Minutes",		300},
	{"10 Minutes",		600},
	{"30 Minutes",		1800},
	{"Indefinite",		0}
};

local doJail;
local jailableArea;

--
-- Jail Target Command (And Unjail if is jailed)
--
local command = {};

command.help = "Jail Target Player.";
command.command = "jail";
command.arguments	= {"<player> [time] (in seconds)"};
command.permissions = "Jail Permissions";

function command:Execute( player, silent, arguments )
	local target = util.FindPlayer(arguments[1], player);
	local seconds;
	local makejail = true;
	--
	if (serverguard.player:GetImmunity(target) <= serverguard.player:GetImmunity(player)) then
		-- ARGUMENTS
		if (arguments[2] == nil) then
			if target.jail then
				target.jail.unjail();
				makejail = false;
			else
				seconds = tonumber(0);
			end;
		else
			seconds = tonumber(arguments[2]);
		end;
		--
		if (makejail) then
			if not jailableArea( target:GetPos() ) then
				serverguard.Notify( player, SERVERGUARD.NOTIFY.RED, target:Name(), " is not in an area where a jail can be placed!" );
			else
				doJail( target, seconds );
				if (!silent) then
					if seconds > 0 then
						serverguard.Notify(nil, SERVERGUARD.NOTIFY.GREEN, player:Name(), SERVERGUARD.NOTIFY.WHITE, " jailed ", SERVERGUARD.NOTIFY.RED, target:Name(), SERVERGUARD.NOTIFY.WHITE, " for ", SERVERGUARD.NOTIFY.RED, tostring(seconds), SERVERGUARD.NOTIFY.WHITE, " second(s)");
					else
						serverguard.Notify(nil, SERVERGUARD.NOTIFY.GREEN, player:Name(), SERVERGUARD.NOTIFY.WHITE, " jailed ", SERVERGUARD.NOTIFY.RED, target:Name());
					end;
				end;
			end;
		else
			if (!silent) then
				serverguard.Notify(nil, SERVERGUARD.NOTIFY.GREEN, player:Name(), SERVERGUARD.NOTIFY.WHITE, " unjailed ", SERVERGUARD.NOTIFY.RED, target:Name());
			end;
		end;
	else
		serverguard.Notify(player, SERVERGUARD.NOTIFY.RED, "This player has a higher immunity than you.");
	end;
end;


-- Called when the command needs an entry in the context menu (right click menu).
function command:ContextMenu(player, menu, rankData)
	local jailMenu, menuOption = menu:AddSubMenu("Jail/Unjail Player");
	menuOption:SetImage("serverguard/icon16/icon_jail.png");
	
	for k, v in pairs(serverguard.jailLengths) do
		local option = jailMenu:AddOption(v[1], function()
			serverguard.command.Run("jail", false, player:UniqueID(), v[2]);
		end);
		
		option:SetImage("icon16/clock.png");
	end;
	
	local option = jailMenu:AddOption("UnJail", function()
		serverguard.command.Run("unjail", false, player:UniqueID());
	end);
	option:SetImage("serverguard/icon16/icon_jail.png");
	
end;

-- Register the command through the plugin so it can be disabled when the plugin is.
plugin:AddCommand(command);


--
-- Unjail Target Command
--
local command = {};

command.help = "Unjail Target Player.";
command.command = "unjail";
command.arguments	= {"<player>"};
command.permissions = "Jail Permissions"; 


function command:Execute( player, silent, arguments )
	local target = util.FindPlayer(arguments[1], player);
	
	if (serverguard.player:GetImmunity(target) <= serverguard.player:GetImmunity(player)) then
		if target.jail then
			target.jail.unjail();
			if (!silent) then
				serverguard.Notify(nil, SERVERGUARD.NOTIFY.GREEN, player:Name(), SERVERGUARD.NOTIFY.WHITE, " unjailed ", SERVERGUARD.NOTIFY.RED, target:Name());
			end;
		end;
	else
		serverguard.Notify(player, SERVERGUARD.NOTIFY.RED, "This player has a higher immunity than you.");
	end;
end;

plugin:AddCommand(command);

--
--  JAIL WITH TELEPORT TO YOUR AIM
--

local command = {};

command.help = "Jail Target Player with teleport to your aim.";
command.command = "jailtp";
command.arguments	= {"<player> [time] (in seconds)"};
command.permissions = "Jail Permissions";

function command:Execute( player, silent, arguments )
	local target = util.FindPlayer(arguments[1], player);
	local seconds;
	if (arguments[2] == nil) then
		seconds = tonumber(0);
	else
		seconds = tonumber(arguments[2]);
	end;
	if (IsValid(target)) then
		if (serverguard.player:GetImmunity(target) > serverguard.player:GetImmunity(player)) then
			serverguard.Notify(player, SERVERGUARD.NOTIFY.RED, "This player has a higher immunity than you.");
			return
		end
		
		if not target:Alive() then
			serverguard.Notify(player, SERVERGUARD.NOTIFY.RED, "[ERROR] ", target:Name(), " is dead!")
			return
		else
			if target:InVehicle() then
				target:ExitVehicle();
			end;
			-- Teleport player
			local trace = player:GetEyeTrace();
				trace = trace.HitPos +trace.HitNormal *1.25;
			target:SetPos(trace);
			doJail( target, seconds );
			if (!silent) then
				if seconds > 0 then
					serverguard.Notify(nil, SERVERGUARD.NOTIFY.GREEN, player:Name(), SERVERGUARD.NOTIFY.WHITE, " jailed ", SERVERGUARD.NOTIFY.RED, target:Name(), SERVERGUARD.NOTIFY.WHITE, " for ", SERVERGUARD.NOTIFY.RED, tostring(seconds), SERVERGUARD.NOTIFY.WHITE, " second(s)");
				else
					serverguard.Notify(nil, SERVERGUARD.NOTIFY.GREEN, player:Name(), SERVERGUARD.NOTIFY.WHITE, " jailed ", SERVERGUARD.NOTIFY.RED, target:Name());
				end
			end
		end
	end
end

plugin:AddCommand(command);


--
-- FUNCTIONS EXTRACTED FROM ULX
--
local function jailCheck()
	local remove_timer = true;
	local players = player.GetAll();
	for i=1, #players do
		local ply = players[ i ];
		if ply.jail then
			remove_timer = false;
		end;
		if ply.jail and (ply.jail.pos-ply:GetPos()):LengthSqr() >= 6500 then
			ply:SetPos( ply.jail.pos );
			if ply.jail.jail_until then
				doJail( ply, ply.jail.jail_until - CurTime() );
			else
				doJail( ply, 0 );
			end;
		end;
	end;

	if remove_timer then
		timer.Remove( "SGJail" );
	end;
end;

jailableArea = function( pos )
	entList = ents.FindInBox( pos - Vector( 35, 35, 5 ), pos + Vector( 35, 35, 110 ) )
	for i=1, #entList do
		if entList[ i ]:GetClass() == "trigger_remove" then
			return false
		end
	end

	return true
end

local mdl1 = Model( "models/props_building_details/Storefront_Template001a_Bars.mdl" )
local jail = {
	{ pos = Vector( 0, 0, -5 ), ang = Angle( 90, 0, 0 ), mdl=mdl1 },
	{ pos = Vector( 0, 0, 97 ), ang = Angle( 90, 0, 0 ), mdl=mdl1 },
	{ pos = Vector( 21, 31, 46 ), ang = Angle( 0, 90, 0 ), mdl=mdl1 },
	{ pos = Vector( 21, -31, 46 ), ang = Angle( 0, 90, 0 ), mdl=mdl1 },
	{ pos = Vector( -21, 31, 46 ), ang = Angle( 0, 90, 0 ), mdl=mdl1 },
	{ pos = Vector( -21, -31, 46), ang = Angle( 0, 90, 0 ), mdl=mdl1 },
	{ pos = Vector( -52, 0, 46 ), ang = Angle( 0, 0, 0 ), mdl=mdl1 },
	{ pos = Vector( 52, 0, 46 ), ang = Angle( 0, 0, 0 ), mdl=mdl1 },
}
doJail = function( v, seconds )
	if v.jail then -- They're already jailed
		v.jail.unjail()
	end

	if v:InVehicle() then
		local vehicle = v:GetParent()
		v:ExitVehicle()
		vehicle:Remove()
	end

	-- Force other players to let go of this player
	if v.physgunned_by then
		for ply, v in pairs( v.physgunned_by ) do
			if ply:IsValid() and ply:GetActiveWeapon():IsValid() and ply:GetActiveWeapon():GetClass() == "weapon_physgun" then
				ply:ConCommand( "-attack" )
			end
		end
	end

	if v:GetMoveType() == MOVETYPE_NOCLIP then -- Take them out of noclip
		v:SetMoveType( MOVETYPE_WALK )
	end

	local pos = v:GetPos()

	local walls = {}
	for _, info in ipairs( jail ) do
		local ent = ents.Create( "prop_physics" )
		ent:SetModel( info.mdl )
		ent:SetPos( pos + info.pos )
		ent:SetAngles( info.ang )
		ent:Spawn()
		ent:GetPhysicsObject():EnableMotion( false )
		ent:SetMoveType( MOVETYPE_NONE )
		ent.jailWall = true
		table.insert( walls, ent )
	end

	local key = {}
	local function unjail()
		if not v:IsValid() or not v.jail or v.jail.key ~= key then -- Nope
			return
		end

		for _, ent in ipairs( walls ) do
			if ent:IsValid() then
				ent:DisallowDeleting( false )
				ent:Remove()
			end
		end
		if not v:IsValid() then return end -- Make sure they're still connected

		v:DisallowNoclip( false )
		v:DisallowMoving( false )
		v:DisallowSpawning( false )
		v:DisallowVehicles( false )

		v.jail = nil
	end
	if seconds > 0 then
		timer.Simple( seconds, unjail )
	end

	local function newWall( old, new )
		table.insert( walls, new )
	end

	for _, ent in ipairs( walls ) do
		ent:DisallowDeleting( true, newWall )
		ent:DisallowMoving( true )
	end
	v:DisallowNoclip( true )
	v:DisallowMoving( true )
	v:DisallowSpawning( true )
	v:DisallowVehicles( true )
	v.jail = { pos=pos, unjail=unjail, key=key }
	if seconds > 0 then
		v.jail.jail_until = CurTime() + seconds
	end

	timer.Create( "SGJail", 1, 0, jailCheck )
end

local function jailDisconnectedCheck( ply )
	if ply.jail then
		ply.jail.unjail()
	end
end
plugin:Hook("PlayerDisconnected", "jailplayers.JailDisconnectedCheck", jailDisconnectedCheck)

local function playerPickup( ply, ent )
	if CLIENT then return end
	if ent:IsPlayer() then
		ent.physgunned_by = ent.physgunned_by or {}
		ent.physgunned_by[ ply ] = true
	end
end
plugin:Hook("PhysgunPickup", "jailplayers.PlayerPickupJailCheck", playerPickup, -20)

--local function playerDrop( ply, ent )
--	if CLIENT then return end
--	if ent:IsPlayer() then
--		ent.physgunned_by[ ply ] = nil
--	end
--end
--plugin:Hook("PhysgunDrop", "jailplayers.PlayerDropJailCheck", playerDrop)
