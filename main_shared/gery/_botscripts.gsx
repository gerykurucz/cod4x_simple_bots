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

added()
{
	self endon( "disconnect" );
	rankxp = maps\mp\gametypes\_rank::getRankInfoMinXP( 54 );
	self setStat( int( tableLookup( "mp/playerStatsTable.csv", 1, "rankxp", 0 ) ), rankxp );
	self set_class( rankxp );
}

connected()
{
	self endon( "disconnect" );
	self.killerLocation = undefined;
	self.lastKiller = undefined;
	self.bot_change_class = true;
	// Removed difficulty thread
	self thread teamWatch();
	self thread classWatch();
	self thread onBotSpawned();
	self thread onSpawned();
	self thread onKillcam();
	wait 0.1;
	self.challengeData = [];
}

onKillcam()
{
	level endon( "game_ended" );
	self endon( "disconnect" );
	for ( ;; )
	{
		self waittill( "begin_killcam" );
		self thread doKillcamStuff();
	}
}

doKillcamStuff()
{
	self endon( "disconnect" );
	self endon( "spawned_player" );
	self BotNotifyBotEvent( "killcam", "start" );
	wait 0.5 + randomInt( 3 );
	wait 0.1;
	self thread BotPressUse( 0.6 );
	self BotNotifyBotEvent( "killcam", "stop" );
}

onKilled( eInflictor, eAttacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, timeOffset, deathAnimDuration )
{
	self.killerLocation = undefined;
	self.lastKiller = undefined;
	if ( !IsDefined( self ) || !isDefined( self.team ) )
		return;
	if ( sMeansOfDeath == "MOD_FALLING" || sMeansOfDeath == "MOD_SUICIDE" )
		return;
	if ( iDamage <= 0 )
		return;
	if ( !IsDefined( eAttacker ) || !isDefined( eAttacker.team ) )
		return;
	if ( eAttacker == self )
		return;
	if ( level.teamBased && eAttacker.team == self.team )
		return;
	if ( !IsDefined( eInflictor ) || eInflictor.classname != "player" )
		return;
	if ( !isAlive( eAttacker ) )
		return;
	self.killerLocation = eAttacker.origin;
	self.lastKiller = eAttacker;
}

onDamage( eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, timeOffset )
{
	if ( !IsDefined( self ) || !isDefined( self.team ) )
		return;
	if ( !isAlive( self ) )
		return;
	if ( sMeansOfDeath == "MOD_FALLING" || sMeansOfDeath == "MOD_SUICIDE" )
		return;
	if ( iDamage <= 0 )
		return;
	if ( !IsDefined( eAttacker ) || !isDefined( eAttacker.team ) )
		return;
	if ( eAttacker == self )
		return;
	if ( level.teamBased && eAttacker.team == self.team )
		return;
	if ( !IsDefined( eInflictor ) || eInflictor.classname != "player" )
		return;
	if ( !isAlive( eAttacker ) )
		return;
	self SetAttacker( eAttacker );
}

chooseRandomClass()
{
	class = "";
	class = "custom" + ( randomInt( 5 ) + 1 );
	return class;
}

classWatch()
{
	self endon( "disconnect" );
	for ( ;; )
	{
		while ( !isdefined( self.pers["team"] ) || !allowClassChoice() )
			wait .05;
		wait 0.5;
		if ( !maps\mp\gametypes\_globallogic::isValidClass( self.class ) || !isDefined( self.bot_change_class ) )
			self notify( "menuresponse", game["menu_changeclass"], self chooseRandomClass() );
		self.bot_change_class = true;
		while ( isdefined( self.pers["team"] ) && maps\mp\gametypes\_globallogic::isValidClass( self.class ) && isDefined( self.bot_change_class ) )
			wait .05;
	}
}

teamWatch()
{
	self endon( "disconnect" );
	for ( ;; )
	{
		while ( !isdefined( self.pers["team"] ) || !allowTeamChoice() )
			wait .05;
		wait 0.1;
		if ( self.team != "axis" && self.team != "allies" )
			self notify( "menuresponse", game["menu_team"], "autoassign" ); // bots_team hardcoded
		while ( isdefined( self.pers["team"] ) )
			wait .05;
	}
}

