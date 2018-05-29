pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
--init

function _init()
 -- game variables --
 prev_t = time()
 
 -- player dynamic variables --
 player = {}
 player.s = 1 --sprite
 player.s_w = 1 --sprite size
 player.s_h = 2
 player.x = 0 --position
 player.y = 0
 player.flipped = false
 player.speed = 32
 player.is_crouching = false
 
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

  
 -- player static variables --
 player.stand_s = 1 --sprite
 player.stand_w = 1 --sprite size
 player.stand_h = 2
 player.stand_speed = 32
 player.crouch_s = 18 --sprite
 player.crouch_w = 1 --sprite size
 player.crouch_h = 1
 player.crouch_speed = 16
 player.can_triplej = false

 -- enemies --
 enemy = {} --kind 1 ez, 2 med, 3 hard
 enemy.s = {6,7,8}
 enemy.s_w = 1 --sprite size
 enemy.s_h = 2
 
 -- player blasts --
 blast = {}
 blast.s = 5
 blast.s_w = 1
 blast.s_h = 1
 blast.w = 3 --size by pixels
 blast.h = 3 --size by pixels
 blast.speed = 2 --speed of blasts
 blast.limit = 2 --max onscreen
 blast.wait = 1 --time between blasts
 blast.last = 0
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
checks if shooting is possible.
returns valid index for new
blast.
criteria:
   -number of blasts
   -time between blasts
]]
function get_valid_blast()
 local dt = time() - blast.last
 if dt < 1 then
  return 0
 end
 for i=1,#blast do
  if blast[i].mx>0 and
     blast[i].x>128 then
   return i
  elseif blast[i].mx<0 and
         blast[i].x<-4 then
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
  blast[k].y = player.y+player.s_h/2*8
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
  blast[i].x += blast[i].mx
 end
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
 enemy[k].s_w = enemy.s_w --size
 enemy[k].s_h = enemy.s_h
 enemy[k].flipped = flipped
end

function display_enemies()
 for i=1,#enemy do
  spr(enemy[i].s,enemy[i].x,enemy[i].y,enemy[i].s_w,enemy[i].s_h,enemy.flipped)
 end
end
-->8
--collision and physics

--[[
make player fall
simulates gravity
]]
function fall()
 local y = player.y+player.s_h*8
 local x1 = player.x
 local x2 = player.x+player.s_w*8-1
 if v_collide(x1,x2,y,0)
 then
  player.njump = 0
 else
  if(not player.is_jumping) player.y += 1
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

-->8
--update and draw

function _update60()
--spawn one enemy
 if #enemy == 0 then
  make_enemy(1,64,104,true)
 end
 dt = time() - prev_t
 prev_t = time()
 local x1 = player.x
 local x2 = player.x+player.s_w*8
 local y1 = player.y
 local y2 = player.y+player.s_h*8
 -- walk
 if btn(0) and not 
    h_collide(x1-1,y1,y2-1,0)
    then
  player.x -= player.speed*dt
  player.flipped = true
 end
 if btn(1) and not
    h_collide(x2,y1,y2-1,0)
    then
  player.x += player.speed*dt
  player.flipped = false
 end
 -- jump
 if btnp(2) and can_jump() then
  start_jump()
 end
 -- crouch
 if btn(3) then
  player.is_crouching = true
  player.y += (player.s_h-player.crouch_h)*8
  player.x += (player.s_w-player.crouch_w)*8
  player.s = player.crouch_s
  player.s_h = player.crouch_h
  player.s_w = player.crouch_w
  player.speed = player.crouch_speed
 elseif not v_collide(x1,x2,y1-1,0) then
  player.is_crouching = false
  player.y += (player.s_h-player.stand_h)*8
  player.x += (player.s_w-player.stand_w)*8
  player.s = player.stand_s
  player.s_h = player.stand_h
  player.s_w = player.stand_w
  player.speed = player.stand_speed
 end
 if btnp(4) then
  shoot()
 end
 if(player.is_jumping) jump()
 fall()
 move_blasts()
end

function _draw()
 cls()
 map(0,0,0,0)
 display_enemies()
 display_blasts()
 spr(player.s,player.x,player.y,player.s_w,player.s_h,player.flipped)
