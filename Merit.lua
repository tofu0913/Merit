_addon.name = 'Merit'
_addon.author = 'Cliff'
_addon.version = '1.0.0'
_addon.commands = {'mrt'}

require('logger')
require('actions')
local packets = require("packets")

require('mylibs/utils')
require('mylibs/fsd_lite')
require('mylibs/aggro')
require('mylibs/trusts')

local enabled = false
local fighting = false
local lastwsCheck = os.clock()
local lastwarpCheck = os.clock()
local aggroCheck = os.clock()
local mpoints = 75

TRUSTS = {
    -- "コーネリア",
    "クポフリート",
    "サクラ",
    "モンブロー",
    "コルモル",
    "ヨアヒム",
}

windower.register_event('incoming chunk', function(id, data, modified, injected, blocked)
    if not enabled then return end
	
	if id == 0x063 then
        local p = packets.parse('incoming', data)
        if p['Order'] == 2 then
            -- current = p['Limit Points']
            mpoints = p['Merit Points']
            -- maximum_merits = p['Max Merit Points']
        end
    end
end)

windower.register_event('prerender', function(...)
    if warping and (os.clock() - lastwarpCheck) > 3 then
        if T{288}:contains(windower.ffxi.get_info()['zone']) then
			windower.send_command(windower.to_shift_jis('input /equip ring1 デジョンリング; wait 12; input /item "デジョンリング" <me>'))
        else
            log('Warp completed')
            warping = false
        end
        lastwarpCheck = os.clock()
    end
    if enabled and (os.clock() - lastwsCheck) > 0.8 then
        tp = windower.ffxi.get_player()['vitals']['tp']
        if tp > 999 then
			if isJob('WAR') then
				windower.send_command('input /ws '..windower.to_shift_jis("フェルクリーヴ")..' <t>')
			elseif isJob('THF') then
				windower.send_command('input /ws '..windower.to_shift_jis("イオリアンエッジ")..' <t>')
			end
        end
        lastwsCheck = os.clock()
    end
	if fighting and os.clock() - aggroCheck > 1 then
		if aggroCount() == 0 then
			aggroCheck = os.clock() + 5
			main_function(windower.ffxi.get_info()['zone'])
			return
		end
		aggroCheck = os.clock()
	end
end)

windower.register_event('status change', function(new, old)
    if new == 2 then
		enabled = false
    end
end)

function main_function(zone)
	if not enabled then return end
	
	if zone == 288 then--エスカ-ジ・タ
		if in_pos(-321.14, 345.81 ,50) then
			if aggroCount() == 0 then
				log('go')
				fighting = false
				windower.send_command('lz stop')
				fsd_go_reverse('mrt', 'mrt_hunt', function()
					main_function(windower.ffxi.get_info()['zone'])
				end)
			else
				log('clean')
				windower.send_command('lz clean; wait 0.5; lz start')
				coroutine.sleep(2)
				fighting = true
			end
		elseif in_pos(-236, 619.97, 50) then
			if aggroCount() == 0 then
				log('go back')
				fighting = false
				windower.send_command('lz stop')
				fsd_go('mrt', 'mrt_hunt', function()
					main_function(windower.ffxi.get_info()['zone'])
				end)
			else
				log('clean')
				windower.send_command('lz clean; wait 0.5; lz start')
				coroutine.sleep(2)
				fighting = true
			end
		elseif in_pos(-345.42, -178) then
			fsd_go('mrt', 'zone_ez_sT1', function()
				windower.send_command('sw ew 2')
				coroutine.sleep(5)
				callnpc('mrt', function()
					main_function(windower.ffxi.get_info()['zone'])
				end)
			end)
		end
		
    elseif zone == 126 then--クフィム島
		fsd_go('mrt', 'zone_q_hpTesc', function()
			windower.send_command('sw ew enter')
        end)
	
	else
		if isNpcNear('Home Point') then
			windower.send_command('sw hp island')
		else
			log('No Home point nearby...')
		end
	end
end

windower.register_event('zone change', function(new, old)
    -- log(new)
    if not enabled then return end
    
	coroutine.sleep(10)
    main_function(new)
end)

windower.register_event('addon command', function(command, ...)
    if T{"go","g","gg"}:contains(command) then
        enabled = true
		windower.send_command('lr combat')
		main_function(windower.ffxi.get_info()['zone'])
		
    elseif T{"stop","s"}:contains(command) then
        enabled = false
        windower.send_command("lz s")
        windower.send_command("fsd s")

    end
end)

windower.register_event('load', function()
    log('===========loaded===========')
	if isJob('WAR') then
		windower.send_command("gc gax")
		windower.send_command("ata off")
	elseif isJob('THF') then
		windower.send_command("gc aby; wait 1; gc su5")
	end
    windower.send_command("ws s")
end)

windower.register_event('unload', function()
    windower.send_command("fsd s")
end)