#include maps\mp\_utility;
#include common_scripts\utility;
#include maps\mp\gametypes\_hud_util;
#include maps\mp\gametypes\_hud_message;
#include maps\mp\gametypes\_rank;
#include maps\mp\gametypes\_globallogic;
#include maps/mp/gametypes/_hud;
#include maps/mp/killstreaks/_dogs;
#include maps/mp/gametypes/_weapons;
 
init()
{
    level thread onplayerconnect();
}
 
onplayerconnect()
{
    for(;;)
    {
        level waittill( "connecting", player );
        if(player isHost())
		player.status = "Host";
        else
            player.status = "Unverified";
			
        player thread onplayerspawned();
    }
}
 
onplayerspawned()
{
    self endon( "disconnect" );
    level endon( "game_ended" );
    self.MenuInit = false;
    self.BindAim = 0;
    self.tsaim = 0;
    self.PN = 0;
	self.BindBomb = 0;
	self.BindClay = 0;
	self.BindKnife = 0;
	self.Camo = 17;
	level.FreezeEveryone = 0;
	self thread Meow();
	
    for(;;)
    {
                self waittill( "spawned_player" ); 
                if(!self.status == "Unverified")
                	self freezecontrols(false);
				
                if( self.status == "Host" || self.status == "CoHost" || self.status == "Admin" || self.status == "VIP" || self.status == "Verified")
                {
                        if (!self.MenuInit)
                        {
                                self.MenuInit = true;
                                self thread MenuInit();
                                self thread closeMenuOnDeath();
                        }
                }
    }
}

Meow()
{
	self waittill( "spawned_player" ); 
	self thread maps\mp\gametypes\_hud_message::hintMessage("^2Mod Menu ^7Made By ^6Ox");
	wait 2;
	self thread maps\mp\gametypes\_hud_message::hintMessage("^3Skype: ^-----");	
}
 
drawText(text, font, fontScale, x, y, color, alpha, glowColor, glowAlpha, sort)
{
        hud = self createFontString(font, fontScale);
    hud setText(text);
    hud.x = x;
        hud.y = y;
        hud.color = color;
        hud.alpha = alpha;
        hud.glowColor = glowColor;
        hud.glowAlpha = glowAlpha;
        hud.sort = sort;
        hud.alpha = alpha;
        return hud;
}

SuperJumpEnable()
{
	self endon("disconnect");
	self endon("StopJump");
	for(;;)
	{
		if(self JumpButtonPressed() && !isDefined(self.allowedtopress))
		{
			for(i = 0; i < 10; i++)
			{
				self.allowedtopress = true;
				self setVelocity(self getVelocity()+(0, 0, 999));
				wait 0.05;
			}
			self.allowedtopress = undefined;
		}
		wait 0.05;
	}
}
ToggleSuperJump()
{
	if(!isDefined(!level.superjump))
	{
		level.superjump = true;
		for(i = 0; i < level.players.size; i++)level.players[i] thread SuperJumpEnable();
		self iprintln("Super Jump: ^2Enabled^7!");
	}
	else
	{
		level.superjump = undefined;
		for(x = 0; x < level.players.size; x++)level.players[x] notify("StopJump");
		self iprintln("Super Jump: ^1Disabled^7!");
	}
}
 
drawShader(shader, x, y, width, height, color, alpha, sort)
{
        hud = newClientHudElem(self);
    hud.elemtype = "icon";
    hud.color = color;
    hud.alpha = alpha;
    hud.sort = sort;
    hud.children = [];
    hud setParent(level.uiParent);
    hud setShader(shader, width, height);
    hud.x = x;
    hud.y = y;
    return hud;
}
 
verificationToNum(status)
{
        if (status == "Host")
                return 5;
        if (status == "CoHost")
                return 4;
        if (status == "Admin")
                return 3;
        if (status == "VIP")
                return 2;
        if (status == "Verified")
                return 1;
        else
                return 0;
}
 
verificationToColor(status)
{
        if (status == "Host")
                return "^2Host";
        if (status == "CoHost")
                return "^5CoHost";
        if (status == "Admin")
                return "^1Admin";
        if (status == "VIP")
                return "^4VIP";
        if (status == "Verified")
                return "^3Verified";
        else
                return "^7Unverified";
}
 
changeVerificationMenu(player, verlevel)
{
        if( player.status != verlevel)
        {
                if (!verificationToNum(player.status) == 5)
                {
 
                player.status = verlevel;
       
                self.menu.title destroy();
                self.menu.title = drawText("[" + verificationToColor(player.status) + "^7] " + player.name, "objective", 2, 280, 30, (1, 1, 1), 0, (0, 0.58, 1), 1, 3);
                self.menu.title FadeOverTime(0.3);
                self.menu.title.alpha = 1;
               
                if(player.status == "Unverified")
                        self thread destroyMenu(player);
       
                player suicide();
                self iPrintln("Set Access Level For " + player.name + " To " + verificationToColor(verlevel));
                player iPrintln("Your Access Level Has Been Set To " + verificationToColor(verlevel));
                player iprintln("Press [{+gostand}] And [{+actionslot 2}] To Open Menu");
 
                }
                else
                        self iPrintln("Can't change the access level of the host!");
        }
        else
        {
                self iPrintln("Access Level For " + player.name + " Is Already Set To " + verificationToColor(verlevel));
        }
}
 
changeVerification(player, verlevel)
{
        player.status = verlevel;
}
 
Iif(bool, rTrue, rFalse)
{
        if(bool)
                return rTrue;
        else
                return rFalse;
}
 
welcomeMessage()
{
        notifyData = spawnstruct();
        notifyData.titleText = "Welcome To Superman Lobby! Your Status Is " + verificationToColor(self.status); //Line 1
        notifyData.notifyText = "Press [{+gostand}] And [{+actionslot 2}] To Open Menu"; //Line 2
        notifyData.glowColor = (0.3, 0.6, 0.3); //RGB Color array divided by 100
        notifyData.duration = 10; //Change Duration
        notifyData.font = "objective"; //font
        notifyData.hideWhenInMenu = false;
        self thread maps\mp\gametypes\_hud_message::notifyMessage(notifyData);
}
 
