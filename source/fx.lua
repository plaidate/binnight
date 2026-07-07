-- Transient effects: floating text, puffs, and expanding noise rings
-- (world-space; Draw applies the camera).

local gfx <const> = playdate.graphics

Fx = {}

function Fx.reset()
    G.fxTexts = {}
    G.fxPuffs = {}
    G.fxRings = {}
end

function Fx.text(txt, x, y)
    G.fxTexts[#G.fxTexts + 1] = { txt = txt, x = x, y = y, t = 1.1 }
end

function Fx.puff(x, y, n)
    for _ = 1, (n or 5) do
        local a = math.random() * 6.283
        local s = 30 + math.random() * 60
        G.fxPuffs[#G.fxPuffs + 1] = {
            x = x, y = y,
            vx = math.cos(a) * s, vy = math.sin(a) * s,
            t = 0.35 + math.random() * 0.2,
        }
    end
end

function Fx.ring(x, y, r)
    G.fxRings[#G.fxRings + 1] = { x = x, y = y, r = r or 60, t = 0.5 }
end

function Fx.update(dt)
    for i = #G.fxTexts, 1, -1 do
        local f = G.fxTexts[i]
        f.t = f.t - dt
        f.y = f.y - 24 * dt
        if f.t <= 0 then table.remove(G.fxTexts, i) end
    end
    for i = #G.fxPuffs, 1, -1 do
        local p = G.fxPuffs[i]
        p.t = p.t - dt
        p.x = p.x + p.vx * dt
        p.y = p.y + p.vy * dt
        if p.t <= 0 then table.remove(G.fxPuffs, i) end
    end
    for i = #G.fxRings, 1, -1 do
        local r = G.fxRings[i]
        r.t = r.t - dt
        if r.t <= 0 then table.remove(G.fxRings, i) end
    end
end

-- cam = camera x offset
function Fx.draw(cam)
    gfx.setColor(gfx.kColorWhite)
    for _, p in ipairs(G.fxPuffs) do
        gfx.fillRect(p.x - cam - 1, p.y - 1, 3, 3)
    end
    gfx.setLineWidth(1)
    for _, r in ipairs(G.fxRings) do
        local k = 1 - r.t / 0.5
        gfx.drawCircleAtPoint(r.x - cam, r.y, r.r * k)
    end
    gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
    for _, f in ipairs(G.fxTexts) do
        gfx.drawTextAligned(f.txt, f.x - cam, f.y, kTextAlignment.center)
    end
    gfx.setImageDrawMode(gfx.kDrawModeCopy)
    gfx.setColor(gfx.kColorBlack)
end
