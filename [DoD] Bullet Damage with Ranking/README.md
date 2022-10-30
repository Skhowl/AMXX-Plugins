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
- Support Sturmbot 1.7b
- Support FFA (Free For All) server
- Support Lan Server
- Player and admin menu
- Records are stored by Steam ID
- Only authorized Steam players can make records
- HUD-Damage indicator can distinguish whether the shot was visible or behind a wall
- Better settings on the bulletdamage.cfg
- Server admins can reset all the records about a command or only a certain weapon record (bd_reset "argument")
- The time of the weapons firing rate is adjustable, for the calculation of the record task (see section Customization plugin)
- And much more ...

### Requirements: [🡅](#bullet-damage-with-ranking-v302)
+ **Game**: Day of Defeat 1.3
+ **Metamod**: Version **1.19** or later
+ **AMXX**: Version **1.8.0** or later
+ **Module**: fakemeta, hamsandwich

### Plugin Customization: [🡅](#bullet-damage-with-ranking-v302)
```
// Save Records File
new const BD_RECORD_FILE[] = "bullet_damage_ranks"

// Firerate Time Multiply for Record Task
// 1.0 is normal | 2.0 is double
const Float:FIRERATE_MULTI = 1.5
```

### Credits: [🡅](#bullet-damage-with-ranking-v302)
+ worldspawn: for few ideas - motd style, damage sorting, new command and bd_no_over_dmg ;)
+ Pneumatic: for the "bd_multi_dmg 2" idea
+ ConnorMcLeod: for Ham_TakeDamage forward idea
+ Alucard^: for the enable/disable (global) HUD-Damage idea
+ Hawk552: for optimization plugin