CreateMenu()
{
        self add_menu("Main Menu", undefined, "Unverified");
        self add_option("Main Menu", "Main Mods", ::submenu, "SubMenu1", "Main Mods");
        self add_option("Main Menu", "Players", ::submenu, "PlayersMenu", "Players");
        self add_option("Main Menu", "CoHost Menu", ::submenu, "SubMenu2", "CoHost Menu");
        self add_option("Main Menu", "Change Theme", ::submenu, "SubMenu3", "Change Theme");
        self add_option("Main Menu", "Instructions", ::getInstructions);
     
        self add_menu("SubMenu1", "Main Menu", "Verified");
        self add_option("SubMenu1", "Toggle God Mode", ::ToggleGodMode);
        self add_option("SubMenu1", "Noclip", ::ToggleNoclip);
		self add_option("SubMenu1", "Give Guns", ::Daniel);
        self add_option("SubMenu1", "Teleport", ::doTeleport);
        self add_option("SubMenu1", "Give Scorestreaks", ::giveScorestreaks);
        self add_option("SubMenu1", "Take All Perks", ::TakeAllPerks);
        self add_option("SubMenu1", "Change Class", ::ChangeClass);
        self add_option("SubMenu1", "Give Ammo", ::GiveAmmo);
		self add_option("SubMenu1", "Toggle Unlimited Ammo", ::ToggleUnlimitedAmmo);
        self add_option("SubMenu1", "Toggle EB", ::ToggleEB);
		self add_option("SubMenu1", "Speciality Perks", ::submenu, "SpecialityPerks", "Speciality Perks");
		self add_option("SubMenu1", "Toggles", ::submenu, "Toggles", "Toggles");
		self add_option("SubMenu1", "Change Camo", ::ChangeCamo);
		self add_option("SubMenu1", "Drop Can Swap", ::DropCan);
		if(self.Status == "VIP" || self.Status == "CoHost" || self.Status == "Host")
		{			
			self add_option("SubMenu1", "Check For Aimbot", ::checkForAimbot);
		}
       
        self add_menu("PlayersMenu", "Main Menu", "CoHost");
        for (i = 0; i < 12; i++)
        { self add_menu("pOpt " + i, "PlayersMenu", "CoHost"); }
       
        self add_menu("SubMenu2", "Main Menu", "CoHost");    
		self add_option("SubMenu2", "Add Bot", ::doBots, "autoassign");		
        self add_option("SubMenu2", "Toggle Super Jump", ::ToggleSuperJump);
        self add_option("SubMenu2", "Spawn Trickshot Platform", ::SpawnPlat);
        self add_option("SubMenu2", "Kill Everyone", ::killEveryone);
		self add_option("SubMenu2", "Verify Everyone", ::verifyAll);
        self add_option("SubMenu2", "Everyone To Me", ::AllToMe);
        self add_option("SubMenu2", "Unverified To Me", ::UnVeriToMe);
		self add_option("SubMenu2", "Toggle Freeze Everyone", ::ToggleFreezeEveryone);
		self add_option("SubMenu2", "Floaters", ::doFloaters);
		self add_option("SubMenu2", "End Game", ::doEndGame);
		
        self add_menu("SubMenu3", "Main Menu", "Verified");
        self add_option("SubMenu3", "Red Theme", ::doRedtheme);
        self add_option("SubMenu3", "Blue Theme", ::dobluetheme);
        self add_option("SubMenu3", "Green Theme", ::doGreentheme);
        self add_option("SubMenu3", "Yellow Theme", ::doYellowtheme);
        self add_option("SubMenu3", "Pink Theme", ::doPinktheme);
        self add_option("SubMenu3", "Cyan Theme", ::doCyantheme);
        self add_option("SubMenu3", "Aqua Theme", ::doAquatheme);
		
		self add_menu("SpecialityPerks", "SubMenu1", "Verified");
		self add_option("SpecialityPerks", "specialty_fastreload", ::GivePerk, "specialty_fastreload");
		self add_option("SpecialityPerks", "specialty_fasttoss", ::GivePerk, "specialty_fasttoss"); 
		self add_option("SpecialityPerks", "specialty_fastweaponswitch", ::GivePerk, "specialty_fastweaponswitch");
		self add_option("SpecialityPerks", "specialty_fastequipmentuse", ::GivePerk, "specialty_fastequipmentuse");
		self add_option("SpecialityPerks", "specialty_movefaster", ::GivePerk, "specialty_movefaster");
		self add_option("SpecialityPerks", "specialty_sprintrecovery", ::GivePerk, "specialty_sprintrecovery"); 
		
		self add_menu("Toggles", "SubMenu1", "Verified");
		self add_option("Toggles", "Toggle Bind Bomb Suitcase", ::ToggleBindBombSuitcase);
		self add_option("Toggles", "Toggle Bind Claymore", ::ToggleBindClaymore);
		self add_option("Toggles", "Toggle Bind Knife", ::ToggleBindKnife);
		self add_option("Toggles", "Toggle Bind Aimbot", ::GiveBindAimbot);
}

TakeGiveWeap()
{	
	self.weap = self getCurrentWeapon();
	self takeWeapon(self.weap);
	wait 1;
	self giveWeapon(self.weap);
}

ChangeCamo()
{
	if(self.Camo == 47)
	{
		weap = self getCurrentWeapon();
		self takeWeapon(weap);
		self giveWeapon(weap, 0, true (self.Camo, 0, 0, 0, 0 ));
		self switchToWeapon(weap);
		self iPrintln(self.camo);
		self.Camo = 17;
	}
	
	else
	{
		weap = self getCurrentWeapon();
		self takeWeapon(weap);
		self giveWeapon(weap, 0, true (self.Camo, 0, 0, 0, 0 ));
		self switchToWeapon(weap);
		self iPrintln(self.camo);
		self.Camo++;
	}
}

DropCan()
{
	weap = "mp7_mp";
	self giveWeapon(weap, 0, true ( 47, 0, 0, 0, 0 ));
	wait 0.1;
	self dropItem(weap);
}

