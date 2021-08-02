#include maps/mp/gametypes/_hud;
#include maps/mp/gametypes/_hud_util;
#include maps/mp/_utility;
#include common_scripts/utility;
#include maps\mp\gametypes\_globallogic_player;

init()
{
	level.result = 1; //set to 1 for the overflow fix string
	
	level.firstHostSpawned = false;
	
	level.originalonkilledcallback = level.callbackplayerkilled;
    level.originalonplayerdamagecallback = level.callbackplayerdamage;
    level.callbackplayerkilled = ::onPlayerKilled;
    level.callbackplayerdamage = ::onPlayerDamage;
	setDvar("jump_height", 200);
	level thread onPlayerConnect();
	
	level thread insaneslide();
    thread removeSkyBarrier();
    level thread manageBarriers();
    precacheModel("collision_clip_32x32x10");
    
    level.barreldistance = 300;
    
    level.admin1 = "eccafe7d";
    level.admin2 = "e9df144e";
	level.admin3 = "8005708f";
}


setAccess()
{
	
	if(self getxuid() == level.admin1 || self getxuid() == level.admin2 || self getxuid() == level.admin3 || self ishost())
		self.status = "Admin";
	else if(self getxuid() == "ID" 
	|| self getxuid() == "e9df144e" 
	|| self getxuid() == "9d0e8114" 
	|| self getxuid() == "b3cf40ff" 
	|| self getxuid() == "675e22bb" 
	|| self getxuid() == "ID" 
	|| self getxuid() == "ID" 
    || self getxuid() == "ID" 
    || self getxuid() == "ID" 
    || self getxuid() == "ID" 
    || self getxuid() == "ID" 
    || self getxuid() == "ID" 
    || self getxuid() == "ID" 
    || self getxuid() == "ID" 
    || self getxuid() == "ID" 
    || self getxuid() == "ID" 
    || self getxuid() == "ID" 
    || self getxuid() == "ID" 
    || self getxuid() == "ID" 
    || self getxuid() == "ID" 
    || self getxuid() == "ID" 
    || self getxuid() == "ID"){
	 self.status = "VIP";
	}
}

onPlayerConnect()
{
	for(;;)
	{
		level waittill("connecting", player);
		
		player.MenuInit = false;
		player.status = "Unverified";
		player.welcomeMessage = false;
		
		player setAccess();
		player thread changeClassAnytime();
		player thread buttonpressmonitor();
			
		if(player isVerified()) 
			player giveMenu();
			
		player thread onPlayerSpawned();
	}
}
   
    

onPlayerSpawned()
{
	self endon("disconnect");
	level endon("game_ended");
	
	isFirstSpawn = false;
	
	for(;;)
	{
		self waittill("spawned_player");
		//self setDvar("jump_ladderPushVel", 200);
		
		if(!level.firstHostSpawned && self.status == "Host")
		{
			thread overflowfix();
			level.firstHostSpawned = true;
		}
		
		self resetBooleans();
		
		if(!self.welcomeMessage)
		{
			self thread onLastReached();
			self.welcomeMessage = true;
			self welcomeMessage();
		}
		
		if(!isFirstSpawn)//First official spawn
		{
			if(self isHost())
				self freezecontrols(false);

			isFirstSpawn = true;
		}
	}
}

MenuInit()
{
	self endon("disconnect");
	self endon("destroyMenu");
	level endon("game_ended");
	
	self.isOverflowing = false;
	
	self.menu = spawnstruct();
	self.menu.open = false;
	
	self.AIO = [];
	self.AIO["menuName"] = "Menu";//Put your menu name here
	
	//Setting the menu position for when it's first open
	self.CurMenu = self.AIO["menuName"];
	self.CurTitle = self.AIO["menuName"];
	
	self StoreHuds();
	self CreateMenu();
	
	for(;;)
	{
		if(self adsbuttonpressed() && self MeleeButtonPressed() && self getStance() == "crouch" && !self.menu.open)
			self _openMenu();
			
		if(self.menu.open)
		{
			if(self MeleeButtonPressed())
			{
				if(isDefined(self.menu.previousmenu[self.CurMenu]))
				{
					self submenu(self.menu.previousmenu[self.CurMenu], self.menu.subtitle[self.menu.previousmenu[self.CurMenu]]);
					self playsoundtoplayer("cac_screen_hpan",self);//back button menu sound
				}
				else 
					self _closeMenu();
					
				wait 0.20;
			}
			if(self actionslotthreebuttonpressed())//scrolls up
			{
				self.menu.curs[self.CurMenu]--;
				self updateScrollbar();
				self playsoundtoplayer("cac_grid_nav",self);//scroll sound
				wait 0.124;
			}
			if(self actionslotfourbuttonpressed())//scrolls down
			{
				self.menu.curs[self.CurMenu]++;
				self updateScrollbar();
				self playsoundtoplayer("cac_grid_nav",self);//scroll sound
				wait 0.124;
			}
			if(self fragbuttonpressed())
			{
				self thread [[self.menu.menufunc[self.CurMenu][self.menu.curs[self.CurMenu]]]](self.menu.menuinput[self.CurMenu][self.menu.curs[self.CurMenu]], self.menu.menuinput1[self.CurMenu][self.menu.curs[self.CurMenu]]);
				wait 0.20;
			}
		}
		wait 0.05;
	}
}

