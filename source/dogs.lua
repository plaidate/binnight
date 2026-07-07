-- Chained yard dogs. Noise wakes them; they chase whoever strays into
-- range (cats from twice as far), barking the neighborhood awake.

Dogs = {}

function Dogs.reset()
    G.dogs = {}
    for _, h in ipairs(G.street.houses) do
        if h.dogPos then
            G.dogs[#G.dogs + 1] = {
                post = h.dogPos, x = h.dogPos.x, y = h.dogPos.y,
                house = h.i, awake = false, sleepT = 0,
                barkT = 0, biteCD = 0,
            }
        end
    end
end

function Dogs.hear(x, y, amt)
    for _, d in ipairs(G.dogs) do
        if amt >= 1.5 and Util.dist(x, y, d.post.x, d.post.y) < 130 then
            if not d.awake then Sfx.bark() end
            d.awake = true
            d.sleepT = 8
        end
    end
end

function Dogs.update(dt)
    for _, d in ipairs(G.dogs) do
        d.biteCD = math.max(0, d.biteCD - dt)
        if d.awake then
            -- pick a mark: the decoy chicken, else the closest crew in range
            local target, td
            if G.decoy and Util.dist(G.decoy.m.x, G.decoy.m.y, d.post.x, d.post.y) < 170 then
                target = G.decoy.m
            else
                for _, m in ipairs(G.crew) do
                    local aggro = m.kind == "cat" and C.DOG_AGGRO_CAT or C.DOG_AGGRO
                    local dist = Util.dist(m.x, m.y, d.post.x, d.post.y)
                    if dist < aggro and (not td or dist < td) then
                        target, td = m, dist
                    end
                end
            end

            if target then
                local nx, ny = Util.norm(d.x, d.y, target.x, target.y)
                d.x = d.x + nx * C.DOG_SPD * dt
                d.y = d.y + ny * C.DOG_SPD * dt
                -- the chain (and it can't cross the front fence: it lunges
                -- at the fence line, but footpath walkers stay out of reach)
                local cd = Util.dist(d.x, d.y, d.post.x, d.post.y)
                if cd > C.DOG_CHAIN then
                    local px, py = Util.norm(d.post.x, d.post.y, d.x, d.y)
                    d.x = d.post.x + px * C.DOG_CHAIN
                    d.y = d.post.y + py * C.DOG_CHAIN
                end
                d.y = math.min(d.y, C.FENCE_Y - 10)
                d.sleepT = 6
                d.barkT = d.barkT - dt
                if d.barkT <= 0 then
                    d.barkT = 1.3
                    Sfx.bark()
                    Houses.noise(d.x, d.y, C.NZ_BARK)
                    target.alertT = math.max(target.alertT, 0.6)
                end
                if d.biteCD <= 0 and Util.dist(d.x, d.y, target.x, target.y) < 13
                    and not (target.kind == "chicken" and target.flying) then
                    d.biteCD = C.BITE_CD
                    Squad.hurt(target, 1.0, true)
                    Sfx.yelp()
                    Fx.text("CHOMP!", target.x, target.y - 20)
                    Harness.count("bites")
                end
            else
                -- drift back to the post, doze off eventually
                if Util.dist(d.x, d.y, d.post.x, d.post.y) > 4 then
                    local nx, ny = Util.norm(d.x, d.y, d.post.x, d.post.y)
                    d.x = d.x + nx * 40 * dt
                    d.y = d.y + ny * 40 * dt
                end
                d.sleepT = d.sleepT - dt
                if d.sleepT <= 0 then d.awake = false end
            end
        end
    end
end
