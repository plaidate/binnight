-- The dawn garbage truck. Enters far right at NIGHT_T, works house by
-- house toward the cache: pull up, claw-grab the bins, move on. Anything
-- still in a bin when the claw closes is gone. Round ends when it passes
-- the last house.

Truck = {}

function Truck.reset()
    G.truck = nil
    G.beepT = 0
end

local function binX(hi)
    -- rightmost surviving bin of house hi (the truck works right to left)
    local bx
    for _, b in ipairs(G.bins) do
        if b.house == hi and b.state ~= "gone" and b.y > 140 then
            if not bx or b.x > bx then bx = b.x end
        end
    end
    return bx
end

function Truck.update(dt)
    if not G.truck then
        if G.playT >= C.NIGHT_T then
            G.truck = { x = C.W + 90, hi = 6, state = "drive", t = 0 }
            Sfx.airbrake()
            Fx.text("*THE TRUCK!*", C.W - 160, 100)
            Harness.count("truckRuns")
        end
        return
    end
    local tk = G.truck
    G.beepT = G.beepT - dt
    if G.beepT <= 0 then
        G.beepT = 1.2
        Sfx.beep()
    end

    -- shove anyone standing in the road out of the way. The velocity push
    -- is resolved by squad.lua:integrate (which owns fence crossings); the
    -- immediate nudge is clamped so it can never skip the fence line where
    -- there's no gate/driveway to cross at.
    for _, m in ipairs(G.crew) do
        if m.y > C.ROAD_Y - 4 and math.abs(m.x - tk.x) < 46 then
            m.vy = -160
            local ny = m.y - 60 * dt
            if ny < C.FENCE_Y and not Street.canCross(m.x) then
                ny = C.FENCE_Y
            end
            m.y = ny
        end
    end

    if tk.state == "drive" then
        -- skip houses with nothing left at the curb
        local bx = binX(tk.hi)
        while not bx and tk.hi > 0 do
            tk.hi = tk.hi - 1
            bx = binX(tk.hi)
        end
        if tk.hi <= 0 then
            tk.x = tk.x - C.TRUCK_SPD * 1.4 * dt
            if tk.x < -120 then Game.endNight() end
            return
        end
        tk.x = tk.x - C.TRUCK_SPD * dt
        if tk.x <= bx + 34 then
            tk.state = "grab"
            tk.t = C.TRUCK_GRAB
            Sfx.claw()
        end
    else -- grab
        tk.t = tk.t - dt
        if tk.t <= C.TRUCK_GRAB / 2 and not tk.grabbed then
            tk.grabbed = true
            for _, b in ipairs(G.bins) do
                if b.house == tk.hi and b.state ~= "gone" and b.y > 140 then
                    b.state = "gone"
                    b.loot = {}
                end
            end
            Fx.puff(tk.x - 30, 168, 6)
            Harness.count("binsEaten")
        end
        if tk.t <= 0 then
            tk.grabbed = false
            tk.hi = tk.hi - 1
            tk.state = "drive"
        end
    end
end
