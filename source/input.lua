-- Controls: d-pad moves, A = context action (hold: sprint/flap/drag),
-- B tap = special (tip/squawk/pounce), B hold = swap, crank = panda pry.
-- The smoke autopilot runs the whole heist by role, engineers a TEAMWORK
-- relay and a daredevil grab, blunders once into a car, a dog and a
-- confiscation, then idles through street 2 to miss quota and game over.

Input = {}

local bT, swapped = 0, false

function Input.gather()
    if Harness.enabled and Harness.autopilot then
        return Harness.autopilot()
    end
    local inp = { mvx = 0, mvy = 0, atap = false, ahold = false, btap = false, swap = false, crank = 0 }
    if playdate.buttonIsPressed(playdate.kButtonLeft) then inp.mvx = -1 end
    if playdate.buttonIsPressed(playdate.kButtonRight) then inp.mvx = 1 end
    if playdate.buttonIsPressed(playdate.kButtonUp) then inp.mvy = -1 end
    if playdate.buttonIsPressed(playdate.kButtonDown) then inp.mvy = 1 end
    inp.atap = playdate.buttonJustPressed(playdate.kButtonA)
    inp.ahold = playdate.buttonIsPressed(playdate.kButtonA)
    if playdate.buttonIsPressed(playdate.kButtonB) then
        bT = bT + C.DT
        if bT >= C.SWAP_HOLD and not swapped then
            swapped = true
            inp.swap = true
        end
    else
        if playdate.buttonJustReleased(playdate.kButtonB) and not swapped and bT > 0 then
            inp.btap = true
        end
        bT = 0
        swapped = false
    end
    inp.crank = playdate.getCrankChange()
    return inp
end

function Input.confirm()
    if Harness.enabled then return G.t > 0.7 end
    return playdate.buttonJustPressed(playdate.kButtonA)
end

-- ---- autopilot ---------------------------------------------------------------

local AP = { lastSwap = 0, parkHauled = false }

local function steerM(inp, m, tx, ty, dead)
    dead = dead or 5
    if math.abs(tx - m.x) > dead then inp.mvx = Util.sign(tx - m.x) end
    if math.abs(ty - m.y) > dead then inp.mvy = Util.sign(ty - m.y) end
    -- the chicken flies over the fence line; others handle it themselves
    if m.kind == "chicken" and ((ty < C.FENCE_Y) ~= (m.y < C.FENCE_Y)) then
        inp.ahold = true
    end
end

local function findBin(f)
    for _, b in ipairs(G.bins) do
        if b.state ~= "gone" and f(b) then return b end
    end
end

local function groundItem(m)
    local best, bi
    for _, it in ipairs(G.items) do
        if not it.dead and Loot.canCarry(m.kind, it.def.cls) then
            local d = Util.dist(m.x, m.y, it.x, it.y)
            if not best or d < best then best, bi = d, it end
        end
    end
    return bi
end