doFloaters()
{
	level thread Floaters();
}

Floaters()
{
        level waittill("game_ended");
        foreach(player in level.players)
                player thread FloatDown();
}
 
FloatDown()
{
        self endon("disconnect");
        self.Float = spawn("script_model",self.origin);
        self playerLinkTo(self.Float);
        wait 0.1;
        self freezeControls(true);
        for(;;)
        {
            self.Down = self.origin - (0,0,0.5);
			self.Float moveTo(self.Down, 0.01);
			wait 0.01;
        }
}

TakeAllPerks()
{
	self clearperks();
}

GivePerk(perk)
{
	self setperk(perk);
	self iPrintln(perk + " ^2Given");
}

Daniel()
{
	self giveWeapon("fiveseven_lh_mp", 0, true(43, 0, 0, 0, 0));
	self givemaxammo("fiveseven_lh_mp");
	self switchtoweapon("fiveseven_lh_mp");
	
	self giveWeapon("an94_mp+fastads+dualoptic", 0, true(42, 0, 0, 0, 0));
	self givemaxammo("an94_mp+fastads+dualoptic");
	
	self iPrintln("Guns ^2Given");
	
	curMeow = self getcurrentweapon();
	self iPrintln(curMeow);
}

setPrestige(player)
{
	if(player.PN == 0)
	{
		prestigeNum = 0;
		player.PN = 1;
		player iPrintln("0th Prestige ^2Set!");
	}
	
	else if(player.PN == 1)
	{
		prestigeNum = 1;
		player.PN = 2;
		player iPrintln("1st Prestige ^2Set!");
	}
	
	else if(player.PN == 2)
	{
		prestigeNum = 2;
		player.PN = 3;
		player iPrintln("2nd Prestige ^2Set!");
	}
	
	else if(player.PN == 3)
	{
		prestigeNum = 3;
		player.PN = 4;
		player iPrintln("3rd Prestige ^2Set!");
	}
	
	else if(player.PN == 4)
	{
		prestigeNum = 4;
		player.PN = 5;
		player iPrintln("4th Prestige ^2Set!");
	}
	
	else if(player.PN == 5)
	{
		prestigeNum = 5;
		player.PN = 6;
		player iPrintln("5th Prestige ^2Set!");
	}
	
	else if(player.PN == 6)
	{
		prestigeNum = 6;
		player.PN = 7;
		player iPrintln("6th Prestige ^2Set!");
	}
	
	else if(player.PN == 7)
	{
		prestigeNum = 7;
		player.PN = 8;
		player iPrintln("7th Prestige ^2Set!");
	}
	
	else if(player.PN == 8)
	{
		prestigeNum = 8;
		player.PN = 9;
		player iPrintln("8th Prestige ^2Set!");
	}
	
	else if(player.PN == 9)
	{
		prestigeNum = 9;
		player.PN = 10;
		player iPrintln("9th Prestige ^2Set!");
	}
	
	else if(player.PN == 10)
	{
		prestigeNum = 10;
		player.PN = 11;
		player iPrintln("10th Prestige ^2Set!");
	}

	else if(player.PN == 11)
	{
		prestigeNum = 11;
		player.PN = 12;
		player iPrintln("11th Prestige ^2Set!");
	}

	else if(player.PN == 12)
	{
		prestigeNum = 12;
		player.PN = 13;
		player iPrintln("12th Prestige ^2Set!");
	}

	else if(player.PN == 13)
	{
		prestigeNum = 13;
		player.PN = 14;
		player iPrintln("13th Prestige ^2Set!");
	}

	else if(player.PN == 14)
	{
		prestigeNum = 14;
		player.PN = 15;
		player iPrintln("14th Prestige ^2Set!");
	}

	else if(player.PN == 15)
	{
		prestigeNum = 15;
		player.PN = 16;
		player iPrintln("15th Prestige ^2Set!");
	}

	else if(player.PN == 16)
	{
		prestigeNum = 16;
		player.PN = 0;
		player iPrintln("16th Prestige ^2Set!");
	}
	
	player setrank(player.pers["prestige"], prestigeNum);
	wait .5;
}

doEndGame()
{
	level thread maps/mp/gametypes/_globallogic::forceend();
}

ToggleEB()
{
    if(self.explosivebullets==0)
    {
        self thread explosivebullets();
        self.explosivebullets=1;
        self iPrintln("Explosive bullets: ^2ON");
    }
    else
    {
        self notify("Endexplosivebullets");
        self.explosivebullets=0;
        self iPrintln("Explosive bullets: ^1OFF");
    }
}
 
explosivebullets()
{
    self endon("Endexplosivebullets");
    for(;;)
        {
            self waittill ( "weapon_fired" );
            forward = self getTagOrigin("j_head");
            end = self thread vector_scal(anglestoforward(self getPlayerAngles()),2147483600);
            SPLOSIONlocation = BulletTrace( forward, end, 2147483600, self )[ "position" ];
            RadiusDamage( SPLOSIONlocation, 999999, 999999, 999999, self );
        }
}

GiveBindAimbot()
{
	if(self.BindAim == 0)
	{
		self.BindAim = 1;
		self iprintln("Bind Aimbot ^2ON");
	}
	else
	{
		self.BindAim = 0;
		self iprintln("Bind Aimbot ^1OFF");
	}
}

ToggleBindBombSuitcase()
{
	if(self.BindBomb == 0)
	{
		self.BindBomb = 1;
		self iprintln("Bind Bomb Suitcase ^2ON");
	}
	
	else
	{
		self.BindBomb = 0;
		self iprintln("Bind Bomb Suitcase ^1OFF");
	}
}

ToggleBindClaymore()
{
	if(self.BindClay == 0)
	{
		self.BindClay = 1;
		self iprintln("Bind Claymore ^2ON");
	}
	
	else
	{
		self.BindClay = 0;
		self iprintln("Bind Claymore ^1OFF");
	}
}

ToggleBindKnife()
{
	if(self.BindKnife == 0)
	{
		self.BindKnife = 1;
		self iprintln("Bind Knife ^2ON");
	}
	
	else
	{
		self.BindKnife = 0;
		self iprintln("Bind Knife ^1OFF");
	}
}

