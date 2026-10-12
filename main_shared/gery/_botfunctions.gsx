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
	
	self.pers["bots"] = [];
	self.pers["bots"]["skill"] = [];

	self.pers["bots"]["skill"]["base"] = 7;
	self.pers["bots"]["skill"]["aim_time"] = 0.215;
	self.pers["bots"]["skill"]["init_react_time"] = 100;
	self.pers["bots"]["skill"]["reaction_time"] = 80;
	self.pers["bots"]["skill"]["no_trace_ads_time"] = 1250;
	self.pers["bots"]["skill"]["no_trace_look_time"] = 1000;
	self.pers["bots"]["skill"]["remember_time"] = 1000;
	self.pers["bots"]["skill"]["fov"] = 0.25;
	self.pers["bots"]["skill"]["dist_max"] = 2400;
	self.pers["bots"]["skill"]["dist_start"] = 450;
	self.pers["bots"]["skill"]["spawn_time"] = 0.1;
	self.pers["bots"]["skill"]["help_dist"] = 10;
	self.pers["bots"]["skill"]["semi_time"] = 0.1;
	self.pers["bots"]["skill"]["shoot_after_time"] = 0.5;
	self.pers["bots"]["skill"]["aim_offset_time"] = 0.01;
	self.pers["bots"]["skill"]["aim_offset_amount"] = 0.01;
	self.pers["bots"]["skill"]["bone_update_interval"] = 0.5;
	self.pers["bots"]["skill"]["bones"] = "j_spineupper,j_spine4,j_elbow_le,j_elbow_ri";
	self.pers["bots"]["skill"]["ads_fov_multi"] = 0.95;
	self.pers["bots"]["skill"]["ads_aimspeed_multi"] = 0.25;

	self.pers["bots"]["behavior"] = [];

	self.pers["bots"]["behavior"]["strafe"] = 0;
	self.pers["bots"]["behavior"]["nade"] = 50;
	self.pers["bots"]["behavior"]["sprint"] = 100;
	self.pers["bots"]["behavior"]["camp"] = 100;
	self.pers["bots"]["behavior"]["follow"] = 0;
	self.pers["bots"]["behavior"]["crouch"] = 0;
	self.pers["bots"]["behavior"]["switch"] = 0;
	self.pers["bots"]["behavior"]["class"] = 0;
	self.pers["bots"]["behavior"]["jump"] = 100;
	self.pers["bots"]["behavior"]["quickscope"] = true;
	self.pers["bots"]["behavior"]["initswitch"] = 0;
}

connected()
{
	self endon( "disconnect" );
	self.bot = spawnStruct();
	self.bot_radar = false;
	self resetBotVars();
	self thread onPlayerSpawned();
	self thread bot_skip_killcam();
}

onKilled( eInflictor, eAttacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, timeOffset, deathAnimDuration )
{
}

onDamage( eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, timeOffset )
{
}

resetBotVars()
{
	self.bot.script_target = undefined;
	self.bot.script_target_offset = undefined;
	self.bot.target = undefined;
	self.bot.targets = [];
	self.bot.target_this_frame = undefined;
	self.bot.after_target = undefined;
	self.bot.after_target_pos = undefined;
	self.bot.script_aimpos = undefined;
	self.bot.script_goal = undefined;
	self.bot.script_goal_dist = 0.0;
	self.bot.next_wp = -1;
	self.bot.second_next_wp = -1;
	self.bot.towards_goal = undefined;
	self.bot.astar = [];
	self.bot.stop_move = false;
	self.bot.greedy_path = false;
	self.bot.climbing = false;
	self.bot.last_next_wp = -1;
	self.bot.last_second_next_wp = -1;
	self.bot.isfrozen = false;
	self.bot.sprintendtime = -1;
	self.bot.isreloading = false;
	self.bot.issprinting = false;
	self.bot.isfragging = false;
	self.bot.issmoking = false;
	self.bot.isfraggingafter = false;
	self.bot.issmokingafter = false;
	self.bot.isknifing = false;
	self.bot.isknifingafter = false;
	self.bot.semi_time = false;
	self.bot.jump_time = undefined;
	self.bot.last_fire_time = -1;
	self.bot.is_cur_full_auto = false;
	self.bot.cur_weap_dist_multi = 1;
	self.bot.is_cur_sniper = false;
	self.bot.rand = randomInt( 100 );
	self botStop();
}

bot_skip_killcam()
{
	level endon( "game_ended" );
	self endon( "disconnect" );
	for ( ;; )
	{
		wait 1;
		if ( isDefined( self.killcam ) )
			self notify( "end_killcam" );
	}
}

onPlayerSpawned()
{
	self endon( "disconnect" );
	for ( ;; )
	{
		self waittill( "spawned_player" );
		self resetBotVars();
		self thread onWeaponChange();
		self thread spawned();
	}
}

spawned()
{
	self endon( "disconnect" );
	self endon( "death" );
	wait 0.1;
	self thread walk();
	self thread target();
	self thread updateBones();
	self thread aim();
	self thread doBotMovement();
	self thread smart_reload_watch();
	self thread continuous_sprint();
	self notify( "bot_spawned" );
}

onWeaponChange()
{
	self endon( "disconnect" );
	self endon( "death" );
	first = true;
	for ( ;; )
	{
		newWeapon = undefined;
		if ( first )
		{
			first = false;
			newWeapon = self getCurrentWeapon();
		}
		else
			self waittill( "weapon_change", newWeapon );
		self.bot.is_cur_full_auto = WeaponIsFullAuto( newWeapon );
		self.bot.cur_weap_dist_multi = SetWeaponDistMulti( newWeapon );
		self.bot.is_cur_sniper = IsWeapSniper( newWeapon );
		if ( newWeapon == "none" )
			continue;
		self changeToWeap( newWeapon );
	}
}