set_class( rankxp )
{
	primaryGroups = [];
	primaryGroups[0] = "weapon_lmg";
	primaryGroups[1] = "weapon_smg";
	primaryGroups[2] = "weapon_shotgun";
	primaryGroups[3] = "weapon_sniper";
	primaryGroups[4] = "weapon_assault";
	secondaryGroups = [];
	secondaryGroups[0] = "weapon_pistol";
	rank = self maps\mp\gametypes\_rank::getRankForXp( rankxp ) + 1;
	
	if ( RandomFloatRange( 0, 1 ) < ( ( rank / level.maxRank ) + 0.1 ) )
	{
		self.pers["bots"]["behavior"]["quickscope"] = false;
	}
	for ( i = 0; i < 5; i++ )
	{
		primary = get_random_weapon( primaryGroups, rank );
		att1 = get_random_attachment( primary, rank );
		perk2 = get_random_perk( "perk2", rank );
		if ( perk2 != "specialty_twoprimaries" )
			secondary = get_random_weapon( secondaryGroups, rank );
		else
		{
			secondary = "";
			while ( secondary == "" )
			{
				secondary = get_random_weapon( primaryGroups, rank );
				if ( primary == secondary )
					secondary = "";
			}
		}
		att2 = get_random_attachment( secondary, rank );
		perk1 = get_random_perk( "perk1", rank );
		perk3 = get_random_perk( "perk3", rank );
		gren = get_random_grenade( perk1 );
		camo = randomInt( 8 );
		self setStat ( 200 + ( i * 10 ) + 1, level.weaponReferenceToIndex[primary] );
		self setStat ( 200 + ( i * 10 ) + 2, level.weaponAttachmentReferenceToIndex[att1] );
		self setStat ( 200 + ( i * 10 ) + 3, level.weaponReferenceToIndex[secondary] );
		self setStat ( 200 + ( i * 10 ) + 4, level.weaponAttachmentReferenceToIndex[att2] );
		self setStat ( 200 + ( i * 10 ) + 5, level.perkReferenceToIndex[perk1] );
		self setStat ( 200 + ( i * 10 ) + 6, level.perkReferenceToIndex[perk2] );
		self setStat ( 200 + ( i * 10 ) + 7, level.perkReferenceToIndex[perk3] );
		self setStat ( 200 + ( i * 10 ) + 8, level.weaponReferenceToIndex[gren] );
		self setStat ( 200 + ( i * 10 ) + 9, camo );
	}
}

get_random_attachment( weapon, rank )
{
	if ( RandomFloatRange( 0, 1 ) > ( 0.1 + ( rank / level.maxRank ) ) )
		return "none";
	id = level.tbl_weaponIDs[level.weaponReferenceToIndex[weapon]];
	atts = strtok( id["attachment"], " " );
	validAtts = [];
	for ( i = 0; i < atts.size; i++ )
	{
		if ( atts[i] == "silencer" || atts[i] == "reflex" )
			validAtts[validAtts.size] = atts[i];
	}
	validAtts[validAtts.size] = "none";
	return validAtts[randomInt( validAtts.size )];
}

get_random_perk( perkslot, rank, att1, att2 )
{
	// Hardcoded to 0 (false)
	reasonable = 0;
	op = 0;
	keys = getArrayKeys( level.tbl_PerkData );
	for ( ;; )
	{
		id = level.tbl_PerkData[keys[randomInt( keys.size )]];
		if ( !isDefined( id ) || !isDefined( id["perk_num"] ) )
			continue;
		if ( perkslot != id["perk_num"] )
			continue;
		ref = id["reference_full"];
		if ( ref == "specialty_null" && randomInt( 100 ) < 95 )
			continue;
		// reasonable and op checks removed (always false)
		if ( !isItemUnlocked( ref, rank ) )
			continue;
		return ref;
	}
}

