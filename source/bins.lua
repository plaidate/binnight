-- Bins: the loot containers. open (anyone), lid (flip, or chicken
-- beak-gap), latch (panda crank-pry only), dump (chicken plunge / panda
-- slow rummage), compost (chicken worm snacks), recyc (pure noise trap).

Bins = {}

local SMALLS = {
    { n = "CHIP PACKET", cal = 12, cls = "s" },
    { n = "SAUSAGE", cal = 22, cls = "s" },
    { n = "CHICKEN WING", cal = 18, cls = "s" },
    { n = "FISH BONES", cal = 15, cls = "s" },
    { n = "HALF SANGA", cal = 25, cls = "s" },
}
local MEDS = {
    { n = "PIZZA BOX", cal = 45, cls = "m" },
    { n = "NOODLE BOX", cal = 40, cls = "m" },
    { n = "BREAD LOAF", cal = 55, cls = "m" },
}
local HEAVIES = {
    { n = "TURKEY", cal = 120, cls = "h" },
    { n = "MELON HALF", cal = 100, cls = "h" },
    { n = "WHOLE CAKE", cal = 150, cls = "h" },
}
local LEGEND = { n = "THE LASAGNA", cal = 400, cls = "l" }

local function pick(pool) return pool[math.random(#pool)] end

local function fill(type, legend)
    local l = {}
    if type == "open" then
        for _ = 1, 3 do l[#l + 1] = pick(SMALLS) end
    elseif type == "lid" then
        l[1] = pick(MEDS)
        l[2] = pick(SMALLS)
        l[3] = pick(SMALLS)
    elseif type == "latch" then
        l[1] = legend and LEGEND or pick(HEAVIES)
        l[2] = pick(MEDS)
    elseif type == "dump" then
        if legend then l[1] = LEGEND end
        l[#l + 1] = pick(MEDS)
        l[#l + 1] = pick(MEDS)
        for _ = 1, 3 do l[#l + 1] = pick(SMALLS) end
    end
    return l
end

function Bins.make(type, x, y, houseI, legend)
    G.bins[#G.bins + 1] = {
        x = x, y = y, type = type, house = houseI,
        -- open-top bins are born rummageable; everything else starts shut
        state = type == "open" and "open" or "closed",
        loot = fill(type, legend),
        pry = 0, slip1 = false, slip2 = false,
        worms = type == "compost" and 3 or 0,
        legend = legend,
    }
end

function Bins.at(x, y, r)
    local best, bb
    for _, b in ipairs(G.bins) do
        if b.state ~= "gone" then
            local d = Util.dist(x, y, b.x, b.y)
            if d < (r or C.ACT_R) and (not best or d < best) then
                best, bb = d, b
            end
        end
    end
    return bb
end

function Bins.left()
    local n = 0
    for _, b in ipairs(G.bins) do
        if b.state ~= "gone" and (#b.loot > 0 or b.worms > 0) then n = n + 1 end
    end
    return n
end

-- is looting this bin a daredevil act (truck about to take it)?
local function dare(b)
    local tk = G.truck
    return (tk and tk.hi == b.house and math.abs(tk.x - b.x) < C.DARE_R) or false
end

local function popTo(m, b)
    if #b.loot == 0 then
        Fx.text("EMPTY", b.x, b.y - 18)
        return
    end
    -- give the best item this member can hold, else spill the top one
    local gi
    for i = #b.loot, 1, -1 do
        if Loot.canCarry(m.kind, b.loot[i].cls) then
            gi = i
            break
        end
    end
    local def = table.remove(b.loot, gi or #b.loot)
    Loot.take(m, def, b.x, b.y, dare(b))
end

-- A-button interaction. Returns true if something happened.
function Bins.interact(m, b)
    local k = m.kind
    if b.type == "recyc" then
        Sfx.clatter()
        Houses.noise(b.x, b.y, C.NZ_CLATTER)
        Fx.text("CLATTER!", b.x, b.y - 20)
        Harness.count("clatters")
        return true
    end
    if b.type == "compost" then
        if k == "chicken" and b.worms > 0 then
            b.worms = b.worms - 1
            G.cal = G.cal + C.WORM_CAL
            G.career = G.career + C.WORM_CAL
            Fx.text("WORMS +" .. C.WORM_CAL, b.x, b.y - 18)
            Houses.noise(b.x, b.y, C.NZ_PLUNGE)
            Sfx.plunge()
            Harness.count("worms")
            return true
        end
        return false
    end
    if b.state == "open" or b.state == "tipped" then
        popTo(m, b)
        Houses.noise(b.x, b.y, C.NZ_RUMMAGE)
        Harness.count("rummages")
        return true
    end
    -- closed
    if b.type == "lid" then
        if k == "chicken" then
            for i = #b.loot, 1, -1 do
                if b.loot[i].cls == "s" then
                    local def = table.remove(b.loot, i)
                    Loot.take(m, def, b.x, b.y, dare(b))
                    Houses.noise(b.x, b.y, C.NZ_PLUNGE)
                    Sfx.plunge()
                    Harness.count("plunges")
                    return true
                end
            end
            Fx.text("NO SCRAPS", b.x, b.y - 18)
            return true
        else
            b.state = "open"
            Sfx.lid()
            Houses.noise(b.x, b.y, C.NZ_LID)
            return true
        end
    end
    if b.type == "latch" then
        Fx.text(k == "panda" and "CRANK TO PRY" or "LATCHED...", b.x, b.y - 20)
        return true
    end
    if b.type == "dump" then
        if k == "chicken" then
            for i = #b.loot, 1, -1 do
                if b.loot[i].cls ~= "l" then
                    local def = table.remove(b.loot, i)
                    Loot.take(m, def, b.x, b.y, dare(b))
                    Houses.noise(b.x, b.y, C.NZ_PLUNGE)
                    Sfx.plunge()
                    Harness.count("plunges")
                    return true
                end
            end
            Fx.text("ONLY THE BIG ONE LEFT", b.x, b.y - 20)
            return true
        elseif k == "panda" then
            if m.rumT > 0 then return true end
            m.rumT = 1.0
            popTo(m, b)
            Houses.noise(b.x, b.y, C.NZ_LID)
            Harness.count("rummages")
            return true
        else
            Fx.text("TOO DEEP", b.x, b.y - 20)
            return true
        end
    end
    return false
end

-- panda cranking a latched bin
function Bins.pry(m, b, deg)
    if m.kind ~= "panda" or b.type ~= "latch" or b.state ~= "closed" then return end
    local before = b.pry
    b.pry = b.pry + math.abs(deg)
    if b.pry > 30 and math.floor(b.pry / 40) ~= math.floor(before / 40) then
        Sfx.ratchet()
    end
    if not b.slip1 and b.pry >= C.PRY_SLIP1 then
        b.slip1 = true
        b.pry = b.pry - C.PRY_SLIPBACK
        Sfx.slip()
        Fx.text("SLIP!", b.x, b.y - 20)
    elseif not b.slip2 and b.pry >= C.PRY_SLIP2 then
        b.slip2 = true
        b.pry = b.pry - C.PRY_SLIPBACK
        Sfx.slip()
        Fx.text("SLIP!", b.x, b.y - 20)
    end
    if b.pry >= C.PRY_NEED then
        b.state = "open"
        Sfx.clunk()
        Houses.noise(b.x, b.y, C.NZ_PRY)
        Fx.text("CLUNK!", b.x, b.y - 20)
        Fx.puff(b.x, b.y - 8, 4)
        Harness.count("prys")
    end
end

-- panda's shoulder-slam: spill everything
function Bins.tip(b)
    if b.state == "gone" or b.type == "dump" or b.type == "compost" then return false end
    for _, def in ipairs(b.loot) do
        Loot.spawnGround(def, b.x + math.random(-22, 22), b.y + math.random(-8, 12), dare(b))
    end
    b.loot = {}
    b.state = "tipped"
    Sfx.crash()
    Houses.noise(b.x, b.y, C.NZ_TIP)
    Fx.puff(b.x, b.y, 8)
    Harness.count("tips")
    return true
end
