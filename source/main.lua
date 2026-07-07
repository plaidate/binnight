-- Bin Night - a tag-team trash heist for Playdate.
-- Trash Panda opens, Bin Chicken crosses, Alley Cat runs. Loot the street
-- into the alley cache before the dawn garbage truck eats it, one bin at
-- a time. Meet the calorie quota or the gang goes hungry.

import "CoreLibs/graphics"

import "config"
import "util"
import "harness"
import "save"
import "sfx"
import "fx"
import "loot"
import "bins"
import "street"
import "houses"
import "dogs"
import "critters"
import "cars"
import "truck"
import "squad"
import "input"
import "draw"

Game = {}

Save.load()
math.randomseed(playdate.getSecondsSinceEpoch())
playdate.display.setRefreshRate(SMOKE_BUILD and 0 or 30)
Harness.shotPath = "build/binnight-shot.png"

local function startStreet(n)
    G.cal = 0
    G.playT = 0
    G.overReason = ""
    Fx.reset()
    Loot.reset()
    Street.reset(n)
    Houses.reset()
    Dogs.reset()
    Critters.reset()
    Cars.reset()
    Truck.reset()
    Squad.reset()
    G.state = "card"
    G.t = 0
end

-- boot: build a street so every screen has a backdrop
startStreet(1)
G.state = "title"
Draw.init()

local function startRun()
    G.career = 0
    Harness.count("games")
    Sfx.trioFanfare()
    startStreet(1)
end

function Game.over(reason)
    G.overReason = reason
    if G.career > G.high then
        G.high = G.career
        Save.store()
    end
    G.state = "gameover"
    G.t = 0
    Harness.count("gameovers")
    Sfx.lose()
end

-- the truck has left: tally the night
function Game.endNight()
    for _, hs in ipairs(G.houses) do
        if not hs.woken then
            G.cal = G.cal + C.STEALTH_PTS
            G.career = G.career + C.STEALTH_PTS
            Harness.count("stealthHouses")
        end
    end
    G.state = "spoils"
    G.t = 0
    if G.cal >= G.quota then
        Sfx.trioFanfare()
    else
        Sfx.lose()
    end
end

-- smoke shortcut: street 2's failure night doesn't need the full clock
local function nightLen()
    if SMOKE_BUILD and G.streetN >= 2 then return 25 end
    return C.NIGHT_T
end

local cricketT = 2

local function updatePlay(dt)
    G.playT = G.playT + dt
    if not G.truck and G.playT >= nightLen() then
        G.playT = math.max(G.playT, C.NIGHT_T) -- fast nights jump straight to 5AM
    end
    local inp = Input.gather()
    Squad.update(dt, inp)
    Street.updateSprinks(dt)
    Houses.update(dt)
    Dogs.update(dt)
    Critters.update(dt)
    Cars.update(dt)
    Truck.update(dt)
    if G.state ~= "play" then return end
    Loot.update(dt)

    cricketT = cricketT - dt
    if cricketT <= 0 then
        cricketT = 2 + math.random() * 4
        if not G.truck then Sfx.blip(1800 + math.random(0, 600)) end
    end
end

local function tick()
    local dt = C.DT
    G.t = G.t + dt
    Util.runPending(dt)
    Fx.update(dt)

    if G.state == "title" then
        if Input.confirm() then startRun() end
        Draw.title()
    elseif G.state == "card" then
        Draw.card()
        if G.t > 2.0 then
            G.state = "play"
            G.t = 0
        end
    elseif G.state == "play" then
        updatePlay(dt)
        if G.state == "play" then Draw.play() end
    elseif G.state == "spoils" then
        Draw.spoils()
        if G.t > 1.2 and Input.confirm() then
            if G.cal >= G.quota then
                Harness.count("streetsCleared")
                startStreet(G.streetN + 1)
            else
                Game.over("THE GANG WENT HUNGRY")
            end
        end
    elseif G.state == "gameover" then
        Draw.gameover()
        if G.t > 1 and Input.confirm() then
            G.state = "title"
            G.t = 0
        end
    end
end

Harness.extra = function(t)
    t.state = G.state
    t.street = G.streetN
    t.cal = G.cal
    t.quota = G.quota
    t.career = G.career
    t.high = G.high
    t.playT = math.floor(G.playT)
    t.cur = G.crew and G.crew[G.cur] and G.crew[G.cur].kind or "?"
    t.binsLeft = G.bins and Bins.left() or 0
    t.itemsOut = G.items and #G.items or 0
    t.truckHouse = G.truck and G.truck.hi or -1
    t.overReason = G.overReason
    -- diagnostics for the confiscation path
    local h1 = G.houses and G.houses[1]
    if h1 then
        t.h1 = math.floor(h1.grumpy) .. (h1.light > 0 and " LIT " or " drk ")
            .. string.format("%.1f", h1.seen) .. (h1.owner and " OWNER" or "")
    end
    local a = G.crew and G.crew[G.cur]
    if a then
        t.ap = math.floor(a.x) .. "," .. math.floor(a.y) .. (a.carry and " CARRY" or "")
    end
end

local frame = 0
function playdate.update()
    frame = frame + 1
    Harness.frame(frame, tick)
end