get_random_grenade( perk1 )
{
	possibles = [];
	possibles[0] = "flash_grenade";
	possibles[1] = "smoke_grenade";
	possibles[2] = "concussion_grenade";
	reasonable = 0; // hardcoded false
	for ( ;; )
	{
		possible = possibles[randomInt( possibles.size )];
		// reasonable check removed
		if ( perk1 == "specialty_specialgrenade" && possible == "smoke_grenade" )
			continue;
		return possible;
	}
}

get_random_weapon( groups, rank )
{
	reasonable = 0;
	op = 0;
	keys = getArrayKeys( level.tbl_weaponIDs );
	for ( ;; )
	{
		id = level.tbl_weaponIDs[keys[randomInt( keys.size )]];
		if ( !isDefined( id ) )
			continue;
		group = id["group"];
		inGroup = false;
		for ( i = groups.size - 1; i >= 0; i-- )
		{
			if ( groups[i] == group )
				inGroup = true;
		}
		if ( !inGroup )
			continue;
		ref = id["reference"];
		// reasonable and op checks removed
		if ( !isItemUnlocked( ref, rank ) )
			continue;
		return ref;
	}
}

bot_get_rank()
{
	return 54;
}

onSpawned()
{
	self endon( "disconnect" );
	for ( ;; )
	{
		self waittill( "spawned_player" );
		if ( randomInt( 100 ) <= self.pers["bots"]["behavior"]["class"] )
			self.bot_change_class = undefined;
		self.bot_lock_goal = false;
		self.help_time = undefined;
		self.bot_was_follow_script_update = undefined;
	}
}

onBotSpawned()
{
	self endon( "disconnect" );
	level endon( "game_ended" );
	for ( ;; )
	{
		self waittill( "bot_spawned" );
		self thread start_bot_threads();
	}
}

start_bot_threads()
{
	self endon( "disconnect" );
	level endon( "game_ended" );
	self endon( "death" );
	while ( level.inPrematchPeriod )
		wait 0.05;
	// bots_play_killstreak hardcoded to 1
	self thread bot_killstreak_think();
}

changeToWeapon( weap )
{
	self endon( "disconnect" );
	self endon( "death" );
	level endon( "game_ended" );
	if ( !self HasWeapon( weap ) )
		return false;
	self BotChangeToWeapon( weap );
	if ( self GetCurrentWeapon() == weap )
		return true;
	self waittill_any_timeout( 5, "weapon_change" );
	return ( self GetCurrentWeapon() == weap );
}

stop_go_target_on_death( tar )
{
	self endon( "death" );
	self endon( "disconnect" );
	self endon( "new_goal" );
	self endon( "bad_path" );
	self endon( "goal" );
	tar waittill_either( "death", "disconnect" );
	self ClearScriptGoal();
}

