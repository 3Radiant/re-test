# Reclamation (rebuild)

A clean Rojo rebuild of the Warley / Attack on Titan game: movement, custom camera, projectile guns with
the Idle → Ready → Aiming stance system, and shifters (Armored, Attack, Female) with melee combat,
transformation and de-shifting.

## Setup

```
aftman install          # installs Rojo 7.7.0
rojo build -o Reclamation.rbxlx
rojo serve              # then connect from Studio's Rojo plugin
```

Open `Reclamation.rbxlx`, press Play. Everything the game needs (spawn, baseplate, `Hitboxes` folder,
`ServerStorage/Titans` and `ServerStorage/Guns`) is created by `default.project.json`, so a fresh
`rojo build` works from scratch. RemoteEvents are created in code (`Shared/Remotes`).

## Controls

| Key | Action |
| --- | --- |
| WASD / Space | move / jump |
| Left Shift | sprint |
| Left Ctrl | crouch (hold) |
| Hold Right Mouse | look around (cursor stays free for aiming) |
| Scroll | zoom |
| 1 | equip / unequip the rifle |
| Click | ready the gun (Idle → Ready). While Aiming: fire. Empty gun: reload |
| F | Ready ⇄ Aiming (you must ready the gun first) |
| R | reload |
| P | shift into your Titan / turn back |
| Left Click (Titan) | melee combo |
| Q (Armored Titan) | Harden |

Aiming is a slow walk (no jump, sprint or crouch) that turns you toward the mouse. Reloading drops you back
to Idle so you can run while it finishes.

## Layout

```
src/
├─ shared/                       -> ReplicatedStorage.Shared
│  ├─ Configs/                   Config, AnimationConfigs, GunConfigs/*, TitanConfigs/*
│  ├─ Gun/                       GunStates (stance rules), Ballistics (projectile sim)
│  ├─ Hitbox, PlayerState (global state), Remotes
├─ server/                       -> ServerScriptService.Server (init.server.luau)
│  ├─ Services/                  Damage, Gun, Player, Shifter
│  └─ Shifter/                   ShifterBase, TitanFactory, Effects, Titans/ArmoredTitan
├─ client/                       -> StarterPlayerScripts.Client (init.client.luau)
│  ├─ Controllers/               Camera, Character, Gun, Shifter, Hud
│  └─ Gun/                       Aim, BulletVisuals
└─ character/Animate.client.luau (empty; suppresses Roblox's default Animate)
assets/titans, assets/guns       drop real models here (see below)
```

## How to customise

- **New gun:** add `src/shared/Configs/GunConfigs/<Name>.luau` (copy `Kar98k`). Put a Tool named `<Name>` in
  `assets/guns` for a real model (needs a `Handle` with a `Muzzle` Attachment).
- **New Titan:** add `TitanConfigs/<Name>.luau`. Optional subclass in `server/Shifter/Titans/<Name>.luau`
  for unique abilities (see `ArmoredTitan`). Real model → `assets/titans/<Name>` (needs Humanoid,
  HumanoidRootPart as PrimaryPart, and a part named `Nape`).
- **Animations:** every ID lives in `AnimationConfigs` / the Titan configs. Blank IDs are skipped. Gun
  animations (idle, ready, aim, fire, reload) should be arm/torso-only so legs keep walking.
- **Movement restrictions:** `CharacterController.setLock(name, {...})` / `clearLock(name)`. The gun uses it
  for aiming and the shifter for the transformation, so systems never fight over WalkSpeed.
- **Global state:** `PlayerState` (attributes on the Player: Shifted, Transforming, ShifterName, ...).

## Testing tips

- `Config.Shifting.MaxShifts` (default 3) and `Cooldown` (20 s) are low on purpose; raise MaxShifts while testing.
- `Config.DebugHitboxes = true` draws Titan melee hitboxes in red.
- Studio chat: `/titan AttackTitan` or `/titan FemaleTitan` switches which Titan you wield (human form only).

## Known limitations

- Written without access to Roblox Studio: it builds with Rojo and passes syntax and path checks, but has not
  been play-tested. Expect some tuning (hit boxes, camera feel, Titan spawn height).
- Titan models are placeholders (recoloured R15 rig scaled to 15 m × 3 studs/m). Anime heights are used for
  the Titans (Armored 15 m, Attack 15 m, Female 14 m); all combat stats are gameplay placeholders.
- Rifles do 5% damage to Titans (nape ×2). Tune `Config.Damage`.
- No lag compensation, mobile/controller input, or datastore persistence yet.
