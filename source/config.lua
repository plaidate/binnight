-- Tunables (C) and live state (G). Fixed 30fps step.
-- One suburban street, 1200x240, scrolling. Black night; the cache is the
-- far-left alley. Bank the calorie quota before the dawn truck eats the
-- street. Three characters, one controlled at a time: Panda opens,
-- Chicken crosses, Cat runs.

C = {
    DT = 1 / 30,
    W = 1200,     -- world width
    SW = 400,     -- screen
    H = 240,

    -- vertical bands (world y)
    YARD_TOP = 64,    -- above: house fronts (solid)
    FENCE_Y = 122,    -- front fence line; gaps at gates/driveways
    CURB_Y = 156,     -- nature strip top; bins live ~168
    ROAD_Y = 190,
    CACHE_X = 46,     -- left of this on any band: the alley cache

    NIGHT_T = 150,    -- seconds from 10PM to the truck (then ~50s truck run)
    SWAP_HOLD = 0.35,

    -- crew
    ACCEL = 900,
    DAMP = 6,
    PANDA_SPD = 70,
    PANDA_DRAG = 45,   -- carrying heavy
    PARK_DRAG = 26,    -- parked panda hauling home
    WRIGGLE_T = 1.2,   -- panda under a fence
    CHICK_SPD = 90,
    FLAP_STAM = 1.6,
    CAT_SPD = 110,
    CAT_SPRINT = 185,
    ACT_R = 24,        -- bin interaction reach
    PICK_R = 18,
    POUNCE_R = 30,

    -- noise (ring strengths) and houses
    NZ_PLUNGE = 0.8,
    NZ_RUMMAGE = 1.5,
    NZ_LID = 2.5,
    NZ_PRY = 3,
    NZ_TIP = 5,
    NZ_SQUAWK = 5,
    NZ_CLATTER = 6,
    NZ_BARK = 2,
    NZ_R = 140,        -- how far noise carries to houses
    GRUMPY_LIGHT = 60, -- grumpy level that flips the porch light
    GRUMPY_DECAY = 4,
    LIGHT_T = 6,
    LIGHT_R = 70,
    SEEN_T = 0.8,      -- lit + moving this long -> homeowner
    OWNER_SPD = 95,
    OWNER_T = 6,

    -- hazards
    DOG_CHAIN = 60,
    DOG_AGGRO = 55,
    DOG_AGGRO_CAT = 115,
    DOG_SPD = 125,
    BITE_CD = 1.5,
    SPRINK_R = 36,
    RAT_SPD = 70,
    RAT_DRAG = 55,
    POSSUM_T = 25,
    POSSUM_SPD = 60,
    CAR_SPD = 320,
    TRUCK_SPD = 65,
    TRUCK_GRAB = 3.5,
    DARE_R = 120,      -- looting this close to the working truck = daredevil

    -- pry (latched bins): total crank degrees, with two scripted slips
    PRY_NEED = 360,
    PRY_SLIP1 = 120,
    PRY_SLIP2 = 240,
    PRY_SLIPBACK = 55,

    -- scoring
    QUOTA1 = 450,
    QUOTA_STEP = 200,
    RELAY_MULT = 1.5,
    DARE_MULT = 1.5,
    SOGGY_MULT = 0.75,
    STEALTH_PTS = 50,
    WORM_CAL = 30,
    RAT_CAL = 15,
}

G = {
    state = "title", -- title | card | play | spoils | gameover
    t = 0,
    playT = 0,
    streetN = 1,
    diff = 0,
    cal = 0,      -- banked this street
    quota = C.QUOTA1,
    career = 0,   -- total banked, all streets this run
    high = 0,     -- best career (saved)
    overReason = "",
}