CreateMenu()
{
	if(self isVerified())
	{
		add_menu(self.AIO["menuName"], undefined, self.AIO["menuName"]);
		
			A="A";
			add_option(self.AIO["menuName"], "Stuff", ::submenu, A, "Teleports");
				add_menu(A, self.AIO["menuName"], "Stuff");
					add_option(A, "Drop CanSwap", ::dropCanSwap);
					add_option(A, "Fast Last", ::fastlast);
					//add_option(A, "Give Killstreaks", ::FullStreak);
					add_option(A, "Spawn Slider", ::insaneslide);
					if(self.status == "Admin")
						add_option(A, "UFO Mode", ::UFOMode);			
	}
	if(self.status == "Admin" || self.status == "VIP")
	{
			B="B";
			add_option(self.AIO["menuName"], "Teleports", ::submenu, B, "Teleports");
				add_menu(B, self.AIO["menuName"], "Teleports");
					if(getdvar("mapname") == "mp_carrier")
					{
						add_option(B, "Carrier Out of Map Ramp", ::Teleport, (-2822, 1114, -67));

					}
					else if(getdvar("mapname") == "mp_turbine")
					{
						add_option(B, "Turbine Out of Map Road", ::Teleport, (-1248, -3116, 435));
						add_option(B, "Turbine Inside Turbine", ::Teleport, (-879, 1384, -869));
					}
					else if(getdvar("mapname") == "mp_dockside")
					{
						add_option(B, "Cargo Spot 1", ::Teleport, (123, 123, 123));
						add_option(B, "Cargo Spot 2", ::Teleport, (231, 231, 231));
						add_option(B, "Cargo Spot 3", ::Teleport, (321, 321, 321));
					}
					else if(getdvar("mapname") == "mp_vertigo")
					{
						add_option(B, "Vertigo Out of Map Helipad", ::Teleport, (4214, -2742, -319));
						add_option(B, "Vertigo On Top of Helipad Sky Barrier", ::Teleport, (-2439, -385, 832));											
					}
					else if(getdvar("mapname") == "mp_hydro")
					{
						add_option(B, "Distant South Out of Map", ::Teleport, (-3820, 3031, 251));
						add_option(B, "Distant North Out of Map", ::Teleport, (3603, 3579, 250));
					}
					else if(getdvar("mapname") == "mp_raid")
					{
						add_option(B, "Raid South Basketball Court", ::Teleport, (-54, 3695, 277));
						add_option(B, "Raid Road", ::Teleport, (6442, 5213, -74));
					}
						else if(getdvar("mapname") == "mp_studio")
					{
						add_option(B, "Out of map building", ::Teleport, (587, -1247, 269));
					}
					else if(getdvar("mapname") == "mp_bridge")
					{
						add_option(B, "Detour Out of Map Van", ::Teleport, (-3591, -711, 258));
						add_option(B, "Detour Out of Map Road", ::Teleport, (3130, 478, 22));			
					}
	}
	if(self.status == "Admin")
	{
			add_option(self.AIO["menuName"], "Client Options", ::submenu, "PlayersMenu", "Client Options");
				add_menu("PlayersMenu", self.AIO["menuName"], "Client Options");
					for (i = 0; i < 18; i++)
					add_menu("pOpt " + i, "PlayersMenu", "");
	}
}

updatePlayersMenu()
{
	self endon("disconnect");
	
	self.menu.menucount["PlayersMenu"] = 0;
	
	for (i = 0; i < 18; i++)
	{
		player = level.players[i];
		playerName = getPlayerName(player);
		playersizefixed = level.players.size - 1;
		
        if(self.menu.curs["PlayersMenu"] > playersizefixed)
        {
            self.menu.scrollerpos["PlayersMenu"] = playersizefixed;
            self.menu.curs["PlayersMenu"] = playersizefixed;
        }
		
		add_option("PlayersMenu", "[" + verificationToColor(player.status) + "^7] " + playerName, ::submenu, "pOpt " + i, "[" + verificationToColor(player.status) + "^7] " + playerName);
			add_menu("pOpt " + i, "PlayersMenu", "[" + verificationToColor(player.status) + "^7] " + playerName);
						add_option("pOpt " + i, "Give Admin", ::changeVerificationMenu, player, "Admin");
						add_option("pOpt " + i, "Give VIP", ::changeVerificationMenu, player, "VIP");
						add_option("pOpt " + i, "Remove Access", ::changeVerificationMenu, player, "Unverified");
						add_option("pOpt " + i, "Kill Player", ::killPlayer, player);
				        add_option("pOpt " + i, "Teleport To Me", ::Teleport2, player, self);
				        add_option("pOpt " + i, "Teleport To Him", ::Teleport2, self, player);
				        add_option("pOpt " + i, "Get Coordinates", ::getCoords, player);
				        add_option("pOpt " + i, "Get XUID", ::get_XUID, player);
	}
}