continuous_sprint()
{
	self endon( "disconnect" );
	self endon( "death" );
	self botAction( "-sprint" );
	self.bot.issprinting = false;
	for ( ;; )
	{
		wait 0.15;
		if( isDefined(self.bot.target) )
			continue;
		if ( self.bot.isfrozen || self.bot.isreloading || self.bot.isfraggingafter || self.bot.issmokingafter || self.bot.isknifingafter )
		{
			if ( self.bot.issprinting )
			{
				self botAction( "-sprint" );
				self.bot.issprinting = false;
			}
			continue;
		}
		if( self getStance() != "stand" )
			self stand();
		eyePos = self getEyePos();
		angles = self GetPlayerAngles();
		forwardDir = anglesToForward( angles );
		closeTraceEnd = eyePos + forwardDir * 15;
		closeTracePos = playerPhysicsTrace( eyePos, closeTraceEnd, false, self );
		if ( DistanceSquared( eyePos, closeTracePos ) < 15 * 15 )
		{
			if ( self.bot.issprinting )
			{
				self botAction( "-sprint" );
				self.bot.issprinting = false;
			}
			continue;
		}
		rightVec = anglesToRight( angles );
		traceLeft = bulletTrace( eyePos, eyePos - rightVec * 120, false, self );
		traceRight = bulletTrace( eyePos, eyePos + rightVec * 120, false, self );
		traceUp = bulletTrace( eyePos, eyePos + (0,0,160), false, self );
		isIndoorsOrNarrow = false;
		if ( traceLeft["fraction"] < 1.0 && traceRight["fraction"] < 1.0 )
			isIndoorsOrNarrow = true;
		if ( traceUp["fraction"] < 1.0 )
			isIndoorsOrNarrow = true;
		if ( isIndoorsOrNarrow )
		{
			if ( self.bot.issprinting )
			{
				self botAction( "-sprint" );
				self.bot.issprinting = false;
			}
			continue;
		}
		if ( isDefined( self.bot.last_fire_time ) && getTime() - self.bot.last_fire_time < 600 )
		{
			if ( self.bot.issprinting )
			{
				self botAction( "-sprint" );
				self.bot.issprinting = false;
			}
			continue;
		}
		if ( self PlayerADS() > 0.1 )
		{
			if ( self.bot.issprinting )
			{
				self botAction( "-sprint" );
				self.bot.issprinting = false;
			}
			continue;
		}
		if ( isDefined( self.bot.target ) && isDefined( self.bot.target.entity ) )
		{
			curweap = self getCurrentWeapon();
			if ( self canFire( curweap ) && self isInRange( self.bot.target.dist, curweap ) )
			{
				if ( self.bot.issprinting )
				{
					self botAction( "-sprint" );
					self.bot.issprinting = false;
				}
				continue;
			}
		}
		if ( !isDefined( self.bot.towards_goal ) || DistanceSquared( self.origin, self.bot.towards_goal ) < 120 * 120 )
		{
			if ( self.bot.issprinting )
			{
				self botAction( "-sprint" );
				self.bot.issprinting = false;
			}
			continue;
		}
		farTraceEnd = eyePos + forwardDir * 250;
		farTracePos = playerPhysicsTrace( eyePos, farTraceEnd, false, self );
		if ( DistanceSquared( eyePos, farTracePos ) < 200 * 200 )
		{
			if ( self.bot.issprinting )
			{
				self botAction( "-sprint" );
				self.bot.issprinting = false;
			}
			continue;
		}
		if ( getConeDot( self.bot.towards_goal, self.origin, self GetPlayerAngles() ) < 0.9 )
		{
			if ( self.bot.issprinting )
			{
				self botAction( "-sprint" );
				self.bot.issprinting = false;
			}
			continue;
		}
		if ( !self.bot.issprinting )
		{
			self botAction( "+sprint" );
			self.bot.issprinting = true;
		}
	}
}

doBotMovement()
{
	self endon( "disconnect" );
	self endon( "death" );
	data = spawnStruct();
	data.wasMantling = false;
	data.stuckTicks = 0;
	for ( data.i = 0; true; data.i += 0.05 )
	{
		wait 0.05;
		self doBotMovement_loop( data );
	}
}

SetWeaponDistMulti( weap )
{
	if ( weap == "none" )
		return 1;
	switch ( weaponClass( weap ) )
	{
		case "rifle":
			return 0.9;
		case "smg":
			return 0.7;
		case "pistol":
			return 0.5;
		default:
			return 1;
	}
}

IsWeapSniper( weap )
{
	if ( weap == "none" )
		return false;
	if ( maps\mp\gametypes\_missions::getWeaponClass( weap ) != "weapon_sniper" )
		return false;
	return true;
}

updateBones()
{
	self endon( "disconnect" );
	self endon( "death" );
	bones = strtok( self.pers["bots"]["skill"]["bones"], "," );
	waittime = self.pers["bots"]["skill"]["bone_update_interval"];
	for ( ;; )
	{
		self waittill_notify_or_timeout( "new_enemy", waittime );
		if ( !isDefined( self.bot.target ) )
			continue;
		self.bot.target.bone = random( bones );
	}
}

createTargetObj( ent, theTime )
{
	obj = spawnStruct();
	obj.entity = ent;
	obj.last_seen_pos = ( 0, 0, 0 );
	obj.dist = 0;
	obj.time = theTime;
	obj.trace_time = 0;
	obj.no_trace_time = 0;
	obj.trace_time_time = 0;
	obj.rand = randomInt( 100 );
	obj.didlook = false;
	obj.isplay = isPlayer( ent );
	obj.offset = undefined;
	obj.bone = undefined;
	obj.aim_offset = undefined;
	obj.aim_offset_base = undefined;
	return obj;
}

target()
{
	self endon( "disconnect" );
	self endon( "death" );
	for ( ;; )
	{
		wait 0.05;
		if ( self maps\mp\_flashgrenades::isFlashbanged() )
			continue;
		self target_loop();
	}
}

start_bot_after_target( who )
{
	self endon( "disconnect" );
	self endon( "death" );
	self.bot.after_target = who;
	self.bot.after_target_pos = who.origin;
	self notify( "kill_after_target" );
	self endon( "kill_after_target" );
	wait self.pers["bots"]["skill"]["shoot_after_time"];
	self.bot.after_target = undefined;
}

clear_bot_after_target()
{
	self.bot.after_target = undefined;
	self notify( "kill_after_target" );
}

aim()
{
	self endon( "disconnect" );
	self endon( "death" );
	for ( ;; )
	{
		wait 0.05;
		if ( level.inPrematchPeriod || level.gameEnded || self.bot.isfrozen || self maps\mp\_flashgrenades::isFlashbanged() )
			continue;
		self aim_loop();
	}
}

botFire()
{
	self.bot.last_fire_time = getTime();
	if ( self.bot.is_cur_full_auto )
	{
		self thread pressFire();
		return;
	}
	if ( self.bot.semi_time )
		return;
	self thread pressFire();
	self thread doSemiTime();
}

doSemiTime()
{
	self endon( "death" );
	self endon( "disconnect" );
	self notify( "bot_semi_time" );
	self endon( "bot_semi_time" );
	self.bot.semi_time = true;
	wait self.pers["bots"]["skill"]["semi_time"];
	self.bot.semi_time = false;
}

canFire( curweap )
{
	if ( curweap == "none" )
		return false;
	return self GetWeaponammoclip( curweap );
}

