local imgui = require 'imgui'
local encoding = require 'encoding'
local vkeys = require 'vkeys'
local sampev = require 'lib.samp.events'
local inicfg = require 'inicfg'
encoding.default = 'CP1251'
u8 = encoding.UTF8
lc = "{ACFF00}"
mc = "{009D00}"
wc = "{FFFFFF}"
mcx = 0xFF009D00

local cfg = inicfg.load({
    black = {
        
    },
	main = {
        key = ''
    },
}, "autoAdminForm")

	requestUpdate = imgui.ImBool(false)
	version_url = "https://gitlab.com/1231332/1231313/-/snippets/2463930/raw"
	tag = " >> FidenForm: "..wc

local allcmd = {"kick", "mute", "jail", "jailoff", "sethp", "sban", "banoff", "muteoff", "sbanoff", "spplayer", "slap", "unmute", "unjail", "sban", "spcar", "ban", "sban", "warn", "skick", "setskin", "ao", "unban", "unwarn", "setskin", "skick", "banip", "offban", "offwarn", "sban", "ptp", "o", "aad", "avig", "aunvig", "setadmin", "givedonate", "spawncars", "mpwin", "prefix", "asellhouse", "delacc", "asellbiz", "money", "test", 'iban'}	

local state, timer = false, -1

local window, hotkeystate = imgui.ImBool(false), imgui.ImBuffer(tostring(cfg.main.key), 1024)

function main()
	if not isSampLoaded() or not isSampfuncsLoaded() then return end
    while not isSampAvailable() do wait(50) end
	
	result_version = check_update(version_url)
	requestUpdate.v = result_version.result

	for i, ip in ipairs(result_version.servers) do
		if select(1, sampGetCurrentServerAddress()) == ip then
			sampAddChatMessage("{20b2aa}Запуск на сервере: " .. lc .. sampGetCurrentServerName(), 0x20b2aa)
			goto server_is_allowed
		end
	end
	if true then
		sampAddChatMessage(tag .. "Скрипт работает только на проекте " .. mc .. "Arizona RP Marti", mcx)
		ErrorMessage = false
		return thisScript():unload()
	end
	::server_is_allowed::
	
    if not doesFileExist('moonloader/config/autoAdminForm.ini') then inicfg.save(cfg, 'autoAdminForm.ini') end
    sampAddChatMessage('[FidenForm]: {FFFFFF}Loaded. Cmd: /fidenform. Author: {6dc451}Fiden @samper vk', 0xFF6dc451)
    sampRegisterChatCommand('fidenform', function() window.v = not window.v imgui.Process = window.v end)
    while true do wait(0)
        if isKeysDown(cfg.main.key) and not isPauseMenuActive() and not sampIsChatInputActive() and not sampIsDialogActive() and not sampIsScoreboardOpen() and not isSampfuncsConsoleActive() then
            state = not state
            sampAddChatMessage('[AutoAdminForm]: {FFFFFF}State: '..(state and 'true' or 'false'), 0xFF6dc451)
        end
        if state and active_forma then
            if not active_forma then break end 
            if os.clock() > timer and timer ~= -1 then
                if mode == 1 then
                    sampSendChat('/a '..admin_nick..', у тебя есть доказательста? (+/-)')
                    timer, mode = os.clock() + 10, 2
                elseif mode == 2 then
                    sampAddChatMessage('[AutoAdminForm]: {FFFFFF}Admin did not respond!', 0xFF6dc451)
                    active_forma = false
                end
            end
        end
    end
end

function sampev.onServerMessage(clr, text)
    if state then
        if active_forma then
            if text:find('%[.*%] '..admin_nick..'%['..admin_id..'%]%: +') and clr == -1714683649 then
                lua_thread.create(function()
                    active_forma = false
                    wait(500)
                    sampSendChat("/"..cmd.." "..admin_other)
                end)
            end
        end
        if not active_forma then
            for k,v in ipairs(allcmd) do
                if text:find("%[.*%] "..sampGetPlayerNickname(select(2, sampGetPlayerIdByCharHandle(PLAYER_PED))).."%["..select(2, sampGetPlayerIdByCharHandle(PLAYER_PED)).."%]%: /"..v.."%s") and clr == -1714683649 then
                    return true
                elseif text:find("%[.*%] (%w+_?%w+)%[(%d+)%]%: /"..v.."%s") and clr == -1714683649 then
                    admin_nick, admin_id, admin_other = text:match("%[.*%] (%w+_?%w+)%[(%d+)%]%: /"..v.."%s(.*)")
                    sampAddChatMessage(admin_nick, -1)
                    find = false
                    for i, d in pairs(cfg.black) do if d == admin_nick then find = true end end
                    if not find then 
                        active_forma, timer, cmd, mode = true, os.clock() + 5, v, 1 
                    else
                        sampAddChatMessage('[AutoAdminForm]: {FFFFFF}Admin in Black List... God damn, skip!', 0xFF6dc451)
                    end
                end
            end
        end
    end
