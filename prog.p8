pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
--init

function _init()
 -- game variables --
 prev_t = time()
 pot_kills = 0 --total potential kills
 level = 0
 
 -- player dynamic variables --
 player = {}
 player.s = 1 --sprite
 player.s_w = 1 --sprite size
 player.s_h = 2
 player.w = 8 --size by pixels
 player.h = 16
 player.x = 0 --position
 player.y = 0
 player.flipped = false
 player.speed = 32
 player.is_crouching = false
 player.hp = 10
 player.tot_kills = 0 --total kills
 player.is_stunned = false
 player.is_evil = false
 
 -- player jumping --
 player.is_jumping = false
 player.jump_tstart = 0
 player.jump_tprev = 0
 player.jump_h = 0 --height
  --[[
  which jump are you on?
  0 = not jumping
  1 = first jump
  2 = double jump
  3 = triple jump (can no longer jump)
  ]]
 player.njump = 0
 player.jump1 = 16 --height of first jump
 player.jumpxtra = 8 --height of extra jumps

 -- player knockback and stun --
 player.stun_start = 0
  
 -- player static variables --
 player.stand_s = 1 --sprite
 player.stand_w = 1 --sprite size
 player.stand_h = 2
 player.standw = 8 --size by pixels
 player.standh = 16
 player.stand_speed = 32
 player.crouch_s = 18 --sprite
 player.crouch_w = 1 --sprite size
 player.crouch_h = 1
 player.crouchw = 8 --size by pixels
 player.crouchh = 8
 player.crouch_speed = 16
 player.evil_stand_s = 32 --sprite
 player.evil_stand_w = 1 --sprite size
 player.evil_stand_h = 2
 player.evil_standw = 8
 player.evil_standh = 16
 player.evil_stand_speed = 32
 player.evil_crouch_s = 49 --sprite
 player.evil_crouch_w = 1 --sprite size
 player.evil_crouch_h = 1
 player.evil_crouchw = 8
 player.evil_crouchh = 8
 player.evil_crouch_speed = 16
 player.can_triplej = false
 player.stun_dur = 1
 player.knock = 10 --knockback when touch enemy
 player.kill_limit = 3 --per level
 
 -- player blasts --
 blast = {}
 blast.s = 5
 blast.s_w = 1
 blast.s_h = 1
 blast.w = 8 --size by pixels
 blast.h = 6 --size by pixels
 blast.speed = 2 --speed of blasts
 blast.limit = 5 --max onscreen
 blast.wait = 0 --time between blasts
 blast.last = 0

 new_level(0,0,1,3)
end

--[[
sets up next level.
new player position (x,y),
lvl: level id for map.
potk: potential kills for this map.
reboots enemies as well.
]]
function new_level(x,y,lvl,potk)
 player.x = x
 player.y = y
 player.s = player.stand_s
 player.lvl_killc = 0
 pot_kills += potk
 -- enemies --
 enemy = {} --kind 1 ez, 2 med, 3 hard
 enemy.s = {6,7,8}
 enemy.s_w = {1,1,2} --sprite size
 enemy.s_h = {2,2,2}
 enemy.w = {7,7,12} --size by pixels
 enemy.h = {16,16,16}
 spawn(lvl)
end

function spawn(lvl)
 if lvl==1 then
  --spawn enemies
  make_enemy(1,96,72,false)
  make_enemy(2,5,88,true)
  make_enemy(3,72,104,false)
  make_enemy(1,100,104,true)
 end
end
-->8
--player

--can the player jump?
function can_jump()
 if player.is_crouching then
  return false
 end
 if player.njump == 3 then
  return false
 end
 if player.njump == 2 and 
    not player.can_triplej then
  return false
 end
 return true 
end

--[[
start the jump.
is this a normal jump, or
a double/triple?
]]
function start_jump()
 player.jump_tstart = time()
 player.jump_tprev = time()
 player.is_jumping = true
 if player.njump==0 then
  player.jump_h = player.jump1
 else
  player.jump_h = player.jumpxtra
 end
 player.y -= 1
 player.njump += 1
end