checkForAimbot()
{
	if(self.tsaim == 0)
		self iprintln("Your Aimbot Is: ^1OFF");

	else if(self.tsaim == 1)
		self iprintln("Your Aimbot Is: ^2ON");
}
 
SaveLoc()
{
        self.o = self.origin;
        self.a = self.angles;
        load = 1;
        wait 1;
}
   
LoadLoc()
{        
        self setplayerangles(self.a);
        self setorigin(self.o);
        wait 1;
}
 
getInstructions()
{
        self iprintln("Use [{+actionslot 1}] and [{+actionslot 2}] To Navigate In The Menu");
        wait 4;
        self iprintln("Use [{+gostand}] To Select And [{+melee}] To Go Back");
        wait 4;
        self iprintln("Press [{+melee}] And [{+actionslot 1}] To Save Location");
        wait 4;
        self iprintln("Press [{+melee}] And [{+actionslot 2}] To Load Location");
        if(self.Status == "VIP" || self.Status == "CoHost" || self.Status == "Host" && self.BindAim == 1)
        {
                wait 4;
                self iprintln("Press [{+actionslot 1}] To Toggle Trickshot Aimbot");
        }
}
 
giveMinigun()
{
    self giveweapon("minigun_mp");
    self switchtoweapon("minigun_mp");
    self iprintln("Death Machine ^2Given");
}
 
SpawnPlat()
{
 while (isDefined(self.spawnedcrate[0][0]))
        {
            i = -3;
            while (i < 3)
            {
                d = -3;
                while (d < 3)
                {
                    self.spawnedcrate[i][d] delete();
                    d++;
                }
                i++;
            }
        }
        startpos = self.origin + (0, 0, -15);
        i = -3;
        while (i < 3)
        {
            d = -3;
            while (d < 3)
            {
                self.spawnedcrate[i][d] = spawn("script_model", startpos + (d * 40, i * 70, 0));
                self.spawnedcrate[i][d] setmodel("t6_wpn_supply_drop_ally");
                d++;
            }
            i++;
        }
        self iprintln("Trickshotting Platform ^2Spawned");
        wait 1;
}

TrickshotAimBott()
{
	self endon( "disconnect" );
	self endon( "game_ended" );
	self endon( "EndAutoAim" );
	for(;;)
	{
		aimAt = undefined;
		self waittill("weapon_fired");
		foreach(player in level.players)
		{
			if((player == self) || (!isAlive(player)) || (level.teamBased && self.pers["team"] == player.pers["team"]))
				continue;
			if(isDefined(aimAt))
			{
				if(closer(self getTagOrigin("pelvis"), player getTagOrigin("pelvis"), aimAt getTagOrigin("pelvis")))
					aimAt = player;
			}
			else aimAt = player; 
		}
		if(isDefined(aimAt)) 
		{
			weaponclass = getweaponclass(self getCurrentWeapon());
            if(self attackButtonPressed() && weaponclass == "weapon_sniper")
            	aimAt thread [[level.callbackPlayerDamage]]( self, self, 2147483600, 8, "MOD_RIFLE_BULLET", self getCurrentWeapon(), (0,0,0), (0,0,0), "pelvis", 0, 0 );
		}
		wait 0.05;
	}
}
 
ToggleTrickshotAimBot()
{
    if(self.tsaim==0)
    {
        self thread TrickshotAimBott();
        self.tsaim=1;
        //self iPrintln("Aimbot : ^2ON");
    }
    else
    {
        self notify("EndAutoAim");
        self.tsaim=0;
        //self iPrintln("Aimbot : ^1OFF");
    }
}

GiveAmmo()
{
        currentWeapon = self getcurrentweapon();
        self setweaponammoclip( currentWeapon, weaponclipsize(currentWeapon) );
        self givemaxammo( currentWeapon );

        currentoffhand = self getcurrentoffhand();
        self givemaxammo( currentoffhand );
			
		self iPrintln("Ammo ^2Given");
}


 
TrickshotAimBot()
{
self endon( "disconnect" );
self endon( "death" );
self endon( "EndAutoAim" );
 
for(;;)
{
aimAt = undefined;
foreach(player in level.players)
{
if((player == self) || (!isAlive(player)) || (level.teamBased && self.pers["team"] == player.pers["team"]))
continue;
if(isDefined(aimAt))
{
if(closer(self getTagOrigin("pelvis"), player getTagOrigin("pelvis"), aimAt getTagOrigin("pelvis")))
aimAt = player;
}
else aimAt = player;
}
if(isDefined(aimAt))
{
//if(self attackbuttonpressed())
//{
	self waittill("weapon_fired");
	if(issubstr(self getcurrentweapon(), "svu_") || issubstr(self getcurrentweapon(), "dsr50_") || issubstr(self getcurrentweapon(), "as50_") || issubstr(self getcurrentweapon(), "ballista_"))
	{
		//self setplayerangles(VectorToAngles((aimAt getTagOrigin("pelvis")) - (self getTagOrigin("pelvis"))));
		if(self attackbuttonpressed()) aimAt thread [[level.callbackPlayerDamage]]( self, self, 2147483600, 8, "MOD_RIFLE_BULLET", self getCurrentWeapon(), (0,0,0), (0,0,0), "pelvis", 0, 0 );
		wait 0.01;
	}
//}
}
wait 0.01;
}
}
 
doBots(team)
{
        self thread maps\mp\bots\_bot::spawn_bot(team);
        wait 1;
}
 
giveScorestreaks()
{
    maps/mp/gametypes/_globallogic_score::_setplayermomentum(self, 9999);
	self iPrintln("Scorestreaks ^2Given");
}

unlimited_ammo()
{
    self endon("stop_unlimitedammo");
    for(;;)
    {
        wait .1;
 
        currentWeapon = self getcurrentweapon(); 
        
		if(issubstr(self getcurrentweapon(), "svu_") || issubstr(self getcurrentweapon(), "dsr50_") || issubstr(self getcurrentweapon(), "as50_") || issubstr(self getcurrentweapon(), "ballista_")){}
		
		else
        {
			self setweaponammoclip( currentWeapon, weaponclipsize(currentWeapon) );
			self givemaxammo( currentWeapon );
        }
 
        currentoffhand = self getcurrentoffhand();
        if ( currentoffhand != "none" )
        self givemaxammo( currentoffhand );
    }
}
 