end

-- imgui 
function imgui.OnDrawFrame()
    if window.v then
        imgui.SetNextWindowPos(imgui.ImVec2(400.0, 350.0), imgui.Cond.FirstUseEver)
        imgui.SetNextWindowSize(imgui.ImVec2(208, 200), imgui.Cond.FirstUseEver)
        imgui.Begin('FidenScript || Author: Fiden vk -@samper210', window, imgui.WindowFlags.NoResize + imgui.WindowFlags.NoCollapse)
        if imgui.Hotkey("- key state (on/off)", hotkeystate, 85) then
            nextLockKey = hotkeystate.v
            cfg.main.key = hotkeystate.v
            inicfg.save(cfg, 'autoAdminForm.ini')
        end
        imgui.Separator()
        userlistblack = imgui.ImBuffer(table.concat(cfg.black, '\n'), 0xFFFF)
        if imgui.InputTextMultiline('##userslistblack', userlistblack, imgui.ImVec2(200, -1)) then
            local tempTable = parseText(userlistblack.v)
            cfg.black = #tempTable > 0 and tempTable or {''}
            inicfg.save(cfg, 'autoAdminForm.ini')
        end 
		
		if result_version == nil then
			requestUpdate.v = false
			return
		end
		
        imgui.End()
    else
        imgui.Process = window.v
    end
end


function check_update(url)
	local message = function(text, bInChat, bInConsole)
		if bInChat then
			sampAddChatMessage(tag .. text, mcx)
		end
		if bInConsole == nil or bInConsole == true then
			print(("%s >> {EEEEEE}%s"):format(mc, text))
		end
		return nil
	end

	local lib_exist, requests = pcall(require, "requests")
	if lib_exist == false then
		message("Невозможно проверить актуальную версию! Отсутствует библиотека {00FF00}«Requests»", true)
		message("Ссылка на скачивание находится у вас в консоли: Ё (~)", true, false)
		message("Ссылка на скачивание: {00FF00}https://www.blast.hk/attachments/11724/")
		message("Содержимое архива распаковать в " .. getGameDirectory() .. "\\moonloader\\lib")
		return { result = false, servers = {} }
	end

	message("Проверка обновлений..")
	local response = requests.get(url)
	if response.status_code == 200 then
		local info = decodeJson(u8:decode(response.text))
		if type(info) == "table" then
			if info.latest == thisScript().version then
				message("Обновлений не найдено, текущая " .. lc .. "версия является актуальной!")
				return { result = false, servers = info.servers }
			else
				message("Найдено обновление скрипта на версию: " .. tostring(info.latest) .. "!")
				local result = { 
					result = true,
					latest = info.latest,
					url = info.updateurl,
					changes = info.changes,
					servers = info.servers
				}

				function result:Download()
					local response = requests.get(self.url)
					if response.status_code == 200 then
						ErrorMessage = false
						cfg.opra.launch_count = 0
						local path_script = ("%s\\%s"):format(getWorkingDirectory(), thisScript().filename)
						local lua = io.open(path_script, "wb")
						lua:write(response.text)
						lua:close()
						message("Обновление успешно установлено!", true)
						return true
					end

					message("Ошибка! Не удалось загрузить версию " .. tostring(self.latest), true)
					message("Код ошибки: " .. response.status_code)
					return false
				end
				return result
			end
		end

		message("Ошибка! Не удалось проверить актуальную версию!", true)
		message("Ошибка конвертации информации. Полученный тип данных: " .. type(info))
		return { result = false, servers = {} }
	end

	message("Ошибка! Не удалось проверить актуальную версию!", true)
	message("Код ошибки: " .. response.status_code)
	return { result = false, servers = {} }
end

-- blacklist
function parseText(text)
    local tempTable = {}
    for user in text:gmatch('([%w+%d+%[%]_@$]+)') do table.insert(tempTable, user) end
    return tempTable
end

