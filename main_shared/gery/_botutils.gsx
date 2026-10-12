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

is_bot()
{
	if( isDefined( self.pers["isBot"] ) && self.pers["isBot"] )
		return true;
	return false;
}

BotPressUse( time )
{
	self gery\_botfunctions::use( time );
}

IsPlayerModelOK()
{
	return ( isDefined( self.bot_model_fix ) );
}

BotFreezeControls( what )
{
	self.bot.isfrozen = what;
	if ( what )
		self notify( "kill_goal" );
}

BotStopMoving( what )
{
	self.bot.stop_move = what;
	if ( what )
		self notify( "kill_goal" );
}

BotNotifyBotEvent( msg, a, b, c, d, e, f, g )
{
	self notify( "bot_event", msg, a, b, c, d, e, f, g );
}

SetAttacker( att )
{
	self.bot.target_this_frame = att;
}

HasThreat()
{
	return ( isDefined( self GetThreat() ) );
}

GetThreat()
{
	if ( !isdefined( self.bot.target ) )
		return undefined;
	return self.bot.target.entity;
}

IsStunned()
{
	return ( isdefined( self.concussionEndTime ) && self.concussionEndTime > gettime() );
}

isArtShocked()
{
	return ( isDefined( self.beingArtilleryShellshocked ) && self.beingArtilleryShellshocked );
}

getValidGrenade()
{
	grenadeTypes = [];
	grenadeTypes[grenadeTypes.size] = "frag_grenade_mp";
	grenadeTypes[grenadeTypes.size] = "smoke_grenade_mp";
	grenadeTypes[grenadeTypes.size] = "flash_grenade_mp";
	grenadeTypes[grenadeTypes.size] = "concussion_grenade_mp";
	possibles = [];
	for ( i = 0; i < grenadeTypes.size; i++ )
	{
		if ( !self hasWeapon( grenadeTypes[i] ) )
			continue;
		if ( !self getAmmoCount( grenadeTypes[i] ) )
			continue;
		possibles[possibles.size] = grenadeTypes[i];
	}
	return Random( possibles );
}

WeaponIsFullAuto( weap )
{
	weaptoks = strtok( weap, "_" );
	return isDefined( weaptoks[0] ) && isString( weaptoks[0] ) && isdefined( level.bots_fullautoguns[weaptoks[0]] );
}

GetEyeHeight()
{
	myEye = self GetEyePos();
	return myEye[2] - self.origin[2];
}

GetEyePos()
{
	return self getTagOrigin( "tag_eye" );
}

allowClassChoice()
{
	return true;
}

allowTeamChoice()
{
	return true;
}

waittill_any_timeout( timeOut, string1, string2, string3, string4, string5 )
{
	if ( ( !isdefined( string1 ) || string1 != "death" ) &&
	    ( !isdefined( string2 ) || string2 != "death" ) &&
	    ( !isdefined( string3 ) || string3 != "death" ) &&
	    ( !isdefined( string4 ) || string4 != "death" ) &&
	    ( !isdefined( string5 ) || string5 != "death" ) )
		self endon( "death" );
	ent = spawnstruct();
	if ( isdefined( string1 ) )
		self thread waittill_string( string1, ent );
	if ( isdefined( string2 ) )
		self thread waittill_string( string2, ent );
	if ( isdefined( string3 ) )
		self thread waittill_string( string3, ent );
	if ( isdefined( string4 ) )
		self thread waittill_string( string4, ent );
	if ( isdefined( string5 ) )
		self thread waittill_string( string5, ent );
	ent thread _timeout( timeOut );
	ent waittill( "returned", msg );
	ent notify( "die" );
	return msg;
}

_timeout( delay )
{
	self endon( "die" );
	wait( delay );
	self notify( "returned", "timeout" );
}

/* Restored helper functions */
waittill_either_return_( str1, str2 )
{
    self endon( str1 );
    self waittill( str2 );
    return true;
}

waittill_either_return( str1, str2 )
{
    if ( !isDefined( self waittill_either_return_( str1, str2 ) ) )
        return str1;
    return str2;
}

