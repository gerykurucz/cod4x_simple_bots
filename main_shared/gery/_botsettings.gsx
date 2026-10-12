/*
 * ============================================================
 *  COD4X - Simple Bots
 *  Version: 1.1
 *  Developer: Gery Kurucz (github.com/gerykurucz)
 * ============================================================
 */

#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;
#include gery\_botutils;

init()
{
	thread load_waypoints();
	cac_init_patch();
	thread hook_callbacks();
	level.defuseObject = undefined;
	level.bots_smokeList = List();
	level.tbl_PerkData[0]["reference_full"] = true;
	for ( h = 1; h < 6; h++ )
		for ( i = 0; i < 3; i++ )
			level.default_perk["CLASS_CUSTOM" + h][i] = "specialty_null";
	level.bots_minSprintDistance = 315;
	level.bots_minSprintDistance *= level.bots_minSprintDistance;
	level.bots_minGrenadeDistance = 256;
	level.bots_minGrenadeDistance *= level.bots_minGrenadeDistance;
	level.bots_maxGrenadeDistance = 1024;
	level.bots_maxGrenadeDistance *= level.bots_maxGrenadeDistance;
	level.bots_maxKnifeDistance = 80;
	level.bots_maxKnifeDistance *= level.bots_maxKnifeDistance;
	level.bots_goalDistance = 27.5;
	level.bots_goalDistance *= level.bots_goalDistance;
	level.bots_noADSDistance = 450;
	level.bots_noADSDistance *= level.bots_noADSDistance;
	level.bots_maxShotgunDistance = 500;
	level.bots_maxShotgunDistance *= level.bots_maxShotgunDistance;
	level.bots_listenDist = 100;
	level.smokeRadius = 255;
	level.bots = [];
	level.bots_fullautoguns = [];
	level.bots_fullautoguns["rpd"] = true;
	level.bots_fullautoguns["m60e4"] = true;
	level.bots_fullautoguns["saw"] = true;
	level.bots_fullautoguns["ak74u"] = true;
	level.bots_fullautoguns["mp5"] = true;
	level.bots_fullautoguns["p90"] = true;
	level.bots_fullautoguns["skorpion"] = true;
	level.bots_fullautoguns["uzi"] = true;
	level.bots_fullautoguns["g36c"] = true;
	level.bots_fullautoguns["m4"] = true;
	level.bots_fullautoguns["ak47"] = true;
	level.bots_fullautoguns["mp44"] = true;
	level thread onPlayerConnect();
	level thread handleBots();
}

handleBots()
{
	level addBots();
	while ( !level.gameEnded )
		wait 0.05;
	setDvar( "bots_manage_add", getBotArray().size );
}

onPlayerDamage( eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, timeOffset )
{
	if ( self is_bot() )
	{
		self gery\_botfunctions::onDamage( eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, timeOffset );
		self gery\_botscripts::onDamage( eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, timeOffset );
	}
	self [[level.prevCallbackPlayerDamage]]( eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, timeOffset );
}

onPlayerKilled( eInflictor, eAttacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, timeOffset, deathAnimDuration )
{
	if ( self is_bot() )
	{
		self gery\_botfunctions::onKilled( eInflictor, eAttacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, timeOffset, deathAnimDuration );
		self gery\_botscripts::onKilled( eInflictor, eAttacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, timeOffset, deathAnimDuration );
	}
	self.lastAttacker = eAttacker;
	if ( isDefined( eAttacker ) )
	{
		eAttacker.lastKilledPlayer = self;
		eAttacker notify( "killed_enemy" );
	}
	self [[level.prevCallbackPlayerKilled]]( eInflictor, eAttacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, timeOffset, deathAnimDuration );
}

hook_callbacks()
{
	wait 0.05;
	level.prevCallbackPlayerDamage = level.callbackPlayerDamage;
	level.callbackPlayerDamage = ::onPlayerDamage;
	level.prevCallbackPlayerKilled = level.callbackPlayerKilled;
	level.callbackPlayerKilled = ::onPlayerKilled;
}

onPlayerConnect()
{
	for ( ;; )
	{
		level waittill( "connected", player );
		player thread onGrenadeFire();
		player thread onWeaponFired();
		player thread doPlayerModelFix();
		player thread connected();
	}
}

fixPerksAndScriptKick()
{
	self endon( "disconnect" );
	self waittill( "spawned" );
	self.pers["isBot"] = true;
	if ( !level.gameEnded )
		level waittill ( "game_ended" );
}

onDisconnect()
{
	self waittill( "disconnect" );
	level.bots = array_remove( level.bots, self );
}

connected()
{
	self endon( "disconnect" );
	if ( !self is_bot() )
		return;
	if ( !isDefined( self.pers["isBot"] ) )
	{
		self.pers["isBot"] = true;
	}
	if ( !isDefined( self.pers["isBotWarfare"] ) )
	{
		self.pers["isBotWarfare"] = true;
		self thread added();
	}
	self thread fixPerksAndScriptKick();
	self thread gery\_botfunctions::connected();
	self thread gery\_botscripts::connected();
	level.bots[level.bots.size] = self;
	self thread onDisconnect();
	level notify( "bot_connected", self );
}