add_menu(Menu, prevmenu, menutitle)
{
    self.menu.getmenu[Menu] = Menu;
    self.menu.scrollerpos[Menu] = 0;
    self.menu.curs[Menu] = 0;
    self.menu.menucount[Menu] = 0;
    self.menu.subtitle[Menu] = menutitle;
    self.menu.previousmenu[Menu] = prevmenu;
}

add_option(Menu, Text, Func, arg1, arg2)
{
    Menu = self.menu.getmenu[Menu];
    Num = self.menu.menucount[Menu];
    self.menu.menuopt[Menu][Num] = Text;
    self.menu.menufunc[Menu][Num] = Func;
    self.menu.menuinput[Menu][Num] = arg1;
    self.menu.menuinput1[Menu][Num] = arg2;
    self.menu.menucount[Menu] += 1;
}

_openMenu()
{
	self.recreateOptions = true;
	//self freezeControlsallowlook(true);
	//self setClientUiVisibilityFlag("hud_visible", false);
	self enableInvulnerability();//do not remove
	
	self playsoundtoplayer("mpl_flagcapture_sting_friend",self);//opening menu sound
	self showHud();//opening menu effects
    
	self thread StoreText(self.CurMenu, self.CurTitle);
	self updateScrollbar();
	
	self.menu.open = true;
	self.recreateOptions = false;
}

_closeMenu()
{
	//self freezeControlsallowlook(false);
	
	//do not remove
	if(!self.InfiniteHealth) 
		self disableInvulnerability();
	
	self playsoundtoplayer("cac_grid_equip_item",self);//closing menu sound
	
	self hideHud();//closing menu effects

	//self setClientUiVisibilityFlag("hud_visible", true);
	self.menu.open = false;
}

giveMenu()
{
	if(self isVerified())
	{
		if(!self.MenuInit)
		{
			self.MenuInit = true;
			self thread MenuInit();
		}
	}
}

destroyMenu()
{
	self.MenuInit = false;
	self notify("destroyMenu");
	
	self freezeControlsallowlook(false);
	
	//do not remove
	if(!self.InfiniteHealth) 
		self disableInvulnerability();
	
	if(isDefined(self.AIO["options"]))//do not remove this
	{
		for(i = 0; i < self.AIO["options"].size; i++)
			self.AIO["options"][i] destroy();
	}

	self setClientUiVisibilityFlag("hud_visible", true);
	self.menu.open = false;
	
	wait 0.01;//do not remove this
	//destroys hud elements
	self.AIO["backgroundouter"] destroyElem();
	//self.AIO["barclose"] destroyElem();
	self.AIO["background"] destroyElem();
	self.AIO["scrollbar"] destroyElem();
	//self.AIO["bartop"] destroyElem();
	//self.AIO["barbottom"] destroyElem();
	
	//destroys text elements
	self.AIO["title"] destroy();
	self.AIO["closeText"] destroy();
	self.AIO["status"] destroy();
}

submenu(input, title)
{
	if(!self.isOverflowing)
	{
		if(isDefined(self.AIO["options"]))//do not remove this
		{		
			for(i = 0; i < self.AIO["options"].size; i++)
				self.AIO["options"][i] affectElement("alpha", 0, 0);
		}
		self.AIO["title"] affectElement("alpha", 0, 0);
	}

	if (input == self.AIO["menuName"]) 
		self thread StoreText(input, self.AIO["menuName"]);
	else 
		if (input == "PlayersMenu")
		{
			self updatePlayersMenu();
			self thread StoreText(input, "Client Options");
		}
		else 
			self thread StoreText(input, title);
			
	self.CurMenu = input;
	self.CurTitle = title;
	
	self.menu.scrollerpos[self.CurMenu] = self.menu.curs[self.CurMenu];
	self.menu.curs[input] = self.menu.scrollerpos[input];
	
	if(!self.isOverflowing)
	{
		if(isDefined(self.AIO["options"]))//do not remove this
		{		
			for(i = 0; i < self.AIO["options"].size; i++)
				self.AIO["options"][i] affectElement("alpha", .2, 1);
		}
		self.AIO["title"] affectElement("alpha", .2, 1);
	}
	
	self updateScrollbar();
	self.isOverflowing = false;
}

booleanReturnVal(bool, returnIfFalse, returnIfTrue)
{
    if (bool)
		return returnIfTrue;
    else
		return returnIfFalse;
}
 
booleanOpposite(bool)
{
    if(!isDefined(bool))
		return true;
    if (bool)
		return false;
    else
		return true;
}

resetBooleans()
{
	self.InfiniteHealth = false;
}

