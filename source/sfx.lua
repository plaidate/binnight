-- Synth sound effects: a suburban night kit. The ibis HONK, ratchet pry
-- clicks, bottle clatter, dog barks, the truck's reverse beeper.

local snd <const> = playdate.sound

Sfx = {}

local tri = snd.synth.new(snd.kWaveTriangle)
local tri2 = snd.synth.new(snd.kWaveTriangle)
local sq = snd.synth.new(snd.kWaveSquare)
local sq2 = snd.synth.new(snd.kWaveSquare)
local saw = snd.synth.new(snd.kWaveSawtooth)
local noise = snd.synth.new(snd.kWaveNoise)
local noise2 = snd.synth.new(snd.kWaveNoise)

function Sfx.blip(f) tri:playNote(f or 660, 0.25, 0.05) end

function Sfx.fanfare(notes, step)
    notes = notes or { 523, 659, 784, 1047 }
    for i, n in ipairs(notes) do
        Util.after((i - 1) * (step or 0.1), function() tri:playNote(n, 0.3, (step or 0.1) * 1.4) end)
    end
end

function Sfx.lose() Sfx.fanfare({ 494, 415, 349, 262 }, 0.14) end

-- the trio
function Sfx.honk()
    saw:playNote(420, 0.35, 0.12)
    Util.after(0.11, function() saw:playNote(260, 0.3, 0.16) end)
end

function Sfx.squawk()
    saw:playNote(500, 0.4, 0.1)
    Util.after(0.09, function() saw:playNote(330, 0.38, 0.1) end)
    Util.after(0.18, function() saw:playNote(240, 0.35, 0.2) end)
end

function Sfx.meow()
    tri2:playNote(520, 0.3, 0.08)
    Util.after(0.07, function() tri2:playNote(700, 0.28, 0.09) end)
    Util.after(0.16, function() tri2:playNote(430, 0.24, 0.1) end)
end

function Sfx.yowl()
    saw:playNote(700, 0.3, 0.08)
    Util.after(0.06, function() saw:playNote(900, 0.25, 0.1) end)
end

function Sfx.hiss() noise:playNote(1200, 0.25, 0.18) end
function Sfx.flapWing() noise:playNote(300, 0.22, 0.06) end
function Sfx.thump() noise2:playNote(90, 0.3, 0.05) end

-- bins
function Sfx.ratchet() sq:playNote(700 + math.random(0, 200), 0.18, 0.02) end
function Sfx.slip() saw:playNote(900, 0.25, 0.08) end

function Sfx.clunk()
    sq2:playNote(160, 0.4, 0.08)
    noise:playNote(200, 0.3, 0.06)
end

function Sfx.crash()
    for i = 0, 3 do
        Util.after(i * 0.06, function() noise2:playNote(320 - i * 50, 0.4, 0.07) end)
    end
end

function Sfx.clatter()
    for i = 0, 4 do
        Util.after(i * 0.05, function() sq:playNote(900 + math.random(-200, 400), 0.25, 0.03) end)
    end
end

function Sfx.lid() sq2:playNote(240, 0.3, 0.05) end
function Sfx.plunge() tri:playNote(880, 0.2, 0.03) end

function Sfx.gulpBank()
    tri2:playNote(520, 0.3, 0.05)
    Util.after(0.05, function() tri2:playNote(700, 0.3, 0.05) end)
end

-- hazards
function Sfx.bark()
    sq2:playNote(170, 0.4, 0.06)
    Util.after(0.08, function() sq2:playNote(150, 0.38, 0.07) end)
end

function Sfx.yelp() tri:playNote(900, 0.35, 0.12) end

function Sfx.oi()
    sq:playNote(220, 0.4, 0.1)
    Util.after(0.1, function() sq:playNote(150, 0.4, 0.14) end)
end

function Sfx.squeak() tri:playNote(1500, 0.2, 0.04) end
function Sfx.chitter()
    for i = 0, 2 do
        Util.after(i * 0.05, function() tri:playNote(1100 + i * 90, 0.18, 0.03) end)
    end
end

function Sfx.tick() sq:playNote(1200, 0.15, 0.02) end
function Sfx.spray() noise:playNote(500, 0.18, 0.25) end
function Sfx.swish() noise2:playNote(240, 0.3, 0.4) end
function Sfx.flatten() sq2:playNote(120, 0.45, 0.2) end

-- the truck
function Sfx.airbrake() noise2:playNote(180, 0.45, 0.6) end
function Sfx.beep() sq:playNote(880, 0.22, 0.09) end
function Sfx.claw()
    saw:playNote(200, 0.3, 0.3)
    Util.after(0.3, function()
        noise2:playNote(150, 0.45, 0.15)
        sq2:playNote(90, 0.4, 0.15)
    end)
end

function Sfx.trioFanfare()
    Sfx.thump()
    Util.after(0.12, Sfx.honk)
    Util.after(0.3, Sfx.meow)
    Util.after(0.55, function() Sfx.fanfare({ 659, 784, 1047 }, 0.09) end)
end