waittill_either( not, not1 )
{
    self endon( not );
    self waittill( not1 );
}

/* Helper: select random element from an array */
Random( arr )
{
    size = arr.size;
    if ( !size )
        return undefined;
    return arr[randomInt( size )];
}

/* Helper: convert key code to character (used by external waypoint scripts) */
keyCodeToString( a )
{
    b = "";
    switch ( a )
    {
        case 0:  b = "a"; break;
        case 1:  b = "b"; break;
        case 2:  b = "c"; break;
        case 3:  b = "d"; break;
        case 4:  b = "e"; break;
        case 5:  b = "f"; break;
        case 6:  b = "g"; break;
        case 7:  b = "h"; break;
        case 8:  b = "i"; break;
        case 9:  b = "j"; break;
        case 10: b = "k"; break;
        case 11: b = "l"; break;
        case 12: b = "m"; break;
        case 13: b = "n"; break;
        case 14: b = "o"; break;
        case 15: b = "p"; break;
        case 16: b = "q"; break;
        case 17: b = "r"; break;
        case 18: b = "s"; break;
        case 19: b = "t"; break;
        case 20: b = "u"; break;
        case 21: b = "v"; break;
        case 22: b = "w"; break;
        case 23: b = "x"; break;
        case 24: b = "y"; break;
        case 25: b = "z"; break;
        case 26: b = "."; break;
        case 27: b = " "; break;
    }
    return b;
}
/* -------------------------------------------------------------- */

isItemUnlocked( what, lvl )
{
	switch ( what )
	{
		case "ak47": return true;
		case "ak74u": return true;
		case "barrett": return false;
		case "dragunov": return false;
		case "g3": return false;
		case "g36c": return true;
		case "m1014": return false;
		case "m14": return false;
		case "m16": return true;
		case "m21": return false;
		case "m4": return true;
		case "m40a3": return false;
		case "m60e4": return false;
		case "mp44": return false;
		case "mp5": return false;
		case "p90": return true;
		case "rpd": return false;
		case "saw": return false;
		case "skorpion": return false;
		case "uzi": return false;
		case "winchester1200": return false;
		case "remington700": return false;
		case "beretta": return false;
		case "colt45": return false;
		case "deserteagle": return false;
		case "deserteaglegold": return true;
		case "usp": return false;
		case "specialty_bulletdamage": return true;
		case "specialty_armorvest": return true;
		case "specialty_fastreload": return true;
		case "specialty_rof": return true;
		case "specialty_twoprimaries": return true;
		case "specialty_gpsjammer": return true;
		case "specialty_explosivedamage": return true;
		case "specialty_longersprint": return true;
		case "specialty_bulletaccuracy": return true;
		case "specialty_pistoldeath": return false;
		case "specialty_grenadepulldeath": return false;
		case "specialty_bulletpenetration": return true;
		case "specialty_holdbreath": return false;
		case "specialty_quieter": return true;
		case "specialty_parabolic": return true;
		case "specialty_specialgrenade": return false;
		case "specialty_weapon_rpg": return false;
		case "specialty_weapon_claymore": return false;
		case "specialty_fraggrenade": return false;
		case "specialty_extraammo": return true;
		case "specialty_detectexplosive": return true;
		case "specialty_weapon_c4": return false;
		default: return false;
	}
}

isWeaponDroppable( weap )
{
	return ( maps\mp\gametypes\_weapons::mayDropWeapon( weap ) );
}

array_remove( ents, remover )
{
	newents = [];
	for ( i = 0; i < ents.size; i++ )
	{
		index = ents[i];
		if ( index != remover )
			newents[ newents.size ] = index;
	}
	return newents;
}

waittill_notify_or_timeout( not, tim )
{
	self endon( not );
	wait tim;
}