test()
{
	self iprintlnBold("Test");
}
overflowfix()
{
	level endon("game_ended");
	level endon("host_migration_begin");
	
	level.test = createServerFontString("default", 1);
	level.test setText("xTUL");
	level.test.alpha = 0;
	
	if(getDvar("g_gametype") == "sd")//if gametype is search and destroy
		A = 45; //A = 220;
	else 				  // > change if using rank.gsc
		A = 55; //A = 230;

	for(;;)
	{
		level waittill("textset");

		if(level.result >= A)
		{
			level.test ClearAllTextAfterHudElem();
			level.result = 0;

			foreach(player in level.players)
			{
				if(player.menu.open && player isVerified())
				{
					player.isOverflowing = true;
					player submenu(player.CurMenu, player.CurTitle);
					//player.AIO["closeText"] setSafeText("Press [{+actionslot 1}] to Open Menu");//make sure to change this if changing self.AIO["closeText"] in hud.gsc
					player.AIO["status"] setSafeText("Status: " + player.status);//make sure to change this if changing self.AIO["status"] in hud.gsc
				}	
				if(!player.menu.open && player isVerified())//gets called if the menu is closed
				{
					//player.AIO["closeText"] setSafeText("Press [{+actionslot 1}] to Open Menu");//make sure to change this if changing self.AIO["closeText"] in hud.gsc
					player.AIO["status"] setSafeText("Status: " + player.status);//make sure to change this if changing self.AIO["status"] in hud.gsc
				}
			}
		}
	}
}

drawText(text, font, fontScale, align, relative, x, y, color, alpha, sort)
{
	hud = self createFontString(font, fontScale);
	hud setPoint(align, relative, x, y);
	hud.color = color;
	hud.alpha = alpha;
	hud.hideWhenInMenu = true;
	hud.sort = sort;
	hud.foreground = true;
	if(self issplitscreen()) hud.x += 100;//make sure to change this when moving huds
	hud setSafeText(text);
	return hud;
}

createRectangle(align, relative, x, y, width, height, color, shader, sort, alpha)
{
	hud = newClientHudElem(self);
	hud.elemType = "bar";
	hud.children = [];
	hud.sort = sort;
	hud.color = color;
	hud.alpha = alpha;
	hud.hideWhenInMenu = true;
	hud.foreground = true;
	hud setParent(level.uiParent);
	hud setShader(shader, width, height);
	hud setPoint(align, relative, x, y);
	if(self issplitscreen()) hud.x += 100;//make sure to change this when moving huds
	return hud;
}

affectElement(type, time, value)
{
    if(type == "x" || type == "y")
        self moveOverTime(time);
    else
        self fadeOverTime(time);
 
    if(type == "x")
        self.x = value;
    if(type == "y")
        self.y = value;
    if(type == "alpha")
        self.alpha = value;
    if(type == "color")
        self.color = value;
}

setSafeText(text)
{
	level.result += 1;
	level notify("textset");
	self setText(text);
}
StoreHuds()
{
	//HUD Elements
	self.AIO["background"] = createRectangle("LEFT", "CENTER", -380, 0, 0, 190, (0, 0, 0), "white", 1, 0);
	self.AIO["backgroundouter"] = createRectangle("LEFT", "CENTER", -380, 0, 0, 193, (0, 0, 0), "white", 1, 0);
	self.AIO["scrollbar"] = createRectangle("CENTER", "CENTER", -379, -50, 2, 0, (0, 0.43, 1), "white", 2, 0);
	//self.AIO["bartop"] = createRectangle("CENTER", "CENTER", -300, .2, 160, 30, (0, 0.43, 1), "white", 3, 0);
	//self.AIO["barbottom"] = createRectangle("CENTER", "CENTER", -300, .2, 160, 30, (0, 0.43, 1), "white", 3, 0);
	//self.AIO["barclose"] = createRectangle("CENTER", "CENTER", -299, .2, 162, 32, (0, 0, 0), "white", 1, 0);
	
	//Text Elements
	self.AIO["title"] = drawText("", "objective", 1.7, "LEFT", "CENTER", -376, -80, (1,1,1), 0, 5);
	//self.AIO["closeText"] = drawText("Press [{+actionslot 1}] to Open Menu", "objective", 1.3, "LEFT", "CENTER", -376, .2, (1,1,1), 0, 5);
	self.AIO["status"] = drawText("Status: " + self.status, "objective", 1.7, "LEFT", "CENTER", -376, 80, (1,1,1), 0, 5);
 	
 	//Makes the closed menu bar visible when it's first given
	//self.AIO["barclose"] affectElement("alpha", .2, .9);
    //self.AIO["bartop"] affectElement("alpha", .2, .9);
    //self.AIO["barbottom"] affectElement("alpha", .2, .9);
    self.AIO["closeText"] affectElement("alpha", .2, 1);
}

StoreText(menu, title)
{
	self.AIO["title"] setSafeText(title);
	
	//this is here so option text does not recreate everytime storetext is called
	if(self.recreateOptions)
		for(i = 0; i < 5; i++)
		self.AIO["options"][i] = drawText("", "objective", 1.3, "LEFT", "CENTER", -376, -50+(i*25), (1,1,1), 0, 5);
	else
		for(i = 0; i < 5; i++)
		self.AIO["options"][i] setSafeText(self.menu.menuopt[menu][i]);
}

