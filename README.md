# Ramen Riot

A 3D Roblox brainrot game for make.fun's "Make the best AI Roblox brainrot game" bounty (roblox-brainrot-01). Set in a night-market ramen district, it is a game of its own: absurd noodle characters parade down a conveyor, you buy them, carry them to your own ramen stall, and they earn money every second while rival thieves and a Spice Storm try to take them from you.

[![make.fun · roblox-brainrot-01](https://make.fun/badge/roblox-brainrot-01.svg)](https://make.fun/bounty/roblox-brainrot-01?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)
[![rank](https://make.fun/badge/roblox-brainrot-01/skynurul/roblox-brainrot/rank.svg)](https://make.fun/bounty/roblox-brainrot-01/leaderboard?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)
[![reward](https://make.fun/badge/roblox-brainrot-01/skynurul/roblox-brainrot/reward.svg)](https://make.fun/bounty/roblox-brainrot-01?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)

## The game

- **The loop:** brainrots roll down the central conveyor with a price. Buy one (click it in the world, or use the Shop), carry it to your stall, step on your coloured pad and it starts earning money per second. Buy the next tier, then the next.
- **The cast:** 36 original ramen and noodle brainrots across 7 rarities (Common, Rare, Epic, Legendary, Mythic, Secret, Divine), each with a name, a rarity, a money-per-second rate and an absurd one-liner. Six mutations (Golden, Spicy, Frozen, Rainbow, Shadow, Giant) multiply earnings up to 10x.
- **The tension:** rivals can steal a brainrot off your stall and run it home, unless you lock your stall (60 seconds of safety, then a 2 minute cooldown). Every 100 seconds a **Spice Storm** sweeps the market: a warning, then a wave that flings anyone caught outside their own stall and scatters whatever they were carrying.
- **The progression:** rebirth wipes your money and clears your stall for a permanent +25% earnings per rebirth. An Index book tracks all 36 brainrots you have ever owned.
- **The world:** a night-market plaza built in Roblox's 3D space (conveyor, 8 colour-coded stalls, lanterns, market buildings, a ramen cart, a torii gate), played under a 3D camera with a ScreenGui interface over it: money, earnings rate, shop, Index, lock and rebirth buttons, storm warnings and toasts.

## How it is built

- `src/shared/` — `BrainrotData.luau` (the whole cast, rarities and mutations) and `Config.luau` (every tuning number in one place).
- `src/server/` — one service per job, all state in `DataService` alone: `BrainrotService` (conveyor, buying, carrying, placing), `MoneyService` (the one-second earnings tick and state snapshots), `StealService` (stealing and stall locks), `HazardService` (the Spice Storm), `RebirthService` (rebirths). `init.server.luau` creates the RemoteEvents and starts them.
- `src/client/Main.client.luau` — the whole interface: top bar, shop, Index book, lock and rebirth buttons, hazard banner and toasts. The server owns state; the client only draws it.
- `default.project.json` — the Rojo project: the whole 3D world as Parts plus the service tree. `game.rbxl` is the binary place Rojo builds from it.
- `main.ts` (Node 22, standard library only) hands the game in: it copies `game.rbxl`, `src/`, `screenshots/` and `PLAY.json` to `/output` and writes `/output/dossier.json` with `vendor/makefun-roblox.ts`, the kit's copy, unchanged.

## Run it in Roblox Studio

1. Install Rojo 7.7.1 and open this repository.
2. Build the place: `rojo build default.project.json --output game.rbxl`
3. Open `game.rbxl` in Roblox Studio and press Play. The game runs as a server with your character in the night market.
4. Publish it from Studio as a Public experience, put your make.fun play code in its description, and fill in `PLAY.json` with its place id and universe id. Then take 3 or 4 screenshots in Studio (one of them is the thumbnail you upload for the experience) and put them in `screenshots/`.

## Hand it in

Run it as the grader does, writing `out/` in place of `/output`:

    mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts

Then run the kit's check from inside the unpacked kit:

    node cli/makefun.mjs check --repo /path/to/this/repository

The rules are on the bounty's page (/bounty/roblox-brainrot-01) and in the kit's RULES.txt, which gives every command in order (Before you submit, then Enter).

An unofficial fan-made game, built for the bounty. Not affiliated with Roblox Corporation.
