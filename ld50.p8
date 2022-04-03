pico-8 cartridge // http://www.pico-8.com
version 18
__lua__
-- game afterquest
-- by etmm
--[[
ld50!

mapgen
The map is a table of rooms. Each room contains goodies, baddies, and hazards
Hazards are imprinted onto the tile map.
-Rocks block movement
-Gaps block movement (without the wing powerup)
-Water slows movement and can be electrified
-Wood can be burned with fireballs
-Doors and boss doors block movement and can be removed with keys and boss keys respectively.
Goodies and baddies both track if they have been collected / defeated respectively.
Goodies include livers (health), keys, and the following
powerups
-fireball
-lightning bolt
-flight
-dash
potions
-red, extra health
-blue, extra speed
-green, improved fire rate
Another table tracks doors. Each door is in a pair indicates its direction (vertical or horizontal) and status 
(open = 0, locked = 1, bosslocked = 2, firelocked = 3, gap = 4)

Level gen algorithm
All doors are open to start with. Their status is changed later on.
Start with several random room nodes roughly in a wheel. Connect them with rooms and doors
From each node start several extra "strands". One of them will contain the node's special item. The others have goodies like potions 
]]
cx = 128 cy = 112 -- camera position
ncx = cx ncy = cy -- next camera position
camlock = false -- if false player can move, otherwise camera moves to next position
gp = 0
gpbuff = 0
gptime = 10
gpclock = 0
message = ""
mess_time = 5
mess_clock = 0
px = 192 py = 192 -- player position
npx = 0 npy = 0
pcx = 0 pcy = 0 -- player cell x and y
debug = {}
cards = {{1,0},{0,-1},{-1,0},{0,1}} -- cardinal directions
visited = {} -- track contents of rooms the player has visited
goodies = {}
--text = "congratulations!\nyou have brought peace!\n\nX to keep playing"
text = "congratulations!\nyou have defeated the\ndark lord and brought\npeace to the land\npress X to continue"
show_text = true
psprt = 16
phf = true
anim_clock = 0
anim_time = 8
lines = {
    "just stop playing.\nnot worth it 0/10",
    "look at these ******\nlevels, so boring!",
    "you know they bothered\nwith proc gen?\nnot like anyone ever\nplayed this twice.",
    "here!",
    "hidden wall ahead",
    "liar ahead",
    "looking for group",
    "nothing here",
    "broken, boring,\nunfinished game. 1/5",
    "where's my refund?",
    "what's the gold for?",
    "just quit.\nhit esc and quit.\n",
    "are they trying to\nbe artsy? what a ****",
    "not a game",
    "get your refund\nwhile you can",
    "lazy devs",
    "you don't have the\nright, o you don't\nhave the right",
    "graphics: 1/10\ngameplay: 1/10\nsound: 1/10"
}
current_line = 1
function _init()
    --seed = 401 -- flr(rnd(1000))
    --add(debug, seed)
    --srand(seed)
    palt(0, false)
    palt(14, true)
    mapgen()
    room_stamp(1, 1)
end
function _draw()
    cls()
    camera(cx, cy)
    map(0, 0, 0, 0, 48, 48)
    for key,good in pairs(goodies) do
        spr(good["spr"], good["x"], good["y"], 1, 1, good["hf"], good["vf"])
    end
    spr(psprt, px, py, 1, 1, phf)
    if anim_clock > 0 then anim_clock -= 1 else anim_clock = anim_time psprt += 1 end
    if psprt > 17 then psprt = 16 end
    ui()
    if show_text then
        rectfill(cx + 16, cy + 32, cx + 112, cy + 64, 0)
        print(text, cx + 18, cy + 34, 7)
    end
    i = 0
    --for key,val in pairs(visited) do add(debug, key) end
    for s in all(debug) do print(s, cx, cy + i + 8, 7) i += 8 end
    --debug = {}