RaySphereIntersect( start, end, spherePos, radius )
{
	r2 = radius * radius;
	if ( DistanceSquared( start, spherePos ) < r2 )
		return true;
	if ( DistanceSquared( end, spherePos ) < r2 )
		return true;
	dp = end - start;
	a = dp[0] * dp[0] + dp[1] * dp[1] + dp[2] * dp[2];
	b = 2 * ( dp[0] * ( start[0] - spherePos[0] ) + dp[1] * ( start[1] - spherePos[1] ) + dp[2] * ( start[2] - spherePos[2] ) );
	c = spherePos[0] * spherePos[0] + spherePos[1] * spherePos[1] + spherePos[2] * spherePos[2];
	c += start[0] * start[0] + start[1] * start[1] + start[2] * start[2];
	c -= 2.0 * ( spherePos[0] * start[0] + spherePos[1] * start[1] + spherePos[2] * start[2] );
	c -= radius * radius;
	bb4ac = b * b - 4.0 * a * c;
	if ( abs( a ) < 0.0001 || bb4ac < 0 )
		return false;
	mu1 = ( 0 - b + sqrt( bb4ac ) ) / ( 2 * a );
	ip1 = start + mu1 * dp;
	myDist = DistanceSquared( start, end );
	if ( DistanceSquared( start, ip1 ) > myDist )
		return false;
	dpAngles = VectorToAngles( dp );
	if ( getConeDot( ip1, start, dpAngles ) < 0 )
		return false;
	return true;
}

SmokeTrace( start, end, rad )
{
	for ( i = level.bots_smokeList.count - 1; i >= 0; i-- )
	{
		nade = level.bots_smokeList.data[i];
		if ( nade.state != "smoking" )
			continue;
		if ( !RaySphereIntersect( start, end, nade.origin, rad ) )
			continue;
		return false;
	}
	return true;
}

getConeDot( to, from, dir )
{
	dirToTarget = VectorNormalize( to - from );
	forward = AnglesToForward( dir );
	return vectordot( dirToTarget, forward );
}

Round( x )
{
	y = int( x );
	if ( abs( x ) - abs( y ) > 0.5 )
	{
		if ( x < 0 )
			return y - 1;
		else
			return y + 1;
	}
	else
		return y;
}

clamp( a, minv, maxv )
{
	return max( min( a, maxv ), minv );
}

cac_init_patch()
{
	if ( !isDefined( level.tbl_weaponIDs ) )
	{
		level.tbl_weaponIDs = [];
		for ( i = 0; i < 150; i++ )
		{
			reference_s = tableLookup( "mp/statsTable.csv", 0, i, 4 );
			if ( reference_s != "" )
			{
				level.tbl_weaponIDs[i]["reference"] = reference_s;
				level.tbl_weaponIDs[i]["group"] = tablelookup( "mp/statstable.csv", 0, i, 2 );
				level.tbl_weaponIDs[i]["count"] = int( tablelookup( "mp/statstable.csv", 0, i, 5 ) );
				level.tbl_weaponIDs[i]["attachment"] = tablelookup( "mp/statstable.csv", 0, i, 8 );
			}
			else
				continue;
		}
	}
	if ( !isDefined( level.tbl_WeaponAttachment ) )
	{
		level.tbl_WeaponAttachment = [];
		for ( i = 0; i < 8; i++ )
		{
			ref = tableLookup( "mp/attachmentTable.csv", 9, i, 4 );
			if( ref == "gl" )
				continue;
			level.tbl_WeaponAttachment[i]["bitmask"] = int( tableLookup( "mp/attachmentTable.csv", 9, i, 10 ) );
			level.tbl_WeaponAttachment[i]["reference"] = ref;
		}
	}
	if ( !isDefined( level.tbl_PerkData ) )
	{
		level.tbl_PerkData = [];
		for ( i = 150; i < 194; i++ )
		{
			reference_s = tableLookup( "mp/statsTable.csv", 0, i, 4 );
			if ( reference_s != "" )
			{
				level.tbl_PerkData[i]["reference"] = reference_s;
				level.tbl_PerkData[i]["reference_full"] = tableLookup( "mp/statsTable.csv", 0, i, 6 );
				level.tbl_PerkData[i]["count"] = int( tableLookup( "mp/statsTable.csv", 0, i, 5 ) );
				level.tbl_PerkData[i]["group"] = tableLookup( "mp/statsTable.csv", 0, i, 2 );
				level.tbl_PerkData[i]["name"] = tableLookupIString( "mp/statsTable.csv", 0, i, 3 );
				level.tbl_PerkData[i]["perk_num"] = tableLookup( "mp/statsTable.csv", 0, i, 8 );
			}
			else
				continue;
		}
	}
	level.perkReferenceToIndex = [];
	level.weaponReferenceToIndex = [];
	level.weaponAttachmentReferenceToIndex = [];
	for ( i = 0; i < 150; i++ )
	{
		if ( !isDefined( level.tbl_weaponIDs[i] ) || !isDefined( level.tbl_weaponIDs[i]["reference"] ) )
			continue;
		level.weaponReferenceToIndex[level.tbl_weaponIDs[i]["reference"]] = i;
	}
	for ( i = 0; i < 8; i++ )
	{
		if ( !isDefined( level.tbl_WeaponAttachment[i] ) || !isDefined( level.tbl_WeaponAttachment[i]["reference"] ) )
			continue;
		level.weaponAttachmentReferenceToIndex[level.tbl_WeaponAttachment[i]["reference"]] = i;
	}
	for ( i = 150; i < 194; i++ )
	{
		if ( !isDefined( level.tbl_PerkData[i] ) || !isDefined( level.tbl_PerkData[i]["reference_full"] ) )
			continue;
		level.perkReferenceToIndex[ level.tbl_PerkData[i]["reference_full"] ] = i;
	}
}