canAds( dist, curweap )
{
	if ( curweap == "none" )
		return false;
	// bots_play_ads hardcoded to 1
	far = level.bots_noADSDistance;
	if ( self hasPerk( "specialty_bulletaccuracy" ) )
		far *= 1.4;
	if ( dist < far )
		return false;
	weapclass = ( weaponClass( curweap ) );
	if ( weapclass == "spread" || weapclass == "grenade" )
		return false;
	return true;
}

isInRange( dist, curweap )
{
	if ( curweap == "none" )
		return false;
	weapclass = weaponClass( curweap );
	if ( weapclass == "spread" && dist > level.bots_maxShotgunDistance )
		return false;
	return true;
}

killWalkCauseNoWaypoints()
{
	self endon( "disconnect" );
	self endon( "death" );
	self endon( "kill_goal" );
	wait 2;
	self notify( "kill_goal" );
}

walk()
{
	self endon( "disconnect" );
	self endon( "death" );
	for ( ;; )
	{
		wait 0.05;
		self botMoveTo( self.origin );
		// bots_play_move hardcoded to 1, so no check
		if ( level.inPrematchPeriod || level.gameEnded || self.bot.isfrozen || self.bot.stop_move )
			continue;
		if ( self maps\mp\_flashgrenades::isFlashbanged() )
		{
			self.bot.last_next_wp = -1;
			self.bot.last_second_next_wp = -1;
			self botMoveTo( self.origin + self GetVelocity() * 500 );
			continue;
		}
		self walk_loop();
	}
}

watchOnGoal( goal, dis )
{
	self endon( "disconnect" );
	self endon( "death" );
	self endon( "kill_goal" );
	while ( DistanceSquared( self.origin, goal ) > dis )
		wait 0.05;
	self notify( "goal_internal" );
}

cleanUpAStar( team )
{
	self waittill_any( "death", "disconnect", "kill_goal" );
	for ( i = self.bot.astar.size - 1; i >= 0; i-- )
		RemoveWaypointUsage( self.bot.astar[i], team );
}

initAStar( goal )
{
	team = undefined;
	if ( level.teamBased )
		team = self.team;
	self.bot.astar = AStarSearch( self.origin, goal, team, self.bot.greedy_path );
	if ( isDefined( team ) )
		self thread cleanUpAStar( team );
	return self.bot.astar.size - 1;
}

removeAStar()
{
	remove = self.bot.astar.size - 1;
	if ( level.teamBased )
		RemoveWaypointUsage( self.bot.astar[remove], self.team );
	self.bot.astar[remove] = undefined;
	return self.bot.astar.size - 1;
}

killWalkOnEvents()
{
	self endon( "kill_goal" );
	self endon( "disconnect" );
	self endon( "death" );
	self waittill_any( "flash_rumble_loop", "new_enemy", "new_goal_internal", "goal_internal", "bad_path_internal" );
	waittillframeend;
	self notify( "kill_goal" );
}

doWalkScriptNotify()
{
	self endon( "disconnect" );
	self endon( "death" );
	self endon( "kill_goal" );
	if ( self waittill_either_return( "goal_internal", "bad_path_internal" ) == "goal_internal" )
		self notify( "goal" );
	else
		self notify( "bad_path" );
}

doWalk( goal, dist, isScriptGoal )
{
	level endon ( "game_ended" );
	self endon( "kill_goal" );
	self endon( "goal_internal" );
	dist *= dist;
	if ( isScriptGoal )
		self thread doWalkScriptNotify();
	self thread killWalkOnEvents();
	self thread watchOnGoal( goal, dist );
	current = self initAStar( goal );
	if ( current > 0 && self.bot.astar[current] == self.bot.last_next_wp && self.bot.astar[current - 1] == self.bot.last_second_next_wp )
		current = self removeAStar();
	if ( current >= 0 )
	{
		if ( DistanceSquared( self.origin, level.waypoints[self.bot.astar[current]].origin ) < DistanceSquared( self.origin, goal ) || DistanceSquared( level.waypoints[self.bot.astar[current]].origin, PlayerPhysicsTrace( self.origin + ( 0, 0, 32 ), level.waypoints[self.bot.astar[current]].origin, false, self ) ) > 1.0 )
		{
			while ( current >= 0 )
			{
				self.bot.next_wp = self.bot.astar[current];
				self.bot.second_next_wp = -1;
				if ( current > 0 )
					self.bot.second_next_wp = self.bot.astar[current - 1];
				self notify( "new_static_waypoint" );
				self movetowards( level.waypoints[self.bot.next_wp].origin );
				self.bot.last_next_wp = self.bot.next_wp;
				self.bot.last_second_next_wp = self.bot.second_next_wp;
				current = self removeAStar();
			}
		}
	}
	self.bot.next_wp = -1;
	self.bot.second_next_wp = -1;
	self notify( "finished_static_waypoints" );
	if ( DistanceSquared( self.origin, goal ) > dist )
	{
		self.bot.last_next_wp = -1;
		self.bot.last_second_next_wp = -1;
		self movetowards( goal );
	}
	self notify( "finished_goal" );
	wait 1;
	if ( DistanceSquared( self.origin, goal ) > dist )
		self notify( "bad_path_internal" );
}

doMantle()
{
	self endon( "disconnect" );
	self endon( "death" );
	self endon( "kill_goal" );
	self jump();
	self crouch();
	wait 0.35;
	self stand();
	self jump();
}

getRandomLargestStafe( dist )
{
	traces = NewHeap( ::HeapTraceFraction );
	myOrg = self.origin + ( 0, 0, 16 );
	traces HeapInsert( bulletTrace( myOrg, myOrg + ( -100 * dist, 0, 0 ), false, self ) );
	traces HeapInsert( bulletTrace( myOrg, myOrg + ( 100 * dist, 0, 0 ), false, self ) );
	traces HeapInsert( bulletTrace( myOrg, myOrg + ( 0, 100 * dist, 0 ), false, self ) );
	traces HeapInsert( bulletTrace( myOrg, myOrg + ( 0, -100 * dist, 0 ), false, self ) );
	traces HeapInsert( bulletTrace( myOrg, myOrg + ( -100 * dist, -100 * dist, 0 ), false, self ) );
	traces HeapInsert( bulletTrace( myOrg, myOrg + ( -100 * dist, 100 * dist, 0 ), false, self ) );
	traces HeapInsert( bulletTrace( myOrg, myOrg + ( 100 * dist, -100 * dist, 0 ), false, self ) );
	traces HeapInsert( bulletTrace( myOrg, myOrg + ( 100 * dist, 100 * dist, 0 ), false, self ) );
	toptraces = [];
	top = traces.data[0];
	toptraces[toptraces.size] = top;
	traces HeapRemove();
	while ( traces.data.size && top["fraction"] - traces.data[0]["fraction"] < 0.1 )
	{
		toptraces[toptraces.size] = traces.data[0];
		traces HeapRemove();
	}
	return toptraces[randomInt( toptraces.size )]["position"];
}

