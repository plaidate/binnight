-- Night rendering. The world is BLACK; everything reads as white shapes,
-- outlines and dithered light pools (streetlamps, porch cones, headlights).
-- Characters are white silhouettes with black detail, plus a black outline
-- so they stay legible standing inside a light pool.

local gfx <const> = playdate.graphics

Draw = {}

local PAT50 <const> = { 0x55, 0xAA, 0x55, 0xAA, 0x55, 0xAA, 0x55, 0xAA }
local PAT25 <const> = { 0x44, 0x00, 0x11, 0x00, 0x44, 0x00, 0x11, 0x00 }
local PAT12 <const> = { 0x40, 0x00, 0x00, 0x00, 0x04, 0x00, 0x00, 0x00 }

local cam = 0

function Draw.init()
    Draw.stars = {}
    for i = 1, 40 do
        Draw.stars[i] = { math.random(0, 399), math.random(0, 40) }
    end
end

local function white() gfx.setColor(gfx.kColorWhite) end
local function black() gfx.setColor(gfx.kColorBlack) end
local function textWhite(s, x, y, align)
    gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
    gfx.drawTextAligned(s, x, y, align or kTextAlignment.center)
    gfx.setImageDrawMode(gfx.kDrawModeCopy)
end

-- ---- terrain ----------------------------------------------------------------

local function drawBands()
    gfx.setPattern(PAT25)
    gfx.fillRect(0, 126, C.SW, 26)          -- footpath
    gfx.setPattern(PAT12)
    gfx.fillRect(0, C.CURB_Y, C.SW, 30)     -- nature strip
    black()
    -- road dashes
    white()
    local off = -(cam % 24)
    for x = off, C.SW, 24 do
        gfx.fillRect(x, 213, 10, 2)
    end
    black()
end