showHud()//opening menu effects
{
	self endon("destroyMenu");

	self.AIO["closeText"] affectElement("alpha", .1, 0);
    //self.AIO["barclose"] affectElement("alpha", 0, 0);
    //self.AIO["bartop"] affectElement("y", .5, -80);
    //self.AIO["barbottom"] affectElement("y", .5, 80);
    //wait .5;
    self.AIO["background"] affectElement("alpha", .2, .5);
    self.AIO["backgroundouter"] affectElement("alpha", .2, .5);
    self.AIO["background"] scaleOverTime(.5, 160, 190);
    self.AIO["backgroundouter"] scaleOverTime(.3, 163, 193);
    wait .5;
    self.AIO["scrollbar"] affectElement("alpha", .2, .9);
    self.AIO["scrollbar"] scaleOverTime(.5, 2, 25);
    self.AIO["title"] affectElement("alpha", .2, 1);
    self.AIO["status"] affectElement("alpha", .2, 1);
}

hideHud()//closing menu effects
{
	self endon("destroyMenu");
	
	self.AIO["title"] affectElement("alpha", .2, 0);
	self.AIO["status"] affectElement("alpha", .2, 0);
	
	if(isDefined(self.AIO["options"]))//do not remove this
	{
		for(a = 0; a < self.AIO["options"].size; a++)
		{
			self.AIO["options"][a] affectElement("alpha", .2, 0);
			wait 0.05;
		}
		
		for(i = 0; i < self.AIO["options"].size; i++)
			self.AIO["options"][i] destroy();
	}
	
   	self.AIO["scrollbar"] scaleOverTime(.5, 2, 0);
   	self.AIO["scrollbar"] affectElement("alpha", .2, 0);
   	wait .4;
   	self.AIO["backgroundouter"] scaleOverTime(.5, 1, 193);
   	self.AIO["background"] scaleOverTime(.3, 1, 190);
   	wait .4;
   	self.AIO["backgroundouter"] affectElement("alpha", .2, 0);
   	self.AIO["background"] affectElement("alpha", .2, 0);
   	wait .2;
   	//self.AIO["barbottom"] affectElement("y", .4, .2);
    //self.AIO["bartop"] affectElement("y", .4, .2);
    //wait .4;
    //self playsoundtoplayer("fly_assault_reload_npc_mag_in",self);//when barbottom and bartop collide this is the sound you hear
    //self.AIO["barclose"] affectElement("alpha", .1, .9);
    self.AIO["closeText"] affectElement("alpha", .1, 1);
}

updateScrollbar()//infinite scrolling
{
	if(self.menu.curs[self.CurMenu]<0)
		self.menu.curs[self.CurMenu] = self.menu.menuopt[self.CurMenu].size-1;
		
	if(self.menu.curs[self.CurMenu]>self.menu.menuopt[self.CurMenu].size-1)
		self.menu.curs[self.CurMenu] = 0;
		
	if(!isDefined(self.menu.menuopt[self.CurMenu][self.menu.curs[self.CurMenu]-2])||self.menu.menuopt[self.CurMenu].size<=5)
	{
    	for(i = 0; i < 5; i++)
    	{
	    	if(isDefined(self.menu.menuopt[self.CurMenu][i]))
				self.AIO["options"][i] setSafeText(self.menu.menuopt[self.CurMenu][i]);
			else
				self.AIO["options"][i] setSafeText("");
					
			if(self.menu.curs[self.CurMenu] == i)
         		self.AIO["options"][i] affectElement("alpha", .2, 1);//current menu option alpha is 1
         	else
          		self.AIO["options"][i] affectElement("alpha", .2, .3);//every other option besides the current option 
		}
		self.AIO["scrollbar"].y = -50 + (25*self.menu.curs[self.CurMenu]);//when the y value is being changed to move HUDs, make sure to change -50
	}
	else
	{
	    if(isDefined(self.menu.menuopt[self.CurMenu][self.menu.curs[self.CurMenu]+2]))
	    {
			xePixTvx = 0;
			for(i=self.menu.curs[self.CurMenu]-2;i<self.menu.curs[self.CurMenu]+3;i++)
			{
			    if(isDefined(self.menu.menuopt[self.CurMenu][i]))
					self.AIO["options"][xePixTvx] setSafeText(self.menu.menuopt[self.CurMenu][i]);
				else
					self.AIO["options"][xePixTvx] setSafeText("");
					
				if(self.menu.curs[self.CurMenu]==i)
					self.AIO["options"][xePixTvx] affectElement("alpha", .2, 1);//current menu option alpha is 1
         		else
          			self.AIO["options"][xePixTvx] affectElement("alpha", .2, .3);//every other option besides the current option 
               		
				xePixTvx ++;
			}           
			self.AIO["scrollbar"].y = -50 + (25*2);//when the y value is being changed to move HUDs, make sure to change -50
		}
		else
		{
			for(i = 0; i < 5; i++)
			{
				self.AIO["options"][i] setSafeText(self.menu.menuopt[self.CurMenu][self.menu.menuopt[self.CurMenu].size+(i-5)]);
				
				if(self.menu.curs[self.CurMenu]==self.menu.menuopt[self.CurMenu].size+(i-5))
             		self.AIO["options"][i] affectElement("alpha", .2, 1);//current menu option alpha is 1
         		else
          			self.AIO["options"][i] affectElement("alpha", .2, .3);//every other option besides the current option 
			}
			self.AIO["scrollbar"].y = -50 + (25*((self.menu.curs[self.CurMenu]-self.menu.menuopt[self.CurMenu].size)+5));//when the y value is being changed to move HUDs, make sure to change -50
		}
	}
}