knife()
{
	self endon( "death" );
	self endon( "disconnect" );
	self notify( "bot_knife" );
	self endon( "bot_knife" );
	self.bot.isknifing = true;
	self.bot.isknifingafter = true;
	self botAction( "+melee" );
	wait 0.05;
	self botAction( "-melee" );
	self.bot.isknifing = false;
	wait 1;
	self.bot.isknifingafter = false;
}

reload()
{
	self endon( "death" );
	self endon( "disconnect" );
	self notify( "bot_reload" );
	self endon( "bot_reload" );
	self botAction( "+reload" );
	wait 0.05;
	self botAction( "-reload" );
	self.bot.isreloading = true;
	while ( true )
	{
		ret = self waittill_any_timeout( 7.5, "reload" );
		if ( ret == "timeout" )
			break;
		weap = self GetCurrentWeapon();
		if ( weap == "none" )
			break;
		if ( self GetWeaponAmmoClip( weap ) >= WeaponClipSize( weap ) )
			break;
	}
	self.bot.isreloading = false;
}

smart_reload_watch()
{
	self endon( "disconnect" );
	self endon( "death" );
	for ( ;; )
	{
		wait 0.5;
		if ( self.bot.isreloading || self.bot.isfrozen || self.bot.isfraggingafter || self.bot.issmokingafter )
			continue;
		hasTargetInFOV = false;
		if ( isDefined( self.bot.target ) && isDefined( self.bot.target.entity ) )
		{
			if ( self.bot.target.trace_time > 0 || self.bot.target.no_trace_time < 1000 )
				hasTargetInFOV = true;
		}
		if ( hasTargetInFOV )
			continue;
		else
			self botAction( "-ads" );
		curweap = self GetCurrentWeapon();
		if ( curweap == "none" || curweap == "" )
			continue;
		if ( IsWeaponClipOnly( curweap ) || !self GetWeaponAmmoStock( curweap ) )
			continue;
		maxsize = WeaponClipSize( curweap );
		cursize = self GetWeaponAmmoClip( curweap );
		missing = maxsize - cursize;
		if ( missing >= 10 )
		{
			self thread reload();
			self botAction( "-ads" );
			wait 7;
		}
	}
}

frag( time )
{
	self endon( "death" );
	self endon( "disconnect" );
	self notify( "bot_frag" );
	self endon( "bot_frag" );
	if ( !isDefined( time ) )
		time = 0.05;
	self botAction( "+frag" );
	self.bot.isfragging = true;
	self.bot.isfraggingafter = true;
	if ( time )
		wait time;
	self botAction( "-frag" );
	self.bot.isfragging = false;
	wait 1.25;
	self.bot.isfraggingafter = false;
}

smoke( time )
{
	self endon( "death" );
	self endon( "disconnect" );
	self notify( "bot_smoke" );
	self endon( "bot_smoke" );
	if ( !isDefined( time ) )
		time = 0.05;
	self botAction( "+smoke" );
	self.bot.issmoking = true;
	self.bot.issmokingafter = true;
	if ( time )
		wait time;
	self botAction( "-smoke" );
	self.bot.issmoking = false;
	wait 1.25;
	self.bot.issmokingafter = false;
}

use( time )
{
	self endon( "death" );
	self endon( "disconnect" );
	self notify( "bot_use" );
	self endon( "bot_use" );
	if ( !isDefined( time ) )
		time = 0.05;
	self botAction( "+activate" );
	if ( time )
		wait time;
	self botAction( "-activate" );
}

pressFire( time )
{
	self endon( "death" );
	self endon( "disconnect" );
	self notify( "bot_fire" );
	self endon( "bot_fire" );
	if ( !isDefined( time ) )
		time = 0.05;
	curweap = self getCurrentWeapon();
	if ( curweap != "none" && self playerADS() > 0.5 )
	{
		pitchKick = -0.3;
		yawKick = -0.3;
		if ( self.bot.is_cur_sniper ) {
			pitchKick = randomFloatRange(-0.3, 0.3);
			yawKick = randomFloatRange(-0.5, 0.5);
		} else if ( weaponClass( curweap ) == "lmg" ) {
			pitchKick = randomFloatRange(-0.3, 0.3);
			yawKick = randomFloatRange(-0.5, 0.5);
		} else if ( weaponClass( curweap ) == "smg" ) {
			pitchKick = randomFloatRange(-0.3, 0.3);
			yawKick = randomFloatRange(-0.5, 0.5);
		} else {
			pitchKick = randomFloatRange(-0.3, 0.3);
			yawKick = randomFloatRange(-0.5, 0.5);
		}
		currentAngles = self getPlayerAngles();
		newAngles = ( currentAngles[0] + pitchKick, currentAngles[1] + yawKick, currentAngles[2] );
		self setPlayerAngles( newAngles );
	}
	self botAction( "+fire" );
	if ( time )
		wait time;
	self botAction( "-fire" );
}

pressADS( time )
{
	self endon( "death" );
	self endon( "disconnect" );
	self endon( "kill_goal" );
	self notify( "bot_ads" );
	self endon( "bot_ads" );
	if ( !isDefined( time ) )
		time = 0.5;
	self botAction( "+ads" );
	if ( time )
		wait time;
	self botAction( "-ads" );
}

jump()
{
	self endon( "death" );
	self endon( "disconnect" );
	self notify( "bot_jump" );
	self endon( "bot_jump" );
	if ( self getStance() != "stand" )
	{
		self stand();
		wait 1;
	}
	self botAction( "+gostand" );
	wait 0.05;
	self botAction( "-gostand" );
}

stand()
{
	self botAction( "-gocrouch" );
	self botAction( "-goprone" );
}

crouch()
{
	self botAction( "+gocrouch" );
	self botAction( "-goprone" );
}

prone()
{
	self botAction( "-gocrouch" );
	self botAction( "+goprone" );
}

