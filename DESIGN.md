# BIN NIGHT — full design

*A tag-team trash heist for Playdate. One street. One night. Three mouths to feed.*

Collection night in the suburbs. A garbage truck arrives at dawn and eats the
street bin by bin. Trash Panda, Bin Chicken and Alley Cat must crack, ferry
and sprint the night's loot back to their alley cache before it's gone —
and no one of them can do it alone.

Status: DESIGN ONLY (2026-07-05). Build follows the peckish/nectarrush
skeleton: multi-file Lua modules, Makefile staging, harness.lua smoke
autopilot, tools/smoke.sh.

---

## 1. The frame

- **World**: one suburban street, side-scrolling top-down, 1200x240 world
  (3 screens), camera follows the active character with look-ahead.
- **Home**: the ALLEY CACHE at the far left — a gap between two houses with
  a growing stash pile. Loot only scores once it is IN the cache.
- **Clock**: the night runs 10PM -> dawn (~4.5 min real time). At dawn the
  TRUCK enters at the far right and works toward the cache end, stopping at
  each house's bins: claw up, empty, gone forever. Total round ~5-6 min.
- **Goal**: bank the street's calorie QUOTA before the truck finishes the
  street. Meet quota -> next street (harder suburb, surplus carries over).
  Miss -> the gang goes hungry: game over. No deaths anywhere — every
  failure is lost time, dropped loot, or lost potential.

### Vertical bands (world y)
| band | y | contents |
| --- | --- | --- |
| house fronts | 0-60 | porches, doors, porch lights, glowing windows |
| front yards | 60-110 | lawns, hedges, sprinklers, dogs, clothesline, trees |
| fence line + footpath | 110-150 | fences (cat highways), gates, letterboxes |
| nature strip / curb | 150-185 | THE BINS, streetlights, storm drains |
| road | 185-240 | parked cars, night cars, the dawn truck |

## 2. The trio — character designs

The tag-team rule: **every character is a verb the other two lack.** Panda
opens, Chicken crosses, Cat runs. Every bin-to-cache trip is a routing
puzzle over those three verbs.

### TRASH PANDA — the Hands
- **Look**: stocky low oval, black mask band across a white face, 4-ring
  striped tail held flat behind, tiny dexterous front paws that patter
  when he works. Waddling gait — body rocks side to side. Carries heavy
  loot hoisted overhead with both paws, staggering. Freeze pose: sits up,
  paws to chest, wide eyes (two white circles in the mask).
- **Movement**: slowest (70 walk, no sprint). Cannot jump or fly; squeezes
  UNDER gates/fences with a 1.2s wriggle animation.
- **Verbs**:
  - **CRANK = PRY**: latched/bungeed bins and jar lids. Resistance curve
    with 2 scripted slips (crank spins back a quarter turn) then a fat
    CLUNK and the lid flips. Only Panda can do this.
  - **Heavy carry**: turkey carcass, watermelon half, whole cake — items
    no one else can lift. Slow drag, leaves a furrow line in lawns.
  - **B tap = BIN TIP**: shoulder-slam a whole bin over, spilling all its
    loot on the ground at once. VERY loud (big noise ring) — the smash-and
    -grab option when the truck is close.
- **Weak**: slow escape; last across the street when headlights sweep.

### BIN CHICKEN — the Reach
- **Look**: white ragged body, black head on a bare black neck, and the
  beak — a huge down-curved black scythe nearly a third of her length.
  Black wingtips and tail. Walks with a deliberate high-step strut, head
  jutting. Flight is gloriously ungainly: wide scruffy wings, legs
  dangling. Carries loot skewered on / dangling from the beak.
- **Movement**: medium walk (90). **A hold = FLAP**: short flapping glide
  over fences, hedges, sprinklers, dogs — stamina-limited (about 1.5
  fence-widths), recharges on the ground.
