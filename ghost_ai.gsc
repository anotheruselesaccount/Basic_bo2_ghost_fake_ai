//Basic ghost fake ai for buried.

#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\zombies\_zm_utility;

#using_animtree("zm_buried_ghost");

init_animtree()
{
    scriptmodelsuseanimtree( #animtree );
}

main()
{
}

disable_out_of_playable_area_callback()
{
	if(is_true(level.player_out_of_playable_area_monitor))
		level.player_out_of_playable_area_monitor = false;
}

init()
{
	maps\mp\zombies\_zm_utility::onplayerconnect_callback( ::disable_out_of_playable_area_callback );

	level.round_spawn_func = ::setup_round_logic;
    level.round_wait_func = ::round_wait;

    precachemodel("c_zom_zombie_buried_ghost_woman_fb");
    precachemodel("p6_zm_bu_tower_base");
    precachemodel("zombie_pickup_perk_bottle");
    precachemodel("zombie_z_money_icon");

    new_spawn_points();

	//new ghost spawn locations
    level.custom_spawners = array((-3297.42, 16898, 560.125), 
								(-4501.4, 16864, 560.125), 
								(-5795.37, 16843.3, 560.125), 
								(-5942.36, 18158, 560.125), 
								(-5943.09, 19747.5, 560.125), 
								(-4782.88, 19900.4, 560.125), 
								(-3215.42, 19898.8, 560.125));
	//start_clean_up();
	//get_players()[0] setorigin((-4880.67, 18566.3, 560.125));

    thread spawn_map();
	thread init_powerups();
	box_init();
	for(;;)
	{
		IPrintLn("Current entity amount: " + getentarray().size);
		wait 1;
	}
}

init_powerups()
{
	maps\mp\zombies\_zm_powerups::include_zombie_powerup("replace_max_ammo");
	maps\mp\zombies\_zm_powerups::add_zombie_powerup("replace_max_ammo", "zombie_ammocan", &"ZOMBIE_POWERUP_MAX_AMMO", ::func_should_always_drop, 0, 0, 0); 
	maps\mp\zombies\_zm_powerups::powerup_set_can_pick_up_in_last_stand("replace_max_ammo", 1);

	maps\mp\zombies\_zm_powerups::include_zombie_powerup("replace_double_points");
	maps\mp\zombies\_zm_powerups::add_zombie_powerup("replace_double_points", "zombie_x2_icon", &"ZOMBIE_POWERUP_DOUBLE_POINTS", ::func_should_always_drop, 0, 0, 0); 
	maps\mp\zombies\_zm_powerups::powerup_set_can_pick_up_in_last_stand("replace_double_points", 1);

	maps\mp\zombies\_zm_powerups::include_zombie_powerup("replace_insta_kill");
	maps\mp\zombies\_zm_powerups::add_zombie_powerup("replace_insta_kill", "zombie_skull", &"ZOMBIE_POWERUP_INSTA_KILL", ::func_should_always_drop, 0, 0, 0); 
	maps\mp\zombies\_zm_powerups::powerup_set_can_pick_up_in_last_stand("replace_insta_kill", 1);
	
	maps\mp\zombies\_zm_powerups::include_zombie_powerup("zombie_cash");
	maps\mp\zombies\_zm_powerups::add_zombie_powerup("zombie_cash", "zombie_z_money_icon", &"ZOMBIE_POWERUP_ZOMBIE_CASH", ::func_should_always_drop, 1, 0, 0); 
	maps\mp\zombies\_zm_powerups::powerup_set_can_pick_up_in_last_stand("zombie_cash", 1);

	maps\mp\zombies\_zm_powerups::include_zombie_powerup("random_perk");
	maps\mp\zombies\_zm_powerups::add_zombie_powerup("random_perk", "zombie_pickup_perk_bottle", &"ZOMBIE_POWERUP_RANDOM_PERK", ::func_should_always_drop, 0, 0, 0); 
	maps\mp\zombies\_zm_powerups::powerup_set_can_pick_up_in_last_stand("random_perk", 0);

	flag_wait( "start_zombie_round_logic" );
	
	flag_wait( "begin_spawning" );


	if(isdefined(level._zombiemode_powerup_grab))
		level.original_custom_powerups = level._zombiemode_powerup_grab;

	level._zombiemode_powerup_grab = ::custom_powerup_grab;

    players = get_players();
    score_to_drop = players.size * level.zombie_vars["zombie_score_start_" + players.size + "p"] + level.zombie_vars["zombie_powerup_drop_increment"];
	curr_total_score = 0;

    for ( ;; )
    {
		level waittill("drop_powerup");
        players = get_players();
        for ( i = 0; i < players.size; i++ )
        {
            if ( isdefined( players[i].score_total ) )
                curr_total_score += players[i].score_total;
        }

        if ( curr_total_score > score_to_drop )
        {
            level.zombie_vars["zombie_powerup_drop_increment"] *= 1.14;
            score_to_drop = curr_total_score + level.zombie_vars["zombie_powerup_drop_increment"];
            level.zombie_vars["zombie_drop_item"] = 1;
			get_next_custom_powerup();
            curr_total_score = 0;
        }
        wait 0.5;
    }
}

custom_powerup_grab(s_powerup, e_player)
{
	players = get_players();
	if (s_powerup.powerup_name == "zombie_cash")
        e_player.score += (100 * randomIntRange(5, 16));

	if (s_powerup.powerup_name == "random_perk")
	{
	    for (i = 0; i < players.size; i++ )
		{
		   players[ i ] thread maps\mp\zombies\_zm_perks::give_random_perk();
		}
	}
	if(s_powerup.powerup_name == "replace_double_points")
    {
		level notify("end_double_points");
		for (i = 0; i < players.size; i++ )
		{
			level thread maps\mp\zombies\_zm_powerups::double_points_powerup( self, players[ i ] );
			players[ i ] thread maps\mp\zombies\_zm_powerups::powerup_vo( "double_points" );
			players[ i ] thread monitor_double_points();
		}
	}
	if(s_powerup.powerup_name == "replace_insta_kill")
    {
		level notify("end_instakill");
		for (i = 0; i < players.size; i++ )
		{
			level thread maps\mp\zombies\_zm_powerups::insta_kill_powerup( self, players[ i ] );
			players[ i ] thread maps\mp\zombies\_zm_powerups::powerup_vo( "insta_kill" );
			players[ i ] thread monitor_instakill();
		}
	}
	if(s_powerup.powerup_name == "replace_max_ammo")
    {
		for (i = 0; i < players.size; i++ )
		{
			players[ i ] thread maps\mp\zombies\_zm_powerups::powerup_vo("full_ammo");
			players[ i ] thread maps\mp\zombies\_zm_audio_announcer::playleaderdialogonplayer("full_ammo", players[ i ].team, 5);
			players[ i ] notify( "zmb_max_ammo" );
            players[ i ] notify( "zmb_lost_knife" );
            players[ i ] notify( "zmb_disable_claymore_prompt" );
            players[ i ] notify( "zmb_disable_spikemore_prompt" );
            weapons = players[ i ] getweaponslist(1);
            foreach (weapon in weapons)
            {
                players[ i ] giveMaxAmmo(weapon);
            }
		}
	}

	if(isdefined(level.original_custom_powerups))
		level thread [[level.original_custom_powerups]](s_powerup, e_player);
}

get_next_custom_powerup()
{
	powerup_list = array("replace_max_ammo", "replace_double_points", "replace_insta_kill", "zombie_cash");

	drop = random(powerup_list);

	while(isdefined(level.last_dropped_powerup) && level.last_dropped_powerup == drop)
	{
		drop = random(powerup_list);
		wait .05;
	}
	level.last_dropped_powerup = drop;

	level maps\mp\zombies\_zm_powerups::specific_powerup_drop( drop, level.last_ghost_location );
}

monitor_instakill()
{
	level endon("end_instakill");
	self thread maps\mp\zombies\_zm_audio_announcer::playleaderdialogonplayer("insta_kill", self.team, 5);
	level.instakill = 1;
	wait 30;
	level.instakill = 0;
}

monitor_double_points()
{
	level endon("end_double_points");
	self thread maps\mp\zombies\_zm_audio_announcer::playleaderdialogonplayer("double_points", self.team, 5);
	level.double_points = 1;
	wait 30;
	level.double_points = 0;
}

box_init()
{
    level endon("end_game");
    setdvar( "magic_chest_movable", "0" );

    new_boxes = [];
    new_boxes[ 0 ][ "name" ]  = "start_chest";
    new_boxes[ 0 ][ "origin" ] = (-3238.88, 16349, 560.125);
    new_boxes[ 0 ][ "angles" ] = (0,0,0);

    foreach(new_box in new_boxes) 
	{    
        for ( i = 0; i < level.chests.size; i++ ) 
		{
            if ( level.chests[ i ].script_noteworthy == new_box[ "name" ] ) 
			{            
                level.chests[ i ].origin = new_box[ "origin" ];
                level.chests[ i ].angles = new_box[ "angles" ];
                
                level.chests[ i ].zbarrier.origin = new_box[ "origin" ];
                level.chests[ i ].zbarrier.angles = new_box[ "angles" ];
                
                level.chests[ i ].pandora_light.origin = new_box[ "origin" ];
                level.chests[ i ].pandora_light.angles = new_box[ "angles" ] + vectorScale( ( -1, 0, -1 ), 90 );
                
                level.chests[ i ].unitrigger_stub.origin = new_box[ "origin" ] + ( anglesToRight( new_box[ "angles" ] ) * -22.5 ) ;
                level.chests[ i ].unitrigger_stub.angles = new_box[ "angles" ]; 

                if(!level.chests[ i ].hidden)
                    level.chests[ i ] thread maps\mp\zombies\_zm_magicbox::show_chest();
                
                break;            
            }        
        }
        
        box_rubble = getentarray( new_box[ "name" ] + "_rubble", "script_noteworthy" );
        
        for ( i = 0; i < box_rubble.size; i++ ) 
		{
            box_rubble[ i ].origin = new_box[ "origin" ];
        }
    }
}

new_spawn_points()
{
	level.player_spawn_points = array((-4645.61, 18100.1, 560.125), 
									(-4374.34, 17894.4, 560.125), 
									(-4106.65, 18041.1, 560.125), 
									(-4025.62, 18270.7, 560.125), 
									(-4075.11, 18498.6, 560.125), 
									(-4207.41, 18649, 560.125),
									(-4395.29, 18753.1, 560.125), 
									(-4612.68, 18767.3, 560.125), 
									(-4801.43, 18711.8, 560.125), 
									(-4884.66, 18541.8, 560.125),
									(-4729.89, 18417.6, 560.125),
									(-4614.6, 18260.4, 560.125));

	structs = getstructarray("initial_spawn", "script_noteworthy");
    for(i=0;i<structs.size;i++)
    {
        structs[i].origin = level.player_spawn_points[0];
        structs[i].target = "pf1801_auto2385";
    }
    spawn = GetstructArray( "initial_spawn_points", "targetname" );
    for(i=0;i<spawn.size;i++)
    {
        spawn[i].origin = level.player_spawn_points[i];
		spawn[i].angles = (0,0,0);
    }
	structs = getstructarray("player_respawn_point", "targetname");
	for(i=0;i<structs.size;i++)
    {
		structs[i].origin = level.player_spawn_points[0];
		structs[i].target = "pf1801_auto2385";
	}
	targetforrespawn = getstructarray("pf1801_auto2385", "targetname");
	for(i=0;i<targetforrespawn.size;i++)
    {
		targetforrespawn[i].origin = level.player_spawn_points[i];
	}
}

//list of ghost animations
reference_anims_from_animtree()
{
    dummy_anim_ref = %ai_zombie_ghost_idle;
    dummy_anim_ref = %ai_zombie_ghost_supersprint;
    dummy_anim_ref = %ai_zombie_ghost_walk;
    dummy_anim_ref = %ai_zombie_ghost_melee;
    dummy_anim_ref = %ai_zombie_ghost_pointdrain;
    dummy_anim_ref = %ai_zombie_ghost_float_death;
    dummy_anim_ref = %ai_zombie_ghost_float_death_b;
    dummy_anim_ref = %ai_zombie_ghost_spawn;
    dummy_anim_ref = %ai_zombie_ghost_ground_pain;
    dummy_anim_ref = %ai_zombie_traverse_v1;
    dummy_anim_ref = %ai_zombie_traverse_v5;
    dummy_anim_ref = %ai_zombie_ghost_jump_across_120;
    dummy_anim_ref = %ai_zombie_ghost_jump_down_48;
    dummy_anim_ref = %ai_zombie_ghost_jump_down_72;
    dummy_anim_ref = %ai_zombie_ghost_jump_down_96;
    dummy_anim_ref = %ai_zombie_ghost_jump_down_127;
    dummy_anim_ref = %ai_zombie_ghost_jump_down_154;
    dummy_anim_ref = %ai_zombie_ghost_jump_down_176;
    dummy_anim_ref = %ai_zombie_ghost_jump_down_190;
    dummy_anim_ref = %ai_zombie_ghost_jump_down_222;
    dummy_anim_ref = %ai_zombie_ghost_jump_down_240;
    dummy_anim_ref = %ai_zombie_ghost_jump_up_72;
    dummy_anim_ref = %ai_zombie_ghost_jump_up_96;
    dummy_anim_ref = %ai_zombie_ghost_jump_up_127;
    dummy_anim_ref = %ai_zombie_ghost_jump_up_154;
    dummy_anim_ref = %ai_zombie_ghost_jump_up_176;
    dummy_anim_ref = %ai_zombie_ghost_jump_up_190;
    dummy_anim_ref = %ai_zombie_ghost_jump_up_222;
    dummy_anim_ref = %ai_zombie_ghost_jump_up_240;
    dummy_anim_ref = %ai_zombie_ghost_jump_up_startrailing;
    dummy_anim_ref = %ai_zombie_ghost_jump_down_startrailing;
    dummy_anim_ref = %ai_zombie_ghost_jump_up_48;
    dummy_anim_ref = %ai_zombie_ghost_playing_piano;
}

spawn_ghost()
{
	if(!isdefined(level.ghosts))
		level.ghosts = 0;

	//if(!isdefined(level.ghost_enemy_team))
	//	level.ghost_enemy_team = [];

    level.ghosts++;

    new_ai = spawn("script_model", random(level.custom_spawners));
    new_ai setmodel("c_zom_zombie_buried_ghost_woman_fb");
	new_ai.has_legs = 1;
	new_ai.animname = "ghost_zombie";
    new_ai.zmb_vocals_attack = "zmb_vocals_zombie_attack";
	new_ai setclientfield( "sndGhostAudio", 1 );
    playfx(loadfx("maps/zombie_buried/fx_buried_ghost_spawn"), new_ai.origin);
	
	//set animation for model
	new_ai useanimtree( #animtree );
    new_ai setanim( %ai_zombie_ghost_supersprint );

    new_ai.script_mover = spawn("script_model", new_ai.origin);
    new_ai.script_mover setmodel("zombie_vending_jugg_on");
    new_ai.script_mover.angles = new_ai.angles;
    new_ai.script_mover hide();
    new_ai linkto( new_ai.script_mover );
    new_ai.script_mover.health = 150; //base start health for zombie
    new_ai.script_mover setcandamage(true);
	new_ai.script_mover thread ai_move_logic(new_ai);
    new_ai.script_mover thread ai_damage_callback(new_ai);

    //level.ghost_enemy_team[ level.ghost_enemy_team.size ] = new_ai.script_mover;
}

ai_damage_callback(model)
{
	level endon("end_game");

	level.melee_death_score = 130;
	level.damage_score = 10;
	level.death_score = 100;

	while(isdefined(model))
	{
		self waittill("damage", idamage, attacker, idflags, vpoint, type, victim, vdir, shitloc, psoffsettime, sweapon);
		
		if(is_true(level.instakill))
			self.health = 0;
		
		score = level.damage_score;

		if(is_true(level.double_points))
			score *= score;

		if(self.health > 0)
			attacker.score += score;

		if(self.health <= 0)
		{
			level.ghosts--;
			level.last_ghost_location = model.origin;

			if(type == "MOD_MELEE")
				score = level.melee_death_score;
			else
				score = level.death_score;

			if(is_true(level.double_points))
				score *= 2;

			attacker.score += score;

			attacker.kills += 1;
			attacker.hits += 1;

			playfx(loadfx("maps/zombie_buried/fx_buried_ghost_death"), self.origin);
			attacker playsound("zmb_ai_ghost_death");
			attacker maps\mp\zombies\_zm_stats::increment_client_stat("buried_ghost_killed", 0);
			attacker maps\mp\zombies\_zm_stats::increment_player_stat("buried_ghost_killed");

			model delete();
			self delete();

			level notify("drop_powerup");
		}
		wait .01;
	}
}

spawn_map()
{	
	if(!isdefined(level.custom_map_models))
		level.custom_map_models = [];

	x = -2330.93;
	y = 16069.7;
	
	for(i=0; i<10; i++)
	{
		for(j=0; j<10; j++)
		{
			floor = spawn("script_model", (x, y + j * 507, 560.125));
			floor setmodel("p6_zm_bu_tower_base");
			if(i == 0 || i == 9)
				floor.angles = (0, 0, 0);
			else
			{
				if(j == 0 || j == 9)
					floor.angles = (0, 0, 0);
				else
					floor.angles = (180, 0, 0);
			}
			level.custom_map_models[level.custom_map_models.size] = floor;
		}
		x -= 477;
	}
}

ai_move_logic(ai_model)
{
	level endon("end_game");
	self endon("death");

	self.move_speed = 8 * 15;

	if(level.round_number <= 10)
		self.move_speed = 8 * 10;		
	
	while(isdefined(ai_model))
	{
		targets = get_array_of_closest( self.origin, level.players, undefined, undefined, undefined );

		for(i=0;i<targets.size;i++)
		{
			if(targets[i].sessionstate == "spectator" || targets[i] maps\mp\zombies\_zm_laststand::player_is_in_laststand())
				wait .05;
			else
			{
				target = targets[i];
				break;	
			}
		}
		
        self.favorite_enemy = target;

		if(isdefined(target))
		{
			look_loc = VectorToAngles(target gettagorigin("j_head") - ai_model gettagorigin("j_head"));
            self rotateto((0, look_loc[1], 0), 0.05);

			if(bullettracepassed(self.origin + (0, 0, 75), target.origin + (0, 0, 65), 0, self))
			{
				if(distance(self.origin, target.origin) > 45)
				{
					self moveto(target.origin, distance(self.origin, target.origin) / self.move_speed);
                	wait .2;
				}
				else
				{
					//do attack
					play_sound_at_pos(ai_model.zmb_vocals_attack, ai_model.origin);
					self moveto(self.origin, 1);
					ai_model setanim( %ai_zombie_ghost_melee );
					
					wait .15;

					//damage only if user is still near
					if(distance(self.origin, target.origin) <= 45)
						target dodamage(30, (0, 0, 0));
					
					wait .5;
					ai_model setanim( %ai_zombie_ghost_supersprint );
				}
			}
		}
		wait .05;
	}
}

setup_round_logic()
{
	level endon("end_game");
	level.ghosts = 0;

	for(;;)
	{
		flag_wait("spawn_zombies");

		zombie_spawn_delay = 0.5;
		zombie_intermission_time = 0.5;
		
		if(!isdefined(level.ghost_total))
			level.ghost_total = 6;
				
		wait zombie_intermission_time;

		for(i = 0; i < level.ghost_total; i++)
		{
			while(level.ghosts >= level.zombie_ai_limit)
			{
				wait 1;
			}
			spawn_ghost();
			wait zombie_spawn_delay;
		}

		while(level.ghosts > 0)
		{
			wait 1;
		}

		level waittill("start_of_round");

		level.ghosts = 0;
	}
}

round_wait()
{
    level endon( "restart_round" );

    wait 1;

	while ( true )
	{
		should_wait = 0;

		if ( isdefined( level.is_ghost_round_started ) && [[ level.is_ghost_round_started ]]() )
			should_wait = 1;
		else
			should_wait = level.ghosts > 0 || level.zombie_total > 0 || level.intermission;

		if ( !should_wait )
			return;

		if ( flag( "end_round_wait" ) )
			return;

		wait 1.0;
	}
}

remove_custom_map() //function to remove spawned models which are in the array
{
	level endon("end_game");
	if(isdefined(level.custom_map_models))
	{
		for(i=0;i<level.custom_map_models.size;i++)
		{
			level.custom_map_models[i] delete();
			wait .01;
		}
	}
}

start_clean_up() //remove unneeded entities because of the entity limit. This will crash currently and need some changes
{
    level endon("end_game");

    flag_wait( "start_zombie_round_logic" );
    map_ents = getEntArray();
    foreach(ent in map_ents) 
    {
        if( (isdefined(ent.target) && ent.target == "specialty_weapupgrade") || (isdefined(ent.targetname) && ent.targetname == "specialty_weapupgrade") || (isdefined(ent.script_noteworthy) && ent.script_noteworthy == "specialty_weapupgrade") ) 
        {
        }
        else if( (isdefined(ent.target) && ent.target == "player_volume") || (isdefined(ent.targetname) && ent.targetname == "player_volume") || (isdefined(ent.script_noteworthy) && ent.script_noteworthy == "player_volume") ) 
        {
        }
        else if( (isdefined(ent.target) && ent.target == "start_chest_zbarrier") || (isdefined(ent.targetname) && ent.targetname == "start_chest_zbarrier") || (isdefined(ent.script_noteworthy) && ent.script_noteworthy == "town_chest_zbarrier") ) 
        {
        }
        else if( (isdefined(ent.target) && ent.target == "vending_packapunch") || (isdefined(ent.targetname) && ent.targetname == "vending_packapunch") || (isdefined(ent.script_noteworthy) && ent.script_noteworthy == "vending_packapunch") ) 
        {
        }
        else if( (isdefined(ent.target) && ent.target == "vending_revive") || (isdefined(ent.targetname) && ent.targetname == "vending_revive") || (isdefined(ent.script_noteworthy) && ent.script_noteworthy == "vending_revive") ) 
        {
        }
        else if( (isdefined(ent.target) && ent.target == "clip") || (isdefined(ent.targetname) && ent.targetname == "clip") || (isdefined(ent.script_noteworthy) && ent.script_noteworthy == "clip") ) 
        {
        }
        else if( (isdefined(ent.target) && ent.target == "vending_marathon") || (isdefined(ent.targetname) && ent.targetname == "vending_marathon") || (isdefined(ent.script_noteworthy) && ent.script_noteworthy == "vending_marathon") ) 
        {
        }
        else if( (isdefined(ent.target) && ent.target == "vending_sleight") || (isdefined(ent.targetname) && ent.targetname == "vending_sleight") || (isdefined(ent.script_noteworthy) && ent.script_noteworthy == "vending_sleight") ) 
        {
        }
        else if( (isdefined(ent.target) && ent.target == "vending_doubletap") || (isdefined(ent.targetname) && ent.targetname == "vending_doubletap") || (isdefined(ent.script_noteworthy) && ent.script_noteworthy == "vending_doubletap") ) 
        {
        }
        else if( (isdefined(ent.target) && ent.target == "vending_jugg") || (isdefined(ent.targetname) && ent.targetname == "vending_jugg") || (isdefined(ent.script_noteworthy) && ent.script_noteworthy == "vending_jugg") ) 
        {
        }
        else
        {
            ent delete();
        }
    }
}