doBotMovement_loop( data )
{
	angles = self GetPlayerAngles();
	if ( self isMantling() )
	{
		data.wasMantling = true;
		self crouch();
	}
	else if ( data.wasMantling )
	{
		data.wasMantling = false;
		self stand();
	}
	startPos = self.origin + ( 0, 0, 50 );
	startPosForward = startPos + anglesToForward( ( 0, angles[1], 0 ) ) * 25;
	btEye = bulletTrace( startPos, startPosForward, false, self );
	if ( btEye["fraction"] < 1 && !self isOnLadder() )
	{
		data.stuckTicks++;
		if ( data.stuckTicks <= 3 )
		{
			backwardVec = anglesToForward( ( 0, angles[1] + 180, 0 ) ) * 150;
			self botMoveTo( self.origin + backwardVec );
			randomDir = self getRandomLargestStafe( 50 );
			self botMoveTo( randomDir );
			self setPlayerAngles( ( 0, angles[1], 0 ) );
			if ( isDefined( self.bot.stable_walk_goal ) )
			    self.bot.stable_walk_goal = undefined;
		}
		else if ( data.stuckTicks <= 8 )
		{
			data.i = 0;
			self doMantle();
			self crouch();
			self stand();
			normal = btEye["normal"];
			perpDir = ( 0 - normal[1], normal[0], 0 );
			if ( randomInt( 2 ) == 0 ) perpDir = ( normal[1], 0 - normal[0], 0 );
			lookPoint = self.origin + ( perpDir[0] * 100, perpDir[1] * 100, 0 );
			self botLookAt( lookPoint, 1.5 );
			self botMoveTo( self.origin + ( perpDir[0] * 40, perpDir[1] * 40, 0 ) );
			randomDir = self getRandomLargestStafe( 50 );
			self botMoveTo( randomDir );
			if ( isDefined( self.bot.stable_walk_goal ) )
			    self.bot.stable_walk_goal = undefined;
		}
		else
		{
			backwardVec = anglesToForward( ( 0, angles[1] + 180, 0 ) ) * 150;
			self botMoveTo( self.origin + backwardVec );
			self setPlayerAngles( ( 0, angles[1], 0 ) );
			if ( isDefined( self.bot.stable_walk_goal ) )
			    self.bot.stable_walk_goal = undefined;
			data.stuckTicks = 0;
		}
	}
}

movetowards( goal )
{
	if ( !isDefined( goal ) )
		return;
	self.bot.towards_goal = goal;
	if ( self.bot.issprinting )
		tempGoalDist = level.bots_goalDistance * 2;
	else
		tempGoalDist = level.bots_goalDistance;
	lastOri = self.origin;
	stucks = 0;
	timeslow = 0;
	time = 0;
	while ( distanceSquared( self.origin, goal ) > tempGoalDist )
	{
		dirToGoal = VectorNormalize( goal - self.origin );
		eyePos = self.origin + (0,0,50);
		angles = self GetPlayerAngles();
		frameWait = 0.05;
		if ( self isOnLadder() )
		{
			self botMoveTo( goal );
		}
		else
		{
			fwdTrace = bulletTrace( eyePos, eyePos + dirToGoal * 5, false, self );
			if ( fwdTrace["fraction"] < 1.0 )
			{
				backwardVec = anglesToForward( ( 0, angles[1] + 180, 0 ) ) * 40;
				self botMoveTo( self.origin + backwardVec );
				wait 0.2;
				normal = fwdTrace["normal"];
				perpDir = ( 0 - normal[1], normal[0], 0 );
				if ( randomInt( 2 ) == 0 ) perpDir = ( normal[1], 0 - normal[0], 0 );
				self botMoveTo( self.origin + perpDir * 40 );
				wait 0.2;
				stucks++;
				frameWait = 0;
			}
			else
			{
				checkTrace = bulletTrace( eyePos, eyePos + dirToGoal * 40, false, self );
				if ( checkTrace["fraction"] >= 1.0 )
					self botMoveTo( goal );
			}
			if ( time > 1000 )
			{
				time = 0;
				if ( distanceSquared( self.origin, lastOri ) < 32 * 32 )
				{
					stucks++;
					self BotNotifyBotEvent( "stuck" );
					self.bot.last_next_wp = -1;
					self.bot.last_second_next_wp = -1;
				}
				lastOri = self.origin;
			}
			else if ( time == 1200 )
			{
				if ( distanceSquared( self.origin, lastOri ) < 32 * 32 )
				{
					checkTrace = bulletTrace( eyePos, eyePos + dirToGoal * 40, false, self );
					if ( checkTrace["fraction"] >= 1.0 )
						self crouch();
				}
			}
		}
		if ( frameWait > 0 )
			wait frameWait;
		time += 50;
		if ( lengthsquared( self getVelocity() ) < 1000 )
			timeslow += 50;
		else
			timeslow = 0;
		if ( self.bot.issprinting )
			tempGoalDist = level.bots_goalDistance * 2;
		else
			tempGoalDist = level.bots_goalDistance;
		if ( stucks >= 5 )
		{
			self notify( "bad_path_internal" );
			return;
		}
	}
	self.bot.towards_goal = undefined;
	self notify( "completed_move_to" );
}

walk_loop()
{
	hasTarget = isDefined( self.bot.target ) && isDefined( self.bot.target.entity );
	if ( hasTarget )
	{
		curweap = self getCurrentWeapon();
		if ( self.bot.target.entity.classname == "script_vehicle" || self.bot.isfraggingafter || self.bot.issmokingafter )
			return;
		if ( self.bot.target.isplay && self.bot.target.trace_time && self canFire( curweap ) && self isInRange( self.bot.target.dist, curweap ) )
		{
			if ( self GetStance() == "prone" || ( self.bot.is_cur_sniper && self PlayerADS() > 0 ) )
				return;
			return;
		}
	}
	dist = 16;
	if ( level.waypointCount )
		goal = level.waypoints[randomInt( level.waypointCount )].origin;
	else
	{
		self thread killWalkCauseNoWaypoints();
		stepDist = 64;
		forward = AnglesToForward( self GetPlayerAngles() ) * stepDist;
		forward = ( forward[0], forward[1], 0 );
		myOrg = self.origin + ( 0, 0, 32 );
		goal = playerPhysicsTrace( myOrg, myOrg + forward, false, self );
		goal = PhysicsTrace( goal + ( 0, 0, 50 ), goal + ( 0, 0, -40 ), false, self );
		if ( DistanceSquared( goal, myOrg ) < stepDist * stepDist - 1 || randomInt( 100 ) < 5 )
		{
			trace = bulletTrace( myOrg, myOrg + forward, false, self );
			if ( trace["surfacetype"] == "none" || randomInt( 100 ) < 25 )
			{
				dir = ( 0, randomIntRange( -180, 180 ), 0 );
				goal = playerPhysicsTrace( myOrg, myOrg + AnglesToForward( dir ) * stepDist, false, self );
				goal = PhysicsTrace( goal + ( 0, 0, 50 ), goal + ( 0, 0, -40 ), false, self );
			}
			else
			{
				d = VectorNormalize( trace["position"] - myOrg );
				n = trace["normal"];
				r = d - 2 * ( VectorDot( d, n ) ) * n;
				goal = playerPhysicsTrace( myOrg, myOrg + ( r[0], r[1], 0 ) * stepDist, false, self );
				goal = PhysicsTrace( goal + ( 0, 0, 50 ), goal + ( 0, 0, -40 ), false, self );
			}
		}
	}
	isScriptGoal = false;
	if ( isDefined( self.bot.script_goal ) && !hasTarget )
	{
		goal = self.bot.script_goal;
		dist = self.bot.script_goal_dist;
		isScriptGoal = true;
	}
	else
	{
		if ( hasTarget )
			goal = self.bot.target.last_seen_pos;
		self notify( "new_goal_internal" );
	}
	self doWalk( goal, dist, isScriptGoal );
	self.bot.towards_goal = undefined;
	self.bot.next_wp = -1;
	self.bot.second_next_wp = -1;
}

