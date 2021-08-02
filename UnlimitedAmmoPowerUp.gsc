#include maps\mp\_utility;
#include common_scripts\utility;
#include maps\mp\gametypes_zm\_hud_util;
#include maps\mp\gametypes_zm\_hud_message;

//important include
#include maps\mp\zombies\_zm_powerups;

init()
{
   	level thread onPlayerConnect();

	//include and init the powerup
   	include_zombie_powerup("unlimited_ammo");
   	//change the powerup duration if you want
   	level.unlimited_ammo_duration = 30;
   	//shitty model, cant find a good model list so cba
   	//change to w/e if you have some nice model
   	add_zombie_powerup("unlimited_ammo", "T6_WPN_AR_GALIL_WORLD", &"ZOMBIE_POWERUP_UNLIMITED_AMMO", ::func_should_always_drop, 0, 0, 0);
	powerup_set_can_pick_up_in_last_stand("unlimited_ammo", 1);
}

onPlayerConnect()
{
    for(;;)
    {
        level waittill("connected", player);
        player thread onPlayerSpawned();
    }
}

onPlayerSpawned()
{
    self endon("disconnect");
	level endon("game_ended");
    for(;;)
    {
        self waittill("spawned_player");
        if(self isHost() && !isDefined(level.unlimited_ammo_first_spawn))
        {
        	wait 2;
        	//store the original custom powerup grab function, 
        	//if one exists (Origins, Buried, Grief & Turned)
        	//note that this is not intended for Grief or Turned
        	//I have no idea what will happen, probably pretty broken
        	if(isDefined(level._zombiemode_powerup_grab))
        		level.original_zombiemode_powerup_grab = level._zombiemode_powerup_grab;
        		
        	//delayed defining of the custom function so we're sure to
        	//override the function Origins and Buried defines for this
        	level._zombiemode_powerup_grab = ::custom_powerup_grab;
        	
        	//message for the host to indicate that it should be all good
        	wait 2;
			self iprintlnbold("^7Unlimited Ammo Custom Powerup Loaded!");
        	
        	//gives host the ability to test the powerup at the start of the game
        	//can be used to make sure it's actually working and all good
        	//remove the line directly below to disable
        	self thread test_the_powerup();
        	
        	//whatever so this variable isn't undefined anymore
        	level.unlimited_ammo_first_spawn = "fortnite!fortnite!!";
        }
    }
}

test_the_powerup()
{
	self endon("death");
	self endon("disconnected");
	self endon("testing_chance_ended");
	level endon("game_ended");
	wait 3;
	self iprintlnbold("^7Press ^1[{+smoke}] ^7to test, you have ^15 seconds^7.");
	self thread testing_duration_timeout();
	for(;;)
	{
		if(self secondaryoffhandbuttonpressed())
		{
			level specific_powerup_drop("unlimited_ammo", self.origin + VectorScale(AnglesToForward(self.angles), 70));
			return;
		}
		wait .05;
	}
}

testing_duration_timeout()
{
	self endon("death");
	self endon("disconnected");
	wait 5;
	self notify("testing_chance_ended");
}

//fires when we grab any custom powerup
custom_powerup_grab(s_powerup, e_player)
{
	if (s_powerup.powerup_name == "unlimited_ammo")
		level thread unlimited_ammo_powerup();
	
	//pass args onto the original custom powerup grab function
	else if (isDefined(level.original_zombiemode_powerup_grab))
		level thread [[level.original_zombiemode_powerup_grab]](s_powerup, e_player);
}

unlimited_ammo_powerup()
{
	foreach(player in level.players)
	{
		//if powerup is already on, turn it off
		player notify("end_unlimited_ammo");
		//small cha ching sound for each player when someone picks up the powerup
		//cba'd to come up with anything better and don't have a list of sounds, 
		//change to w/e if you want.
		player playsound("zmb_cha_ching");
		player thread turn_on_unlimited_ammo();
		player thread unlimited_ammo_on_hud();
		player thread notify_unlimited_ammo_end();
	}
}

