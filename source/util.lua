-- Shared helpers: math bits and a delayed-call scheduler (used by multi-note
-- sound effects and timed fx).

Util = {}

function Util.clamp(v, lo, hi)
    if v < lo then return lo elseif v > hi then return hi else return v end
end

function Util.lerp(a, b, t)
    return a + (b - a) * t
end

function Util.sign(v)
    if v > 0 then return 1 elseif v < 0 then return -1 else return 0 end
end

function Util.dist(x1, y1, x2, y2)
    local dx, dy = x2 - x1, y2 - y1
    return math.sqrt(dx * dx + dy * dy)
end

-- unit vector from (x1,y1) toward (x2,y2); (1,0) if coincident
function Util.norm(x1, y1, x2, y2)
    local dx, dy = x2 - x1, y2 - y1
    local d = math.sqrt(dx * dx + dy * dy)
    if d < 0.001 then return 1, 0 end
    return dx / d, dy / d
end

local pending = {}
function Util.after(delay, fn)
    pending[#pending + 1] = { t = delay, fn = fn }
end

function Util.runPending(dt)
    for i = #pending, 1, -1 do
        local p = pending[i]
        p.t = p.t - dt
        if p.t <= 0 then
            table.remove(pending, i)
            p.fn()
        end
    end
end
