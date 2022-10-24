# Bullet Damage with Ranking v3.0.2

### Content:
+ [Description](#description-)
+ [Features](#features-)
+ [Requirements](#requirements-)
+ [Plugin Customization](#plugin-customization-)
+ [Credits](#credits-)

### Description: [🡅](#bullet-damage-with-ranking-v302)
```
Display single, multiple, grenade or take Damage via Hud message.
Can give a Chat announce, if you score a new weapon/personal record.
The Chat command /bd show up a menu to configuration your bd.
```

### Features: [🡅](#bullet-damage-with-ranking-v302)
- Support for multiple languages
- Support Lan Server
- Support FFA (Free For All) server
- Support Zombie Plague 4.3 (look Plugin Customization section)
- Support Zombie Plague Advance 1.6 (look Plugin Customization section)
- Player and admin menu
- Records are stored by Steam ID
- Only authorized Steam players can made records
- HUD-Damage indicator can distinguish whether the shot was visible or behind a wall
- Better settings on the bulletdamage.cfg
- Server admins can reset all the records about a command or only a certain weapon record (bd_reset "argument")
- The time of the weapons firing rate is adjustable, for the calculation of the record task (look Plugin Customization section)
- And much more...

### Requirements: [🡅](#bullet-damage-with-ranking-v302)
+ **Game**: Counter-Strike 1.6 or Condition Zero
+ **Metamod**: Version **1.19** or later
+ **AMXX**: Version **1.8.0** or later
+ **Module**: cstrike, fakemeta, hamsandwich

### Plugin Customization: [🡅](#bullet-damage-with-ranking-v302)
```
// Save Records File
new const BD_RECORD_FILE[] = "bullet_damage_ranks"

// Firerate Time Multiply for Record Task
// 1.0 is normal | 2.0 is double
const Float:FIRERATE_MULTI = 1.5

// uncomment the line to have Zombie Plague 4.3 Compatibility
//#define ZOMBIE_PLAGUE_MOD
// uncomment the line to have Zombie Plague Advance 1.6 Compatibility
//#define ZOMBIE_PLAGUE_ADVANCE_MOD
```

### Credits: [🡅](#bullet-damage-with-ranking-v302)
+ MeRcyLeZZ: for some useful stuff
+ worldspawn: for few ideas - motd style, damage sorting, new command and bd_no_over_dmg ;)
+ Pneumatic: for the "bd_multi_dmg 2" idea
+ ConnorMcLeod: for Ham_TakeDamage forward idea (v2.2.0 -> HE-Grenade compatibility)
+ Alucard^: for the enable/disable (global) HUD-Damage idea
+ Hawk552: for approve and optimization plugin
+ GAARA54: for colored chat idea and Zombie Plague Advance 1.6 Compatibility request