FrontLinesWaypoints()
{
	waypoints = [];
	for ( i = 0;; i++ )
	{
		dvar_answer = getDvar( "flwp_" + i );
		if ( dvar_answer == "" || dvar_answer == "eof" )
			break;
		toks = strtok( dvar_answer, "," );
		waypoint = spawnStruct();
		wp_num = int( toks[0] );
		x = float( toks[1] );
		y = float( toks[2] );
		z = float( toks[3] );
		waypoint.origin = ( x, y, z );
		waypoint.type = toks[4];
		waypoint.children = [];
		num_children = int( toks[5] );
		for ( h = 0; h < num_children; h++ )
		{
			waypoint.children[waypoint.children.size] = int( toks[6 + h] );
		}
		waypoints[wp_num] = waypoint;
	}
	return waypoints;
}

getABotName()
{
	if ( !isDefined( level.bot_names ) )
	{
		level.bot_names = [];
		filename = "botnames.txt";
		if ( FS_TestFile( filename ) )
		{
			f = FS_FOpen( filename, "read" );
			name = FS_ReadLine( f );
			while ( isDefined( name ) && name != "" )
			{
				level.bot_names[level.bot_names.size] = name;
				name = FS_ReadLine( f );
			}
			FS_FClose( f );
		}
		level.available_bot_names = [];
		for(i = 0; i < level.bot_names.size; i++)
		{
			level.available_bot_names[i] = level.bot_names[i];
		}
	}
	if ( !level.bot_names.size )
		return undefined;
	if ( !isDefined(level.available_bot_names) || level.available_bot_names.size == 0 )
	{
		level.available_bot_names = [];
		for(i = 0; i < level.bot_names.size; i++)
		{
			level.available_bot_names[i] = level.bot_names[i];
		}
	}
	randIdx = randomInt( level.available_bot_names.size );
	chosenName = level.available_bot_names[randIdx];
	newArr = [];
	for(i = 0; i < level.available_bot_names.size; i++)
	{
		if(i != randIdx)
			newArr[newArr.size] = level.available_bot_names[i];
	}
	level.available_bot_names = newArr;
	return chosenName;
}

printToConsole( str )
{
#if isSyscallDefined PrintConsole
	PrintConsole( str + "\n" );
#else
	println( str );
#endif
}