unlimited_ammo_on_hud()
{
	self endon("disconnect");
	//hud elems for text & icon
	unlimited_ammo_hud_string = newclienthudelem(self);
	unlimited_ammo_hud_string.elemtype = "font";
	unlimited_ammo_hud_string.font = "objective";
	unlimited_ammo_hud_string.fontscale = 2;
	unlimited_ammo_hud_string.x = 0;
	unlimited_ammo_hud_string.y = 0;
	unlimited_ammo_hud_string.width = 0;
	unlimited_ammo_hud_string.height = int( level.fontheight * 2 );
	unlimited_ammo_hud_string.xoffset = 0;
	unlimited_ammo_hud_string.yoffset = 0;
	unlimited_ammo_hud_string.children = [];
	unlimited_ammo_hud_string setparent(level.uiparent);
	unlimited_ammo_hud_string.hidden = 0;
	unlimited_ammo_hud_string maps/mp/gametypes_zm/_hud_util::setpoint("TOP", undefined, 0, level.zombie_vars["zombie_timer_offset"] - (level.zombie_vars["zombie_timer_offset_interval"] * 2));
	unlimited_ammo_hud_string.sort = .5;
	unlimited_ammo_hud_string.alpha = 0;
	unlimited_ammo_hud_string fadeovertime(.5);
	unlimited_ammo_hud_string.alpha = 1;
	//cool powerup name, sounds like something that could actually be in the game
	//credits to "Banni" for it
	unlimited_ammo_hud_string setText("Bottomless Clip!");
	unlimited_ammo_hud_string thread unlimited_ammo_hud_string_move();
	
	unlimited_ammo_hud_icon = newclienthudelem(self);
	unlimited_ammo_hud_icon.horzalign = "center";
	unlimited_ammo_hud_icon.vertalign = "bottom";
	unlimited_ammo_hud_icon.x = -75;
	unlimited_ammo_hud_icon.y = 0;
	unlimited_ammo_hud_icon.alpha = 1;
	unlimited_ammo_hud_icon.hidewheninmenu = true;   
	unlimited_ammo_hud_icon setshader("hud_icon_minigun", 40, 40);
	self thread unlimited_ammo_hud_icon_blink(unlimited_ammo_hud_icon);
	self thread destroy_unlimited_ammo_icon_hud(unlimited_ammo_hud_icon);
}

unlimited_ammo_hud_string_move()
{
	wait .5;
	self fadeovertime(1.5);
	self moveovertime(1.5);
	self.y = 270;
	self.alpha = 0;
	wait 1.5;
	self destroy();
}

//blinking times match the normal powerup hud blinking times
unlimited_ammo_hud_icon_blink(elem)
{
	level endon("disconnect");
	self endon("disconnect");
	self endon("end_unlimited_ammo");
	time_left = level.unlimited_ammo_duration;
	for(;;)
	{
		//less than 5sec left on powerup, blink fast
		if(time_left <= 5)
			time = .1;
		//less than 10sec left on powerup, blink
		else if(time_left <= 10)
			time = .2;
		//over 20sec left, dont blink
		else
		{
			wait .05;
			time_left -= .05;
			continue;
		}
		elem fadeovertime(time);
		elem.alpha = 0;
		wait time;
		elem fadeovertime(time);
		elem.alpha = 1;
		wait time;
		time_left -= time * 2;
	}
}

destroy_unlimited_ammo_icon_hud(elem)
{
	level endon("game_ended");
	//timeout just in case aswell, shouldnt ever get used, but who knows if I missed something
	self waittill_any_timeout(level.unlimited_ammo_duration+1, "disconnect", "end_unlimited_ammo");
	elem destroy();
}

turn_on_unlimited_ammo()
{
	level endon("game_ended");
	self endon("disonnect");
	self endon("end_unlimited_ammo");
	for(;;)
	{
		//simply set the current mag to be full on a loop
		self setWeaponAmmoClip(self GetCurrentWeapon(), 150);
		wait .05;
	}
}

notify_unlimited_ammo_end()
{
	level endon("game_ended");
	self endon("disonnect");
	self endon("end_unlimited_ammo");
	wait level.unlimited_ammo_duration;
	//the same sound that plays when instakill powerup ends
	self playsound("zmb_insta_kill");
	self notify("end_unlimited_ammo");
}