--find new position in jump
function jump()
 local dt = time() - player.jump_tprev
 --check for ceiling
 local x1 = player.x
 local x2 = player.x+player.s_w*8-1
 if v_collide(x1,x2,player.y-1,0)
 then
  player.jump_h = 0 --end jump
 end
 if dt > 0.005 and
    player.jump_h > 0
 then --do some jumping
  player.y -= 2
  player.jump_h -= 1
  player.jump_tprev = time()
 end
 if(player.jump_h==0) player.is_jumping = false
end

--[[
what to do when player
kills someone
]]
function kill(b,e)
 kill_blast(b)
 kill_enemy(e)
 player.tot_kills += 1
 player.lvl_killc += 1
 local ratio = player.tot_kills/pot_kills
 if not player.is_evil and
    ratio > 0.5 then
  player.is_evil = true
--  player.s = player.evil_stand_s
  player.stand_s = player.evil_stand_s
  player.stand_h = player.evil_stand_h
  player.stand_w = player.evil_stand_w
  player.stand_speed = player.evil_stand_speed
  player.crouch_s = player.evil_crouch_s
  player.crouch_h = player.evil_crouch_h
  player.crouch_w = player.evil_crouch_w
  player.crouch_speed = player.evil_crouch_speed
 end
end

--[[
player touched enemy!
knockback and stun.
]]
function player_hit(kb)
player.x += kb
player.hp -= 1
player.is_stunned = true
player.stun_start = time()
end

--[[
check to see if stun is
finished
]]
function stop_stun()
 local dt = time() - player.stun_start
 if dt >= player.stun_dur then
  player.is_stunned = false
 end
end

--[[
checks if shooting is possible.
returns valid index for new
blast.
criteria:
   -number of blasts
   -time between blasts
]]
function get_valid_blast()
 local dt = time() - blast.last
 if dt < blast.wait then
  return 0
 end
 for i=1,#blast do
  if blast[i].y < 0 then
   return i
  end
 end
 if #blast < blast.limit then
  return #blast+1
 end
 return 0
end

--[[
shoot an energy blast in the
direction the player is facing
]]
function shoot()
 local k = get_valid_blast()
 if k != 0 then
  blast.last = time() --time at latest shot
  blast[k] = {}
  --find y of blast
  if player.is_crouching then
   blast[k].y = player.y
  else
   blast[k].y = player.y+4
  end
  if player.flipped then --left
   blast[k].x = player.x-blast.w
   blast[k].mx = -blast.speed
   blast[k].flipped = true
  else --right
   blast[k].x = player.x+player.s_w*8
   blast[k].mx = blast.speed
   blast[k].flipped = false
  end
 end
end

--[[
after shooting, where are
the blasts?
]]
function move_blasts()
 for i=1,#blast do
  --move only valid blasts
  if blast[i].y>0 then
   blast[i].x += blast[i].mx
   --is blast still valid?
   if blast[i].flipped and
      blast[i].x<-4 then
    kill_blast(i) --not valid
   elseif not blast[i].flipped and
      blast[i].x > 130 then
    kill_blast(i)
   end
   --check wall collision
   blast_hit_wall(i)
   --check enemy collision
   blast_hit(i)
  end--end if
 end--end for
end

--[[
make blasts invalid by
moving to y=-100
]]
function kill_blast(i)
 blast[i].y = -100
end

function display_blasts()
 for i=1,#blast do
  spr(blast.s,blast[i].x,blast[i].y,blast.s_w,blast.s_h,blast[i].flipped)
 end
end
-->8
--enemies

--[[
spawn enemies
kind: enemy type
x and y: position
]]
function make_enemy(kind,x,y,flipped)
 local k = #enemy+1
 enemy[k] = {}
 enemy[k].x = x
 enemy[k].y = y
 enemy[k].kind = kind --1 ez, 2 med, 3 hard
 enemy[k].s = enemy.s[kind] --sprite
 enemy[k].s_w = enemy.s_w[kind] --size
 enemy[k].s_h = enemy.s_h[kind]
 enemy[k].w = enemy.w[kind]
 enemy[k].h = enemy.h[kind]
 enemy[k].flipped = flipped
 enemy[k].is_dead = false
