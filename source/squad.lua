-- The crew: Trash Panda (opens), Bin Chicken (crosses), Alley Cat (runs).
-- One is controlled at a time; the other two are PARKED but keep working:
-- panda hauls his heavy item home, chicken piles loot from an open bin,
-- cat guards against rats and the possum.

Squad = {}

local function member(kind, x, y)
    return {
        kind = kind, x = x, y = y, vx = 0, vy = 0, face = 1,
        carry = nil, stun = 0, flatT = 0,
        wrig = 0, wrigDir = 1,
        flying = false, stam = C.FLAP_STAM, flapS = 0,
        rumT = 0, actT = 0, alertT = 0,
        pounceT = 0, hopT = 0, parkT = 0,
        still = true,
    }
end

function Squad.reset()
    G.crew = {
        member("panda", 26, 146),
        member("chicken", 26, 166),
        member("cat", 26, 180),
    }
    G.cur = 1
    G.decoy = nil
end

function Squad.active()
    return G.crew[G.cur]
end

function Squad.swap()
    G.cur = G.cur % 3 + 1
    local m = Squad.active()
    Fx.ring(m.x, m.y, 26)
    Sfx.blip(700)
    Harness.count("swaps")
end

-- stun + optionally scatter whatever they were holding
function Squad.hurt(m, stun, scatter)
    m.stun = math.max(m.stun, stun)
    if scatter and m.carry then
        Loot.drop(m, true)
    end
    m.alertT = 1.2
end

local function kindSpd(m, sprint)
    if m.kind == "panda" then
        local c = m.carry and m.carry.def.cls
        return (c == "h" or c == "l") and C.PANDA_DRAG or C.PANDA_SPD
    elseif m.kind == "chicken" then
        return C.CHICK_SPD
    else
        return sprint and C.CAT_SPRINT or C.CAT_SPD
    end
end

local function integrate(m, dt)
    local nx = Util.clamp(m.x + m.vx * dt, 8, C.W - 8)
    local ny = Util.clamp(m.y + m.vy * dt, C.YARD_TOP + 2, 232)
    -- the front fence
    local before, after = m.y - C.FENCE_Y, ny - C.FENCE_Y
    if (before < 0) ~= (after < 0) and not Street.canCross(nx) then
        if m.kind == "cat" then
            m.hopT = 0.25 -- hops it
        elseif m.kind == "chicken" then
            if not m.flying then ny = m.y end
        else -- panda wriggles under
            if m.wrig <= 0 then
                m.wrig = C.WRIGGLE_T
                m.wrigDir = after < 0 and -1 or 1
                Fx.puff(m.x, C.FENCE_Y, 3)
            end
            ny = m.y
        end
    end
    m.x, m.y = nx, ny
end

local function tryAction(m)
    m.actT = 0.5
    local b = Bins.at(m.x, m.y)
    if b and Bins.interact(m, b) then return end
    if Loot.pickup(m) then return end
    if m.carry then
        Loot.drop(m, false)
        Sfx.blip(300)
    end
end

local function special(m)
    m.actT = 0.5
    if m.kind == "panda" then
        local b = Bins.at(m.x, m.y, C.ACT_R + 6)
        if b and Bins.tip(b) then return end
        Sfx.thump()
    elseif m.kind == "chicken" then
        Sfx.squawk()
        Houses.noise(m.x, m.y, C.NZ_SQUAWK)
        G.decoy = { m = m, t = 3 }
        Fx.text("SQUAWK!!", m.x, m.y - 24)
        Harness.count("squawks")
    else
        m.pounceT = 0.18
        m.vx = m.vx + m.face * 160
        Sfx.yowl()
        Critters.pounceAt(m.x + m.face * 16, m.y)
        Harness.count("pounces")
    end
end

