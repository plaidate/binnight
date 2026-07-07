-- Best-career persistence in the "binnight" datastore.

Save = {}

function Save.load()
    local d = playdate.datastore.read("binnight")
    G.high = (d and d.high) or 0
end

function Save.store()
    playdate.datastore.write({ high = G.high }, "binnight")
end