end
__gfx__
00000000010000000101111001000000010000000110001001000000005555000044444000000444440000000055550000444440000000444440000000000000
0000000010111100101444411011110010111110101111011011111000ffff500044444000000a44a400000000ffff5000444440000000484440000000000000
00700700014444100104747001444410014444010144440001444401005f5f00006446400000044444000000008f8f0000844840000000444440000000000000
0007700010474701000444401047470110474700014747001047470000ffff0000444440000000044000000000ffff0000444440000000004400000000000000
000770000044440000033330004444000044440010444400004444000000f0000000445000000044440000000000f00000004455000000004444400000000000
00700700000400000003630000040000000400000334330000040000004444400055555500000444444440000044444000555556000000044440040000000000
00000000003330000000555000333300033330003333303003333337040444040555555500004444440040000404440466666666888884444440400000056000
000000000333330000650060033330303033330030333006303330005555555f0550556688884444400080005555555f64466644888880844444000000055000
0705500030333030010111103033300303633060603330000336300000f655f066666666888044444888800000f655f000555446888800844444000000000000
00057050303330301014444103633006003330000044400000333000000445006446644588805555588880000004450000555565888800855555000000000000
0560507560444060010474700044400000444000005555000044400000011100001144110000555558880000000111000011111100000005555500000ddd0000
605000060055500000044440005550000055500000500500005550000001111000111611000055000550000000111110001111110000000550055000dccccddd
0607606000505000003333360050500000500500655005000050500000110010001101110005500000550000001000100011011100000055000555000d77dd00
000507000050500000603300655050000050600060000660005005000010000100110111000800000080000001000001001101110000008000000800007d0000
00000000005050000000555060005000050060000000000065000500001000010011011100550000055000000100000100110111000055000000055000700000
00000000066066000006506000006600066000000000000060000660055000550555055505550000550000005500005505550555000555000000555000000000
090000000a0999a00a000000090000000a9000a00a0000000c0000000c0cccc00c0000000c0000000cc000c00c00000000000000000000000000000000555500
a0a9a9009095555a9099aa00909a99a090999a0aa099aa70c0cccc00c0c4444cc0cccc00c0cccc00c0cccc0cc0ccccc000000000000666600000000000ffff50
0a5555a00a0585800a5555a00a55550a0a555500095555070c4444c00c0474700c4444c00c4444c00c4444000c44440c088088000050070600000000008f8f00
90585809000555509058580a905858000958580090585800c047470c00044440c047470cc047470c0c474700c047470028887800005000760000000000ffff00
00555500000499400055550000555500a05555000055550000444400000777700044440000444400c0444400004444002888880000560006000000000000f000
000400000009a400000400000005000004a5a4000005000000040000000757000004000000040000077477000004000002888000005666060000000000444440
0049400000005590044a4000044a400044aaa09004499aa70074700000005550007770000777700077777060077777670028000000055550000000005f555554
04aaa40000a900a090a9a90040999400909a900a90aaa00007777700007500700777770070777700607770057077700000000000000000000000000004445f40
409a90400a09a9a009aa90aa09a990a0a04940000a9aa000707770700c0cccc00677706007577060507770000765700000000000000000000000000004044500
90494090909555590099900000494000004440000049900060777060c0c4444c6077705000777005007770000077700000000000000000000000000000044400
a04440a00a05858000444000004440000055550000449000507770500c0474705077700000777000005555000077700005505500000550000000000000011100
00555000000555500055500000555000005009000055500000555000000444400055500000555000005005000055500005050500005005000000000000111110
005050000099449a0050500000500900aa900a000050500000505000007777750050500000500600765006000050500005000500005005000000000000100010
0090900000a0aa00aa9090000090a000a0000aa00090090000505000005077007650500000507000700007700050050000505000000550000000000001000001
00a0a00000005590a000a0000a00a00000000000aa000a0000606000000055607000600006007000000000007600060000050000000000000000000001000001
0aa0aa00000a90a00000aa000aa0000000000000a0000aa007707700000750700000770007700000000000007000077000000000000000000000000055000055
511151515555555533b3333333b33333000400400555055511000001000000000000000000000000000000000021500000000000000000000000055000000000
15151115555555553333333b3333333b000004001555115500101110000000000000000000000000000000000021555555555555555555555555555000000000
55555515555555554334434453355355040400045111151100011000001111111111110011111111111111110021111111151111111111111111100000000000
5515555555a55a5544444444555555550040000051555155011111100015ddddddddd100dddddddddddddddd0022222222251222222222222220110000000000
555515550444444034444444355555554004404015111155111000010015d5555555d1005555d555555555550000000000251000000000000220110000000000
555555550444444044444434555555350044000455555111000100110015d1111115d1001115d111111111110000000000251000000000000000000000000000
555555550040040044454444555355550404044055555555001111100015d1000015d1000015d100000000000000000000251000000000000000000000000000
555555550000000044444444555555550040400055555555011000100015d1000015d1000015d100000000000000000000251000000000000000000000000000
555555555555555544444444000000000005050053000353553553530015d1000015d1000015d1000015d1000000000000251000000000000000000000000000
555555555555555544444444000000000005050013553315353335530015d1000015d1000015d1000015d1000000000000251000000000000000000000000000
555555555555555544444444000000000005050055513515553555530015d1111115d1111115d1001115d1110000000000251000000000000000000000000000
555555555555555544444444000000000005050055155555355353330015ddddddddddddddddd100dddddddd0000000000a51000000000000000000000000000
55555555000000004444444400000000000005005555155533555553001555555555d55555555100555555550000000000050100000000000000000000000000
55555555000000004444444400000000000550005555555553355535001111111115d11111111100111111110000000000050100000000000000000000000000
55555555000000004444444400000000000505005555555553553355000000000015d100000000000000000000000000000a00a0000000000000000000000000
55555555000000004444444400000000000505005555555535535553000000000015d10000000000000000000000000000000000000000000000000000000000
55555555000000000000000000000000000505001551155100000000000000000015d1000015d100000000000000000000000600000000000000000000000000
55555555000000000000000000000000000505001551151100000000000000000015d1000015d100000000000000000000000600000000000000000000000000
55555555000000000000000000000000000505001100111100000000000000000015d1000015d1000000000000000000000006000000dddd0000000000000000
55555505000000000000000000000000000505001115515100000000000000000155d5100155d5100000000000000000000dddddddddd0000000000000000000
55055555000000000000000000000000005005001105055000000000000000000155dd100155dd100000000000000000dddd060d000000000000000000000000
55555555000000000000000000000000055550001500150000000000000000000000000000bbbb0000000000000000000d000600000000000000000000000000
50555505000000000000000000000000550505055015511500000000000000000000000000bbbb0000000000000000000dd00660000000000000000000000000
05050555000000000000000000000000550005050151551500000000000000000000000000b0bb0000000000000000000dd00660000000000000000000000000
53335353000000000000000000000000000000000000000000000000000000000000000000b0b00000000000000000000d000600000000000000000000000000
3535333500000000000000000000000000000000000000000000000000000000000000000000b00000000000000000000d666600000000000000000000000000
5555553500000000000000000000000000000000000000000000000000000000000000000000b00000000000000000000d600000000000000000000000000000
5535555500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d6dddd0000000000000000000000000
555535550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006000d0000000000000000000000000
555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000066000d0000000000000000000000000
555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000066000dd000000000000000000000000
555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000dd000000000000000000000000
00555500004444400000044444000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00ffff500044444000000a44a4000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
005f5f00006446400000044444000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00ffff00004444400000000440000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000f000000044500000004444000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00444440005555550000044444444000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
04044404055555550000444444004000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5555555f055055668888444440008000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00f655f0666666668880444448888000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00044500644664458880555558888000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00011100011144100000555558880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00011100011116100000550005500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00100100011001100005500000550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00100100011001100008000000800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
05500010011001100055000005500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000550555055500555000055000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07770000000760000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00677000007600077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077700077600077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00076770777600000000077000000000000077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00076077707600776007760700000077007760700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00076007007600076000760007700700700760000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00076000007600076000760776070700700760000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00076000007600076000760076000707700760000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000007600777607777076000077007777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00777700077770000000000076000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000777700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000077777777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000777777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000006700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000006700006706700077000770700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000006700077777770700707007007700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000006700006707070077707007070070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000006700006707070700707007077700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000006666777706707077077070777007777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000077777777770000000000000000700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000077070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000700070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000077700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__gff__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001000000000100000000000000000000010000000001010000000000000000000100000000000000000000000000000001010000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
6c475a58495a4958484b4c4d4e6c6d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7c6900685748686857485c006c6c6d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0079000000680000006900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000007900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000c0c1c2c3c4000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000d0d1d2d3d40000000000000000000000000000004400000000000000000b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000e0e1e2e3e40000000000000000000000000000005400000054000000001b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4151410000000000000000000000000000000000000000000000000800540000445400000042420000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000045000000000000000000000000000000000000000000001800640000646400000052520000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000045000000000000000000000000000000000000000040434343434242424242000000000045454500464646460000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000004151410000000000000000004050505050505252525252007171710000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000405050505050505252525252000000005555550056565600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4040400000000000000000000000000000000000000040505050505051515252525252000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000004050505050505000000000000000000000000000656565000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4040404040404040404040404040404040404040406060606060505051515141515141515151515100404040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000464646464646460000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000464646464646460000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