- **Verbs**:
  - **BEAK PLUNGE (A tap at a bin)**: steals small items through a closed
    lid's gap — no opening, no noise. The only character who can reach
    the bottom of the deep dumpster and the compost bin (worm delicacy
    bonus: chicken-only calories).
  - **Ferry**: the only way loot crosses fenced yards without a gate —
    fly it over and drop it to a teammate.
  - **B tap = SQUAWK**: the infamous ibis honk. A huge decoy noise ring
    centered on HER — dogs and woken homeowners retarget the chicken,
    who can flap off. The sacrificial-lure role.
- **Weak**: every flap emits a noise ring (wakes dogs, warms porch
  lights); carries exactly one small/medium item; a clumsy landing
  (landing on a fence or in a sprinkler burst) drops it.

### ALLEY CAT — the Legs
- **Look**: lean tuxedo moggy, tail a question mark, one ear with a
  chewed notch, white socks. Slinks low and long when walking near
  hazards; full stretched gallop at sprint; sits and wraps tail when
  parked. Carries small loot in mouth, head high.
- **Movement**: fastest (110 walk / 190 sprint on A hold, cheap). Walks
  ALONG fence tops — fences are cat highways over the yards. Squeezes
  through any gap instantly.
- **Verbs**:
  - **B tap = POUNCE**: short targeted leap. Kills rats, scares the
    possum, knocks small loot out of their grip. The only reliable
    counter to cache raids.
  - **Fence routes**: crosses the street's yard maze faster than anyone,
    ignoring gates entirely — but only with small cargo.
- **Weak**: smallest carry (small items only); dogs aggro on the cat at
  double radius; refuses to cross active sprinklers or puddles (stops
  and hisses).

## 3. The tag-team machine

- **Swap**: hold B (0.35s) -> a 3-portrait swap wheel; d-pad or crank
  selects, release swaps. Camera whips to the new character. (B tap
  stays the character special: tip / squawk / pounce.)
- **Parked jobs** — an idle character keeps working; the crew feels like
  a crew, not puppets:
  - Parked PANDA slowly drags whatever heavy item he's holding toward
    the cache (crawl speed). "Leave him hauling the turkey."
  - Parked CHICKEN pecks any open/tipped bin she's beside, piling small
    loot at her feet for someone to run home.
  - Parked CAT guards: auto-hisses rats off any loot within reach; parked
    AT the cache she auto-pounces cache raiders.
- **Relay bonus**: any item touched by 2+ characters between bin and
  cache banks at **x1.5 "TEAMWORK"**. The optimal play is literally the
  tag team: Panda cracks and tips, Chicken ferries over the fence,
  Cat runs the last leg. Floating "TEAMWORK x1.5!" text on bank.
- **Danger pings**: a parked character in a light cone / dog radius gets
  a HUD chip flash + leash of time before consequences — pulling the
  player into swap-to-rescue moments.

## 4. Loot & bins

Calories are score AND survival (quota). Weight classes gate carriers.

| class | carriers | examples | cal |
| --- | --- | --- | --- |
| small | all three | chicken wing, chip packet, sausage, fish skeleton | 10-30 |
| medium | panda, chicken (beak, wobbly) | pizza box, noodle box, bread loaf | 40-60 |
| heavy | panda only | turkey carcass, watermelon half, whole cake | 100-150 |
| legendary | varies | THE LASAGNA — one per street, worst bin | 400 |

Bin types (each house gets a cluster; the mix is the difficulty dial):
- **Open-top**: anyone rummages (A). Cheap loot.
- **Lidded**: panda/cat flip the lid (noise blip) OR chicken beak-gaps
  small items silently through the crack.
- **Latched/bungee**: PANDA CRANK-PRY only. Best medium/heavy loot.
- **Dumpster** (1-2 per street): deep — chicken plunge or panda tip; the
  legendary item lives in one of these, or:
- **Compost**: chicken-only worm bonus calories.
- **Recycling**: worthless clatter — rummaging it is pure noise (a trap,
  and a decoy tool: tip it deliberately to pull attention).

## 5. The night ecology (hazards)