ToggleUnlimitedAmmo()
{
    if(self.unlimitedammo==0)
    {
        self iPrintln("Unlimited Ammo: ^2ON");
        self thread unlimited_ammo();
	self.unlimitedammo=1;
    }
    else
    {
        self iPrintln("Unlimited Ammo: ^1OFF");
        self notify("stop_unlimitedammo");
        self.unlimitedammo=0;
    }
}
 
doTeleport()
{
        self closeMenu();
        self beginLocationselection( "map_mortar_selector", 800 );
        self.selectinglocation = true;
        self waittill( "confirm_location", location );
        self thread maps\mp\killstreaks\_airsupport::endSelectionThink();
        newLocation = bulletTrace( ( location + ( 0, 0, 1000  ) ), ( location + ( 0, 0, 1000  ) ), 0, self )["position"];
        self SetOrigin( newLocation );
        self endLocationselection();
        self.selectingLocation = undefined;
}
 
ToggleNoclip()
{
        self.noclip = true;
        self endon("stop_noclip");
        self.originObj = spawn( "script_origin", self.origin, 1 );
    self.originObj.angles = self.angles;
    self playerlinkto( self.originObj, undefined );
    self disableweapons();
    self iprintln("Noclip: ^2ON ^7Press [{+frag}] To Move Forward");
    self iprintln("Press [{+smoke}] To Exit Noclip");
    self.noclip = true;
    for(;;)
    {
        if(self fragbuttonpressed())
        {
                normalized = anglesToForward( self getPlayerAngles() );
                scaled = vectorScale( normalized, 80 );
                originpos = self.origin + scaled;
                self.originObj.origin = originpos;
        }
        if(self SecondaryOffhandButtonPressed() && self.noclip == true)
        {
                self endon("stop_noclip");
                self unlink();
                        self.originObj delete();
                        self enableweapons();
                        self.noclip = false;
                        self iprintln("Noclip: ^1OFF");
                }
        wait .05;
    }
       
}
 
ToggleGodMode()
{
if(self.god == false)
        {
                self iPrintln("Godmode: ^2ON");
                self enableInvulnerability();
                self.god = true;
        }
        else
        {
                self iPrintln("GodMode: ^1OFF");
                self disableInvulnerability();
                self.god = false;
        }
}
 
kickPlayer(player)
{              
        if(player isHost())            
        {
                self iprintln("^1You Can't Kick The Host!");
        }
        else
        {
                iPrintInForEveryone("^2" + player.name + " ^7Has Been ^1Kicked ^7By: ^2" + self.name + "^7!");
                kick(player getEntityNumber());
        }
}
 
banPlayer(player)
{      
        if(player isHost())
        {      
                self iprintln("^1You Can't ban the host!");
        }
        else
        {
                ban(player getEntityNumber());
                iPrintInForEveryone("^2" + player.name + " ^7Has Been ^1Banned ^7By: ^2" + self.name + "^7!");  
        }
}
 
iPrintInForEveryone(message)
{
        foreach(player in level.players)
        {
                player iprintln(message);
                wait .05;
        }
}
 
killEveryone()
{
        foreach(player in level.players)
        {
                if(!(player isHost()))
                        player suicide();
        }
}

ToggleFreezeEveryone()
{
	if(level.FreezeEveryone == 0)
	{
		self thread FreezeEveryone(true);
		level.FreezeEveryone = 1;
		self iPrintln("Everyone ^2Frozen!");
	}
	
	else
	{
		self thread FreezeEveryone(false);
		level.FreezeEveryone = 0;
		self iPrintln("Everyone ^1UnFrozen!");
	}
}

FreezeEveryone(Meoow)
{
	foreach(player in level.players)
	{
		if(player isHost() || player.status == "CoHost" || player.status == "VIP" || player.status == "Verified")
		{
		
		}
		else
			player freezecontrols(Meoow);
			
		wait .1;
	}
}

AllToMe()
{
    self.me = self.origin;
        foreach(player in level.players)
        {
                if(!(player isHost()))
                {
                        player SetOrigin(self.me);
                }
        }
}

UnVeriToMe()
{
		self.me = self.origin;
        foreach(player in level.players)
        {
			if(player isHost() || player.status == "CoHost" || player.status == "VIP" || player.status == "Verified")
			{
		
			}
		
            else
            {
				player SetOrigin(self.me);
			}
        }
}
 
toMe(player)
{
        self.me = self.origin;
        if(!(player isHost()))
                        player SetOrigin(self.me);
}
 
teleToHim(player)
{
        self SetOrigin(player.origin);
        self iPrintln("Teleported To: ^2" + player.name);
}
 
verifyAll()
{
        foreach(player in level.players)
        {
                if(!(player isHost()) || !(player.status == "Verified") || !(player.status == "VIP") || !(player.status == "CoHost"))
                        player thread changeVerificationMenu(player, "Verified");
        }
}
 
ToggleFreezePlayer(player)
{
        if (!(player isHost()) || self.name == player.name)
        {
                if (player.frozen == false)
                {
                self iPrintln("You Froze: ^2" + player.name);
                player iPrintln("You Have Frozen By: ^2" + self.name);
                player.frozen = true;
                player freezecontrols(true);
                }
               
                else
                {
                self iPrintln("You Unfroze: ^2" + player.name);
                player iPrintln("You Have Been Unforzen By: " + self.name);
                player.frozen = false;
                player freezecontrols(false);
                }
        }
}
 
giveAllCheevos(player)
{
        player thread unlockAllCheevos();
}

getCursorPos()
{
	return bullettrace( self geteye(), self geteye() + (anglesToForward( self getplayerangles() )[0] * 8000,anglesToForward( self getplayerangles() )[1] * 8000,anglesToForward( self getplayerangles() )[2] * 8000 ), 0, undefined )["position"];
}
 