local function drawHouse(h, hs)
    local x = h.x0 - cam
    if x > C.SW + 20 or x < -220 then return end
    white()
    gfx.setLineWidth(1)
    local fx0, fw = x + 18, 164
    gfx.drawRect(fx0, 10, fw, 48)
    if h.style == 1 then -- weatherboard + porch posts
        gfx.drawLine(fx0, 10, fx0 + fw / 2, 2)
        gfx.drawLine(fx0 + fw / 2, 2, fx0 + fw, 10)
        gfx.drawLine(h.porchX - cam - 14, 58, h.porchX - cam - 14, 42)
        gfx.drawLine(h.porchX - cam + 14, 58, h.porchX - cam + 14, 42)
    elseif h.style == 2 then -- brick box with awnings
        gfx.drawLine(fx0 + 8, 10, fx0 + 8, 58)
        gfx.drawLine(fx0 + fw - 8, 10, fx0 + fw - 8, 58)
    else -- skinny two-story
        gfx.drawRect(fx0 + 30, 0, fw - 60, 10)
    end
    -- windows (glow when the house is awake)
    for wi = 0, 1 do
        local wx = fx0 + 28 + wi * 92
        if hs and hs.woken then
            gfx.fillRect(wx, 22, 22, 14)
        else
            gfx.drawRect(wx, 22, 22, 14)
            gfx.drawLine(wx + 11, 22, wx + 11, 36)
        end
    end
    -- door + porch light fixture
    gfx.drawRect(h.doorX - cam - 8, 34, 16, 24)
    gfx.fillCircleAtPoint(h.porchX - cam, 62, 2)
    -- letterbox at the gate
    gfx.drawRect(h.gateX - cam - 3, 112, 7, 5)
    gfx.drawLine(h.gateX - cam, 117, h.gateX - cam, 121)
    -- tree
    if h.tree then
        local tx, ty = h.tree.x - cam, h.tree.y
        gfx.drawLine(tx, ty + 14, tx, ty)
        gfx.drawCircleAtPoint(tx, ty - 6, 10)
        gfx.drawCircleAtPoint(tx - 7, ty - 1, 7)
        gfx.drawCircleAtPoint(tx + 7, ty - 1, 7)
    end
    -- the Hills Hoist (house 4's yard)
    if h.i == 4 then
        local hx, hy = x + 40, 92
        gfx.drawLine(hx, hy + 12, hx, hy - 6)
        gfx.drawLine(hx - 10, hy - 2, hx + 10, hy - 10)
        gfx.drawLine(hx - 10, hy - 10, hx + 10, hy - 2)
    end
    black()
end

local function drawFence()
    white()
    for x = 0, C.SW do
        local wx = x + cam
        if wx > C.CACHE_X + 10 and not Street.canCross(wx) then
            if x % 6 < 1 then
                gfx.fillRect(x, C.FENCE_Y - 3, 1, 6)
            end
        end
    end
    for _, h in ipairs(G.street.houses) do
        local gx = h.gateX - cam
        if gx > -12 and gx < C.SW + 12 then
            gfx.drawLine(gx - 8, C.FENCE_Y - 3, gx + 8, C.FENCE_Y + 3)
            gfx.drawLine(gx - 8, C.FENCE_Y + 3, gx + 8, C.FENCE_Y - 3)
        end
    end
    black()
end

local function drawLights()
    -- streetlamp pools + poles
    for _, lx in ipairs(G.street.lampXs) do
        local x = lx - cam
        if x > -60 and x < C.SW + 60 then
            gfx.setPattern(PAT25)
            gfx.fillEllipseInRect(x - 44, 132, 88, 40)
            white()
            gfx.drawLine(x, 150, x, 98)
            gfx.fillCircleAtPoint(x, 96, 3)
            black()
        end
    end
    -- porch cones
    for _, hs in ipairs(G.houses) do
        if hs.light > 0 then
            local px = hs.def.porchX - cam
            gfx.setPattern(PAT50)
            gfx.fillPolygon(px, 62, px - 48, 62 + C.LIGHT_R, px + 48, 62 + C.LIGHT_R)
            white()
            gfx.fillEllipseInRect(px - 36, 96, 72, 40)
            black()
        end
    end
end

local function drawCache()
    white()
    gfx.drawLine(C.CACHE_X - cam, C.YARD_TOP, C.CACHE_X - cam, 232)
    textWhite("CACHE", C.CACHE_X - cam - 24, 70, kTextAlignment.left)
    local pile = math.min(12, math.floor(G.cal / 40))
    for i = 1, pile do
        local px = 14 + (i % 3) * 9 - cam
        gfx.drawRect(px, 176 - math.floor((i - 1) / 3) * 6, 7, 5)
    end
    black()
end

-- ---- bins & loot -------------------------------------------------------------

local function drawBin(b)
    local x, y = b.x - cam, b.y
    if x < -40 or x > C.SW + 40 then return end
    if b.state == "gone" then return end
    white()
    gfx.setLineWidth(1)
    if b.state == "tipped" then
        gfx.drawRect(x - 9, y - 2, 20, 12)
        gfx.drawLine(x + 11, y - 2, x + 15, y + 2)
    elseif b.type == "dump" then
        gfx.drawRect(x - 14, y - 14, 28, 18)
        gfx.drawLine(x - 14, y - 14, x - 10, y - 18)
        gfx.drawLine(x - 10, y - 18, x + 18, y - 18)
        gfx.drawLine(x + 18, y - 18, x + 14, y - 14)
    elseif b.type == "compost" then
        gfx.drawArc(x, y, 8, -90, 90)
        gfx.drawLine(x - 8, y, x + 8, y)
    else
        gfx.drawRect(x - 6, y - 12, 13, 14)
        if b.state == "closed" then
            gfx.drawLine(x - 8, y - 12, x + 8, y - 12)
        else
            gfx.drawLine(x - 6, y - 12, x + 2, y - 18)
        end
        if b.type == "latch" then
            gfx.fillRect(x - 1, y - 11, 3, 3)
            if b.pry > 0 and b.state == "closed" then
                gfx.drawArc(x, y - 6, 11, 0, 360 * b.pry / C.PRY_NEED)
            end
        elseif b.type == "recyc" then
            gfx.drawLine(x - 3, y - 4, x + 3, y - 4)
            gfx.drawLine(x - 3, y - 4, x, y - 9)
            gfx.drawLine(x + 3, y - 4, x, y - 9)
        end
    end
    black()
end

local function drawItem(x, y, cls, blinkLegend)
    white()
    if cls == "s" then
        gfx.fillCircleAtPoint(x, y, 2.5)
    elseif cls == "m" then
        gfx.fillRect(x - 4, y - 3, 8, 6)
        black()
        gfx.drawPixel(x, y)
        white()
    elseif cls == "h" then
        gfx.fillRect(x - 5, y - 4, 11, 9)
        black()
        gfx.drawLine(x - 3, y, x + 3, y)
        white()
    else -- the lasagna
        if not blinkLegend or math.floor(G.t * 6) % 2 == 0 then
            gfx.fillRect(x - 6, y - 4, 13, 9)
            black()
            gfx.drawRect(x - 4, y - 2, 9, 5)
            white()
            gfx.drawLine(x, y - 8, x, y - 6)
            gfx.drawLine(x - 8, y, x - 6, y)
            gfx.drawLine(x + 6, y, x + 8, y)
        end
    end
    black()
end

local function drawLoot()
    for _, it in ipairs(G.items) do
        if not it.dead then
            drawItem(it.x - cam, it.y, it.def.cls, true)
            if it.soggy then
                white()
                gfx.drawPixel(it.x - cam - 4, it.y + 5)
                gfx.drawPixel(it.x - cam + 4, it.y + 6)
                black()
            end
        end
    end
end

-- ---- creatures --------------------------------------------------------------

local function outlined(fill)
    -- white silhouette + black outline keeps shapes readable in light pools
    white()
    fill(gfx.fillEllipseInRect)
    black()
    fill(gfx.drawEllipseInRect)
end

local function drawCarry(m)
    if m.carry then
        drawItem(m.x - cam, m.y - 16, m.carry.def.cls, false)
    end
end

local function drawPanda(m)
    local x, y = m.x - cam, m.y
    if m.wrig > 0 then
        outlined(function(f) f(x - 10, y - 3, 20, 7) end)
        return
    end
    local w, h = 22, 13
    if m.still and not m.carry and m.stun <= 0 then w, h = 16, 16 end -- sits up
    outlined(function(f) f(x - w / 2, y - h / 2, w, h) end)
    -- striped tail
    for i = 0, 3 do
        if i % 2 == 0 then white() else black() end
        gfx.fillRect(x - m.face * (w / 2 + 4 + i * 3) - 1, y - 2, 3, 5)
    end
    black()
    -- mask band + ears
    gfx.fillRect(x + m.face * 3 - 4, y - h / 2 + 1, 9, 3)
    white()
    gfx.fillCircleAtPoint(x + m.face * 5, y - h / 2 + 2, 1)
    gfx.fillCircleAtPoint(x + m.face * 1, y - h / 2 + 2, 1)
    gfx.fillRect(x - 3, y - h / 2 - 2, 2, 2)
    gfx.fillRect(x + 2, y - h / 2 - 2, 2, 2)
    black()
    drawCarry(m)
end

local function drawChicken(m)
    local x, y = m.x - cam, m.y
    local fly = m.flying and math.sin(G.t * 20) * 4 or 0
    if m.flying then y = y - 6 end
    outlined(function(f) f(x - 8, y - 5, 17, 10) end)
    -- wings
    if m.flying then
        white()
        gfx.fillPolygon(x - 2, y - 2, x - 14, y - 10 - fly, x - 4, y - 6)
        gfx.fillPolygon(x + 2, y - 2, x + 14, y - 10 - fly, x + 4, y - 6)
        black()
        gfx.drawLine(x - 2, y - 2, x - 14, y - 10 - fly)
        gfx.drawLine(x + 2, y - 2, x + 14, y - 10 - fly)
    end
    -- black neck, head, THE BEAK
    black()
    gfx.setLineWidth(2)
    local hx, hy = x + m.face * 9, y - 9
    gfx.drawLine(x + m.face * 5, y - 3, hx, hy)
    gfx.fillCircleAtPoint(hx, hy, 3)
    gfx.drawLine(hx, hy, hx + m.face * 7, hy + 3)
    gfx.drawLine(hx + m.face * 7, hy + 3, hx + m.face * 10, hy + 8)
    gfx.setLineWidth(1)
    -- black tail tip + legs
    gfx.fillRect(x - m.face * 9 - 1, y - 3, 3, 3)
    if not m.flying then
        gfx.setColor(gfx.kColorWhite)
        gfx.drawLine(x - 2, y + 5, x - 2, y + 9)
        gfx.drawLine(x + 2, y + 5, x + 2, y + 9)
        black()
    end
    if m.carry then
        drawItem(hx + m.face * 10, hy + 10, m.carry.def.cls, false)
    end
end

local function drawCat(m)
    local x, y = m.x - cam, m.y
    if m.hopT > 0 then y = y - math.sin(m.hopT / 0.25 * 3.14) * 8 end
    local stretch = (m.pounceT > 0 or math.abs(m.vx) > 130) and 6 or 0
    outlined(function(f) f(x - 8 - stretch / 2, y - 4, 16 + stretch, 8) end)
    -- black patches
    black()
    gfx.fillCircleAtPoint(x - 3, y - 1, 2)
    gfx.fillCircleAtPoint(x + 4, y + 1, 1.5)
    -- head + ears (one notched)
    white()
    local hx = x + m.face * (10 + stretch / 2)
    gfx.fillCircleAtPoint(hx, y - 4, 4)
    black()
    gfx.drawCircleAtPoint(hx, y - 4, 4)
    gfx.fillPolygon(hx - 3, y - 7, hx - 1, y - 11, hx + 1, y - 7)
    gfx.fillPolygon(hx + 1, y - 7, hx + 3, y - 10, hx + 3.5, y - 7) -- chewed ear
    -- question-mark tail
    gfx.setColor(gfx.kColorWhite)
    gfx.drawArc(x - m.face * 11, y - 4, 4, m.face > 0 and 180 or 0, m.face > 0 and 360 or 180)
    gfx.drawLine(x - m.face * 8, y, x - m.face * 11, y + 2)
    black()
    drawCarry(m)
end

local function drawMember(m, active)
    if m.stun > 0 and math.floor(G.t * 12) % 2 == 1 then return end
    if m.flatT > 0 then
        outlined(function(f) f(m.x - cam - 12, m.y - 2, 24, 4) end)
        return
    end
    if m.kind == "panda" then
        drawPanda(m)
    elseif m.kind == "chicken" then
        drawChicken(m)
    else
        drawCat(m)
    end
    if active then
        white()
        gfx.fillPolygon(m.x - cam - 3, m.y - 24, m.x - cam + 3, m.y - 24, m.x - cam, m.y - 19)
        black()
    end
end

-- ---- hazards ----------------------------------------------------------------

local function drawDogs()
    for _, d in ipairs(G.dogs) do
        local x, y = d.x - cam, d.y
        if x > -30 and x < C.SW + 30 then
            white()
            -- chain back to the post
            local px = d.post.x - cam
            for i = 0, 4 do
                gfx.drawPixel(px + (x - px) * i / 4, d.post.y + (y - d.post.y) * i / 4)
            end
            gfx.fillCircleAtPoint(px, d.post.y, 2)
            outlined(function(f) f(x - 7, y - 4, 14, 8) end)
            white()
            gfx.fillCircleAtPoint(x + (d.awake and 8 or 6), y - 3, 3)
            black()
            if not d.awake then
                textWhite("z", x + 2, y - 22)
            end
        end
    end
end

local function drawCritters()
    white()
    for _, r in ipairs(G.rats) do
        local x = r.x - cam
        gfx.fillEllipseInRect(x - 3, r.y - 2, 7, 4)
        gfx.drawLine(x - 3, r.y, x - 8, r.y - 2)
    end
    local p = G.possum
    if p then
        local x = p.x - cam
        gfx.setPattern(PAT50)
        gfx.fillEllipseInRect(x - 7, p.y - 5, 14, 9)
        white()
        gfx.drawEllipseInRect(x - 7, p.y - 5, 14, 9)
        gfx.drawArc(x - 9, p.y, 3, 90, 270)
        gfx.fillCircleAtPoint(x + 6, p.y - 3, 1)
    end
    black()
end

local function drawPeople()
    for _, hs in ipairs(G.houses) do
        local o = hs.owner
        if o then
            local x = o.x - cam
            white()
            gfx.fillRect(x - 4, o.y - 8, 9, 14)
            gfx.fillCircleAtPoint(x, o.y - 12, 4)
            gfx.drawLine(x + 5, o.y - 4, x + 9 + math.sin(G.t * 14) * 2, o.y - 9)
            black()
        end
    end
end

local function drawSprinks()
    for _, s in ipairs(G.sprinks) do
        local x = s.x - cam
        white()
        gfx.fillRect(x - 1, s.y - 1, 3, 3)
        if s.state == "warn" then
            if math.floor(G.t * 8) % 2 == 0 then
                gfx.drawCircleAtPoint(x, s.y, 5)
            end
        elseif s.state == "on" then
            for i = 1, 8 do
                local a = i / 8 * 6.283 + G.t * 4
                local r = C.SPRINK_R * (0.4 + 0.55 * ((G.t * 2 + i / 8) % 1))
                gfx.drawPixel(x + math.cos(a) * r, s.y + math.sin(a) * r * 0.7)
            end
        end
        black()
    end
end

local function drawCar()
    local c = G.car
    if not c then return end
    local x = c.x - cam
    gfx.setPattern(PAT50)
    gfx.fillPolygon(x + c.dir * 18, c.y - 5, x + c.dir * 78, c.y - 12,
        x + c.dir * 78, c.y + 12, x + c.dir * 18, c.y + 5)
    white()
    gfx.drawRect(x - 18, c.y - 7, 36, 14)
    gfx.fillCircleAtPoint(x - 10, c.y + 8, 3)
    gfx.fillCircleAtPoint(x + 10, c.y + 8, 3)
    black()
end

local function drawTruck()
    local tk = G.truck
    if not tk then return end
    local x = tk.x - cam
    if x < -140 or x > C.SW + 140 then return end
    -- headlights (it drives leftward)
    gfx.setPattern(PAT50)
    gfx.fillPolygon(x - 48, 200, x - 118, 192, x - 118, 224, x - 48, 216)
    -- body
    gfx.setPattern(PAT25)
    gfx.fillRect(x - 30, 190, 78, 30)
    white()
    gfx.drawRect(x - 30, 190, 78, 30)
    gfx.drawRect(x - 48, 196, 18, 24)          -- cab
    gfx.fillCircleAtPoint(x - 38, 222, 5)
    gfx.fillCircleAtPoint(x - 12, 222, 5)
    gfx.fillCircleAtPoint(x + 32, 222, 5)
    if math.floor(G.t * 4) % 2 == 0 then
        gfx.fillRect(x - 28, 186, 6, 3)        -- light bar blink
    end
    -- the claw
    if tk.state == "grab" then
        local k = 1 - tk.t / C.TRUCK_GRAB
        local reach = math.sin(k * 3.14)
        local cx, cy = x - 20 - reach * 14, 190 - reach * 26
        gfx.setLineWidth(2)
        gfx.drawLine(x - 10, 192, cx, cy)
        gfx.drawLine(cx, cy, cx - 5, cy + 7)
        gfx.drawLine(cx, cy, cx + 5, cy + 7)
        gfx.setLineWidth(1)
    end
    black()
end

-- ---- HUD --------------------------------------------------------------------

local function clockStr()
    local hrs = 22 + 7 * math.min(1, G.playT / C.NIGHT_T)
    local h24 = math.floor(hrs) % 24
    local mm = math.floor((hrs % 1) * 6) * 10
    local ampm = h24 >= 12 and "PM" or "AM"
    local h12 = h24 % 12
    if h12 == 0 then h12 = 12 end
    return string.format("%d:%02d%s", h12, mm, ampm)
end

local function drawHud()
    textWhite("CAL " .. G.cal .. "/" .. G.quota, 4, 2, kTextAlignment.left)
    textWhite(clockStr(), 396, 2, kTextAlignment.right)
    -- minimap
    white()
    gfx.drawLine(130, 7, 290, 7)
    for _, b in ipairs(G.bins) do
        if b.state ~= "gone" and (#b.loot > 0 or b.worms > 0) then
            gfx.fillRect(130 + b.x / C.W * 160 - 1, 5, 2, 2)
        end
    end
    gfx.fillRect(129, 3, 2, 8) -- cache flag
    if G.truck then
        gfx.fillRect(130 + Util.clamp(G.truck.x / C.W, 0, 1) * 160 - 2, 2, 5, 4)
    end
    local a = Squad.active()
    if math.floor(G.t * 4) % 2 == 0 then
        gfx.drawCircleAtPoint(130 + a.x / C.W * 160, 6, 3)
    end
    -- crew chips
    local letters = { "P", "C", "A" }
    for i = 1, 3 do
        local m = G.crew[i]
        local bx = 4 + (i - 1) * 18
        if i == G.cur then
            gfx.fillRect(bx, 220, 15, 15)
            black()
            gfx.drawTextAligned(letters[i], bx + 8, 222, kTextAlignment.center)
            white()
        else
            if m.alertT > 0 and math.floor(G.t * 8) % 2 == 0 then
                gfx.drawRect(bx - 1, 219, 17, 17)
            end
            gfx.drawRect(bx, 220, 15, 15)
            textWhite(letters[i], bx + 8, 222)
            white()
        end
        if m.carry then
            gfx.fillCircleAtPoint(bx + 7, 217, 2)
        end
    end
    black()
    -- context prompt over the active character
    local b = Bins.at(a.x, a.y)
    if b and G.state == "play" then
        local verb
        if b.type == "latch" and b.state == "closed" then
            verb = a.kind == "panda" and "CRANK: PRY" or "LATCHED"
        elseif b.type == "recyc" then
            verb = "JUST NOISE"
        elseif b.type == "compost" then
            verb = a.kind == "chicken" and (b.worms > 0 and "A: WORMS" or "EMPTY") or "COMPOST"
        elseif b.state == "closed" and b.type == "lid" then
            verb = a.kind == "chicken" and "A: BEAK-GAP" or "A: FLIP LID"
        elseif b.type == "dump" then
            verb = a.kind == "chicken" and "A: PLUNGE" or (a.kind == "panda" and "A: RUMMAGE" or "TOO DEEP")
        elseif #b.loot > 0 then
            verb = "A: RUMMAGE"
        end
        if verb then
            textWhite(verb, a.x - cam, a.y - 38)
        end
    end
end

-- ---- scenes -----------------------------------------------------------------

local function drawWorld()
    gfx.clear(gfx.kColorBlack)
    white()
    for _, s in ipairs(Draw.stars) do
        gfx.drawPixel(s[1], s[2] % 8 + (s[1] % 3)) -- sparse sky pixels above roofs
    end
    black()
    -- dawn creeps in as the truck approaches
    if G.playT > C.NIGHT_T * 0.85 then
        gfx.setPattern(G.truck and PAT25 or PAT12)
        gfx.fillRect(0, 0, C.SW, 10)
        black()
    end
    drawBands()
    drawLights()
    -- yard grass dots (deterministic scatter)
    white()
    for i = 1, 90 do
        local gx = (i * 137 + 31) % C.W
        local gy = C.YARD_TOP + 6 + (i * 61) % 48
        local sx = gx - cam
        if sx > 0 and sx < C.SW then gfx.drawPixel(sx, gy) end
    end
    black()
    for i, h in ipairs(G.street.houses) do
        drawHouse(h, G.houses[i])
    end
    drawFence()
    -- drains
    white()
    for _, dx in ipairs(G.street.drains) do
        gfx.fillRect(dx - cam - 5, 186, 10, 2)
    end
    -- parked cars on the road
    for _, px in ipairs(G.street.parked) do
        gfx.drawRect(px - cam - 16, 198, 32, 13)
        black()
        gfx.fillRect(px - cam - 10, 201, 20, 7)
        white()
    end
    black()
    drawCache()
    for _, b in ipairs(G.bins) do drawBin(b) end
    drawSprinks()
    drawLoot()
    drawDogs()
    drawCritters()
    drawPeople()
    drawCar()
    drawTruck()
    for i = 3, 1, -1 do
        drawMember(G.crew[i], i == G.cur)
    end
end

function Draw.play()
    local a = Squad.active()
    local target = Util.clamp(a.x - 190, 0, C.W - C.SW)
    cam = cam + (target - cam) * 0.22
    drawWorld()
    Fx.draw(cam)
    drawHud()
end

function Draw.title()
    cam = 0
    drawWorld()
    black()
    gfx.fillRect(30, 20, 340, 92)
    white()
    gfx.drawRect(30, 20, 340, 92)
    black()
    if not Draw.titleImg then
        local img = gfx.image.new(84, 18)
        gfx.pushContext(img)
        gfx.drawTextAligned("*BIN NIGHT*", 42, 0, kTextAlignment.center)
        gfx.popContext()
        Draw.titleImg = img
    end
    gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
    Draw.titleImg:drawScaled(74, 26, 3)
    gfx.setImageDrawMode(gfx.kDrawModeCopy)
    textWhite("a tag-team trash heist", 200, 84)
    textWhite("TRASH PANDA opens - BIN CHICKEN crosses - ALLEY CAT runs", 200, 122)
    textWhite("A: act/grab   hold A: sprint/fly   B: tip/squawk/pounce", 200, 152)
    textWhite("hold B: swap character   crank: pry latched bins", 200, 168)
    textWhite("Bank " .. C.QUOTA1 .. " cal before the dawn truck. BEST: " .. G.high, 200, 190)
    if math.floor(G.t * 2) % 2 == 0 then
        textWhite("*PRESS A*", 200, 214)
    end
end

function Draw.card()
    cam = 0
    drawWorld()
    black()
    gfx.fillRect(70, 78, 260, 84)
    white()
    gfx.drawRect(70, 78, 260, 84)
    black()
    textWhite("NIGHT " .. G.streetN, 200, 88)
    textWhite("*" .. Street.name(G.streetN) .. "*", 200, 106)
    textWhite("QUOTA: " .. G.quota .. " CAL", 200, 128)
    textWhite("collection at dawn", 200, 144)
end

function Draw.spoils()
    gfx.clear(gfx.kColorBlack)
    local pass = G.cal >= G.quota
    textWhite("*DAWN ON " .. Street.name(G.streetN) .. "*", 200, 24)
    textWhite("BANKED  " .. G.cal .. " / " .. G.quota .. " CAL", 200, 62)
    textWhite(pass and "*QUOTA MET - THE GANG FEASTS*" or "*SHORT OF QUOTA...*", 200, 88)
    local stealth = 0
    for _, hs in ipairs(G.houses) do
        if not hs.woken then stealth = stealth + 1 end
    end
    textWhite("houses never woken: " .. stealth .. "  (+" .. stealth * C.STEALTH_PTS .. ")", 200, 116)
    textWhite("career haul: " .. G.career .. "   best: " .. G.high, 200, 140)
    if G.t > 1.2 and math.floor(G.t * 2) % 2 == 0 then
        textWhite(pass and "*PRESS A: NEXT STREET*" or "*PRESS A*", 200, 190)
    end
end

function Draw.gameover()
    gfx.clear(gfx.kColorBlack)
    textWhite("*" .. (G.overReason ~= "" and G.overReason or "GAME OVER") .. "*", 200, 70)
    textWhite("streets survived: " .. (G.streetN - 1), 200, 104)
    textWhite("career haul: " .. G.career .. "   best: " .. G.high, 200, 124)
    if G.t > 1 and math.floor(G.t * 2) % 2 == 0 then
        textWhite("*PRESS A*", 200, 170)
    end
end