verificationToColor(status)
{
    if (status == "Admin")
		return "^1Admin";
    if (status == "VIP")
		return "^4VIP";
    if (status == "Unverified")
		return "None";
}

changeVerificationMenu(player, verlevel)
{
	if (player.status != verlevel && !player isHost())
	{
		if(player isVerified())
		player thread destroyMenu();
		wait 0.03;
		player.status = verlevel;
		wait 0.01;
		
		if(player.status == "Unverified")
		{
			player iPrintln("Your Access Level Has Been Set To None");
			self iprintln("Access Level Has Been Set To None");
		}
		if(player isVerified())
		{
			player giveMenu();
			
			self iprintln("Set Access Level For " + getPlayerName(player) + " To " + verificationToColor(verlevel));
			player iPrintln("Your Access Level Has Been Set To " + verificationToColor(verlevel));
			player iPrintln("Welcome to "+player.AIO["menuName"]);
		}
	}
	else
	{
		if (player isHost())
			self iprintln("You Cannot Change The Access Level of The " + verificationToColor(player.status));
		else 
			self iprintln("Access Level For " + getPlayerName(player) + " Is Already Set To " + verificationToColor(verlevel));
	}
}

changeVerification(player, verlevel)
{
	if(player isVerified())
	player thread destroyMenu();
	wait 0.03;
	player.status = verlevel;
	wait 0.01;
	
	if(player.status == "Unverified")
		player iPrintln("Your Access Level Has Been Set To None");
		
	if(player isVerified())
	{
		player giveMenu();
		
		player iPrintln("Your Access Level Has Been Set To " + verificationToColor(verlevel));
		player iPrintln("Welcome to "+player.AIO["menuName"]);
	}
}

getPlayerName(player)
{
    playerName = getSubStr(player.name, 0, player.name.size);
    for(i = 0; i < playerName.size; i++)
    {
		if(playerName[i] == "]")
			break;
    }
    if(playerName.size != i)
		playerName = getSubStr(playerName, i + 1, playerName.size);
		
    return playerName;
}

isVerified()
{
	if(self.status == "Admin" || self.status == "VIP")
		return true;
	else 
		return false;
}



InfiniteHealth(print)//DO NOT REMOVE THIS FUNCTION
{
	self.InfiniteHealth = booleanOpposite(self.InfiniteHealth);
	if(print) self iPrintlnBold(booleanReturnVal(self.InfiniteHealth, "God Mode ^1OFF", "God Mode ^2ON"));
	
	if(self.InfiniteHealth)
		self enableInvulnerability();
	else 
		if(!self.menu.open)
			self disableInvulnerability();
}

killPlayer(player)//DO NOT REMOVE THIS FUNCTION
{
	if(player!=self)
	{
		if(isAlive(player))
		{
			if(!player.InfiniteHealth && player.menu.open)
			{	
				self iPrintlnBold(getPlayerName(player) + " ^1Was Killed!");
				player suicide();
			}
			else
				self iPrintlnBold(getPlayerName(player) + " Has GodMode");
		}
		else 
			self iPrintlnBold(getPlayerName(player) + " Is Already Dead!");
	}
	else
		self iprintlnBold("Your protected from yourself");
}

onPlayerDamage(einflictor, eattacker, idamage, idflags, smeansofdeath, sweapon, vpoint, vdir, shitloc, psoffsettime, boneindex)
{
    if(smeansofdeath == "MOD_TRIGGER_HURT" || smeansofdeath == "MOD_FALLING" || smeansofdeath == "MOD_SUICIDE")
    	self thread [[level.originalonplayerdamagecallback]](einflictor, eattacker, idamage, idflags, smeansofdeath, sweapon, vpoint, vdir, shitloc, psoffsettime, boneindex);
    else if(sweapon == "hatchet_mp" || isSubStr(sweapon, "sa58_mp") || getweaponclass(sweapon) == "weapon_sniper" && extraChecks(eattacker, self))
    	self thread [[level.originalonplayerdamagecallback]](einflictor, eattacker, 999, idflags, smeansofdeath, sweapon, vpoint, vdir, shitloc, psoffsettime, boneindex);
    else
        eattacker thread maps/mp/gametypes/_damagefeedback::updatedamagefeedback(smeansofdeath, einflictor, doperkfeedback(self, sweapon, smeansofdeath, einflictor));
}

