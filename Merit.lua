_addon.name = 'Merit'
_addon.author = 'Cliff'
_addon.version = '1.0.0'
_addon.commands = {'mrt'}

require('logger')
require('actions')
local packets = require("packets")

require('mylibs/utils')
require('mylibs/fsd_lite')

local enabled = false
local start = false
local ws_count = 0
local lastwsCheck = os.clock()
local lastwarpCheck = os.clock()
local mpoints = 75

TRUSTS_FARM = {
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

function action_handler(act)
    if not enabled then
        return
    end
    local actionpacket = ActionPacket.new(act)
    local category = actionpacket:get_category_string()

    if category == 'weaponskill_finish' and act.param ~= 0 then
		log(ws_count)
		ws_count = ws_count + 1
		if ws_count >= 2 then
			windower.send_command('lz stop')
			windower.send_command('/a off; /a off; /a off; /a off; ')
			start_fight()
		end
	end
end
ActionPacket.open_listener(action_handler)

windower.register_event('prerender', function(...)
    if not enabled then return end
    
    if warping and (os.clock() - lastwarpCheck) > 3 then
        if T{298,279}:contains(windower.ffxi.get_info()['zone']) then
			-- windower.send_command(windower.to_shift_jis('input /ma デジョン <me>'))
        else
            log('Warp completed')
            warping = false
        end
        lastwarpCheck = os.clock()
    end
    if windower.ffxi.get_player()['status'] == 1 and (os.clock() - lastwsCheck) > 0.8 then
        tp = windower.ffxi.get_player()['vitals']['tp']
        if tp > 999 then
			if isJob('wAR') then
				windower.send_command('input /ws '..windower.to_shift_jis("フェルクリーヴ")..' <t>')
			elseif isJob('THF') then
				windower.send_command('input /ws '..windower.to_shift_jis("イオリアンエッジ")..' <t>')
			end
        end
        lastwsCheck = os.clock()
    end
end)

windower.register_event('status change', function(new, old)
    if new == 2 then
		enabled = false
		start = false
    end
end)

function start_fight()
	if not enabled or not start then return end
	
	ws_count = 0
	if in_pos(-321.14016723633,345.8117980957,50) then
		log('go')
		fsd_go_reverse('mrt', 'mrt_hunt', function()
			windower.send_command('lz start')
		end)
	else
		log('bak')
		fsd_go('mrt', 'mrt_hunt', function()
			windower.send_command('lz start')
		end)
	end
end

windower.register_event('zone change', function(new, old)
    -- log(new)
    if not enabled then return end
    
	coroutine.sleep(10)
    if new == 288 then--エスカ-ジ・タ
		fsd_go('mrt', 'zone_ez_sT1', function()--todo, path
			windower.send_command('input //sw ew 2')
			coroutine.sleep(5)
            for c = 1, #TRUSTS_FARM do
                windower.send_command(windower.to_shift_jis('input /ma "'..TRUSTS_FARM[c]..'" <me>'))
                coroutine.sleep(6)
            end
			start = true
			start_fight()
		end)
        
    elseif new == 126 then--クフィム島
		fsd_go('mrt', 'zone_q_hpTesc', function()--todo, path
			windower.send_command('input //sw ew enter')
        end)
    end
end)

windower.register_event('addon command', function(command, ...)
    if T{"go","g","gg"}:contains(command) then
        enabled = true
        start = false
		
    elseif T{"test"}:contains(command) then
        enabled = true
		start = true
		start_fight()
	
    elseif T{"stop","s"}:contains(command) then
        enabled = false
		start = false
        windower.send_command("input //fsd s")

    end
end)

windower.register_event('load', function()
    log('===========loaded===========')
	if isJob('wAR') then
		windower.send_command("gc gax")
		windower.send_command("ata off")
	elseif isJob('THF') then
		windower.send_command("gc aby; wait 1; gc su5")
	end
    windower.send_command("input //ws s")
end)

windower.register_event('unload', function()
    windower.send_command("input //fsd s")
end)