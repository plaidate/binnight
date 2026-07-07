-- Night cars: occasional headlight sweeps down the road band. Getting
-- caught means a cartoon flattening, a stun, and scattered loot.

Cars = {}

function Cars.reset()
    G.car = nil
    G.carT = 10 + math.random() * 10
end

function Cars.update(dt)
    if G.playT >= C.NIGHT_T then return end -- the truck owns the road at dawn
    if not G.car then
        G.carT = G.carT - dt
        if G.carT <= 0 then
            local dir = math.random() < 0.5 and 1 or -1
            G.car = {
                dir = dir,
                x = dir == 1 and -40 or C.W + 40,
                y = dir == 1 and 222 or 202,
            }
            Sfx.swish()
        end
        return
    end
    local c = G.car
    c.x = c.x + c.dir * C.CAR_SPD * dt
    for _, m in ipairs(G.crew) do
        if m.flatT <= 0 and math.abs(m.y - c.y) < 12 and math.abs(m.x - c.x) < 22 then
            m.flatT = 1.5
            Squad.hurt(m, 1.5, true)
            Sfx.flatten()
            Fx.text("FLATTENED!", m.x, m.y - 20)
            Fx.puff(m.x, m.y, 6)
            Harness.count("flattens")
        end
    end
    if (c.dir == 1 and c.x > C.W + 50) or (c.dir == -1 and c.x < -50) then
        G.car = nil
        G.carT = 14 + math.random() * 14
    end
end