load_waypoints()
{
	mapname = getDvar( "mapname" );
	level.waypointCount = 0;
	level.waypoints = [];
	level.waypointUsage = [];
	level.waypointUsage["allies"] = [];
	level.waypointUsage["axis"] = [];
	switch(mapname)
	{
		case "mp_convoy": level.waypoints = waypoints\ambush::Ambush(); break;
		case "mp_backlot": level.waypoints = waypoints\backlot::Backlot(); break;
		case "mp_bloc": level.waypoints = waypoints\bloc::Bloc(); break;
		case "mp_bog": level.waypoints = waypoints\bog::Bog(); break;
		case "mp_countdown": level.waypoints = waypoints\countdown::Countdown(); break;
		case "mp_crash": case "mp_crash_snow": level.waypoints = waypoints\crash::Crash(); break;
		case "mp_crossfire": level.waypoints = waypoints\crossfire::Crossfire(); break;
		case "mp_citystreets": level.waypoints = waypoints\district::District(); break;
		case "mp_farm": level.waypoints = waypoints\downpour::Downpour(); break;
		case "mp_overgrown": level.waypoints = waypoints\overgrown::Overgrown(); break;
		case "mp_pipeline": level.waypoints = waypoints\pipeline::Pipeline(); break;
		case "mp_shipment": level.waypoints = waypoints\shipment::Shipment(); break;
		case "mp_showdown": level.waypoints = waypoints\showdown::Showdown(); break;
		case "mp_strike": level.waypoints = waypoints\strike::Strike(); break;
		case "mp_vacant": level.waypoints = waypoints\vacant::Vacant(); break;
		case "mp_cargoship": level.waypoints = waypoints\wetwork::Wetwork(); break;
		case "mp_broadcast": level.waypoints = waypoints\broadcast::Broadcast(); break;
		case "mp_creek": level.waypoints = waypoints\creek::Creek(); break;
		case "mp_carentan": level.waypoints = waypoints\chinatown::Chinatown(); break;
		case "mp_killhouse": level.waypoints = waypoints\killhouse::Killhouse(); break;
		default: waypoints\custom::main(mapname); break;
	}
	if (level.waypoints.size)
		printToConsole("Loaded " + level.waypoints.size + " waypoints from script.");
	if ( !level.waypoints.size )
	{
		level.waypoints = FrontLinesWaypoints();
		if ( level.waypoints.size )
			printToConsole( "Loaded " + level.waypoints.size + " waypoints from frontlines." );
	}
	level.waypointCount = level.waypoints.size;
	for ( i = 0; i < level.waypointCount; i++ )
	{
		if ( !isDefined( level.waypoints[i].children ) || !isDefined( level.waypoints[i].children.size ) )
			level.waypoints[i].children = [];
		if ( !isDefined( level.waypoints[i].origin ) )
			level.waypoints[i].origin = ( 0, 0, 0 );
		if ( !isDefined( level.waypoints[i].type ) )
			level.waypoints[i].type = "crouch";
		level.waypoints[i].childCount = undefined;
	}
}

getBotArray()
{
	result = [];
	playercount = level.players.size;
	for ( i = 0; i < playercount; i++ )
	{
		player = level.players[i];
		if ( !player is_bot() )
			continue;
		result[result.size] = player;
	}
	return result;
}

List()
{
	list = spawnStruct();
	list.count = 0;
	list.data = [];
	return list;
}

ListAdd( thing )
{
	self.data[self.count] = thing;
	self.count++;
}

ListRemove( thing )
{
	for ( i = 0; i < self.count; i++ )
	{
		if ( self.data[i] == thing )
		{
			while ( i < self.count - 1 )
			{
				self.data[i] = self.data[i + 1];
				i++;
			}
			self.data[i] = undefined;
			self.count--;
			break;
		}
	}
}

HeapTraceFraction( item, item2 )
{
	return item["fraction"] > item2["fraction"];
}

NewHeap( compare )
{
	heap_node = spawnStruct();
	heap_node.data = [];
	heap_node.compare = compare;
	return heap_node;
}