local function control(m, inp, dt)
    -- panda cranks a latched bin
    if m.kind == "panda" and math.abs(inp.crank or 0) > 1 then
        local b = Bins.at(m.x, m.y, C.ACT_R + 4)
        if b and b.type == "latch" then
            Bins.pry(m, b, inp.crank)
            m.actT = 0.5
        end
    end

    -- chicken flight
    if m.kind == "chicken" then
        local wantFly = inp.ahold and m.stam > 0
        m.flying = wantFly
        if wantFly then
            m.stam = m.stam - dt * (m.carry and m.carry.def.cls == "m" and 2 or 1)
            m.flapS = m.flapS - dt
            if m.flapS <= 0 then
                m.flapS = 0.28
                Sfx.flapWing()
                Houses.noise(m.x, m.y, 0.4)
            end
        else
            m.stam = math.min(C.FLAP_STAM, m.stam + dt * 0.9)
        end
    end

    local control_ok = m.stun <= 0 and m.wrig <= 0
    local moving = inp.mvx ~= 0 or inp.mvy ~= 0
    if control_ok and moving then
        local nx, ny = Util.norm(0, 0, inp.mvx, inp.mvy)
        m.vx = m.vx + nx * C.ACCEL * dt
        m.vy = m.vy + ny * C.ACCEL * dt
        local f = Street.sprinkFactor(m)
        local spd = kindSpd(m, inp.ahold and m.kind == "cat") * f
        local v = math.sqrt(m.vx * m.vx + m.vy * m.vy)
        if v > spd then
            if spd == 0 then spd = 0.01 end
            m.vx, m.vy = m.vx / v * spd, m.vy / v * spd
        end
        if f == 0 then
            -- cat recoils from the sprinkler
            for _, s in ipairs(G.sprinks) do
                if s.state == "on" and Util.dist(m.x, m.y, s.x, s.y) < C.SPRINK_R + 10 then
                    local rx, ry = Util.norm(s.x, s.y, m.x, m.y)
                    m.vx, m.vy = rx * 120, ry * 120
                    if math.random() < 0.1 then Sfx.hiss() end
                end
            end
        end
        if inp.mvx ~= 0 then m.face = Util.sign(inp.mvx) end
    else
        m.vx = m.vx - m.vx * math.min(1, C.DAMP * dt)
        m.vy = m.vy - m.vy * math.min(1, C.DAMP * dt)
    end

    if control_ok then
        if inp.atap then tryAction(m) end
        if inp.btap then special(m) end
    end

    integrate(m, dt)
    m.still = math.abs(m.vx) + math.abs(m.vy) < 8 and m.actT <= 0
end

local function parked(m, dt)
    m.flying = false
    m.parkT = m.parkT - dt
    if m.stun > 0 or m.wrig > 0 then return end

    -- shuffle out of an awake dog's run rather than standing there as chow
    for _, d in ipairs(G.dogs) do
        if d.awake and Util.dist(d.x, d.y, m.x, m.y) < 46 then
            local nx, ny = Util.norm(d.x, d.y, m.x, m.y)
            m.x = Util.clamp(m.x + nx * 55 * dt, 8, C.W - 8)
            m.y = Util.clamp(m.y + ny * 55 * dt, C.YARD_TOP + 2, 232)
        end
    end

    if m.kind == "panda" then
        -- haul the heavy prize home
        if m.carry then
            m.x = math.max(10, m.x - C.PARK_DRAG * dt)
            m.face = -1
        end
    elseif m.kind == "chicken" then
        if m.parkT <= 0 then
            local b = Bins.at(m.x, m.y, 30)
            if b and (b.state == "open" or b.state == "tipped") and #b.loot > 0 then
                m.parkT = 2.2
                local def = table.remove(b.loot)
                Loot.spawnGround(def, m.x + math.random(-10, 10), m.y + 8, false)
                Sfx.plunge()
                Houses.noise(m.x, m.y, 0.5)
                Harness.count("chickPiles")
            end
        end
    else -- cat on guard
        if m.parkT <= 0 then
            m.parkT = 0.8
            local r = Critters.nearestRat(m.x, m.y, 60)
            if r then
                m.face = Util.sign(r.x - m.x)
                Critters.killRat(r)
                m.pounceT = 0.18
            elseif Critters.possumNear(m.x, m.y, 60) then
                Critters.scarePossum()
                m.pounceT = 0.18
            end
        end
    end
    m.still = true
end

function Squad.update(dt, inp)
    -- consume the swap ONCE, before the member loop: a swap inside the loop
    -- makes the next member match G.cur and re-consume the same input,
    -- cascading through the whole crew and back in a single frame
    if inp.swap then Squad.swap() end
    if G.decoy then
        G.decoy.t = G.decoy.t - dt
        if G.decoy.t <= 0 then G.decoy = nil end
    end
    for i, m in ipairs(G.crew) do
        m.stun = math.max(0, m.stun - dt)
        m.flatT = math.max(0, m.flatT - dt)
        m.rumT = math.max(0, m.rumT - dt)
        m.actT = math.max(0, m.actT - dt)
        m.alertT = math.max(0, m.alertT - dt)
        m.pounceT = math.max(0, m.pounceT - dt)
        m.hopT = math.max(0, m.hopT - dt)
        if m.wrig > 0 then
            m.wrig = m.wrig - dt
            if m.wrig <= 0 then
                m.y = C.FENCE_Y + m.wrigDir * 10
                Fx.puff(m.x, C.FENCE_Y, 3)
            end
        end

        if i == G.cur then
            control(m, inp, dt)
        else
            parked(m, dt)
        end

        -- anything carried into the alley banks
        if m.carry and m.x < C.CACHE_X then
            Loot.bankCarry(m)
        end
    end
end