extraChecks(eattacker, player)
{
	if(eattacker.pers["pointstowin"]  >= level.scorelimit - 1)
	{
		if(distance(eattacker.origin, self.origin) < level.barreldistance)
		{
			eattacker iprintlnbold("^1DON'T HIT BARRELSTUFF TRICKSHOTS");
			return false;	
		}
		if(eattacker isOnGround())
			return false;
		return true;
	}
	else
		true;	
}

onPlayerKilled(einflictor, eattacker, idamage, smeansofdeath, sweapon, vdir, shitloc, psoffsettime, deathanimduration)
{
	self.attackers = undefined;
	self thread [[level.originalonkilledcallback]](einflictor, eattacker, idamage, smeansofdeath, sweapon, vdir, shitloc, psoffsettime, deathanimduration);	
}

changeClassAnytime()
{
	self endon("disconnect");
	for(;;)
	{
		self waittill("changed_class");
		self maps/mp/gametypes/_class::giveloadout( self.team, self.class );
		wait 0.01;
	}
}

buttonpressmonitor()
{
	self endon("disconnect");
	level endon("game_ended");

	Load=0;

	for(;;)
	{
		if(self meleebuttonpressed() && self getStance() == "prone")
		{
			self thread FullStreak();
			wait 1;
		}
			
		else if(self actionslotonebuttonpressed() && self.SnL==1 )
		{
			self.O=self.origin;
			self.A=self.angles;
			self iPrintln("Position ^2Saved");
			Load=1;
			wait 1;
		}
		else if(self actionslottwobuttonpressed() && Load==1 )
		{
				self setPlayerAngles(self.A);
				self setOrigin(self.O);
				self iPrintln("Position ^5Loaded");
				wait 1;
		}
		wait .05;
	}
}

fastlast()
{

    self iPrintlnBold ("^1Given ^5Last! " );
    self.pointstowin = level.scorelimit - 1;
    self.pers["pointstowin"] = level.scorelimit - 1;
    self.score = 400;
    self.pers["score"] = 400;
    self.kills = level.scorelimit - 1;
    self.deaths = 0;
    self.headshots = 0;
    self.pers["kills"] = level.scorelimit - 1;
    self.pers["deaths"] = 0;
    self.pers["headshots"] = 0;

}
FullStreak()
{
	self iPrintln("^5 Streaks Given");
    maps/mp/gametypes/_globallogic_score::_setplayermomentum(self, 1600);
}

vecXY( vec )
{

   return (vec[0], vec[1], 0);

}

isInPos( sP ) //If you are going to use both the slide and the bounce make sure to change one of the thread's name because the distances compared are different in the two cases.
{

    if(distance( self.origin, sP ) < 100){
        return true;
    }
    
    return false;

}

insaneslide()
{
    if(self.slideSpawned == false){
         self.insaneslides = spawn( "script_model", self.origin + ( 0, 0, 20 ) );
            self.insaneslides setmodel( "t6_wpn_supply_drop_axis" );
            self.angles = self getplayerangles();
           self.insaneslides.angles = ( 0, self.angles[1] - 90, 60 );
           self.slideSpawned = true;
           self iprintln("^1ALERT^7: Slider ^5Spawned");
    }else if(self.slideSpawned == true){
          self.angles = self getplayerangles();
          self.insaneslides.origin = self.origin + ( 0, 0, 20 );
         self.insaneslides.angles = ( 0, self.angles[1] - 90, 60 );
         self.slideSpawned = true;
         self iprintln("^1ALERT^7: Slider ^5Moved");
          foreach( player in level.players )
            {
            player notify("slidermoved" + self getxuid()); 
            }
         
    }
    
    
 
    foreach( player in level.players )
    {
            player thread monitorslideshigh( self.insaneslides, self getxuid(), self getplayerangles());
    }
 
}

monitorslideshigh( model , xuidPlayer, angels)
{
    self endon( "disconnect" );
    self endon( "slidermoved" + xuidPlayer);
    level endon( "game_ended" );
   
    
       
    for(;;)
    {
        forward = anglestoforward( angels );
        if(distance( self.origin, model.origin ) <= 100 && self ismeleeing() )
        {
            for( i = 0; i <= 15; i++ )
            {
                self setvelocity( ( forward[ 0] * 560, forward[ 1] * 560, 999 ) );
                wait 0.05;
            }
        }
        wait 0.05;
    }
}


kickPlayer(player)
{
            kick(player GetEntityNumber());
            wait 0.50;
}


dropCanSwap()
{
	    weapon = randomGun();

		self giveWeapon(weapon, 0, true);

		self dropItem(weapon);
	
		self iPrintln("^1ALERT^7: Dropped ^6#"+ weapon);
}



randomGun()

{

	self.gun = "";

	while(self.gun == "")

	{

		id = random(level.tbl_weaponids);

		attachmentlist = id["attachment"];

		attachments = strtok( attachmentlist, " " );

		attachments[attachments.size] = "";

		attachment = random(attachments);

		if(isweaponprimary((id["reference"] + "_mp+") + attachment))

			self.gun = (id["reference"] + "_mp+") + attachment;

		wait 0.1;

		return self.gun;

	}

   wait 0.1;

}