added()
{
	self endon( "disconnect" );
	self thread gery\_botfunctions::added();
	self thread gery\_botscripts::added();
}

add_bot()
{
	name = getABotName();
	bot = undefined;
	if ( isDefined( name ) && name.size >= 3 )
		bot = addtestclient( name );
	else
		bot = addtestclient();
	if ( isdefined( bot ) )
	{
		bot.pers["isBot"] = true;
		bot.pers["isBotWarfare"] = true;
		bot thread added();
	}
}

addBots_loop()
{
	botsToAdd = GetDvarInt( "bots_manage_add" );

	if ( botsToAdd > 0 )
	{
		SetDvar( "bots_manage_add", 0 );

		if ( botsToAdd > 64 )
			botsToAdd = 64;

		for ( ; botsToAdd > 0; botsToAdd-- )
		{
			level add_bot();
			wait 0.25;
		}
	}

	players = 0;
	bots = 0;
	spec = 0;
	
	alliesPlayers = 0;
	axisPlayers = 0;
	alliesBots = 0;
	axisBots = 0;

	playercount = level.players.size;

	for ( i = 0; i < playercount; i++ )
	{
		player = level.players[i];

		if ( player is_bot() )
		{
			bots++;
			if ( player.pers["team"] == "allies" )
				alliesBots++;
			else if ( player.pers["team"] == "axis" )
				axisBots++;
		}
		else if ( !isDefined( player.pers["team"] ) || ( player.pers["team"] != "axis" && player.pers["team"] != "allies" ) )
		{
			spec++;
		}
		else
		{
			players++;
			if ( player.pers["team"] == "allies" )
				alliesPlayers++;
			else if ( player.pers["team"] == "axis" )
				axisPlayers++;
		}
	}

	maxManagedBots = 8;
	targetBots = maxManagedBots - (players - 24);
	
	if ( targetBots > maxManagedBots )
		targetBots = maxManagedBots;
	if ( targetBots < 0 )
		targetBots = 0;

	if ( bots > targetBots )
	{
		kickAmount = bots - targetBots;
		
		alliesTotal = alliesPlayers + alliesBots;
		axisTotal = axisPlayers + axisBots;

		primaryKickArray = [];
		secondaryKickArray = [];

		for ( i = 0; i < level.players.size; i++ )
		{
			player = level.players[i];
			if ( player is_bot() )
			{
				if ( alliesTotal >= axisTotal && player.pers["team"] == "allies" )
					primaryKickArray[primaryKickArray.size] = player;

				else if ( axisTotal > alliesTotal && player.pers["team"] == "axis" )
					primaryKickArray[primaryKickArray.size] = player;

				else
					secondaryKickArray[secondaryKickArray.size] = player;
			}
		}
		
		kickedCount = 0;
		
		for ( k = 0; k < primaryKickArray.size && kickedCount < kickAmount; k++ )
		{
			kick( primaryKickArray[k] getEntityNumber() );
			kickedCount++;
			wait 0.1;
		}
		
		for ( k = 0; k < secondaryKickArray.size && kickedCount < kickAmount; k++ )
		{
			kick( secondaryKickArray[k] getEntityNumber() );
			kickedCount++;
			wait 0.1;
		}
	}
	else if ( bots < targetBots )
	{
		addAmount = targetBots - bots;
		
		for ( ; addAmount > 0; addAmount-- )
		{
			level add_bot();
			wait 0.25;
		}
	}
}

addBots()
{
	level endon( "game_ended" );
	for ( ;; )
	{
		wait 1.5;
		addBots_loop();
	}
}

onGrenadeFire()
{
	self endon( "disconnect" );
	for ( ;; )
	{
		self waittill ( "grenade_fire", grenade, weaponName );
		if ( !isDefined( grenade ) )
			continue;
		grenade.name = weaponName;
		if ( weaponName == "smoke_grenade_mp" )
			grenade thread AddToSmokeList();
	}
}

AddToSmokeList()
{
	grenade = spawnstruct();
	grenade.origin = self getOrigin();
	grenade.state = "moving";
	grenade.grenade = self;
	grenade thread thinkSmoke();
	level.bots_smokeList ListAdd( grenade );
}

thinkSmoke()
{
	while ( isDefined( self.grenade ) )
	{
		self.origin = self.grenade getOrigin();
		self.state = "moving";
		wait 0.05;
	}
	self.state = "smoking";
	wait 11.5;
	level.bots_smokeList ListRemove( self );
}

doPlayerModelFix()
{
	self endon( "disconnect" );
	self waittill( "spawned_player" );
	wait 0.05;
	self.bot_model_fix = true;
}

onWeaponFired()
{
	self endon( "disconnect" );
	self.bots_firing = false;
	for ( ;; )
	{
		self waittill( "weapon_fired" );
		self thread doFiringThread();
	}
}

doFiringThread()
{
	self endon( "disconnect" );
	self endon( "weapon_fired" );
	self.bots_firing = true;
	wait 1;
	self.bots_firing = false;
}