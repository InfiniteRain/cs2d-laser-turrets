config = {
	countdown = 5, -- shoot to target after X seconds
	laserimage = "gfx/lsr.bmp", -- laser image
	turretimg = "gfx/trtimg.bmp", -- turret image
	turretshooterimg = "gfx/shtrimg.bmp", -- turret shooter image
	r = 0, g = 255, b = 0, -- laser color (RGB)
	damage = 145, -- laser damage
	limit = 3, -- max turret limit per team
	playerlimit = 1, -- max turret limit per player
	turretprice = 16000, -- laser turret price
}

laserturrets = {}
_player = {}

function getpos(x, y, dir, speed)
	return x + math.sin(math.rad(dir)) * speed, y + -math.cos(math.rad(dir)) * speed
end

function freeline(x1, y1, x2, y2)
	local len = math.sqrt((x1 - x2)^2 + (y1 - y2)^2)
	len = math.floor(len)
	for k = 20, len do
		local x, y = getpos(x1, y1, -math.deg(math.atan2(x1 - x2, y1 - y2)), k)
		if tile(math.floor(x / 32), math.floor(y / 32), "wall") then
			return false
		end
	end
	return true
end

addhook('buildattempt', 'buildattempt_hook')
function buildattempt_hook(id, type, x, y, mode)
	if type == 8 then
		menu(id, "Select turret, Normal turret|5000, Laser turret|".. config.turretprice)
		_player[id].lx = x
		_player[id].ly = y
		return 1
	end
end