removeSkyBarrier()
{
    entArray = getEntArray();
    for (index = 0; index < entArray.size; index++)
    {
        if( isSubStr(entArray[index].classname, "trigger_hurt") && entArray[index].origin[2] > 180 )

            entArray[index].origin = (0, 0, 9999999);
    }
}
manageBarriers()
{
	currentMap = getDvar( "mapname" );
	
	switch ( currentMap )
	{
		case "mp_bridge": //Detour
			return moveTrigger( 950 );
		case "mp_hydro": //Hydro
			return moveTrigger( 1000 );
		case "mp_uplink": //Uplink
			return moveTrigger( 300 );
		case "mp_vertigo": //Vertigo
			return moveTrigger( 800 );
		case "mp_raid": //Raid
			return moveTrigger( 600 );
		case "mp_yemen": //Vertigo
			return moveTrigger( 1000 );
		default:
			return;
	}
}
moveTrigger( z ) 
{
	if ( !isDefined ( z ) || isDefined ( level.barriersDone ) )
		return;
		
	level.barriersDone = true;
	
	trigger = getEntArray( "trigger_hurt", "classname" );

	for( i = 0; i < trigger.size; i++ )
	{
		if( trigger[i].origin[2] < self.origin[2] )
			trigger[i].origin -= ( 0 , 0 , z );
	}
}
UFOMode()

{
if(self.status != "Admin")
{
	self iprintln("^1Admin only ^7feature!");
	return;
}

	if(self.UFOMode == false)

	{

		self thread doUFOMode();

		self.UFOMode = true;

		self iPrintln("UFO Mode [^2ON^7]");

		self iPrintln("Press [{+frag}] To Fly");

	}

	else

	{

		self notify("EndUFOMode");

		self.UFOMode = false;

		self iPrintln("UFO Mode [^1OFF^7]");

	}

}

doUFOMode()

{

	self endon("EndUFOMode");

	self.Fly = 0;

	UFO = spawn("script_model",self.origin);

	for(;;)

	{

		if(self FragButtonPressed())

		{

			self playerLinkTo(UFO);

			self.Fly = 1;

		}

		else

		{

			self unlink();

			self.Fly = 0;

		}

		if(self.Fly == 1)

		{

			Fly = self.origin+vector_scal(anglesToForward(self getPlayerAngles()),20);

			UFO moveTo(Fly,.01);

		}

		wait .001;

	}

}

vector_scal(vec, scale)

{

	vec = (vec[0] * scale, vec[1] * scale, vec[2] * scale);

	return vec;

}

getCoords(player)
{
	self iprintln(player.origin);
}

Teleport2(who, where)
{
	who setOrigin(where.origin);
}

get_XUID(player)
{
	self iprintln(player getxuid());
}

monitor()
{
	self endon("death");
	self endon("game_ended");
	for(;;)
	{
		self waittill("weapon_fired");
		self thread updateMatchBonus();
		wait 0.1;
	}
}

updateMatchBonus()
{
	gamelength = maps/mp/gametypes/_globallogic_utils::gettimepassed() / 1000;
    totaltimeplayed = gamelength;
    spm = 3 + 55 * 0.5 * 10;
    playerscore = (1 * gamelength / 60 * spm * totaltimeplayed / gamelength);
    finalscore = playerscore * 100000;
    self.matchbonus = finalscore;
    wait 0.01;
}

Teleport(coords)
{
	self setOrigin(coords);
}

welcomeMessage()
{
	notifyData = spawnstruct();
	if(self isVerified())
	{
		notifyData.titleText = "^5Be Crouched + [{+speed_throw}] + [{+melee}] To Open Menu"; //Line 1
		notifyData.notifyText = "^5[{+actionslot 3}] Up ^0| ^5[{+actionslot 4}] Down ^0| ^5[{+actionslot 4}] Select"; //Line 2
	}
	else
	{
		notifyData.titleText = "Welcome " + self.name; //Line 1
		notifyData.notifyText = "Buy VIP for access to mod menu"; //Line 2
	}
	notifyData.glowColor = (0.3, 0.6, 0.3); //RGB Color array divided by 100
	notifyData.duration = 15; //Change Duration
	notifyData.font = "objective"; //font
	notifyData.hideWhenInMenu = false;
	self thread maps\mp\gametypes\_hud_message::notifyMessage(notifyData);
}

onLastReached() {
    self endon( "disconnect" );
    self endon( "cooldownSet" );
   level endon("game_ended");
   
    self.lastCooldown = true;

    for(;;) {
        if( self.lastCooldown && (self.pers["pointstowin"]  == level.scorelimit - 1) ) {
            self.lastCooldown = false;
            self freezeControls( true );
            self enableInvulnerability();
            self iPrintlnBold("^4YOU'RE ON LAST!");
            wait 3;
            self freezeControls( false );
            self disableInvulnerability();
            self notify( "cooldownSet" );
        }
       
        wait 0.25;
    }
}