- **Noise & grumpy meters**: every action has a noise ring (beak plunge
  1, lid flip 2, tip/squawk 5, bottle clatter 6). Each house has a grumpy
  meter fed by nearby noise -> porch light ON (hard white cone sweeping
  the yard/curb) -> homeowner emerges, chases the nearest VISIBLE
  character, confiscates carried loot (redistributed into a random
  remaining bin) and stomps back. Standing perfectly still in a light
  cone delays detection (the raccoon-statue trick — works for all three,
  drains nothing, nerve-wracking).
- **Dogs**: chained (bark radius arcs) or yard-roaming. Bark feeds the
  house's grumpy meter AND wakes adjacent dogs (chain reaction down the
  street). Bite = yelp, drop loot, 1s stun. Doubled aggro radius vs Cat.
  Sleeping until noise. Chicken's squawk retargets them.
- **Sprinklers**: timed sectors (tick-tick-tick telegraph, then bursts).
  Cat won't enter; panda slowed; chicken flies over. Wet loot is worth
  -25% (soggy chips).
- **Rats**: spawn from storm drains, swarm to dropped/spilled loot and
  drag it down the drain. Cat's pounce is the counter; anyone else can
  shoo (they scatter and return).
- **The Possum**: neutral chaos agent. Wanders, grabs the best loose item
  in view and beelines for a tree; up the tree = gone. Any character can
  scare it (cat instantly, others must get close); it drops the goods.
- **Night cars**: occasional headlight sweeps along the road band;
  getting caught mid-road = cartoon flatten, 1.5s stun, loot scatter.
  Teaches road-crossing discipline before dawn.
- **THE TRUCK**: at 5AM the sky dithers lighter, magpies warble, air
  brakes hiss — the truck enters far right with headlight cones and a
  beeping reverse alarm. It advances house by house, pauses ~8s at each
  bin cluster, claw-grabs and empties them (minimap dots blink out).
  Everything still in those bins is lost. You can loot a bin the claw is
  reaching for until the final second: **DAREDEVIL +50%** on anything
  grabbed within 3s of the crunch. The round ends when the truck passes
  the last bin.

## 6. Street generation & progression

Procedural street from a parts kit, seeded per run:
- 6-8 houses/street; each house = {front style, yard features, fence
  style, dog?, sprinkler?, bin cluster mix, porch-light sensitivity}.
- Difficulty knobs per street#: latched-bin %, dog count, sprinkler
  density, grumpy sensitivity, quota, truck pause time (shrinks).
- Street 1 "Quiet Crescent": tutorialish — mostly open/lidded bins, one
  dog, generous quota. Street 2 "Sprinkler Row". Street 3 "McMansion
  Drive": security-light houses, the fabled triple-locked dumpster.
  Street 4+ endless ramp; high score = total calories banked.
- Between streets: a "SPOILS" card — the cache pile drawn item by item,
  calories tallied, teamwork/daredevil/stealth bonuses itemized, the trio
  eating animation (panda munches, chicken tosses-and-gulps, cat drags a
  fish skeleton off to the side).

## 7. Graphics design (1-bit, night)

**Inverted palette from the daylight games: the night is BLACK.** Ground
is black/dark dither; everything reads as white shapes and outlines.

- **Two-pass outline rendering** (per archer/): every creature and loot
  item draws a 1px white outline pass first, then black detail — so
  white-on-white never vanishes and black shapes never melt into the
  road.
- **Light pools are the visual language**: streetlight cones (soft Bayer
  dither discs on the ground every ~180px), porch cones (hard white
  wedges with black penumbra edge when triggered), window glow (white
  rects that flick on as houses wake), car/truck headlights (long
  sweeping wedges). Characters inside light render inverted (black
  detail on white ground) — instant legibility of "you are seen".
- **House parts kit**: 3 silhouettes (weatherboard + porch posts, brick
  box with awning windows, skinny two-story), roofline against a star
  field (sparse white pixel stars, quarter moon, drifting cloud bands of
  fine dither). Details: letterboxes, garden gnome (knockable — clatter),
  bird bath, Hills Hoist clothesline (spins if the chicken lands on it —
  pure Aussie flavor for the bin chicken), potted plants, hedges as
  scribble-dither blobs, paling vs picket vs chain-link fences (distinct
  dither signatures; cat walks paling/picket tops only).