HeapInsert( item )
{
	insert = self.data.size;
	self.data[insert] = item;
	current = insert + 1;
	while ( current > 1 )
	{
		last = current;
		current = int( current / 2 );
		if ( ![[self.compare]]( item, self.data[current - 1] ) )
			break;
		self.data[last - 1] = self.data[current - 1];
		self.data[current - 1] = item;
	}
}

_HeapNextChild( node, hsize )
{
	left = node * 2;
	right = left + 1;
	if ( left > hsize )
		return -1;
	if ( right > hsize )
		return left;
	if ( [[self.compare]]( self.data[left - 1], self.data[right - 1] ) )
		return left;
	else
		return right;
}

HeapRemove()
{
	remove = self.data.size;
	if ( !remove )
		return remove;
	move = self.data[remove - 1];
	self.data[0] = move;
	self.data[remove - 1] = undefined;
	remove--;
	if ( !remove )
		return remove;
	last = 1;
	next = self _HeapNextChild( 1, remove );
	while ( next != -1 )
	{
		if ( [[self.compare]]( move, self.data[next - 1] ) )
			break;
		self.data[last - 1] = self.data[next - 1];
		self.data[next - 1] = move;
		last = next;
		next = self _HeapNextChild( next, remove );
	}
	return remove;
}

ReverseHeapAStar( item, item2 )
{
	return item.f < item2.f;
}

RemoveWaypointUsage( wp, team )
{
	if ( !isDefined( level.waypointUsage ) )
		return;
	if ( !isDefined( level.waypointUsage[team][wp + ""] ) )
		return;
	level.waypointUsage[team][wp + ""]--;
	if ( level.waypointUsage[team][wp + ""] <= 0 )
		level.waypointUsage[team][wp + ""] = undefined;
}

GetNearestWaypointWithSight( pos )
{
	candidate = undefined;
	dist = 2147483647;
	for ( i = 0; i < level.waypointCount; i++ )
	{
		if ( !bulletTracePassed( pos + ( 0, 0, 15 ), level.waypoints[i].origin + ( 0, 0, 15 ), false, undefined ) )
			continue;
		curdis = DistanceSquared( level.waypoints[i].origin, pos );
		if ( curdis > dist )
			continue;
		dist = curdis;
		candidate = i;
	}
	return candidate;
}

GetNearestWaypoint( pos )
{
	candidate = undefined;
	dist = 2147483647;
	for ( i = 0; i < level.waypointCount; i++ )
	{
		curdis = DistanceSquared( level.waypoints[i].origin, pos );
		if ( curdis > dist )
			continue;
		dist = curdis;
		candidate = i;
	}
	return candidate;
}

