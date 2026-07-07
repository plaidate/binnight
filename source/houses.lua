-- Houses: grumpy meters fed by noise, porch lights, and homeowners who
-- chase and confiscate. Standing perfectly still in a light cone delays
-- detection (the raccoon-statue trick).

Houses = {}

function Houses.reset()
    G.houses = {}
    for i, h in ipairs(G.street.houses) do
        G.houses[i] = {
            def = h, grumpy = 0, light = 0, seen = 0,
            owner = nil, woken = false,
        }
    end
end

-- a noise ring at (x,y): feeds nearby grumpy meters, pokes the dogs
function Houses.noise(x, y, amt)
    Fx.ring(x, y, 20 + amt * 12)
    for _, hs in ipairs(G.houses) do
        local d = math.abs(hs.def.porchX - x)
        if d < C.NZ_R then
            hs.grumpy = hs.grumpy + amt * 9 * (1 - d / C.NZ_R) * hs.def.sens
        end
    end
    Dogs.hear(x, y, amt)
end

function Houses.isLit(x, y)
    for _, hs in ipairs(G.houses) do
        if hs.light > 0 and Util.dist(x, y, hs.def.porchX, 84) < C.LIGHT_R then
            return true
        end
    end
    if G.truck and math.abs(x - (G.truck.x - 50)) < 46 and y > C.ROAD_Y - 24 then
        return true
    end
    return false
end

local function chase(hs, dt)
    local o = hs.owner
    local target = o.target
    if G.decoy then target = G.decoy.m end
    local nx, ny = Util.norm(o.x, o.y, target.x, target.y)
    o.x = o.x + nx * C.OWNER_SPD * dt
    o.y = Util.clamp(o.y + ny * C.OWNER_SPD * dt, C.YARD_TOP, 185)
    o.t = o.t - dt
    if Util.dist(o.x, o.y, target.x, target.y) < 14 then
        if target.carry then
            local it = target.carry
            target.carry = nil
            -- the loot goes back into a random surviving bin
            local alive = {}
            for _, b in ipairs(G.bins) do
                if b.state ~= "gone" and b.type ~= "recyc" and b.type ~= "compost" then
                    alive[#alive + 1] = b
                end
            end
            if #alive > 0 then
                local b = alive[math.random(#alive)]
                b.loot[#b.loot + 1] = it.def
                if b.state == "tipped" then b.state = "open" end
            end
            Fx.text("CONFISCATED!", target.x, target.y - 22)
            Harness.count("confiscations")
        else
            Fx.text("SHOO!", target.x, target.y - 22)
        end
        Squad.hurt(target, 1.0, false)
        Sfx.oi()
        o.t = math.min(o.t, 0.6)
    end
    if o.t <= 0 then
        hs.owner = nil
        hs.grumpy = 20
        hs.seen = 0
    end
end

function Houses.update(dt)
    for _, hs in ipairs(G.houses) do
        hs.grumpy = math.max(0, hs.grumpy - C.GRUMPY_DECAY * dt)
        if hs.light <= 0 and hs.grumpy > C.GRUMPY_LIGHT then
            hs.light = C.LIGHT_T
            hs.woken = true
            Sfx.blip(220)
        end
        if hs.light > 0 then
            hs.light = hs.light - dt
            -- anyone moving in the cone gets noticed
            local spotted = nil
            for _, m in ipairs(G.crew) do
                if Util.dist(m.x, m.y, hs.def.porchX, 84) < C.LIGHT_R and not m.still then
                    spotted = m
                    m.alertT = 0.5
                    break
                end
            end
            if spotted then
                hs.seen = hs.seen + dt
                if hs.seen > C.SEEN_T and not hs.owner then
                    hs.owner = {
                        x = hs.def.doorX, y = C.YARD_TOP,
                        t = C.OWNER_T, target = spotted,
                    }
                    Sfx.oi()
                    Fx.text("OI!!", hs.def.doorX, C.YARD_TOP - 8)
                    Harness.count("owners")
                end
            else
                hs.seen = math.max(0, hs.seen - dt * 2)
            end
        end
        if hs.owner then chase(hs, dt) end
    end
end