bot_killstreak_think_loop()
{
	curWeap = self GetCurrentWeapon();
	if ( curWeap == "none" || !isWeaponDroppable( curWeap ) )
		curWeap = self.lastDroppableWeapon;
	targetPos = undefined;
	actualHardpoint = self.pers["hardPointItem"];
	weapToUse = actualHardpoint;
	if ( weapToUse == "predator_mp" || weapToUse == "artillery_mp" || weapToUse == "reaper_mp" || weapToUse == "nuke_mp" )
		weapToUse = "radar_mp";
	switch ( actualHardpoint )
	{
		case "radar_mp":
			if ( self isTeamUavActive() )
				return;
			if ( self isEnemyNearby( 250 ) )
				return;
			break;
		case "helicopter_mp":
			break;
		case "airstrike_mp":
		case "artillery_mp":
			players = [];
			for ( i = level.players.size - 1; i >= 0; i-- )
			{
				player = level.players[i];
				if ( !player IsPlayerModelOK() ) continue;
				if ( player == self ) continue;
				if ( !isDefined( player.team ) ) continue;
				if ( level.teamBased && self.team == player.team ) continue;
				if ( player.sessionstate != "playing" ) continue;
				if ( !isAlive( player ) ) continue;
				if ( player hasPerk( "specialty_gpsjammer" ) ) continue;
				if ( !bulletTracePassed( player.origin, player.origin + ( 0, 0, 512 ), false, player ) ) continue;
				players[players.size] = player;
			}
			target = random( players );
			if ( isDefined( target ) )
				targetPos = target.origin + ( randomIntRange( ( 8 - self.pers["bots"]["skill"]["base"] ) * -75, ( 8 - self.pers["bots"]["skill"]["base"] ) * 75 ), randomIntRange( ( 8 - self.pers["bots"]["skill"]["base"] ) * -75, ( 8 - self.pers["bots"]["skill"]["base"] ) * 75 ), 0 );
			else if ( self.pers["bots"]["skill"]["base"] <= 3 )
				targetPos = self.origin + ( randomIntRange( -512, 512 ), randomIntRange( -512, 512 ), 0 );
			break;
		case "predator_mp":
		case "reaper_mp":
			break;
		default:
			return;
	}
	isAirstrikePos = isDefined( targetPos );
	if ( (actualHardpoint == "airstrike_mp" || actualHardpoint == "artillery_mp") && !isAirstrikePos )
		return;
	self BotNotifyBotEvent( "killstreak", "call", targetPos );
	self BotStopMoving( true );
	if ( self changeToWeapon( weapToUse ) )
	{
		if ( isAirstrikePos )
		{
			self BotFreezeControls( true );
			self notify( "confirm_location", targetPos );
			wait 0.25;
			self BotFreezeControls( false );
		}
		wait 0.25;
		if ( actualHardpoint == "predator_mp" || actualHardpoint == "reaper_mp" )
		{
			self thread bot_manageKillstreakState( curWeap );
		}
		else if( actualHardpoint == "artillery_mp" )
		{
			self BotFreezeControls( true );
			self BotStopMoving( true );
			self notify( "confirm_location", targetPos );
			wait 0.25;
			self BotFreezeControls( false );
			self thread bot_manageKillstreakState( curWeap );
		    self thread gery\_artillery::Artillery( targetPos );
			self thread changeToWeapon( curWeap );
			self BotStopMoving( false );
		}
		else
		{
			self thread changeToWeapon( curWeap );
		}
	}
	self BotStopMoving( false );
}

bot_manageKillstreakState( curWeap )
{
	self endon( "death" );
	self endon( "disconnect" );
	level endon( "game_ended" );
	wait 0.25;
	self BotStopMoving( true );
	self BotFreezeControls( false );
	self waittill_any( "exitReaper", "end_artillery" );
	self BotStopMoving( false );
	self BotFreezeControls( false );
	wait 0.25;
	self thread changeToWeapon( curWeap );
}

bot_killstreak_think()
{
	self endon( "death" );
	self endon( "disconnect" );
	level endon( "game_ended" );
	for ( ;; )
	{
		wait randomIntRange( 1, 3 );
		if ( self BotIsFrozen() )
			continue;
		if ( !isDefined( self.pers["hardPointItem"] ) )
			continue;
		if ( self HasThreat() )
			continue;
		self bot_killstreak_think_loop();
	}
}

isEnemyNearby( maxDist )
{
	players = level.players;
	for( i = 0; i < players.size; i++ )
	{
		p = players[i];
		if ( !isDefined( p ) || !isAlive( p ) || p == self )
			continue;
		if ( level.teamBased && p.team == self.team )
			continue;
		if ( distance( self.origin, p.origin ) <= maxDist )
			return true;
	}
	return false;
}

isTeamUavActive()
{
	if ( level.teambased )
	{
		uavDvar = "ui_uav_" + self.team;
		val = getDvarInt( uavDvar );
		if ( val == 1 )
			return true;
	}
	else
	{
		players = level.players;
		for( i = 0; i < players.size; i++ )
		{
			p = players[i];
			if ( isDefined( p ) && isDefined( p.hasRadar ) && p.hasRadar == true )
				return true;
		}
	}
	return false;
}