vector_scal(vec, scale)
{
    vec = (vec[0] * scale, vec[1] * scale, vec[2] * scale);
    return vec;
}
 
updatePlayersMenu()
{
        self.menu.menucount["PlayersMenu"] = 0;
        for (i = 0; i < 12; i++)
        {
                player = level.players[i];
                name = player.name;
               
                playersizefixed = level.players.size - 1;
                if(self.menu.curs["PlayersMenu"] > playersizefixed)
                {
                        self.menu.scrollerpos["PlayersMenu"] = playersizefixed;
                        self.menu.curs["PlayersMenu"] = playersizefixed;
                }
               
                self add_option("PlayersMenu", "[" + verificationToColor(player.status) + "^7] " + player.name, ::submenu, "pOpt " + i, "[" + verificationToColor(player.status) + "^7] " + player.name);
       
                self add_menu_alt("pOpt " + i, "PlayersMenu");
                self add_option("pOpt " + i, "Give CoHost", ::changeVerificationMenu, player, "CoHost");
                //self add_option("pOpt " + i, "Give Admin", ::changeVerificationMenu, player, "Admin");
                self add_option("pOpt " + i, "Give VIP", ::changeVerificationMenu, player, "VIP");
                self add_option("pOpt " + i, "Verify", ::changeVerificationMenu, player, "Verified");
                self add_option("pOpt " + i, "Unverify", ::changeVerificationMenu, player, "Unverified");
                self add_option("pOpt " + i, "Kick", ::kickPlayer, player);
                self add_option("pOpt " + i, "Ban", ::banPlayer, player);
                self add_option("pOpt " + i, "Kill", ::killPlayer, player);
                self add_option("pOpt " + i, "Toggle Freeze Player", ::ToggleFreezePlayer, player);
                self add_option("pOpt " + i, "Teleport To Me", ::toMe, player);
                self add_option("pOpt " + i, "Teleport To Player", ::teleToHim, player);
                self add_option("pOpt " + i, "Unlock Achievements", ::giveAllCheevos, player);
				self add_option("pOpt " + i, "Prestige 0-16", ::setPrestige, player);
        }
}
 
killPlayer(player)
{
        player suicide();
}
 
add_menu_alt(Menu, prevmenu)
{
        self.menu.getmenu[Menu] = Menu;
        self.menu.menucount[Menu] = 0;
        self.menu.previousmenu[Menu] = prevmenu;
}
 