end
function _update60()
    if show_text then
        if btnp(5) then show_text = false end
        return
    end
    if camlock then
        if cx < ncx then cx += 2
        elseif cx > ncx then cx -= 2
        elseif cy < ncy then cy += 2
        elseif cy > ncy then cy -= 2
        else camlock = false px = npx py = npy end
        return
    else trans() end
    -- gold stuff
    if gpbuff > 0 then
        if gpclock > 0 then
            gpclock -= 1 
        else
            gpbuff -= 1
            gp += 1
            gpclock = gptime
            --add(debug, gpclock)
            sfx(randrange(0,4))
        end
    end
    -- collision detection
    vx = -(btn(0) and 1 or 0) + (btn(1) and 1 or 0)
    vy = -(btn(2) and 1 or 0) + (btn(3) and 1 or 0)
    opx = px
    px += vx
    py += vy
    gx = flr((px + 4) / 8)
    gy = flr((py +4) / 8)
    if mget(gx, gy - 1) == 3 and py < gy * 8 then py = gy * 8 end
    if mget(gx, gy + 1) == 3 and py > gy * 8 then py = gy * 8 end
    if mget(gx - 1, gy) == 3 and px < gx * 8 then px = gx * 8 end
    if mget(gx + 1, gy) == 3 and px > gx * 8 then px = gx * 8 end
    anim_time = 6
    if px < opx then phf = false elseif px > opx then phf = true else anim_time = 12 end
    message = ""
    for key, good in pairs(goodies) do
        dis = abs(px - good["x"]) + abs(py - good["y"])
        if dis < 6 then
            if good["type"] == "message" then
                message = good["text"]
                if btnp(5) then
                    text = good["mess"] 
                    show_text = true sfx(5) 
                    if good["play"] then music(0)
                    elseif good["stop"] then music(-1) end
                end
            elseif good["type"] == "enemy" then
                if not good["looted"] then
                    message = good["text"]
                    if btnp(5) then 
                        good["looted"] = true
                        good["vf"] = true
                        gpbuff += randrange(1, 16)
                    end
                else message = "empty" if btnp(5) then sfx(4) end end
            end
        end
    end
end
function ui()
    rectfill(cx, cy, cx+128, cy+8, 0)
    print("gold: " .. gp, cx, cy, 10)
    rectfill(cx, cy+120, cx+128, cy+128, 0)
    print(message, cx, cy+120, 7)
end
function gen_key(x, y)
    return x .. "_" .. y
end
function randrange(min, max)
    return flr(rnd(max - min)) + min
end
function free_place(tab)
    while true do
        x = randrange(1, 15) * 8
        y = randrange(1, 13) * 8
        local key = gen_key(x, y)
        if tab[key] == nil then return {x,y} end
    end
end
function get_goodies(x, y)
    --add(debug, x)
    --add(debug, y)
    key = gen_key(x, y)
    --add(debug, key)
    eranges = {{0,0}, {1, 3},{1,6},{2, 8}}
    if visited[key] == nil then
        tab = {}
        num_messages = randrange(2, 6)
        erange = eranges[randrange(1,5)]
        num_enemies =  randrange(erange[1], erange[2])
        ents = {}
        for i = 1,num_messages,1 do
            add(ents, "message")
        end
        for i = 1,num_enemies,1 do
            add(ents, "enemy")
            add(ents, "proj")
        end
        --for i = 1,num_messages,1 do
        for ent in all(ents) do
            coords = free_place(tab)
            mkey = gen_key(coords[1], coords[2])
            obj = {type = ent, x = coords[1] + 128, y = coords[2] + 120, hf = false, vf = false}
            if ent == "message" then
                line = lines[randrange(1, count(lines) + 1)]
                r = rnd(100)
                if r < 3 then line = "how about some music?" obj["play"] = true
                elseif r < 6 then line = "oh god stop the music!" obj["stop"] = true end
                obj["text"] = "X read message"
                obj["spr"] = 41
                obj["mess"] = line
            elseif ent == "proj" then
                sprs = {33,34,35}
                obj["spr"] = sprs[randrange(1,count(sprs)+1)]
                obj["vf"] = rnd(1) < 0.5
                obj["hf"] = rnd(1) < 0.5
            elseif ent == "enemy" then
                looted = rnd(1) < 0.25
                obj["text"] = "X loot"
                obj["looted"] = looted
                obj["vf"] = looted
                obj["spr"] = rnd(1) < 0.5 and 40 or 42
            else
            end
            tab[mkey] = obj
            --add(debug, coords[1])
            --add(debug, coords[2])
            --add(tab, {text = "X read", mess = current_line})
            --current_line += 1
        end
        visited[key] = tab
        -- for key, value in pairs(visited) do add(debug, key) end
    end
    --add(debug, key)
    -- place goodies
    goodies = visited[key]