-- hotkey
function getDownKeys()
    local curkeys = ""
    local bool = false
    for k, v in pairs(vkeys) do
        if isKeyDown(v) and (v == VK_MENU or v == VK_CONTROL or v == VK_SHIFT or v == VK_LMENU or v == VK_RMENU or v == VK_RCONTROL or v == VK_LCONTROL or v == VK_LSHIFT or v == VK_RSHIFT) then
            if v ~= VK_MENU and v ~= VK_CONTROL and v ~= VK_SHIFT then
                curkeys = v
            end
        end
    end
    for k, v in pairs(vkeys) do
        if isKeyDown(v) and (v ~= VK_MENU and v ~= VK_CONTROL and v ~= VK_SHIFT and v ~= VK_LMENU and v ~= VK_RMENU and v ~= VK_RCONTROL and v ~= VK_LCONTROL and v ~= VK_LSHIFT and v ~= VK_RSHIFT) then
            if tostring(curkeys):len() == 0 then
                curkeys = v
            else
                curkeys = curkeys .. " " .. v
            end
            bool = true
        end
    end
    return curkeys, bool
end
  
function isKeysDown(keylist, pressed)
    local tKeys = string.split(keylist, " ")
    if pressed == nil then
        pressed = false
    end
    if tKeys[1] == nil then
        return false
    end
    local bool = false
    local key = #tKeys < 2 and tonumber(tKeys[1]) or tonumber(tKeys[2])
    local modified = tonumber(tKeys[1])
    if #tKeys < 2 then
        if not isKeyDown(VK_RMENU) and not isKeyDown(VK_LMENU) and not isKeyDown(VK_LSHIFT) and not isKeyDown(VK_RSHIFT) and not isKeyDown(VK_LCONTROL) and not isKeyDown(VK_RCONTROL) then
            if wasKeyPressed(key) and not pressed then
                bool = true
            elseif isKeyDown(key) and pressed then
                bool = true
            end
        end
    else
        if isKeyDown(modified) and not wasKeyReleased(modified) then
            if wasKeyPressed(key) and not pressed then
                bool = true
            elseif isKeyDown(key) and pressed then
                bool = true
            end
        end
    end
    if nextLockKey == keylist then
        if pressed and not wasKeyReleased(key) then
            bool = false
    --            nextLockKey = ""
        else
            bool = false
            nextLockKey = ""
        end
    end
    return bool
end

function string.split(inputstr, sep)
    if sep == nil then
            sep = "%s"
    end
    local t={} ; i=1
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
            t[i] = str
            i = i + 1
    end
    return t
end

local editHotkey = nil
function imgui.Hotkey(name, keyBuf, width)
    local name = tostring(name)
    local keys, endkey = getDownKeys()
    local keysName = ""
    local ImVec2 = imgui.ImVec2
    local bool = false
    if editHotkey == name then
        if keys == VK_BACK then
            keyBuf.v = ''
            editHotkey = nil
            nextLockKey = keys
            editKeys = 0
        else
            local tNames = string.split(keys, " ")
            local keylist = ""
            for _, v in ipairs(tNames) do
                local key = tostring(vkeys.id_to_name(tonumber(v)))
                if tostring(keylist):len() == 0 then
                    keylist = key
                else
                    keylist = keylist .. " + " .. key
                end
            end
            keysName = keylist
            if endkey then
                bool = true
                keyBuf.v = tostring(keys)
                editHotkey = nil
                nextLockKey = keys
                editKeys = 0
            end
        end
    else
        local tNames = string.split(keyBuf.v, " ")
        for _, v in ipairs(tNames) do
            local key = tostring(vkeys.id_to_name(tonumber(v)))
            if tostring(keysName):len() == 0 then
                keysName = key
            else
                keysName = keysName .. " + " .. key
            end
        end
    end
    local style = imgui.GetStyle()
    local colors = style.Colors
    local clr = imgui.Col
    imgui.PushStyleColor(imgui.Col.Button, colors[clr.FrameBg])
    imgui.PushStyleColor(imgui.Col.ButtonActive, colors[clr.FrameBg])
    imgui.PushStyleColor(imgui.Col.ButtonHovered, colors[clr.FrameBg])
    imgui.PushStyleVar(imgui.StyleVar.ButtonTextAlign, ImVec2(0.04, 0.5))
    imgui.Button(u8((tostring(keysName):len() > 0 or editHotkey == name) and keysName or "Нет"), ImVec2(width, 20))
    imgui.PopStyleVar()
    imgui.PopStyleColor(3)
    if imgui.IsItemHovered() and imgui.IsItemClicked() and editHotkey == nil then
        editHotkey = name
        editKeys = 100
    end
    if name:len() > 0 then
        imgui.SameLine()
        imgui.Text(name)
    end
    return bool
end