end

--[[
enemy has been killed,
delete them
]]
function kill_enemy(k)
 enemy[k].is_dead = true
end

function display_enemies()
 for i=1,#enemy do
  if not enemy[i].is_dead then
   spr(enemy[i].s,enemy[i].x,enemy[i].y,enemy[i].s_w,enemy[i].s_h,enemy[i].flipped)
  end
 end
end

-->8
--collision and physics

--[[
make player fall
simulates gravity
]]
function fall()
 local y = player.y+player.h
 local x1 = player.x
 local x2 = player.x+player.w-1
 if v_collide(x1,x2,y,0) then
  player.njump = 0
  if v_collide(x1,x2,y-1,0) then
   player.y -= 1
  end
 else
  if(not player.is_jumping) player.y += 1.5
 end
end

--[[
detect horizontal map collision
x: left or right side of player
y1: top side of player
y2: bottom side of player
flag: flag of relevant map tile
]]
function h_collide(x,y1,y2,flag)
 -- screen boundary
 if(x>127 or x<0) return true
 --wall collision
 x = x/8
 y1 = y1
 y2 = y2
 for i=y1,y2 do
  if fget(mget(x,i/8),flag) then
   return true
  end
 end
 return false
end

--[[
detect vertical map collision
ex. ceiling, floor
x1: left side of player
x2: right side
y: top or bottom of player
flag: flag of relevant map tile
]]
function v_collide(x1,x2,y,flag)
 x1 = x1
 x2 = x2
 y = y/8
 --screen boundary
 if(y<0) return true
 --wall collision
 for i=x1,x2 do
  if fget(mget(i/8,y),flag) then
   return true
  end  
 end
 return false
end

--blast map collision
function blast_hit_wall(i)
 local y1 = blast[i].y
 local y2 = blast[i].y+blast.h-1
 local x = 0
 if blast[i].flipped then
  x = blast[i].x+8-blast.w
 else
  x = blast[i].x+blast.w-1
 end
 --collision
 if h_collide(x,y1,y2,0) then
  kill_blast(i)
 end
end

--blast enemy collision
function blast_hit(i)
 local y1 = blast[i].y
 local y2 = blast[i].y+blast.h-1
 --find blast x
 local x = blast[i].x
 if not blast[i].flipped then
  x = x+blast.w-1
 end
 --detect collision
 for j=1,#enemy do
  if not enemy[j].is_dead and
     x>=enemy[j].x and
     x<=enemy[j].x+enemy[j].w-1 and
     (y1>=enemy[j].y and
      y1<=enemy[j].y+enemy[j].h-1 or
      y2>=enemy[j].y and
      y2<=enemy[j].y+enemy[j].h-1
     ) then
   kill(i,j)
  end
 end
end

--[[
does the player touch
an enemy?
]]
function touch_enemy(kb)
  local y1 = player.y
  local y2 = player.y+player.s_h*8-1
 --find player x
  local x = player.x
 if not player.flipped then
  x = x+player.w-1
 end
 --detect collision
 for j=1,#enemy do
  if not enemy[j].is_dead and
     x>=enemy[j].x and
     x<=enemy[j].x+enemy[j].w-1 and
     (y1>=enemy[j].y and
      y1<=enemy[j].y+enemy[j].h-1 or
      y2>=enemy[j].y and
      y2<=enemy[j].y+enemy[j].h-1
     ) then
   player_hit(kb)
  end
 end
end
-->8
--update and draw