end
function mapgen()
    -- place nodes in wheel shape
    ns = {} -- nodes
    -- radius 8, spacing from center 6, wobble 2
    add(ns, {8,8})
    ang = 0
    function calc(n) return flr(n * 4) + 6 + flr(rnd(4)) end
    --function calc(n) return flr(n * 6) + 8 end
    while ang < 1 do
        x = calc(cos(ang))
        y = calc(sin(ang))
        add(ns, {x,y})
        ang+=1/5
    end
    pcx = ns[1][1] pcy = ns[1][2] -- start player at center
    get_goodies(pcx, pcy)
    for coord in all(ns) do mset(coord[1],coord[2],2)end
    -- connect outer nodes
    for i = 2,7,1 do
        n = ns[i] -- node
        mset(n[1],n[2],i)
        nx = ns[i+1] -- next node
        if i == 7 then nx = ns[2] end
        make_path(n[1],n[2],nx[1],nx[2])
        --make_path(ns[1][1],ns[1][2],n[1],n[2])
    end
    make_path(ns[1][1],ns[1][2],ns[2][1],ns[2][2])
end
function make_path(tx, ty, dx, dy)
    while true do
        lx = 0 ly = 0
        dis = 10000 x = 0 y = 0
        for adj in all(cards) do
            xa = adj[1] ya = adj[2]
            x = dx - tx + xa
            y = dy - ty + ya
            d = x * x + y * y
            if d < dis then dis = d lx = tx - xa ly = ty - ya end
        end
        tx = lx
        ty = ly
        if dis == 0 then break end
        mset(tx, ty,1)
    end
end
function room_stamp(x, y)
    -- clear room
    rx = x * 16 ry = y * 14
    for i = 0,15,1 do
        for f = 1,14,1 do
            mset(rx + i, ry + f, 2)
            if i == 0 or i == 15 or f == 1 or f == 14 then mset(rx + i, ry + f, 3) end
        end
    end
    -- check and stamp doors
    holes = {{15, 7, 15, 8}, {7,1,8,1},{0, 7, 0, 8},{7,14,8,14}}
    for i = 1,4,1 do
        dx = cards[i][1] dy = cards[i][2]
        --add(debug, mget(x, y))
        if(mget(pcx + dx, pcy + dy) != 0) then
            hole = holes[i]
            --add(debug, hole)
            mset(rx + hole[1], ry + hole[2], 2)
            mset(rx + hole[3], ry + hole[4], 2)
        end
    end
    -- place objects
end
function trans()
    -- detect what direction the player is moving in
    ncx = cx ncy = cy
    npx = px npy = py
    if px > 252 then
        room_stamp(0, 1)
        cx -= 128
        px -= 128
        pcx += 1
        npx = 132
        room_stamp(1,1)
    elseif px < 125 then
        room_stamp(2, 1)
        cx += 128
        px += 128
        pcx -= 1
        npx = 248
        room_stamp(1,1)
    elseif py > 220 then
        room_stamp(1, 0)
        cy -= 112
        py -= 112
        pcy += 1
        npy = 122
        room_stamp(1, 1)
    elseif py < 108 then
        room_stamp(1, 2)
        cy += 112
        py += 112
        pcy -= 1
        npy = 218
        room_stamp(1, 1)
    else
        -- no transition needed
        return
    end
    camlock = true
    get_goodies(pcx, pcy)
    room_stamp(1, 1)
    -- stamp the current room in the opposite direction
    -- move camera in opposite direction
    -- stamp the next room where the first one was
    --slide the player and camera back to central position