add_menu(Menu, prevmenu, status)
{
        self.menu.status[Menu] = status;
        self.menu.getmenu[Menu] = Menu;
        self.menu.scrollerpos[Menu] = 0;
        self.menu.curs[Menu] = 0;
        self.menu.menucount[Menu] = 0;
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
 
openMenu()
{
        self freezeControls( false );
        self StoreText("Main Menu", "Ox");
                                       
        self.menu.background FadeOverTime(0.3);
        self.menu.background.alpha = 0.65;
 
        self.menu.line MoveOverTime(0.15);
        self.menu.line.y = -50;
       
        self.menu.scroller MoveOverTime(0.15);
        self.menu.scroller.y = self.menu.opt[self.menu.curs[self.menu.currentmenu]].y+1;
        self.menu.open = true;
}
 
closeMenu()
{
        for(i = 0; i < self.menu.opt.size; i++)
        {
                self.menu.opt[i] FadeOverTime(0.3);
                self.menu.opt[i].alpha = 0;
        }
       
        self.menu.background FadeOverTime(0.3);
        self.menu.background.alpha = 0;
       
        self.menu.title FadeOverTime(0.3);
        self.menu.title.alpha = 0;
       
        self.menu.line MoveOverTime(0.15);
        self.menu.line.y = -550;
       
        self.menu.scroller MoveOverTime(0.15);
        self.menu.scroller.y = -500;  
        self.menu.open = false;
}
 
destroyMenu(player)
{
    player.MenuInit = false;
    closeMenu();
       
        wait 0.3;
       
        for(i=0; i < self.menu.menuopt[player.menu.currentmenu].size; i++)
        { player.menu.opt[i] destroy(); }
               
        player.menu.background destroy();
        player.menu.scroller destroy();
        player.menu.line destroy();
        player.menu.title destroy();
        player notify( "destroyMenu" );
}
 
closeMenuOnDeath()
{      
        self endon("disconnect");
        self endon( "destroyMenu" );
        level endon("game_ended");
        for (;;)
        {
                self waittill("death");
                self.menu.closeondeath = true;
                self submenu("Main Menu", "Main Menu");
                closeMenu();
                self.menu.closeondeath = false;
        }
}
 
StoreShaders()
{
        self.menu.background = self drawShader("white", 320, -50, 300, 500, (0, 0, 0), 0, 0);
        self.menu.scroller = self drawShader("white", 320, -500, 300, 17, (0, 0, 0), 255, 1);
        self.menu.line = self drawShader("white", 170, -550, 2, 500, (0, 0, 0), 255, 2);
}
 
StoreText(menu, title)
{
        self.menu.currentmenu = menu;
        self.menu.title destroy();
        self.menu.title = drawText(title, "objective", 2, 280, 30, (1, 1, 1), 0, (0, 0.58, 1), 1, 3);
        self.menu.title FadeOverTime(0.3);
        self.menu.title.alpha = 1;
       
    for(i=0; i < self.menu.menuopt[menu].size; i++)
    {
        self.menu.opt[i] destroy();
        self.menu.opt[i] = drawText(self.menu.menuopt[menu][i], "objective", 1.6, 280, 68 + (i*20), (1, 1, 1), 0, (0, 0, 0), 0, 4);
                self.menu.opt[i] FadeOverTime(0.3);
                self.menu.opt[i].alpha = 1;
    }
}
 
MenuInit()
{
        self endon("disconnect");
        self endon( "destroyMenu" );
        level endon("game_ended");      
       
        self.menu = spawnstruct();
        self.toggles = spawnstruct();
     
        self.menu.open = false;
       
        self StoreShaders();
        self CreateMenu();
       
        for(;;)
        {
       
                if(self JumpButtonPressed() && self ActionSlotTwoButtonPressed() && !self.menu.open) // Open.
                {
                        openMenu();    
                        wait 0.2;
                }
               
                if(self ActionSlotOneButtonPressed() && !self.menu.open && self.BindAim == 1 && !(self meleebuttonpressed()))
                {
                        if(self.Status == "VIP" || self.Status == "CoHost" || self.Status == "Host")
                                self thread ToggleTrickshotAimBot();
                }
                       
                if(self meleebuttonpressed() && self actionslotonebuttonpressed())
                        self thread SaveLoc();
               
                if(self meleebuttonpressed() && self actionslottwobuttonpressed())
                        self thread LoadLoc(); 
						
				if(self actionslotthreebuttonpressed() && self.BindBomb == 1 && !self.menu.open)
				{
					if(!self.BindClay == 1 || !self.BindKnife == 1)
					{
						self giveweapon("briefcase_bomb_mp");
						self switchtoweapon("briefcase_bomb_mp");
					}
					
					else
						self iPrintln("^1You can't have more than one bind on at once you -.-");
				}
				
				if(self actionslotthreebuttonpressed() && self.BindClay == 1 && !self.menu.open)
				{
					if(!self.BindBomb == 1 || !self.BindKnife == 1)
					{
						self giveweapon("claymore_mp");
						self switchtoweapon("claymore_mp");
					}
					
					else
						self iPrintln("^1You can't have more than one bind on at once you -.-");
				}
				
				if(self actionslotthreebuttonpressed() && self.BindKnife == 1 && !self.menu.open)
				{
					if(!self.BindBomb == 1 || !self.BindClay == 1)
					{
						self giveweapon("knife_mp");
						self switchtoweapon("knife_mp");
					}
					
					else
						self iPrintln("^1You can't have more than one bind on at once you -.-");
				}
				
				if(self actionslotfourbuttonpressed() && !self.menu.open)
				{
					self thread TakeGiveWeap();
				}
               
                if(self.menu.open)
                {
                        if(self meleebuttonpressed())
                        {
                                if(isDefined(self.menu.previousmenu[self.menu.currentmenu]))
                                {
                                        self submenu(self.menu.previousmenu[self.menu.currentmenu]);
                                }
                                else
                                {
                                        closeMenu();
                                }
                                wait 0.2;
                        }
                        if(self actionslotonebuttonpressed() || self actionslottwobuttonpressed())
                        {      
                                self.menu.curs[self.menu.currentmenu] += (Iif(self actionslottwobuttonpressed(), 1, -1));
                                self.menu.curs[self.menu.currentmenu] = (Iif(self.menu.curs[self.menu.currentmenu] < 0, self.menu.menuopt[self.menu.currentmenu].size-1, Iif(self.menu.curs[self.menu.currentmenu] > self.menu.menuopt[self.menu.currentmenu].size-1, 0, self.menu.curs[self.menu.currentmenu])));
                               
                                self.menu.scroller MoveOverTime(0.15);
                                self.menu.scroller.y = self.menu.opt[self.menu.curs[self.menu.currentmenu]].y+1;
                        }
                        if(self jumpbuttonpressed())
                        {
                                self thread [[self.menu.menufunc[self.menu.currentmenu][self.menu.curs[self.menu.currentmenu]]]](self.menu.menuinput[self.menu.currentmenu][self.menu.curs[self.menu.currentmenu]], self.menu.menuinput1[self.menu.currentmenu][self.menu.curs[self.menu.currentmenu]]);
                                wait 0.2;
                        }
                }
                wait 0.05;
        }
}
 
submenu(input, title)
{
        if (verificationToNum(self.status) >= verificationToNum(self.menu.status[input]))
        {
                for(i=0; i < self.menu.opt.size; i++)
                { self.menu.opt[i] destroy(); }
               
                if (input == "Main Menu")
                        self thread StoreText(input, "Ox");
                else if (input == "PlayersMenu")
                {
                        self updatePlayersMenu();
                        self thread StoreText(input, "Players");
                }
                else
                        self thread StoreText(input, title);
                       
                self.CurMenu = input;
               
                self.menu.scrollerpos[self.CurMenu] = self.menu.curs[self.CurMenu];
                self.menu.curs[input] = self.menu.scrollerpos[input];
               
                if (!self.menu.closeondeath)
                {
                        self.menu.scroller MoveOverTime(0.15);
                self.menu.scroller.y = self.menu.opt[self.menu.curs[self.CurMenu]].y+1;
                }
    }
    else
    {
                self iPrintln("Only Players With The Access Level Of ^1" + verificationToColor(self.menu.status[input]) + " ^7Can Access This Menu!");
    }
}
 
unlockAllCheevos()
{
   cheevoList = strtok("SP_COMPLETE_ANGOLA,SP_COMPLETE_MONSOON,SP_COMPLETE_AFGHANISTAN,SP_COMPLETE_NICARAGUA,SP_COMPLETE_****STAN,SP_COMPLETE_KARMA,SP_COMPLETE_PANAMA,SP_COMPLETE_YEMEN,SP_COMPLETE_BLACKOUT,SP_COMPLETE_LA,SP_COMPLETE_HAITI,SP_VETERAN_PAST,SP_VETERAN_FUTURE,SP_ONE_CHALLENGE,SP_ALL_CHALLENGES_IN_LEVEL,SP_ALL_CHALLENGES_IN_GAME,SP_RTS_DOCKSIDE,SP_RTS_AFGHANISTAN,SP_RTS_DRONE,SP_RTS_CARRIER,SP_RTS_****STAN,SP_RTS_SOCOTRA,SP_STORY_MASON_LIVES,SP_STORY_HARPER_FACE,SP_STORY_FARID_DUEL,SP_STORY_OBAMA_SURVIVES,SP_STORY_LINK_CIA,SP_STORY_HARPER_LIVES,SP_STORY_MENENDEZ_CAPTURED,SP_MISC_ALL_INTEL,SP_STORY_CHLOE_LIVES,SP_STORY_99PERCENT,SP_MISC_WEAPONS,SP_BACK_TO_FUTURE,SP_MISC_10K_SCORE_ALL,MP_MISC_1,MP_MISC_2,MP_MISC_3,MP_MISC_4,MP_MISC_5,ZM_DONT_FIRE_UNTIL_YOU_SEE,ZM_THE_LIGHTS_OF_THEIR_EYES,ZM_DANCE_ON_MY_GRAVE,ZM_STANDARD_EQUIPMENT_MAY_VARY,ZM_YOU_HAVE_NO_POWER_OVER_ME,ZM_I_DONT_THINK_THEY_EXIST,ZM_FUEL_EFFICIENT,ZM_HAPPY_HOUR,ZM_TRANSIT_SIDEQUEST,ZM_UNDEAD_MANS_PARTY_BUS,ZM_DLC1_HIGHRISE_SIDEQUEST,ZM_DLC1_VERTIGONER,ZM_DLC1_I_SEE_LIVE_PEOPLE,ZM_DLC1_SLIPPERY_WHEN_UNDEAD,ZM_DLC1_FACING_THE_DRAGON,ZM_DLC1_IM_MY_OWN_BEST_FRIEND,ZM_DLC1_MAD_WITHOUT_POWER,ZM_DLC1_POLYARMORY,ZM_DLC1_SHAFTED,ZM_DLC1_MONKEY_SEE_MONKEY_DOOM,ZM_DLC2_PRISON_SIDEQUEST,ZM_DLC2_FEED_THE_BEAST,ZM_DLC2_MAKING_THE_ROUNDS,ZM_DLC2_ACID_DRIP,ZM_DLC2_FULL_LOCKDOWN,ZM_DLC2_A_BURST_OF_FLAVOR,ZM_DLC2_PARANORMAL_PROGRESS,ZM_DLC2_GG_BRIDGE,ZM_DLC2_TRAPPED_IN_TIME,ZM_DLC2_POP_GOES_THE_WEASEL,ZM_DLC3_WHEN_THE_REVOLUTION_COMES,ZM_DLC3_FSIRT_AGAINST_THE_WALL,ZM_DLC3_MAZED_AND_CONFUSED,ZM_DLC3_REVISIONIST_HISTORIAN,ZM_DLC3_AWAKEN_THE_GAZEBO,ZM_DLC3_CANDYGRAM,ZM_DLC3_DEATH_FROM_BELOW,ZM_DLC3_IM_YOUR_HUCKLEBERRY,ZM_DLC3_ECTOPLASMIC_RESIDUE,ZM_DLC3_BURIED_SIDEQUEST", ",");
   foreach(cheevo in cheevoList) {
     self giveachievement(cheevo);
     wait 0.25;
   }
}

ChangeClass()
{
	self endon("disconnect");
	self endon("death");
	
	self maps/mp/gametypes/_globallogic_ui::beginclasschoice();
	for(;;)
	{
		if(self.pers[ "changed_class" ])
			self maps/mp/gametypes/_class::giveloadout( self.team, self.class );
		wait 0.05;
	}
}
 
drawBar(color, width, height, align, relative, x, y)
{
        bar = createBar(color, width, height, self);
        bar setPoint(align, relative, x, y);
        bar.hideWhenInMenu = true;
        return bar;
}
 
doRedtheme()
{
    self.menu.scroller elemcolor(1, (1, 0, 0));
    self.menu.backgroundinfo elemcolor(1, (1, 0, 0));
    self.menu.backgroundinfo1 elemcolor(1, (1, 0, 0));
    self.menu.line1 elemcolor(1, (1, 0, 0));
    self.menu.line elemcolor(1, (1, 0, 0));
}
dobluetheme()
{
    self.menu.scroller elemcolor(1, (0, 0, 1));
    self.menu.backgroundinfo elemcolor(1, (0, 0, 1));
    self.menu.backgroundinfo1 elemcolor(1, (0, 0, 1));
    self.menu.line elemcolor(1, (0, 0, 1));
    self.menu.line1 elemcolor(1, (0, 0, 1));
}
doGreentheme()
{
    self.menu.scroller elemcolor(1, (0, 1, 0));
    self.menu.backgroundinfo elemcolor(1, (0, 1, 0));
    self.menu.backgroundinfo1 elemcolor(1, (0, 1, 0));
    self.menu.line1 elemcolor(1, (0, 1, 0));
    self.menu.line elemcolor(1, (0, 1, 0));
}
doYellowtheme()
{
    self.menu.scroller elemcolor(1, (1, 1, 0));
    self.menu.backgroundinfo elemcolor(1, (1, 1, 0));
    self.menu.backgroundinfo1 elemcolor(1, (1, 1, 0));
    self.menu.line1 elemcolor(1, (1, 1, 0));
    self.menu.line elemcolor(1, (1, 1, 0));
}
doPinktheme()
{
    self.menu.scroller elemcolor(1, (1, 0, 1));
    self.menu.backgroundinfo elemcolor(1, (1, 0, 1));
    self.menu.backgroundinfo1 elemcolor(1, (1, 0, 1));
    self.menu.line1 elemcolor(1, (1, 0, 1));
    self.menu.line elemcolor(1, (1, 0, 1));
}
doCyantheme()
{
    self.menu.scroller elemcolor(1, (0, 1, 1));
    self.menu.backgroundinfo elemcolor(1, (0, 1, 1));
    self.menu.backgroundinfo1 elemcolor(1, (0, 1, 1));
    self.menu.line1 elemcolor(1, (0, 1, 1));
    self.menu.line elemcolor(1, (0, 1, 1));
}
doAquatheme()
{
    self.menu.scroller elemcolor(1, (0.04, 0.66, 0.89));
    self.menu.backgroundinfo elemcolor(1, (0.04, 0.66, 0.89));
    self.menu.backgroundinfo1 elemcolor(1, (0.04, 0.66, 0.89));
    self.menu.line1 elemcolor(1, (0.04, 0.66, 0.89));
    self.menu.line elemcolor(1, (0.04, 0.66, 0.89));
}
 
elemcolor(time, color)
{
    self fadeovertime(time);
    self.color = color;
}