updateAimOffset( obj )
{
	if ( !isDefined( obj.aim_offset_base ) )
	{
		diffAimAmount = self.pers["bots"]["skill"]["aim_offset_amount"];
		if ( diffAimAmount > 0 )
			obj.aim_offset_base = ( randomFloatRange( 0 - diffAimAmount, diffAimAmount ),
			        randomFloatRange( 0 - diffAimAmount, diffAimAmount ),
			        randomFloatRange( 0 - diffAimAmount, diffAimAmount ) );
		else
			obj.aim_offset_base = ( 0, 0, 0 );
	}
	aimDiffTime = self.pers["bots"]["skill"]["aim_offset_time"] * 1000;
	objCreatedFor = obj.trace_time;
	if ( objCreatedFor >= aimDiffTime )
		offsetScalar = 0;
	else
		offsetScalar = 0.15 - objCreatedFor / aimDiffTime;
	obj.aim_offset = obj.aim_offset_base * offsetScalar;
}

targetObjUpdateTraced( obj, daDist, ent, theTime, isScriptObj )
{
	distClose = self.pers["bots"]["skill"]["dist_start"];
	distClose *= self.bot.cur_weap_dist_multi;
	distClose *= distClose;
	distMax = self.pers["bots"]["skill"]["dist_max"];
	distMax *= self.bot.cur_weap_dist_multi;
	distMax *= distMax;
	timeMulti = 1;
	if ( !isScriptObj )
	{
		if ( daDist > distMax )
			timeMulti = 0;
		else if ( daDist > distClose )
			timeMulti = 1 - ( ( daDist - distClose ) / ( distMax - distClose ) );
	}
	obj.no_trace_time = 0;
	obj.trace_time += int( 50 * timeMulti );
	obj.dist = daDist;
	obj.last_seen_pos = ent.origin;
	obj.trace_time_time = theTime;
	self updateAimOffset( obj );
}

targetObjUpdateNoTrace( obj )
{
	obj.no_trace_time += 50;
	obj.trace_time = 0;
	obj.didlook = false;
}

target_loop()
{
	myEye = self GetEyePos();
	theTime = getTime();
	myAngles = self GetPlayerAngles();
	myFov = 0.85;
	bestTargets = [];
	bestTime = 2147483647;
	rememberTime = self.pers["bots"]["skill"]["remember_time"];
	initReactTime = self.pers["bots"]["skill"]["init_react_time"];
	hasTarget = isDefined( self.bot.target );
	adsAmount = self PlayerADS();
	adsFovFact = 0.95;
	if ( self isOnLadder() )
		return;
	if ( adsAmount > 0 )
		myFov = 0.95;
	if ( hasTarget && !isDefined( self.bot.target.entity ) )
	{
		self.bot.target = undefined;
		hasTarget = false;
	}
	playercount = level.players.size;
	for ( i = 0; i < playercount; i++ )
	{
		player = level.players[i];
		if ( !player IsPlayerModelOK() )
			continue;
		if ( player == self )
			continue;
		if ( (isDefined( player.hidden ) && player.hidden) || (isDefined( player.ishidden ) && player.ishidden) )
		{
			key = player getEntityNumber() + "";
			if ( isDefined( self.bot.targets[key] ) )
				self.bot.targets[key] = undefined;
			continue;
		}
		key = player getEntityNumber() + "";
		obj = self.bot.targets[key];
		daDist = distanceSquared( self.origin, player.origin );
		isObjDef = isDefined( obj );
		if ( ( level.teamBased && self.team == player.team ) || player.sessionstate != "playing" || !isAlive( player ) )
		{
			if ( isObjDef )
				self.bot.targets[key] = undefined;
			continue;
		}
		targetHead = player getTagOrigin( "j_head" );
		targetAnkleLeft = player getTagOrigin( "j_ankle_le" );
		targetAnkleRight = player getTagOrigin( "j_ankle_ri" );
		traceHead = bulletTrace( myEye, targetHead, false, self );
		traceAnkleLeft = bulletTrace( myEye, targetAnkleLeft, false, self );
		traceAnkleRight = bulletTrace( myEye, targetAnkleRight, false, self );
		canTargetPlayer = ( ( sightTracePassed( myEye, targetHead, false, self ) ||
		            sightTracePassed( myEye, targetAnkleLeft, false, self ) ||
		            sightTracePassed( myEye, targetAnkleRight, false, self ) )
		        && ( ( traceHead["fraction"] >= 1.0 || traceHead["surfacetype"] == "glass" ) ||
		            ( traceAnkleLeft["fraction"] >= 1.0 || traceAnkleLeft["surfacetype"] == "glass" ) ||
		            ( traceAnkleRight["fraction"] >= 1.0 || traceAnkleRight["surfacetype"] == "glass" ) )
		        && ( SmokeTrace( myEye, player.origin, level.smokeRadius ) ||
		            daDist < level.bots_maxKnifeDistance * 4 )
		        && ( getConeDot( player.origin, self.origin, myAngles ) >= myFov ||
		            ( isObjDef && obj.trace_time ) ) );
		if ( isDefined( self.bot.target_this_frame ) && self.bot.target_this_frame == player )
		{
			self.bot.target_this_frame = undefined;
			canTargetPlayer = true;
		}
		if ( canTargetPlayer )
		{
			if ( !isObjDef )
			{
				obj = self createTargetObj( player, theTime );
				self.bot.targets[key] = obj;
			}
			self targetObjUpdateTraced( obj, daDist, player, theTime, false );
		}
		else
		{
			if ( !isObjDef )
				continue;
			self targetObjUpdateNoTrace( obj );
			if ( obj.no_trace_time > rememberTime )
			{
				self.bot.targets[key] = undefined;
				continue;
			}
		}
		if ( !isdefined( obj ) )
			continue;
		if ( theTime - obj.time < initReactTime )
			continue;
		timeDiff = theTime - obj.trace_time_time;
		if ( timeDiff < bestTime )
		{
			bestTargets = [];
			bestTime = timeDiff;
		}
		if ( timeDiff == bestTime )
			bestTargets[key] = obj;
	}
	bestKeys = getArrayKeys( bestTargets );
	closest = 2147483647;
	toBeTarget = undefined;
	for ( i = bestKeys.size - 1; i >= 0; i-- )
	{
		theDist = bestTargets[bestKeys[i]].dist;
		if ( theDist > closest )
			continue;
		closest = theDist;
		toBeTarget = bestTargets[bestKeys[i]];
	}
	beforeTargetID = -1;
	newTargetID = -1;
	if ( hasTarget && isDefined( self.bot.target.entity ) )
		beforeTargetID = self.bot.target.entity getEntityNumber();
	if ( isDefined( toBeTarget ) && isDefined( toBeTarget.entity ) )
		newTargetID = toBeTarget.entity getEntityNumber();
	if ( beforeTargetID != newTargetID )
	{
		if ( isDefined( self.bot.target_switch_time ) && getTime() - self.bot.target_switch_time < 400 )
			return;
		self.bot.target = toBeTarget;
		self.bot.target_switch_time = getTime();
		self notify( "new_enemy" );
	}
}

