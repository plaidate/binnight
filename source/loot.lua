-- Ground items and carrying. Weight classes gate who can hold what.
-- Anything that reaches the cache zone banks: relay (2+ handlers) x1.5,
-- daredevil x1.5, soggy x0.75.

Loot = {}

function Loot.reset()
    G.items = {}
end

function Loot.canCarry(kind, cls)
    if kind == "cat" then return cls == "s" end
    if kind == "chicken" then return cls == "s" or cls == "m" end
    return true -- panda lifts anything, including THE LASAGNA
end

function Loot.spawnGround(def, x, y, dare)
    G.items[#G.items + 1] = {
        x = Util.clamp(x, 10, C.W - 10), y = Util.clamp(y, C.YARD_TOP + 4, 230),
        def = def, h = {}, soggy = false, dare = dare or false,
    }
end

-- a bin hands an item to a member: carried if possible, else piled at the bin
function Loot.take(m, def, x, y, dare)
    if not m.carry and Loot.canCarry(m.kind, def.cls) then
        m.carry = { def = def, h = { [m.kind] = true }, soggy = false, dare = dare or false }
    else
        Loot.spawnGround(def, x + math.random(-14, 14), y + 10, dare)
    end
    Fx.text(def.n, x, y - 28)
end

function Loot.pickup(m)
    local best, bi
    for i, it in ipairs(G.items) do
        if Loot.canCarry(m.kind, it.def.cls) then
            local d = Util.dist(m.x, m.y, it.x, it.y)
            if d < C.PICK_R and (not best or d < best) then
                best, bi = d, i
            end
        end
    end
    if not bi or m.carry then return false end
    local it = table.remove(G.items, bi)
    it.h[m.kind] = true
    m.carry = it
    Sfx.blip(500)
    return true
end

function Loot.drop(m, scatter)
    if not m.carry then return end
    local it = m.carry
    m.carry = nil
    it.x = m.x + (scatter and math.random(-20, 20) or 0)
    it.y = Util.clamp(m.y + (scatter and math.random(-14, 14) or 6), C.YARD_TOP + 4, 230)
    G.items[#G.items + 1] = it
end

local function bankItem(it, x, y)
    local mult, tags = 1, {}
    local handlers = 0
    for _ in pairs(it.h) do handlers = handlers + 1 end
    if handlers >= 2 then
        mult = mult * C.RELAY_MULT
        tags[#tags + 1] = "TEAMWORK"
        Harness.count("relays")
    end
    if it.dare then
        mult = mult * C.DARE_MULT
        tags[#tags + 1] = "DAREDEVIL"
        Harness.count("daredevils")
    end
    if it.soggy then
        mult = mult * C.SOGGY_MULT
        tags[#tags + 1] = "SOGGY"
    end
    local cal = math.floor(it.def.cal * mult + 0.5)
    G.cal = G.cal + cal
    G.career = G.career + cal
    Fx.text("+" .. cal .. (tags[1] and (" " .. table.concat(tags, "+")) or ""), math.max(x, 60), y - 16)
    Sfx.gulpBank()
    Harness.count("banks")
    if it.def.cls == "l" then
        Fx.text("*THE LASAGNA IS OURS!*", 200, 60)
        Sfx.trioFanfare()
        Harness.count("legends")
    end
end

function Loot.bankCarry(m)
    if not m.carry then return end
    local it = m.carry
    m.carry = nil
    bankItem(it, m.x, m.y)
end

function Loot.update(dt)
    for i = #G.items, 1, -1 do
        local it = G.items[i]
        if it.dead then
            table.remove(G.items, i)
        elseif it.x < C.CACHE_X then
            table.remove(G.items, i)
            bankItem(it, 60, it.y)
        end
    end
end

-- juiciest loose item (possum shopping)
function Loot.best()
    local best, bi
    for _, it in ipairs(G.items) do
        if not it.dead and (not best or it.def.cal > best) then
            best, bi = it.def.cal, it
        end
    end
    return bi
end
