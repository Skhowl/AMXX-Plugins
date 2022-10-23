# Semiclip Mod v3.3.2
**Zombie Plague v5.0 _(Recommended v5.0.8a)_**

### Content:
+ [Features](#features-)
+ [Requirements](#requirements-)
+ [Other Versions](#other-versions-)
+ [Youtube](#youtube-)
+ [Plugin Customization Section](#plugin-customization-section-)
+ [Supported Entities](#supported-entities-)
+ [To Do List](#to-do-list-)
+ [Credits](#credits-)

### Features: [🡅](#semiclip-mod-v332)
+ team semiclip
+ single / both teams
+ enemy trespass
+ button activation (customize)
+ boosting
+ unstuck on team change
+ preparation (own unstuck algorithm)
+ duration (own unstuck algorithm)
+ knife trace to next enemy
+ constant / fading render
+ render for humans, zombies, admins
+ render visual for alive, death and spectators
+ **entities movement while in semiclip**
+ **no one gets blocked before first zombie is choosen**

### Requirements: [🡅](#semiclip-mod-v332)
+ **Game**: Counter-Strike 1.6 or Condition Zero
+ **Metamod**: Version **1.19** or later
+ **AMXX**: Version **1.8.1** or later
+ **Module**: cstrike, engine, fakemeta, hamsandwich

### Other Versions: [🡅](#semiclip-mod-v332)
+ For **Counter-Strike 1.6 or Condition Zero** version click [here](../%5BCS%5D%20Semiclip%20Mod).
+ For **Day of Defeat 1.3** version click [here](../%5BDoD%5D%20Semiclip%20Mod).
+ For **Zombie Plague 4.3** version click [here](../%5BZP43%5D%20Semiclip%20Mod).

### Youtube: [🡅](#semiclip-mod-v332)
+ [v1.8.8 with Bots and new native](https://www.youtube.com/watch?v=TC27ZSmuL00)
+ [v3.1.0 func_door showcase](https://www.youtube.com/watch?v=XGcUjWvFwmg)
+ [v3.1.0 func_door_rotating showcase](https://www.youtube.com/watch?v=L8tVNr-Mjxc)
+ [v3.2.0 knife trace fix](https://www.youtube.com/watch?v=K1hYlyZ67W8)

### Plugin Customization Section: [🡅](#semiclip-mod-v332)
```
const Float:CVAR_INTERVAL  = 6.0 /* ¬ 6.0 */
const Float:SPEC_INTERVAL  = 0.2 /* ¬ 0.2 */
const Float:RANGE_INTERVAL = 0.1 /* It's like a 10 FPS server ¬ 0.1 */

#define MAX_PLAYERS     32  /* Server slots ¬ 32 */
#define MAX_REG_SPAWNS  24  /* Max cached regular spawns ¬ 24 */
#define MAX_CSDM_SPAWNS 60  /* CSDM 2.1.2 value if you have more increase it ¬ 60 */
#define MAX_ENT_ARRAY   128 /* Is for max 4096 entities (128*32=4096) ¬ 128 */
```

### Supported Entities: [🡅](#semiclip-mod-v332)
`This plugin don't fix any kind of GoldSrc entity issues! Fixed in 3.2+ [✔]`
+ func_button
+ func_door
+ func_door_rotating
+ func_guntarget
+ func_pendulum
+ func_plat
+ func_platrot
+ func_rot_button
+ func_rotating
+ func_tank
+ func_trackchange
+ func_tracktrain
+ func_train
+ func_vehicle
+ momentary_door
+ momentary_rot_button

### To Do List: [🡅](#semiclip-mod-v332)
+ [✔] nothing

### Credits: [🡅](#semiclip-mod-v332)
+ SchlumPF*: Team Semiclip (main core)
+ joaquimandrade: Module: Semiclip (some cvars)
+ ConnorMcLeod: show playersname (bugfix)
+ MeRcyLeZZ & VEN: Unstuck (function)
+ georgik57: for many suggestions and help, you are the best
+ Bugsy: for his bitsum macro's