function setTheme()
    imgui.SwitchContext()
    local style = imgui.GetStyle()
    local colors = style.Colors
    local clr = imgui.Col
    local ImVec4 = imgui.ImVec4
    local ImVec2 = imgui.ImVec2
    style.WindowPadding                = ImVec2(4.0, 4.0)
    style.WindowRounding               = 7
    style.WindowTitleAlign             = ImVec2(0.5, 0.5)
    style.FramePadding                 = ImVec2(4.0, 3.0)
    style.ItemSpacing                  = ImVec2(8.0, 4.0)
    style.ItemInnerSpacing             = ImVec2(4.0, 4.0)
    style.ChildWindowRounding          = 7
    style.FrameRounding                = 7
    style.ScrollbarRounding            = 7
    style.GrabRounding                 = 7
    style.IndentSpacing                = 21.0
    style.ScrollbarSize                = 13.0
    style.GrabMinSize                  = 10.0
    style.ButtonTextAlign              = ImVec2(0.5, 0.5)
    colors[clr.Text]                   = ImVec4(0.90, 0.90, 0.90, 1.00)
    colors[clr.TextDisabled]           = ImVec4(1.00, 1.00, 1.00, 1.00)
    colors[clr.WindowBg]               = ImVec4(0.06, 0.06, 0.06, 1.00)
    colors[clr.PopupBg]                = ImVec4(0.08, 0.08, 0.08, 0.96)
    colors[clr.FrameBg]                = ImVec4(0.49, 0.24, 0.00, 1.00)
    colors[clr.FrameBgHovered]         = ImVec4(0.65, 0.32, 0.00, 1.00)
    colors[clr.FrameBgActive]          = ImVec4(0.73, 0.36, 0.00, 1.00)
    colors[clr.TitleBg]                = ImVec4(0.15, 0.11, 0.09, 1.00)
    colors[clr.TitleBgActive]          = ImVec4(0.73, 0.36, 0.00, 1.00)
    colors[clr.TitleBgCollapsed]       = ImVec4(0.15, 0.11, 0.09, 0.51)
    colors[clr.MenuBarBg]              = ImVec4(0.62, 0.31, 0.00, 1.00)
    colors[clr.CheckMark]              = ImVec4(1.00, 0.49, 0.00, 1.00)
    colors[clr.SliderGrab]             = ImVec4(0.84, 0.41, 0.00, 1.00)
    colors[clr.SliderGrabActive]       = ImVec4(0.98, 0.49, 0.00, 1.00)
    colors[clr.Button]                 = ImVec4(0.73, 0.36, 0.00, 0.40)
    colors[clr.ButtonHovered]          = ImVec4(0.73, 0.36, 0.00, 1.00)
    colors[clr.ButtonActive]           = ImVec4(1.00, 0.50, 0.00, 1.00)
    colors[clr.Header]                 = ImVec4(0.49, 0.24, 0.00, 1.00)
    colors[clr.HeaderHovered]          = ImVec4(0.70, 0.35, 0.01, 1.00)
    colors[clr.HeaderActive]           = ImVec4(1.00, 0.49, 0.00, 1.00)
    colors[clr.SeparatorHovered]       = ImVec4(0.49, 0.24, 0.00, 0.78)
    colors[clr.SeparatorActive]        = ImVec4(0.49, 0.24, 0.00, 1.00)
    colors[clr.ResizeGrip]             = ImVec4(0.48, 0.23, 0.00, 1.00)
    colors[clr.ResizeGripHovered]      = ImVec4(0.78, 0.38, 0.00, 1.00)
    colors[clr.ResizeGripActive]       = ImVec4(1.00, 0.49, 0.00, 1.00)
    colors[clr.PlotLines]              = ImVec4(0.83, 0.41, 0.00, 1.00)
    colors[clr.PlotLinesHovered]       = ImVec4(1.00, 0.99, 0.00, 1.00)
    colors[clr.PlotHistogram]          = ImVec4(0.93, 0.46, 0.00, 1.00)
    colors[clr.TextSelectedBg]         = ImVec4(0.26, 0.59, 0.98, 0.00)
    colors[clr.ScrollbarBg]            = ImVec4(0.00, 0.00, 0.00, 0.53)
    colors[clr.ScrollbarGrab]          = ImVec4(0.33, 0.33, 0.33, 1.00)
    colors[clr.ScrollbarGrabHovered]   = ImVec4(0.39, 0.39, 0.39, 1.00)
    colors[clr.ScrollbarGrabActive]    = ImVec4(0.48, 0.48, 0.48, 1.00)
    colors[clr.CloseButton]            = colors[clr.FrameBg]
    colors[clr.CloseButtonHovered]     = colors[clr.FrameBgHovered]
    colors[clr.CloseButtonActive]      = colors[clr.FrameBgActive]
end
setTheme()