aim_loop()
{
	aimspeed = 0.115;
	if ( self IsStunned() || self isArtShocked() )
		aimspeed *= 10;
	if ( isDefined( self.bot.target_switch_time ) && getTime() - self.bot.target_switch_time < 400 )
		aimspeed *= 5;
	eyePos = self getEyePos();
	curweap = self getCurrentWeapon();
	angles = self GetPlayerAngles();
	adsAmount = self PlayerADS();
	adsAimSpeedFact = self.pers["bots"]["skill"]["ads_aimspeed_multi"];
	if ( adsAmount > 0 )
		aimspeed *= (0.5 + adsAimSpeedFact * adsAmount);
	if ( isDefined( self.bot.target ) && isDefined( self.bot.target.entity ) )
	{
		no_trace_time = self.bot.target.no_trace_time;
		no_trace_look_time = self.pers["bots"]["skill"]["no_trace_look_time"];
		if ( no_trace_time <= no_trace_look_time )
		{
			trace_time = self.bot.target.trace_time;
			last_pos = self.bot.target.last_seen_pos;
			target = self.bot.target.entity;
			conedot = 0;
			isplay = self.bot.target.isplay;
			offset = ( 0, 0, 0 );
			aimoffset = ( 0, 0, 0 );
			dist = self.bot.target.dist;
			rand = self.bot.target.rand;
			no_trace_ads_time = self.pers["bots"]["skill"]["no_trace_ads_time"];
			reaction_time = self.pers["bots"]["skill"]["reaction_time"];
			nadeAimOffset = 0;
			fireThreshold = 0.98;
			bone = self.bot.target.bone;
			if ( !isDefined( bone ) )
				bone = "j_spineupper";
			if ( self.bot.isfraggingafter || self.bot.issmokingafter )
				nadeAimOffset = dist / 3000;
			else if ( curweap != "none" &&  weaponClass( curweap ) == "grenade" )
			{
				if ( maps\mp\gametypes\_missions::getWeaponClass( curweap ) == "weapon_projectile" )
					nadeAimOffset = dist / 16000;
				else
					nadeAimOffset = dist / 3000;
			}
			if ( no_trace_time && ( !isDefined( self.bot.after_target ) || self.bot.after_target != target ) )
			{
				if ( no_trace_time > no_trace_ads_time )
				{
					if ( isplay )
					{
						if ( !self.bot.isfraggingafter && !self.bot.issmokingafter )
						{
							nade = self getValidGrenade();
							if ( isDefined( nade ) && rand <= self.pers["bots"]["behavior"]["nade"] && bulletTracePassed( eyePos, eyePos + ( 0, 0, 75 ), false, self ) && bulletTracePassed( last_pos, last_pos + ( 0, 0, 100 ), false, target ) && dist > level.bots_minGrenadeDistance && dist < level.bots_maxGrenadeDistance ) // bots_play_nade hardcoded to 1
							{
								if ( nade == "frag_grenade_mp" )
									self thread frag( 2.5 );
								else
									self thread smoke( 0.5 );
								self notify( "kill_goal" );
							}
						}
					}
				}
			}
			if ( trace_time )
			{
				if ( isplay )
				{
					if ( !target IsPlayerModelOK() )
						return;
					aimpos = target getTagOrigin( bone );
					if ( !isDefined( aimpos ) )
						return;
					targetVelocity = target getVelocity();
					velSq = lengthsquared( targetVelocity );
					if ( velSq > 70000 )
						leadFactor = 0.18;
					else
						leadFactor = 0;
					if ( velSq > 10000 )
					{
						aimpos += targetVelocity * leadFactor;
					}
					aimpos += offset;
					aimpos += aimoffset;
					aimpos += ( 0, 0, nadeAimOffset );
					conedot = getConeDot( aimpos, eyePos, angles );
					actualDist = sqrt( dist );
					fireThreshold = 0.9;
					baseAimSpeed = aimspeed;
					if ( actualDist < 100 ) {
						if ( !self IsStunned() && !self isArtShocked() )
							baseAimSpeed = 0.1;
						fireThreshold = 0.95;
					} else if ( actualDist < 200 ) {
						baseAimSpeed = aimspeed * 1.5;
						fireThreshold = 0.96;
					} else if ( actualDist < 400 ) {
						baseAimSpeed = aimspeed * 2.0;
						fireThreshold = 0.97;
					} else if ( actualDist < 800 ) {
						baseAimSpeed = aimspeed * 3.0;
						fireThreshold = 0.98;
					} else {
						baseAimSpeed = aimspeed * 6.5;
						fireThreshold = 0.99;
					}
					clampedConeDot = conedot;
					if ( clampedConeDot < 0 ) clampedConeDot = 0;
					if ( clampedConeDot > 1 ) clampedConeDot = 1;
					angleDiff = 1.0 - clampedConeDot;
					angleMultiplier = 0.5 + (angleDiff * 1.6);
					dynamicAimSpeed = baseAimSpeed * angleMultiplier;
					// bots_play_aim hardcoded to 1
					self botLookAt( aimpos, dynamicAimSpeed * 1.2 + 0.5);
				}
				if ( isplay && !self.bot.isknifingafter && conedot > 0.95 && dist < level.bots_maxKnifeDistance && trace_time > reaction_time ) // bots_play_knife hardcoded to 1
				{
					self clear_bot_after_target();
					self thread knife();
					return;
				}
				if ( !self canFire( curweap ) || !self isInRange( dist, curweap ) )
					return;
				canADS = ( self canAds( dist, curweap ) && conedot > 0.85 );
				if ( canADS )
				{
					stopAdsOverride = false;
					if ( self.bot.is_cur_sniper )
					{
						if ( self.pers["bots"]["behavior"]["quickscope"] && self.bot.last_fire_time != -1 && getTime() - self.bot.last_fire_time < 1000 )
							stopAdsOverride = true;
						else
							self notify( "kill_goal" );
					}
					if ( !stopAdsOverride )
						self thread pressAds();
				}
				if ( trace_time > reaction_time )
				{
					if ( isplay )
					{
						headPos = target getTagOrigin( "j_head" );
						spinePos = target getTagOrigin( "j_spineupper" );
						canSeeTarget = false;
						if ( isDefined( headPos ) && sightTracePassed( eyePos, headPos, false, self ) )
							canSeeTarget = true;
						else if ( isDefined( spinePos ) && sightTracePassed( eyePos, spinePos, false, self ) )
							canSeeTarget = true;
						else if ( sightTracePassed( eyePos, target.origin + (0,0,40), false, self ) )
							canSeeTarget = true;
						if ( !canSeeTarget )
							return;
					}
					if ( adsAmount > 0.5 )
					{
						if ( !isDefined( self.bot.ads_acquire_time ) )
							self.bot.ads_acquire_time = getTime();
						if ( getTime() - self.bot.ads_acquire_time < 300 )
							return;
					}
					else
					{
						self.bot.ads_acquire_time = undefined;
					}
					if ( ( !canADS || adsAmount >= 1.0 || self GetStance() == "prone" ) && ( conedot > fireThreshold || dist < level.bots_maxKnifeDistance ) ) // bots_play_fire hardcoded to 1
						self botFire();
					if ( isplay )
						self thread start_bot_after_target( target );
				}
				return;
			}
		}
	}
	if ( isDefined( self.bot.after_target ) )
	{
		nadeAimOffset = 0;
		last_pos = self.bot.after_target_pos;
		dist = DistanceSquared( self.origin, last_pos );
		if ( self.bot.isfraggingafter || self.bot.issmokingafter )
			nadeAimOffset = dist / 3000;
		else if ( curweap != "none" &&  weaponClass( curweap ) == "grenade" )
		{
			if ( maps\mp\gametypes\_missions::getWeaponClass( curweap ) == "weapon_projectile" )
				nadeAimOffset = dist / 16000;
			else
				nadeAimOffset = dist / 3000;
		}
		aimpos = last_pos + ( 0, 0, self getEyeHeight() + nadeAimOffset );
		conedot = getConeDot( aimpos, eyePos, angles );
		actualDist = sqrt( dist );
		fireThreshold = 0.95;
		baseAimSpeed = aimspeed;
		if ( actualDist < 100 ) {
			if ( !self IsStunned() && !self isArtShocked() )
				baseAimSpeed = 0.15;
			fireThreshold = 0.95;
		} else if ( actualDist < 200 ) {
			baseAimSpeed = aimspeed * 2.5;
			fireThreshold = 0.96;
		} else if ( actualDist < 400 ) {
			baseAimSpeed = aimspeed * 3.0;
			fireThreshold = 0.97;
		} else if ( actualDist < 800 ) {
			baseAimSpeed = aimspeed * 5.5;
			fireThreshold = 0.98;
		} else {
			baseAimSpeed = aimspeed * 9.5;
			fireThreshold = 0.99;
		}
		clampedConeDot = conedot;
		if ( clampedConeDot < 0 ) clampedConeDot = 0;
		if ( clampedConeDot > 1 ) clampedConeDot = 1;
		angleDiff = 1.0 - clampedConeDot;
		angleMultiplier = 0.5 + (angleDiff * 1.8);
		dynamicAimSpeed = baseAimSpeed * angleMultiplier;
		// bots_play_aim hardcoded to 1
		self botLookAt( aimpos, dynamicAimSpeed * 1.2 + 0.5);
		if ( !self canFire( curweap ) || !self isInRange( dist, curweap ) )
			return;
		canADS = ( self canAds( dist, curweap ) && conedot > 0.9 );
		if ( canADS )
		{
			stopAdsOverride = false;
			if ( self.bot.is_cur_sniper )
			{
				if ( self.pers["bots"]["behavior"]["quickscope"] && self.bot.last_fire_time != -1 && getTime() - self.bot.last_fire_time < 1000 )
					stopAdsOverride = true;
				else
					self notify( "kill_goal" );
			}
			if ( !stopAdsOverride )
				self thread pressAds();
		}
		if ( ( !canADS || adsAmount >= 1.0 || self GetStance() == "prone" ) && ( conedot > fireThreshold || dist < level.bots_maxKnifeDistance ) ) // bots_play_fire hardcoded to 1
			self botFire();
		return;
	}
	if( self playerADS() < 1 )
	{
		if ( self.bot.next_wp != -1 && isDefined( level.waypoints[self.bot.next_wp].angles ) && false )
		{
			forwardPos = anglesToForward( level.waypoints[self.bot.next_wp].angles ) * 1024;
			// bots_play_aim hardcoded to 1
			self botLookAt( eyePos + forwardPos, aimspeed * 1.4 + 1);
		}
		else if ( isDefined( self.bot.script_aimpos ) )
		{
			// bots_play_aim hardcoded to 1
			self botLookAt( self.bot.script_aimpos, aimspeed * 1.4 + 1);
		}
		else
		{
			lookat = undefined;
			if ( self.bot.second_next_wp != -1 && !self.bot.issprinting && !self.bot.climbing )
				lookat = level.waypoints[self.bot.second_next_wp].origin;
			else if ( isDefined( self.bot.towards_goal ) )
				lookat = self.bot.towards_goal;
			if ( isDefined( lookat ) ) // bots_play_aim hardcoded to 1
			{
				wpAimPos = lookat + ( 0, 0, self getEyeHeight() );
				wpConeDot = getConeDot( wpAimPos, eyePos, angles );
				clampedConeDot = wpConeDot;
				if ( clampedConeDot < 0 ) clampedConeDot = 0;
				if ( clampedConeDot > 1 ) clampedConeDot = 1;
				angleDiff = 1.0 - clampedConeDot;
				angleMultiplier = 0.5 + (angleDiff * 2.5);
				wpAimSpeed = aimspeed * angleMultiplier;
				self botLookAt( wpAimPos, wpAimSpeed * 1.2 + 1.5);
			}
		}
	}
}

changeToWeap( weap )
{
#if isSyscallDefined botWeapon
	self botWeapon( weap );
#else
	self setSpawnWeapon( weap );
#endif
}