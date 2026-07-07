-- Rats (steal dropped loot into the storm drains) and the possum (grabs
-- your best loose item and climbs a tree with it). The cat is the answer
-- to both.

Critters = {}

function Critters.reset()
    G.rats = {}
    G.possum = nil
    G.ratT = 4
    G.possumT = C.POSSUM_T
end

-- ---- rats -------------------------------------------------------------------

local function nearestDrain(x)
    local best, bx
    for _, dx in ipairs(G.street.drains) do
        local d = math.abs(dx - x)
        if not best or d < best then best, bx = d, dx end
    end
    return bx
end

function Critters.nearestRat(x, y, r)
    local best, br
    for _, rat in ipairs(G.rats) do
        local d = Util.dist(x, y, rat.x, rat.y)
        if d < r and (not best or d < best) then best, br = d, rat end
    end
    return br
end

function Critters.killRat(rat)
    for i, r in ipairs(G.rats) do
        if r == rat then
            table.remove(G.rats, i)
            G.cal = G.cal + C.RAT_CAL
            G.career = G.career + C.RAT_CAL
            Fx.text("PROTEIN +" .. C.RAT_CAL, r.x, r.y - 14)
            Fx.puff(r.x, r.y, 4)
            Sfx.squeak()
            Harness.count("ratsKilled")
            return
        end
    end
end

local function updateRats(dt)
    G.ratT = G.ratT - dt
    local maxRats = 2 + G.streetN
    if G.ratT <= 0 and #G.rats < maxRats then
        G.ratT = 6 - G.diff * 2
        -- a rat only bothers if there is loose food near a drain
        for _, it in ipairs(G.items) do
            if not it.dead and it.def.cls == "s" then
                local dx = nearestDrain(it.x)
                if math.abs(dx - it.x) < 150 then
                    G.rats[#G.rats + 1] = { x = dx, y = 186, item = nil, want = it }
                    Sfx.squeak()
                    break
                end
            end
        end
    end
    for i = #G.rats, 1, -1 do
        local r = G.rats[i]
        -- scatter if the crew looms
        local scared = false
        for _, m in ipairs(G.crew) do
            if Util.dist(m.x, m.y, r.x, r.y) < 22 then scared = true end
        end
        if scared and not r.flee then
            r.item = nil
            r.flee = true
        end
        if r.flee then
            local dx = nearestDrain(r.x)
            r.x = r.x + Util.sign(dx - r.x) * C.RAT_SPD * dt
            r.y = r.y + Util.sign(186 - r.y) * C.RAT_SPD * dt * 0.7
            if math.abs(r.x - dx) < 6 and math.abs(r.y - 186) < 8 then
                table.remove(G.rats, i)
            end
        elseif r.item then
            local dx = nearestDrain(r.x)
            r.x = r.x + Util.sign(dx - r.x) * C.RAT_DRAG * dt
            r.y = r.y + Util.sign(186 - r.y) * C.RAT_DRAG * dt * 0.7
            r.item.x, r.item.y = r.x, r.y - 4
            if math.abs(r.x - dx) < 6 and math.abs(r.y - 186) < 8 then
                r.item.dead = true
                Fx.text("RATTED!", r.x, r.y - 16)
                Harness.count("ratSteals")
                table.remove(G.rats, i)
            end
        else
            local it = r.want
            if not it or it.dead then
                -- shop for the nearest small loose item
                it = nil
                local best
                for _, gi in ipairs(G.items) do
                    if not gi.dead and gi.def.cls == "s" then
                        local d = Util.dist(r.x, r.y, gi.x, gi.y)
                        if not best or d < best then best, it = d, gi end
                    end
                end
                r.want = it
            end
            if not it then
                r.flee = true
            else
                local nx, ny = Util.norm(r.x, r.y, it.x, it.y)
                r.x = r.x + nx * C.RAT_SPD * dt
                r.y = r.y + ny * C.RAT_SPD * dt
                if Util.dist(r.x, r.y, it.x, it.y) < 8 then
                    r.item = it
                end
            end
        end
    end
end

-- ---- the possum ---------------------------------------------------------------

function Critters.possumNear(x, y, r)
    local p = G.possum
    return (p and Util.dist(x, y, p.x, p.y) < r) or false
end

function Critters.scarePossum()
    local p = G.possum
    if not p then return end
    p.item = nil
    p.flee = true
    Sfx.chitter()
    Fx.text("SCRAM!", p.x, p.y - 16)
end

local function possumTree()
    for _, h in ipairs(G.street.houses) do
        if h.tree then return h.tree end
    end
    return { x = C.W - 60, y = 80 }
end

local function updatePossum(dt)
    if not G.possum then
        G.possumT = G.possumT - dt
        if G.possumT <= 0 then
            local tree = possumTree()
            G.possum = { x = tree.x, y = tree.y, tree = tree, flee = false }
            Sfx.chitter()
        end
        return
    end
    local p = G.possum
    if p.flee then
        local nx, ny = Util.norm(p.x, p.y, p.tree.x, p.tree.y)
        p.x = p.x + nx * C.POSSUM_SPD * 1.6 * dt
        p.y = p.y + ny * C.POSSUM_SPD * 1.6 * dt
        if Util.dist(p.x, p.y, p.tree.x, p.tree.y) < 8 then
            G.possum = nil
            G.possumT = C.POSSUM_T
        end
        return
    end
    -- a nearby cat spooks it even in passing
    for _, m in ipairs(G.crew) do
        local r = m.kind == "cat" and 34 or 16
        if Util.dist(m.x, m.y, p.x, p.y) < r then
            Critters.scarePossum()
            return
        end
    end
    if p.item then
        local nx, ny = Util.norm(p.x, p.y, p.tree.x, p.tree.y)
        p.x = p.x + nx * C.POSSUM_SPD * dt
        p.y = p.y + ny * C.POSSUM_SPD * dt
        p.item.x, p.item.y = p.x, p.y - 6
        if Util.dist(p.x, p.y, p.tree.x, p.tree.y) < 10 then
            p.item.dead = true
            Fx.text("UP THE TREE!", p.x, p.y - 18)
            Harness.count("possumSteals")
            G.possum = nil
            G.possumT = C.POSSUM_T
        end
    else
        local it = Loot.best()
        if not it then
            p.flee = true
        else
            local nx, ny = Util.norm(p.x, p.y, it.x, it.y)
            p.x = p.x + nx * C.POSSUM_SPD * dt
            p.y = p.y + ny * C.POSSUM_SPD * dt
            if Util.dist(p.x, p.y, it.x, it.y) < 8 then
                p.item = it
            end
        end
    end
end

-- cat pounce lands here
function Critters.pounceAt(x, y)
    local r = Critters.nearestRat(x, y, C.POUNCE_R)
    if r then
        Critters.killRat(r)
        return
    end
    if Critters.possumNear(x, y, C.POUNCE_R + 6) then
        Critters.scarePossum()
    end
end

function Critters.update(dt)
    updateRats(dt)
    updatePossum(dt)
end