Harness.autopilot = function()
    local inp = { mvx = 0, mvy = 0, atap = false, ahold = false, btap = false, swap = false, crank = 0 }
    if G.state ~= "play" then return inp end
    local m = Squad.active()
    local cnt = Harness.counters

    -- street 2+: sit out the night to exercise quota failure and game over
    if G.streetN >= 2 then
        steerM(inp, m, 28, 150)
        return inp
    end

    -- scripted blunder: get flattened by a car once
    if (cnt.flattens or 0) == 0 and G.car then
        local c = G.car
        local ahead = c.x + c.dir * 50
        if ahead > 30 and ahead < C.W - 30 then
            steerM(inp, m, ahead, c.y, 3)
            return inp
        end
    end

    -- scripted blunder: take one dog bite (only from a dog that is already
    -- awake - walking up to a sleeping dog deadlocks the whole night).
    -- All pre-dawn blunders give up at playT 100: quota comes first.
    if (cnt.bites or 0) == 0 and G.playT > 20 and G.playT < 100 then
        for _, d in ipairs(G.dogs) do
            if d.awake then
                steerM(inp, m, d.post.x, d.post.y, 2)
                return inp
            end
        end
    end

    -- swap toward the character a coverage errand needs (one hop per 1/4s)
    local function need(kind)
        if m.kind == kind then return true end
        if G.t - (AP.swapAt or -1) > 0.25 then
            AP.swapAt = G.t
            inp.swap = true
        end
        return false
    end
    local dogAwake = false
    for _, d in ipairs(G.dogs) do
        if d.awake then dogAwake = true end
    end

    -- nobody has woken a dog yet: clatter the recycling beside the dog run
    -- so the bite and squawk paths get their turn
    if (cnt.bites or 0) == 0 and not dogAwake and G.playT > 55 and G.playT < 100 then
        local rb = findBin(function(b) return b.house == 2 and b.type == "recyc" end)
        if rb then
            if Util.dist(m.x, m.y, rb.x, rb.y) > 18 then
                steerM(inp, m, rb.x, rb.y, 3)
            else
                inp.atap = math.floor(G.t * 2) % 2 == 0
            end
            return inp
        end
    end

    -- squawk decoy once a dog is annoyed
    if (cnt.squawks or 0) == 0 and dogAwake and G.playT > 22 then
        if need("chicken") then inp.btap = true end
        return inp
    end

    -- scripted blunder: get caught carrying in the porch light. Fully
    -- self-contained at dogless house 1: grab something from its bins,
    -- rummage-noise until the light flips, then fidget inside the cone
    -- until the owner storms out and takes it.
    if (cnt.confiscations or 0) == 0 and G.playT > 30 and G.playT < 120 then
        local hs = G.houses[1]
        if not m.carry then
            local rb = findBin(function(b)
                return b.house == 1 and b.type ~= "compost" and #b.loot > 0
            end)
            local it = groundItem(m)
            if rb and (not it or Util.dist(m.x, m.y, rb.x, rb.y) < Util.dist(m.x, m.y, it.x, it.y)) then
                if Util.dist(m.x, m.y, rb.x, rb.y) > 18 then
                    steerM(inp, m, rb.x, rb.y, 3)
                else
                    inp.atap = true
                end
                return inp
            elseif it then
                if Util.dist(m.x, m.y, it.x, it.y) > 12 then
                    steerM(inp, m, it.x, it.y, 3)
                else
                    inp.atap = true
                end
                return inp
            end
            -- nothing carryable anywhere yet: let the roles make some loot
        elseif hs.light > 0 then
            if Util.dist(m.x, m.y, hs.def.porchX, 126) > 8 then
                steerM(inp, m, hs.def.porchX, 126, 3)
            else
                inp.mvx = math.floor(G.t * 4) % 2 == 0 and 1 or -1 -- fidget: be seen
            end
            return inp
        else
            local rb = findBin(function(b) return b.house == 1 and b.type ~= "compost" end)
            if rb then
                if Util.dist(m.x, m.y, rb.x, rb.y) > 18 then
                    steerM(inp, m, rb.x, rb.y, 3)
                else
                    inp.atap = math.floor(G.t * 2) % 2 == 0 -- rummage noise flips the light
                end
                return inp
            end
        end
    end

    -- chicken curriculum: compost worms, then a silent beak-gap plunge
    if (cnt.worms or 0) == 0 and G.playT > 8 and G.playT < 100 then
        local b = findBin(function(b) return b.type == "compost" and b.worms > 0 end)
        if b then
            if need("chicken") then
                if Util.dist(m.x, m.y, b.x, b.y) > 16 then
                    steerM(inp, m, b.x, b.y, 3)
                else
                    inp.atap = true
                end
            end
            return inp
        end
    end
    if (cnt.plunges or 0) == 0 and G.playT < 110 then
        local b = findBin(function(b)
            if b.state ~= "closed" then return false end
            for _, def in ipairs(b.loot) do
                if (b.type == "lid" and def.cls == "s")
                    or (b.type == "dump" and def.cls ~= "l") then
                    return true
                end
            end
            return false
        end)
        if b then
            if need("chicken") then
                if Util.dist(m.x, m.y, b.x, b.y) > 16 then
                    steerM(inp, m, b.x, b.y, 3)
                else
                    inp.atap = true
                end
            end
            return inp
        end
    end

    -- the cat earns one rat
    if (cnt.ratsKilled or 0) == 0 and #G.rats > 0 and G.playT < 130 then
        if need("cat") then
            local r = Critters.nearestRat(m.x, m.y, 2000)
            if r then
                if Util.dist(m.x, m.y, r.x, r.y) > 24 then
                    inp.ahold = true
                    steerM(inp, m, r.x, r.y, 3)
                else
                    if math.abs(r.x - m.x) > 2 then m.face = Util.sign(r.x - m.x) end
                    inp.btap = true
                end
            end
        end
        return inp
    end

    -- daredevil: rob the very bin the claw is reaching for
    if G.truck and (cnt.daredevils or 0) == 0 and not m.carry then
        local b = findBin(function(b)
            return b.house == G.truck.hi and b.y > 140 and #b.loot > 0
        end)
        if b then
            if Util.dist(m.x, m.y, b.x, b.y) > 20 then
                steerM(inp, m, b.x, b.y, 3)
                inp.ahold = m.kind == "cat"
            else
                inp.atap = true
            end
            return inp
        end
    end

    -- rotate the crew so every parked job gets exercised (rarely - swapping
    -- mid-errand wastes the night in half-finished walks)
    if G.playT - AP.lastSwap > 25 and not m.carry then
        AP.lastSwap = G.playT
        inp.swap = true
        return inp
    end

    -- role play
    if m.kind == "panda" then
        if m.carry then
            local cls = m.carry.def.cls
            if (cls == "h" or cls == "l") and not AP.parkHauled then
                AP.parkHauled = true -- leave him dragging it: parked-job demo
                AP.lastSwap = G.playT
                inp.swap = true
                return inp
            end
            -- small stuff: pile it beside the dumpster for the cat to ferry
            -- rather than waddling every item home one by one
            if cls ~= "h" and cls ~= "l" then
                local db = findBin(function(b) return b.type == "dump" and #b.loot > 0 end)
                if db and m.x > 200 then
                    if Util.dist(m.x, m.y, db.x + 40, 158) > 10 then
                        steerM(inp, m, db.x + 40, 158, 4)
                    else
                        inp.atap = true -- drop on the pile
                    end
                    return inp
                end
            end
            steerM(inp, m, 24, 160)
            return inp
        end
        local b = findBin(function(b) return b.type == "latch" and b.state == "closed" end)
        if b then
            if Util.dist(m.x, m.y, b.x, b.y) > 18 then
                steerM(inp, m, b.x, b.y, 3)
            else
                inp.crank = 170
            end
            return inp
        end
        b = findBin(function(b) return b.type == "dump" and #b.loot > 0 end)
        if b then
            if Util.dist(m.x, m.y, b.x, b.y) > 20 then
                steerM(inp, m, b.x, b.y, 3)
            else
                inp.atap = true
            end
            return inp
        end
        if (cnt.tips or 0) == 0 then
            b = findBin(function(b) return b.type == "lid" and b.state == "closed" and #b.loot > 0 end)
            if b then
                if Util.dist(m.x, m.y, b.x, b.y) > 22 then
                    steerM(inp, m, b.x, b.y, 3)
                else
                    inp.btap = true
                end
                return inp
            end
        end
    elseif m.kind == "chicken" then
        if m.carry then
            if m.x > 160 then
                steerM(inp, m, 130, 150, 4) -- relay drop point
                if math.abs(m.x - 130) <= 8 and math.abs(m.y - 150) <= 8 then
                    inp.atap = true
                end
            else
                steerM(inp, m, 24, 160)
            end
            return inp
        end
        local b = findBin(function(b) return b.type == "compost" and b.worms > 0 end)
        if b then
            if Util.dist(m.x, m.y, b.x, b.y) > 18 then
                steerM(inp, m, b.x, b.y, 3)
            else
                inp.atap = true
            end
            return inp
        end
        b = findBin(function(b)
            if b.type ~= "lid" and b.type ~= "dump" then return false end
            for _, def in ipairs(b.loot) do
                if def.cls == "s" or (b.type == "dump" and def.cls ~= "l") then return true end
            end
            return false
        end)
        if b then
            if Util.dist(m.x, m.y, b.x, b.y) > 18 then
                steerM(inp, m, b.x, b.y, 3)
            else
                inp.atap = true
            end
            return inp
        end
    else -- cat
        if m.carry then
            inp.ahold = true
            steerM(inp, m, 24, 170)
            return inp
        end
        local r = Critters.nearestRat(m.x, m.y, 300)
        if r then
            if Util.dist(m.x, m.y, r.x, r.y) > 24 then
                inp.ahold = true
                steerM(inp, m, r.x, r.y, 3)
            else
                if math.abs(r.x - m.x) > 2 then m.face = Util.sign(r.x - m.x) end
                inp.btap = true
            end
            return inp
        end
        local it = groundItem(m)
        if it then
            if Util.dist(m.x, m.y, it.x, it.y) > 12 then
                inp.ahold = Util.dist(m.x, m.y, it.x, it.y) > 60
                steerM(inp, m, it.x, it.y, 3)
            else
                inp.atap = true
            end
            return inp
        end
        -- rummage whatever is open near the cache end
        local b = findBin(function(b)
            return (b.state == "open" or b.state == "tipped" or b.type == "open") and #b.loot > 0
        end)
        if b then
            if Util.dist(m.x, m.y, b.x, b.y) > 18 then
                steerM(inp, m, b.x, b.y, 3)
            else
                inp.atap = true
            end
            return inp
        end
    end

    -- nothing for this character: hand over
    if G.playT - AP.lastSwap > 2 then
        AP.lastSwap = G.playT
        inp.swap = true
    end
    return inp
end