AStarSearch( start, goal, team, greedy_path )
{
	open = NewHeap( ::ReverseHeapAStar );
	openset = [];
	closed = [];
	startWp = getNearestWaypoint( start );
	if ( !isDefined( startWp ) )
		return [];
	_startwp = undefined;
	if ( !bulletTracePassed( start + ( 0, 0, 15 ), level.waypoints[startWp].origin + ( 0, 0, 15 ), false, undefined ) )
		_startwp = GetNearestWaypointWithSight( start );
	if ( isDefined( _startwp ) )
		startWp = _startwp;
	goalWp = getNearestWaypoint( goal );
	if ( !isDefined( goalWp ) )
		return [];
	_goalWp = undefined;
	if ( !bulletTracePassed( goal + ( 0, 0, 15 ), level.waypoints[goalWp].origin + ( 0, 0, 15 ), false, undefined ) )
		_goalwp = GetNearestWaypointWithSight( goal );
	if ( isDefined( _goalwp ) )
		goalWp = _goalwp;
	node = spawnStruct();
	node.g = 0;
	node.h = DistanceSquared( level.waypoints[startWp].origin, level.waypoints[goalWp].origin );
	node.f = node.h + node.g;
	node.index = startWp;
	node.parent = undefined;
	openset[node.index + ""] = node;
	open HeapInsert( node );
	while ( open.data.size )
	{
		bestNode = open.data[0];
		open HeapRemove();
		openset[bestNode.index + ""] = undefined;
		wp = level.waypoints[bestNode.index];
		if ( bestNode.index == goalWp )
		{
			path = [];
			while ( isDefined( bestNode ) )
			{
				if ( isdefined( team ) && isDefined( level.waypointUsage ) )
				{
					if ( !isDefined( level.waypointUsage[team][bestNode.index + ""] ) )
						level.waypointUsage[team][bestNode.index + ""] = 0;
					level.waypointUsage[team][bestNode.index + ""]++;
				}
				path[path.size] = bestNode.index;
				bestNode = bestNode.parent;
			}
			return path;
		}
		for ( i = wp.children.size - 1; i >= 0; i-- )
		{
			child = wp.children[i];
			childWp = level.waypoints[child];
			penalty = 1;
			if ( !greedy_path && isdefined( team ) && isDefined( level.waypointUsage ) )
			{
				temppen = 1;
				if ( isDefined( level.waypointUsage[team][child + ""] ) )
					temppen = level.waypointUsage[team][child + ""];
				if ( temppen > 1 )
					penalty = temppen;
			}
			if ( childWp.type == "climb" || childWp.type == "prone" )
				penalty += 4;
			newg = bestNode.g + DistanceSquared( wp.origin, childWp.origin ) * penalty;
			inopen = isDefined( openset[child + ""] );
			if ( inopen && openset[child + ""].g <= newg )
				continue;
			inclosed = isDefined( closed[child + ""] );
			if ( inclosed && closed[child + ""].g <= newg )
				continue;
			node = undefined;
			if ( inopen )
				node = openset[child + ""];
			else if ( inclosed )
				node = closed[child + ""];
			else
				node = spawnStruct();
			node.parent = bestNode;
			node.g = newg;
			node.h = DistanceSquared( childWp.origin, level.waypoints[goalWp].origin );
			node.f = node.g + node.h;
			node.index = child;
			if ( inclosed )
				closed[child + ""] = undefined;
			if ( !inopen )
			{
				open HeapInsert( node );
				openset[child + ""] = node;
			}
		}
		closed[bestNode.index + ""] = bestNode;
	}
	return [];
}

Log( x )
{
	old_sum = 0.0;
	xmlxpl = ( x - 1 ) / ( x + 1 );
	xmlxpl_2 = xmlxpl * xmlxpl;
	denom = 1.0;
	frac = xmlxpl;
	sum = frac;
	while ( sum != old_sum )
	{
		old_sum = sum;
		denom += 2.0;
		frac *= xmlxpl_2;
		sum += frac / denom;
	}
	return 2.0 * sum;
}

random_normal_distribution( mean, std_deviation, lower_bound, upper_bound )
{
	x1 = 0; x2 = 0; w = 1; y1 = 0;
	while ( w >= 1 )
	{
		x1 = 2 * RandomFloatRange( 0, 1 ) - 1;
		x2 = 2 * RandomFloatRange( 0, 1 ) - 1;
		w = x1 * x1 + x2 * x2;
	}
	w = Sqrt( ( -2.0 * Log( w ) ) / w );
	y1 = x1 * w;
	number = mean + y1 * std_deviation;
	if ( IsDefined( lower_bound ) && number < lower_bound )
		number = lower_bound;
	if ( IsDefined( upper_bound ) && number > upper_bound )
		number = upper_bound;
	return ( number );
}

BotIsFrozen()
{
	return self.bot.isfrozen;
}

ClearScriptGoal()
{
	self SetScriptGoal( undefined, 0 );
}

SetScriptGoal( goal, dist )
{
	if ( !isDefined( dist ) )
		dist = 16;

	self.bot.script_goal = goal;
	self.bot.script_goal_dist = dist;
	waittillframeend;
	self notify( "new_goal_internal" );
	self notify( "new_goal" );
}

BotChangeToWeapon( weap )
{
	self gery\_botfunctions::changeToWeap( weap );
}