addhook('menu', 'menu_hook')
function menu_hook(id, title, button)
	if title == "Select turret" then
		if button == 2 then
			if player(id, 'money') >= config.turretprice then
				if #_player[id].turrettable ~= config.playerlimit then
					if #laserturrets ~= config.limit then
						local x, y = _player[id].lx, _player[id].ly
						parse('spawnobject 3 '.. x ..' '.. y ..' 0 0 '.. player(id, 'team') ..' '.. id)
						local obj
						for n, w in pairs(object(0, 'table')) do
							if object(w, 'tilex') == x and object(w, 'tiley') == y and object(w, 'type') == 3 then
								obj = w
							end
						end
						table.insert(laserturrets, {x = x, y = y, turretimg = image(config.turretimg, x * 32 + 16, y * 32 + 16, 1), turretlightingimg = image('gfx/sprites/flare1.bmp', x * 32 + 16, y * 32 + 16, 1), turretshooterimg = image(config.turretshooterimg, x * 32 + 16, y * 32 + 16, 1), object = obj, lasers = 0, cntdwn = 0, team = player(id, 'team'), player = id, rotationvar = 0, rootrotation = player(id, 'rot'), rotationcooldown = 0})
						table.insert(_player[id].turrettable, obj)
						tween_rotateconstantly(laserturrets[#laserturrets].turretlightingimg, 2)
						imageblend(laserturrets[#laserturrets].turretlightingimg, 1)
						local col
						if player(id, 'team') == 1 then col = {255, 0, 0} else col = {0, 0, 255} end
						imagecolor(laserturrets[#laserturrets].turretlightingimg, col[1], col[2], col[3])
						parse('setmoney '.. id ..' '.. player(id, 'money') - config.turretprice)
						return 1
					else
						msg2(id, string.char(169) .."255000000Server limit reached! You can't build anymore laser turrets!@C")
					end
				else
					msg2(id, string.char(169) .."255000000Player limit reached! You can't build anymore laser turrets!@C")
				end
			else
				msg2(id, string.char(169) .."255000000Not enough money!")
			end
		elseif button == 1 then
			if player(id, 'money') >= 5000 then
				parse('spawnobject 8 '.. _player[id].lx ..' '.. _player[id].ly ..' 0 0 '.. player(id, 'team') ..' '.. id)
				parse('setmoney '.. id ..' '.. player(id, 'money') - 5000)
			else
				msg2(id, string.char(169) .."255000000Not enough money!")
			end
		end
	end	
end
	
addhook('join', 'join_hook')
function join_hook(id)
	_player[id] = {turrettable = {}, lx = 0, ly = 0}
end

addhook('ms100', 'ms100_hook')
function ms100_hook()
	for _, tur in pairs(laserturrets) do
		if tur.rotationcooldown > 0 then
			tur.rotationcooldown = tur.rotationcooldown - 1
		end
		local x = tur.x * 32 + 16
		local y = tur.y * 32 + 16
		local cls = 255
		local closest
		local t if tur.team == 1 then t = 2 elseif tur.team == 2 then t = 1 end
		for __, id in pairs(player(0, 'team'.. t)) do
			if math.sqrt((player(id, 'x') - x)^2 + (player(id, 'y') - y)^2) < cls then
				if freeline(x, y, player(id, 'x'), player(id, 'y')) then
					cls = math.sqrt((player(id, 'x') - x)^2 + (player(id, 'y') - y)^2)
					if player(id, 'health') > 0 then
						closest = id
					end
				end
			end
		end
		tur.cntdwn = tur.cntdwn + 0.1
		if tur.cntdwn >= config.countdown then
			if closest then
				tur.lasers = image(config.laserimage, x + 16, y + 16, 1)
				local rot = -math.deg(math.atan2(x - player(closest, 'x'), y - player(closest, 'y'))) 
				tur.rootrotation = rot
				tur.rotationvar = 0
				tur.rotationcooldown = 10
				imagepos(tur.lasers, x + math.sin(math.rad(rot)) * cls/2, y + -math.cos(math.rad(rot)) * cls/2, -math.deg(math.atan2(x - player(closest, 'x'), y - player(closest, 'y'))))
				imagepos(tur.turretshooterimg, x, y, rot)
				imagecolor(tur.lasers, config.r, config.g, config.b)
				imagescale(tur.lasers, 1, cls)
				tween_alpha(tur.lasers, 1000, 0.0)
				timer(1000, "freeimage", tur.lasers)
				if player(closest, 'health') - config.damage <= 0 then
					parse('customkill '.. tur.player ..' "laser turret" '.. closest)
				else
					parse('sethealth '.. closest ..' '.. player(closest, 'health') - config.damage)
				end
				tur.cntdwn = 0
			else
				tur.cntdwn = 0
			end
		end
	end
end

addhook('always', 'always_hook')
function always_hook()
	for n, w in pairs(laserturrets) do
		if w.rotationcooldown == 0 then
			w.rotationvar = w.rotationvar + 1
			imagepos(w.turretshooterimg, w.x * 32 + 16, w.y * 32 + 16, w.rootrotation + math.sin(math.rad(w.rotationvar)) * 60)
		end
	end
end

addhook('objectkill', 'objectkill_hook')
function objectkill_hook(id, player)
	for n, w in pairs(laserturrets) do
		if id == w.object then
			freeimage(w.turretimg)
			freeimage(w.turretshooterimg)
			freeimage(w.turretlightingimg)
			table.remove(laserturrets, n)
		end
	end
	for n, w in pairs(_player[id].turrettable) do
		if id == w then
			table.remove(_player[id].turrettable, n) 
		end
	end
end

addhook('team', 'team_hook')
function team_hook(id)
	if player(id, 'bot') then return end
	for n, w in pairs(_player[id].turrettable) do
		parse('killobject '.. w)
	end
	_player[id].turrettable = {}
end

addhook('leave', 'leave_hook')
function leave_hook(id)
	if player(id, 'bot') then return end
	for n, w in pairs(_player[id].turrettable) do
		parse('killobject '.. w)
	end
	_player[id].turrettable = {}
end

addhook('startround', 'startround_hook')
function startround_hook()
	laserturrets = {}
	for n, w in pairs(player(0, 'table')) do
		if not player(w, 'bot') then
			_player[w].turrettable = {}
		end
	end
end