function _update60()
 dt = time() - prev_t
 prev_t = time()
 local x1 = player.x
 local x2 = player.x+player.w
 local y1 = player.y
 local y2 = player.y+player.h
 -- walk
 if btn(0) and not 
    h_collide(x1-1,y1,y2-1,0) and
    not player.is_stunned then
  player.x -= player.speed*dt
  player.flipped = true
  touch_enemy(player.knock)
 end
 if btn(1) and not
    h_collide(x2,y1,y2-1,0) and
    not player.is_stunned then
  player.x += player.speed*dt
  player.flipped = false
  touch_enemy(-player.knock)
 end 
 --walk into wall correction
 if btn(0) or btn(1) then
  if h_collide(x1,y1,y2-1,0) then
   player.x += 1
  elseif h_collide(x2-1,y1,y2-1,0) then
   player.x -= 1
  end
 end
 -- jump
 if btnp(2) and 
    can_jump() and
    not player.is_stunned then
  start_jump()
 end
 -- crouch
 if btn(3) and
    not player.is_stunned then
  player.is_crouching = true
  player.y += player.h-player.crouchh
  player.x += player.w-player.crouchw
  player.s = player.crouch_s
  player.s_h = player.crouch_h
  player.s_w = player.crouch_w
  player.w = player.crouchw
  player.h = player.crouchh
  player.speed = player.crouch_speed
 elseif not v_collide(x1,x2,y1-1,0) then
  player.is_crouching = false
  player.y += player.h-player.standh
  player.x += player.w-player.standw
  player.s = player.stand_s
  player.s_h = player.stand_h
  player.s_w = player.stand_w
  player.w = player.standw
  player.h = player.standh
  player.speed = player.stand_speed
 end
 if btnp(4) and
    player.lvl_killc<player.kill_limit
    then
  shoot()
 end
 if(player.is_jumping) jump()
 if(player.is_stunned) stop_stun()
 fall()
 move_blasts()
end

function _draw()
 cls()
 map(0,0,0,0)
 display_enemies()
 display_blasts()
 spr(player.s,player.x,player.y,player.s_w,player.s_h,player.flipped)
 print("hp: "..player.hp,5,5,8)
 print("kills: "..player.tot_kills,5,15,8)
end
__gfx__
00000000010000000000000051115151010000000009800005555000044444000000444440000000000000000000000000000000000000000000000000000000
0000000010111100000000001515111510111100009a98800ffff500044444000000a44a40000000000000000000000000000000000000000000000000000000
00700700014444100000000055555515014444100a90a09805f5f000054454000000444440000000000000000000000000000000000000000000000000000000
0007700010474701000000005515555510474701a0a909080ffff000044444000000000400000000000000000000000000000000000000000000000000000000
00077000004444000000000055551555004444000a998080000f0000005445500000004440000000000000000000000000000000000000000000000000000000
0070070000040000000000005555555500040000000a980004444400055555500000044444400000000000000000000000000000000000000000000000000000
00000000003330000000000055555555003330000000000040444040550555500000444444040000000000000000000000000000000000000000000000000000
00000000033333000000000055555555033333000000000040444040550555608888444440080000000000000000000000000000000000000000000000000000
000000003033303001011110000000003033303000000000555555f5666666668880444448880000000000000000000000000000000000000000000000000000
0000000030333030101444410000000030333030000000000f655f00446664468880555558880000000000000000000000000000000000000000000000000000
00000000604440600104747000000000604440600000000000115000011144100000555558800000000000000000000000000000000000000000000000000000
00000000005550000004444000000000005550000000000001111100011116100000550055000000000000000000000000000000000000000000000000000000
00000000005050000003333300000000005050000000000001000100011011100005500005500000000000000000000000000000000000000000000000000000
00000000005050000060330600000000655050000000000010000010011011100005000000550000000000000000000000000000000000000000000000000000
00000000005050000005555000000000600050000000000010000010011011100555000005500000000000000000000000000000000000000000000000000000
00000000006066000065006000000000000066000000000050000555555055500555000055000000000000000000000000000000000000000000000000000000
09000000000000000900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
a0a9a90000000000a099aa0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0a5555a0000000000955559000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
9058580900000000a058580a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00555500000000000055550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00040000000000000005000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00494000000000000049400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
04aaa4000000000004aaa40000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
409a90400a09a9a0409a904000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
90494090909555599049409000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
a04440a00a058580a04440a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00555000000555500055500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00505000000944990050500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0090900000a0aa0aaa90900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00a0a00000055590a000a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00a0aa0000a900a00000aa0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__gff__
0000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0303030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000303030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0303030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0303030303030303030303030303030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
