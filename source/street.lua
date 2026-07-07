-- Street layout. Six 200px lots: house front, yard, front fence with a
-- gate (and sometimes a driveway gap), bins on the nature strip. Street 1
-- is handcrafted; later streets are generated from the same parts kit
-- with difficulty knobs. Also owns fence-crossing queries and sprinklers.

Street = {}

local NAMES = {
    "QUIET CRESCENT", "SPRINKLER ROW", "McMANSION DRIVE",
    "BINCHICKEN BLVD", "RACCOON ROAD", "MOGGY LANE",
}

local function lot(i) return (i - 1) * 200 end

local function house(i, style, sens, opts)
    local x0 = lot(i)
    local h = {
        i = i, x0 = x0, style = style, sens = sens,
        doorX = x0 + 100, porchX = x0 + 66, gateX = x0 + 138,
        drive = opts.drive and { x = x0 + 172, w = 50 } or nil,
        dogPos = opts.dog and { x = x0 + 56, y = 94 } or nil,
        sprink = opts.sprink and { x = x0 + 76, y = 96 } or nil,
        tree = opts.tree and { x = x0 + 158, y = 82 } or nil,
    }
    return h
end

local function addBins(h, kinds, legendAt)
    local xs = { h.x0 + 88, h.x0 + 116 }
    for k, kind in ipairs(kinds) do
        if kind == "dump" then
            Bins.make("dump", h.drive.x, 170, h.i, legendAt == k)
        elseif kind == "compost" then
            Bins.make("compost", h.x0 + 34, 92, h.i, false)
        else
            Bins.make(kind, xs[math.min(k, 2)] + (k > 2 and 26 or 0), 168, h.i, legendAt == k)
        end
    end
end

function Street.name(n)
    local nm = NAMES[(n - 1) % #NAMES + 1]
    if n > #NAMES then nm = nm .. " " .. (math.floor((n - 1) / #NAMES) + 1) end
    return nm
end

function Street.reset(n)
    G.streetN = n
    G.diff = math.min(1, (n - 1) / 4)
    G.quota = C.QUOTA1 + C.QUOTA_STEP * (n - 1)
    G.bins = {}
    G.sprinks = {}
    local hs = {}

    if n == 1 then
        hs[1] = house(1, 1, 0.7, {})
        hs[2] = house(2, 2, 0.8, { drive = true, dog = true })
        hs[3] = house(3, 3, 0.8, { sprink = true })
        hs[4] = house(4, 1, 1.0, {})
        hs[5] = house(5, 2, 0.9, { drive = true, dog = true })
        hs[6] = house(6, 3, 0.8, { tree = true })
        addBins(hs[1], { "open", "lid" })
        addBins(hs[2], { "lid", "recyc", "dump" }, 3) -- the lasagna dumpster
        addBins(hs[3], { "latch", "open", "compost" })
        addBins(hs[4], { "lid", "lid" })
        addBins(hs[5], { "latch", "recyc" })
        addBins(hs[6], { "open", "lid", "compost" })
    else
        local d = G.diff
        local legendHouse = math.random(2, 6)
        local trees, dogs = 0, 0
        for i = 1, 6 do
            local style = math.random(1, 3)
            local dog = dogs < 3 and math.random() < 0.25 + 0.2 * d
            if dog then dogs = dogs + 1 end
            local tree = (i == 6 and trees == 0) or math.random() < 0.2
            if tree then trees = trees + 1 end
            local drive = math.random() < 0.45
            hs[i] = house(i, style, 0.7 + d * 0.5 + math.random() * 0.2, {
                dog = dog, sprink = math.random() < 0.2 + 0.25 * d,
                tree = tree, drive = drive,
            })
            local kinds = {}
            for k = 1, 2 do
                local r = math.random()
                if r < 0.30 - 0.1 * d then kinds[k] = "open"
                elseif r < 0.62 then kinds[k] = "lid"
                elseif r < 0.82 + 0.1 * d then kinds[k] = "latch"
                else kinds[k] = "recyc" end
            end
            local legendAt = nil
            if drive and math.random() < 0.6 then
                kinds[#kinds + 1] = "dump"
                if i == legendHouse then legendAt = #kinds end
            elseif i == legendHouse then
                kinds[1] = "latch"
                legendAt = 1
            end
            if math.random() < 0.3 then kinds[#kinds + 1] = "compost" end
            addBins(hs[i], kinds, legendAt)
        end
    end

    for _, h in ipairs(hs) do
        if h.sprink then
            G.sprinks[#G.sprinks + 1] = {
                x = h.sprink.x, y = h.sprink.y,
                state = "off", t = 3 + math.random() * 5,
            }
        end
    end

    G.street = {
        n = n, houses = hs,
        drains = { 160, 560, 960 },
        lampXs = { 90, 270, 450, 630, 810, 990, 1170 },
        parked = { 340 + math.random(0, 60), 760 + math.random(0, 80) },
    }
end

-- can a grounded creature cross the front fence at this x?
function Street.canCross(x)
    if x < C.CACHE_X + 10 then return true end -- the alley
    for _, h in ipairs(G.street.houses) do
        if math.abs(x - h.gateX) < 10 then return true end
        if h.drive and math.abs(x - h.drive.x) < h.drive.w / 2 then return true end
    end
    return false
end

-- sprinklers: off -> warn (ticks) -> on (burst)
function Street.updateSprinks(dt)
    for _, s in ipairs(G.sprinks) do
        s.t = s.t - dt
        if s.state == "off" and s.t <= 0 then
            s.state = "warn"
            s.t = 1.2
        elseif s.state == "warn" then
            if math.floor(s.t * 6) ~= math.floor((s.t + dt) * 6) then Sfx.tick() end
            if s.t <= 0 then
                s.state = "on"
                s.t = 3
                Sfx.spray()
            end
        elseif s.state == "on" and s.t <= 0 then
            s.state = "off"
            s.t = 5 + math.random() * 4
        end
        if s.state == "on" then
            for _, it in ipairs(G.items) do
                if not it.soggy and Util.dist(it.x, it.y, s.x, s.y) < C.SPRINK_R then
                    it.soggy = true
                end
            end
        end
    end
end

-- speed factor / hard-block for a member at (x,y)
function Street.sprinkFactor(m)
    for _, s in ipairs(G.sprinks) do
        if s.state == "on" and Util.dist(m.x, m.y, s.x, s.y) < C.SPRINK_R + (m.kind == "cat" and 8 or 0) then
            if m.kind == "cat" then return 0 end   -- refuses: repulsed
            if m.kind == "panda" then return 0.55 end
        end
    end
    return 1
end