end
__gfx__
00000000666666666666666655555555cccccccc555aa5555868a55558666855866666686666666666666666666666666666666600000000ccaccacccccccacc
00000000665555666666666655555555cccccccc55a00a5558668a5586666855866666686454454664868546686668466866668600000000ccaacacccccccaca
00700700655555566666666655555555cccccccc5a0000a55a8680a586666685866666686454454664868546686668466866668600000000cccaaaccccaaaaaa
00077000655555566666666655555555cccccccc5a0000a55a8668a586666685866666686454454664866846686666866866668600000000cccaacccaacaacac
00077000655555566666666655555555cccccccc55a00a5555a8685586666685866666686454454664586846648666866866668600000000cccaaacccccacccc
00700700655555566666666655555555cccccccc55a00a5555a8685586666685866666686454454664586846648666866866668600000000ccaacacccccacccc
00000000665555666666666655555555cccccccc55aaaa5555868a5558866685866666686454454664548686645866666866668600000000ccaccaaaccaacccc
00000000666666666666666655555555cccccccc555555555586855555866855866666686666666666666666666666666666666600000000caacccacccaccccc
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee66666666666666666666666600000000
ee8888eeee8888eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeecccceeeecccceeeeeeeeeeeeeeeeee66444466668844666666846600000000
ee8008eeee8008eeeeeeeeeeeee88eeee222eeeee222eeeee222eeeee222eeeeeec00ceeeec00ceeeeee4eeeeeeeeeee64444446686684466666684600000000
e880088ee880088eeeeaaaaeee8aa8eee2882eeee2002eeee2002eeee2aa2eeeecc00cceecc00cceeeeee4eeeeeeeeee64444446648668466866668600000000
e8a00a88e8a00a88eaaaaeeeee8aa8eee28822eee20822eee20022eee2aa22eeeca00acceca00acceeeee4eeee4ee4ee64444446644868466486668600000000
ee800008ee800088eeeeeeeeeee88eeee22882eee22882eee22002eee22aa2eeeec0000ceec000cceeee4eeeeee44eee64444446644486866448666600000000
ee80008eee800008eeeeeeeeeeeeeeeeee2222eeee2222eeee2222eeee2222eeeec000ceeec0000ceeeeeeeeeeeeeeee66444466664486666648666600000000
eee888eeeee8888eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeccceeeeecccceeeeeeeeeeeeeeeee66666666666666666666666600000000
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee0000000000000000000000000000000000000000
e555555eeeeeeeeeeeee5eeeeeee5eeeeeeeeeeebeeeeeebe5eeee5eeeeeeeeee555885eeeeeeeeee5eeee5e0000000000000000000000000000000000000000
e5bbbb5eeeeee5eeeeee4eeeeee555eeeeeeeeeebbeeeebbe555555eeeaeeeeee5b88b5eeee0eeeee558855e0000000000000000000000000000000000000000
ebb5b5beeeeeee5eeeee4eeeee55e55ebbeeeebbebeeeebee505505eeaeaaaaeeb88b5be00eeee00e505805e0000000000000000000000000000000000000000
eeb8b8bee5444555eeee4eeeeee555eeebbeebbeebeeeebee580085eeeaeaeaeee88b0bee00e000ee580885e0000000000000000000000000000000000000000
eeb5b5beeeeeee5eee5e5e5eeeee5eeeeb8bb8beebbeebbee550055eeeeeeeeeee85b5beeee00ee0e550058e0000000000000000000000000000000000000000
eeebbbeeeeeee5eeeee555eeeeeeeeeeebeeeebeeb8bb8bee550055eeeeeeeeeeeebbbeeeeeeeeeee550058e0000000000000000000000000000000000000000
eeeeeeeeeeeeeeeeeeee5eeeeeeeeeeeeebeebeebeeeeeebeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee0000000000000000000000000000000000000000
__gff__
0000000102010000000100000000020200000404000000000000000000000000000808000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
0001000000000000000000000000000000000000000000000a3500b350000000c350000000f350123500000015350193501c3501e350203502735028350000000000000000000000000000000000000000000000
0001000000000000000000000000000000000000000000000635006350053500c350053500535007350083500a3500a350103500f3500f3501d3501f3501f3500000000000000000000000000000000000000000
0001000000000000000000000000000000000000000000001b3501d3501f35020350233502535027350293502a3502c3502e3502f3503135032350343501f3500000000000000000000000000000000000000000
00010000000000000000000000000000000000000000000007350073500735008350093500a3500b350000000c3500b3500d3500f35012350183501b350000000000000000000000000000000000000000000000
00010000000500005000050000500000000000000000000000000330502f0502a05025050210501f0501d0501a0501705015050100500d0500505001050000000000000000000000000000000000000000000000
00010000000000000000000000000000000000000000000000000000000000005050080500a0500c050000000e0501005012050170501e0502105028050320503405000000000000000000000000000000000000
010e00001305013050120501205013050130500f0500f050180501805013050120500f050000001205012050120500f0500c05012050140500000013050130501205012050130501305010050100500c0500c050
010e00000e0500000000000000000e0500000000000000000c0500000000000000000c0500000000000000000f050000000f0500000000000000000c050000000f050000000f050000000c050000000000000000
__music__
02 07474344