- **Curb & road**: bins with distinct silhouettes (wheelie bin, flip-lid,
  dumpster, compost dome), storm drain slots (rat eyes glint inside —
  two white pixels), parked cars (cat can hide under — shadow slot),
  dashed centerline, manhole.
- **The truck**: the biggest sprite in the game — two-tone dithered box,
  light bar, animated hydraulic claw arm with 3-frame grab cycle,
  exhaust puffs, headlight wedges. It should feel like a slow monster.
- **Dawn**: sky band dithers from black -> 25% -> 50% over the last
  minute; long shadows switch direction; streetlights pop off one by one.
- **HUD**: top strip = street minimap (bin dots, truck icon, cache flag),
  calorie counter vs quota, clock; bottom-left = three character chips
  (portrait + state icon: carrying/pecking/dragging/ALERT flash). Swap
  wheel = radial 3-portrait overlay with crank tick highlights.

## 8. Sound design (all synth, no assets)

- Night bed: sparse cricket blips (random high tri), distant woofs,
  occasional far car swish.
- Panda: low waddle thumps; pry = ratchet clicks + slip zips + CLUNK;
  tip = big crash arpeggio of noise hits.
- Chicken: THE HONK (descending saw blat — instantly recognizable ibis),
  wing flaps (noise whumps), beak plunge = quick zip + gulp.
- Cat: meow (pitch-bent triangle), purr (LFO'd low tri when parked at
  cache), pounce yowl, hiss (noise burst) at sprinklers/rats.
- World: bottle clatter cascade (recycling), lid clang, dog bark chains,
  homeowner "OI!" (two-note gruff square), sprinkler tick-tick-hiss,
  rat squeaks, possum chitter.
- Dawn sequence: magpie warble motif, truck air brakes, reverse beeper
  (relentless), hydraulic whine + crunch per bin. Quota met = full trio
  fanfare (thump + honk + meow arpeggio).

## 9. Scoring

- Calories banked (only in the cache counts).
- TEAMWORK x1.5 (2+ handlers), DAREDEVIL +50% (looted <3s before claw),
  SOGGY -25%, worm bonus (chicken compost), stealth bonus per house
  never woken (+100 each, tallied at dawn), legendary fanfare (+400 and
  the trio does a little dance at the cache).
- Personal-best per street + total-career calories saved to datastore.

## 10. Controls summary

| input | active character | notes |
| --- | --- | --- |
| d-pad | move | 8-way |
| A tap | context: grab/drop, rummage, lid, beak plunge | prompt shows verb |
| A hold | cat sprint / chicken flap / panda heavy-drag | per-character |
| B tap | special: tip / squawk / pounce | per-character |
| B hold | swap wheel (d-pad or crank picks, release swaps) | camera whip |
| crank | panda pry (latched bins) ; swap wheel scroll ; idle camera peek | |

## 11. Build plan (when green-lit)

~19 modules on the peckish skeleton: config, util, harness, save, sfx,
fx, street (procgen + parts kit), lights (noise/grumpy/cones), bins,
loot, panda, chicken, cat, squad (swap/parked-jobs/relay), dogs,
critters (rats+possum), people (homeowner+cars), truck, input
(+autopilot), draw (two-pass outline night renderer), hud, main.

Smoke autopilot (staged, per peckish pattern): pry-and-haul with panda;
chicken ferry relay over a fence (verify TEAMWORK bonus); cat cache
defense (rat kills); deliberate failures — one homeowner confiscation,
one dog bite, one possum theft, one car flatten; daredevil grab under
the claw; street-1 quota pass -> street 2; final staged run misses quota
-> game over -> restart. Heartbeat: calories, quota, street, truckHouse,
binsLeft, swaps, relays, confiscations, ratsKilled, stealthHouses,
overReason.

Open questions for the user:
1. Round length OK (~5-6 min/street) or shorter arcade nights?
2. Fixed handcrafted street 1 for onboarding, procedural after — or all
   procedural?
3. Any appetite for a 2P pass-and-play mode later (alternate nights,
   compare hauls)?
