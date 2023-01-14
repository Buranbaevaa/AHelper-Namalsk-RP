--========================================================DIRECTIVES========================================================

script_name("Admin Helper") 
script_author("Bruno")
script_description("Помощник для администрации на Namalsk RolePlay")
script_version(2)
script_dependencies("mimgui", "ffi", "encoding", "samp.events", "mimtoasts", "memory", "inicfg", "mimhotkey", "fAwesome6_solid", "moonloader")

--========================================================LIB=========================================================

local imgui = require("mimgui")
local ffi = require("ffi")
local encoding = require("encoding")
local hook = require("lib.samp.events")
local toast_bool, toast = pcall(import, "lib\\mimtoasts.lua")
local memory = require("memory")
local inicfg = require("inicfg")
local hotkey = require("mimhotkey")
local fa = require("fAwesome6_solid")
local fontFlag = require("moonloader").font_flag
local downloadStatus = require('moonloader').download_status

--========================================================CONFIG=========================================================

local mainIni = inicfg.load({
    config = {                       
        afly = false,
        togphone = false,
        check = false,
        hp = false
    },

    keys = {
        menu = "[46]",
        pos = "[40]",
        navodki = "[45]"            
    },

    airbreak = {
        actived = false,
        speed = 1
    },

    wallhack = {
        actived = false,
    },

    navodki = {
        actived = true,
        time = 3000
    },

    carInfo = {
        actived = true,
        model = true,
        id = true,
        engine = true,
        hp = true,
        dist = true
    },

    checker = {
        actived = false,
        posX = 0,
        posY = 0
    },

    style = {
        theme = 0,
        twist = 0
    },

    pos = {
        x = 0,
        y = 0,
        z = 0
    },

    serverInfo = {
        serverIP = "",
        serverPort = ""
    }

}, "AHelper.ini")

if not doesDirectoryExist("moonloader\\config") then 
    createDirectory("moonloader\\config") 
end
if not doesFileExist("moonloader/config/AHelper.ini") then 
    inicfg.save(mainIni, "AHelper.ini") 
end

--========================================================VARIABLES=========================================================

hotkey.no_flood = false
encoding.default = "CP1251"

local u8 = encoding.UTF8
local new = imgui.new
local str, sizeof = ffi.string, ffi.sizeof
local ToU32 = imgui.ColorConvertFloat4ToU32

local sw, sh = getScreenResolution()
local fontCarInfo = renderCreateFont("Arial", 8, fontFlag.BOLD + fontFlag.SHADOW)
local fontAdm = renderCreateFont("Arial", 9)

--========================================================TABLES=========================================================

local style_list = {u8"Тёмная", u8"Берюзовая", u8"Красная", u8"Фиолетовая", u8"Розово-фиолетовая"}
local twist_list = {u8"Мягккий", u8"Резкий"}

local TriggerCommand = {"/warn", "/ban", "/jail", "/skick", "/sethp", "/unwarn", "/write", "/unmute", "/unjail", "/spawncar", "/clear", "/spcar", "/spawncar", "/sban", "/unfreeze", "/ip", "/resgun", "/freeze", "/ans", "/sp", "/tempskin", "/offmorgan", "/offmute", "/jailoff", "/muteoff", "/ao", "/msg", "/banip", "/banoff", "/offban", "/warnoff", "/offwarn", "/mute", "/voicemute", "/kick", "/setarm", "/spawn"}

local header_name = {
    setting = {u8"Основные настройки", u8"Дополнительные настройки", u8"Серверные настройки", u8"Настройки интерфейса"}, 
    additionally = {u8"Настройки софта", u8"Настройки трейсеров", u8"Настройки рекона"}
}

local admins = {
    [7771] = {
        ["Andrey_Astrovskiy"] = "Главный Администратор",
        ["Danil_Bragin"] = "Заместитель Главного Администратора",
        ["Artem_Mitoff"] = "Куратор",
        ["Vasiliy_Kubinecc"] = "Куратор",
        ["Timofey_Sundwarezz"] = "Куратор"
    },
    [7772] = {
        ["Thomas_Mackardy"] = "Главный Администратор",
        ["Egor_Harmon"] = "Заместитель Главного Администратора",
        ["Andrey_Zharov"] = "Куратор",
        ["Stretch_Expluse"] = "Куратор"
    },
    [7773] = {
        ["Fernando_Flyweather"] = "Главный Администратор",  
        ["Kostya_Ovchinnikov"] = "Заместитель Главного Администратора",
        ["Fake_Kirya"] = "Куратор",
        ["Fake_Boogeyman"] = "Куратор"    
    }
}

local spInfo = {
    id = -1,
    cursor = false,
}

local config = {
    mainWindow = new.bool(), 
    spWindow = new.bool(),
    
    afly = new.bool(mainIni.config.afly),
    togphone = new.bool(mainIni.config.togphone),
    hp = new.bool(mainIni.config.hp),

    header = {
        setting = {new.bool(true), new.bool(), new.bool(), new.bool()}, 
        additionally = {new.bool(true), new.bool()}
    },

    airbreak = {
        actived = new.bool(mainIni.airbreak.actived),
        speed = new.float(mainIni.airbreak.speed),
        AirBreak = false
    },

    wallhack = {
        actived = new.bool(mainIni.wallhack.actived),        
    },  

    carInfo = {
        actived = new.bool(mainIni.carInfo.actived),
        data = {
            model = new.bool(mainIni.carInfo.model),
            id = new.bool(mainIni.carInfo.id),
            engine = new.bool(mainIni.carInfo.engine),
            hp = new.bool(mainIni.carInfo.hp),
            dist = new.bool(mainIni.carInfo.dist)
        }
    },
    
    navodki = {
        actived = new.bool(mainIni.navodki.actived),
        send = false,
        time = new.int(mainIni.navodki.time),

        data = {
            name = "",
            id = "",
            prichina = "",
            command = ""
        }
    },   

    checker = {
        actived = new.bool(mainIni.checker.actived),
        setting = false
    },

    style = new.int(mainIni.style.theme),
    twist = new.int(mainIni.style.twist),
    page = new.int(1),

    style_combo = imgui.new["const char*"][#style_list](style_list),
    twist_combo = imgui.new["const char*"][#twist_list](twist_list),

    search = new.char[256](),    
}

local binds = {
    menu = {
        keys = decodeJson(mainIni.keys.menu),
        callback = function()   
            if not sampIsCursorActive() then       
                config.mainWindow[0] = not config.mainWindow[0]
            end
        end
    },

    pos = {
        keys = decodeJson(mainIni.keys.pos),
        callback = function()
            if not sampIsCursorActive() then   
                setCharCoordinates(PLAYER_PED, mainIni.pos.x, mainIni.pos.y, mainIni.pos.z)
                toast.Show(u8"Вы телепортировались на сохранённый пост", toast.TYPE.INFO, 7, ColorNotification())
            end    
        end
    },

    navodki = {
        keys = decodeJson(mainIni.keys.navodki),
        callback = function()
            if config.navodki.actived[0] and config.navodki.send then       
                lua_thread.create(function()
                    config.navodki.send = false         
                    sampSendChat(string.format("%s %s %s | %s", config.navodki.data.command, config.navodki.data.id, config.navodki.data.prichina, shorten(config.navodki.data.name)))
                    wait(1200)
                    sampSendChat(string.format("/a Наводка от - %s на %s - принята.", config.navodki.data.name, config.navodki.data.command))
                end)
            end
        end
    }
}

local spButton = {
    sendChat = {
        {text = "Статистика", send = "stats"},
        {text = "Подбросить", send = "slap"},
        {text = "Телепортироваться", send = "goto"},
        {text = "Телепортировать", send = "gethere"},
        {text = "Флипнуть", send = "flip"},
        {text = "Заморозить", send = "freeze"},
        {text = "Разаморозить", send = "unfreeze"},
        {text = "Заспавнить", send = "spawn"},
        {text = "Снять наручники", send = "auncuff"},
        {text = "Инвентарь", send = "checkinv"},        
        {text = "Забрать оружие", send = "resgun"}
    },

    func = {
        {
            text = "Проверка на бота", 
            func = function() 
                local rand1 = random(1, 50)
                local rand2 = random(1, 20)
                lua_thread.create(function()
                    for i = 1, 3 do                        
                        sampSendChat(string.format("/write %s Уважаемый игрок, сколько будет %s+%s? (Ответ в /b)", spInfo.id, rand1, rand2))
                        wait(1000)
                    end    
                end)
            end
        }
    }
}

local spTextdraw = {
    [2053] = function() end,
    [2054] = function() end,
    [2055] = function() end,
    [2056] = function() end,
    [2057] = function() end,
    [2058] = function() end,
    [2059] = function() end,
    [2060] = function() end,
    [2061] = function() end,
    [2062] = function() end,
    [2063] = function() end,
    [2064] = function() end,
    [2065] = function() end,
    [2066] = function() end
}

local fastButton = {
    {
        name = "Очистить чат", 
        func = function() 
            memory.fill(sampGetChatInfoPtr() + 306, 0x0, 25200)
            memory.write(sampGetChatInfoPtr() + 306, 25562, 4, 0x0)
            memory.write(sampGetChatInfoPtr() + 0x63DA, 1, 1)
        end
    },

    {
        name = "Подключиться",
        func = function()
            if mainIni.serverInfo.serverIP and mainIni.serverInfo.serverPort then
                sampConnectToServer(mainIni.serverInfo.serverIP, mainIni.serverInfo.serverPort)
            else
                toast.Show(u8"Ошибка в получении IP и порта сервера", toast.TYPE.INFO, 7, ColorNotification())
            end
        end
    },

    {
        name = "Отключиться",
        func = function()
            local bs = raknetNewBitStream()
            raknetEmulPacketReceiveBitStream(32, bs)
            raknetDeleteBitStream(bs)
        end
    },

    {
        name = "Заспавниться",
        func = function()
            local bs = raknetNewBitStream()
            raknetSendRpc(52, bs)
            raknetDeleteBitStream(bs)
        end
    },

    {
        name = "Умереть",
        func = function()
            setCharHealth(PLAYER_PED, 0)
        end
    },

    {
        name = "Freeze",
        func = function()
            freezeChar(false)            
        end
    },

    {
        name = "UnFreeze",
        func = function()
            freezeChar(true)
        end
    },

    {
        name = "Телепорт на чекпоинт",
        func = function()
            local mx, my, mz = getCharCoordinates(PLAYER_PED)
            local result, x, y, z = SearchMarker(mx, my, mz, -1, true)
            if result then
                setCharCoordinates(PLAYER_PED, x, y, z)
                toast.Show(u8"Успешно телепортировались", toast.TYPE.INFO, 7, ColorNotification())
            else
                toast.Show(u8"Не нашли чекпоинт", toast.TYPE.INFO, 7, ColorNotification())
            end
        end
    },

    {
        name = "Телепорт на метку",
        func = function()
            local result, x, y, z = getTargetBlipCoordinates()
            if result then
                setCharCoordinates(PLAYER_PED, x, y, z)
                toast.Show(u8"Успешно телепортировались", toast.TYPE.INFO, 7, ColorNotification())
            else
                toast.Show(u8"Не нашли метку", toast.TYPE.INFO, 7, ColorNotification())
            end
        end
    },    

    {
        name = "Восстановить HP",
        func = function()
            sampSendChat("/hp")
        end
    },

    {
        name = "Восстановить ARM",
        func = function()
            sampSendChat(string.format("/setarm %s 100", select(2, sampGetPlayerIdByCharHandle(PLAYER_PED))))
        end
    },

    {
        name = "Slap Up",
        func = function()
            local mx, my, mz = getCharCoordinates(PLAYER_PED)
            setCharCoordinates(PLAYER_PED, mx, my, mz+5)
        end
    },

    {
        name = "Slap Down",
        func = function()
            local mx, my, mz = getCharCoordinates(PLAYER_PED)
            setCharCoordinates(PLAYER_PED, mx, my, mz-5)
        end
    }
}

local vehicle = {
    [462] = {name = "Faggio"},
    [521] = {name = "Планета 5"},
    [467] = {name = "ВАЗ 2101"},
    [404] = {name = "ВАЗ 2107"},
    [458] = {name = "ВАЗ 2114"},
    [585] = {name = "ВАЗ 2115"},
    [478] = {name = "ВАЗ 2106"},  
    [412] = {name = "ВАЗ 2112"},
    [442] = {name = "Лада приора"},
    [542] = {name = "Лада 4х4(Нива)"},    
    [468] = {name = "Yamaha DT-180"},
    [431] = {name = "Audi 80"},
    [567] = {name = "ВАЗ 2107 (TUN)"},
    [471] = {name = "Снегоход"},
    [443] = {name = "Jeep Cherokee"},
    [463] = {name = "Harrley Chopper"},
    [558] = {name = "Lada Vesta Sport"},
    [535] = {name = "Turbo Oka (TUN)"},
    [445] = {name = "Skoda Rapid"},
    [411] = {name = "Renault Logan"}, 
    [418] = {name = "GMC Vanduro"},   
    [560] = {name = "Mitsubishi Lancer (TUN)"},
    [527] = {name = "Honda Civik 97"},
    [15084] = {name = "Skoda Octavia"},
    [600] = {name = "BMW M5 E34"},
    [540] = {name = "Toyota Mark II"},
    [507] = {name = "Mercedes E55 W210"},
    [516] = {name = "Ford Focus 3"},
    [575] = {name = "Mitsubishi Lancer 9"},
    [499] = {name = "Mitsubishi Pajero"},
    [15065] = {name = "Lexus IS300"},  
    [491] = {name = "Toyota Chaser"},
    [550] = {name = "BMW M5 E39"}, 
    [500] = {name = "UAZ Patriot"}, 
    [536] = {name = "Toyota AE86 (TUN)"},          
    [559] = {name = "BMW E46 (TUN)"},
    [421] = {name = "Mercedes S600 W140"},
    [546] = {name = "Volvo XC90 Sport"},
    [605] = {name = "BMW X5"},
    [437] = {name = "BMW 750 E38"},
    [15108] = {name = "Mazda 3 Mps 2008"},
    [15072] = {name = "Audi S4"},
    [568] = {name = "Can-Am Maverick"},
    [424] = {name = "Caterham Superlight R500"},
    [522] = {name = "Yamaha R6"},
    [558] = {name = "Subaru BRZ (TUN)", id = "558"},
    [423] = {name = "Nissan 400Z"},
    [15071] = {name = "Audi Q7"},
    [541] =  {name = "Ford Mustrang GT"},
    [551] = {name = "Toyota Camry"},
    [587] = {name = "Renault RS"},
    [533] = {name = "Honda S2000"},
    [492] = {name = "Honda Accord"},
    [524] = {name = "Nissan Skyline X"},
    [15107] = {name = "Mercedes Benz CLS63 AMG 2008"},
    [15074] = {name = "Mercedes S65 W221"},  
    [15075] = {name = "Mercedes A45 AMG"}, 
    [15079] = {name = "Subaru WRX STi"},   
    [15089] = {name = "Oper Astra GTC"},
    [401] = {name = "Audi S3"},   
    [562] = {name = "Nissan Skyline R34"},    
    [429] = {name = "Volkswagen Touareg"},
    [561] = {name = "Toyota Supra (TUN)"},
    [589] = {name = "BMW M3 E92"},
    [547] = {name = "Tesla Model S"},
    [574] = {name = "Renault Megane RS"},   
    [526] =  {name = "Porsche Carrera 2"},
    [474] = {name = "BMW M5 E60"},
    [565] = {name = "Mercedes-Benz C180 (TUN)"},
    [410] = {name = "BMW X5M E70"},
    [529] = {name = "Jaguar F-Type"},
    [604] = {name = "BMW 750I"},
    [495] = {name = "Ford Ranger Raptor"},  
    [15092] = {name = "Alfa Romeo Giulia"},
    [15081] = {name = "Jeep Wrangler"},
    [482] = {name = "Mini Countryman"},
    [483] = {name = "Mercedes 560SEC"},
    [440] = {name = "KIA Stinger"},
    [15080] = {name = "Mercedes E63 '14"},
    [489] = {name = "Toyota LC200"},
    [576] = {name = "BMW M5 F10"},
    [15082] = {name = "Audi TT"},
    [15086] = {name = "Kia Rio"},
    [422] = {name = "BMW M2"},
    [15090] = {name = "Dodge Chadger SRT"},
    [433] = {name = "VW Golf GTI"},     
    [490] = {name = "Range Rover Sport SVR"},
    [15077] = {name = "Porsche Boxster"},
    [555] = {name = "Volvo XC90 II"},
    [15066] = {name = "Mercedes C63S AMG"},
    [477] = {name = "Mazda RX-7"},
    [479] = {name = "BMW X6M F86"},
    [580] = {name = "Dodge Charger 70"},
    [459] = {name = "Mercedes-Benz V250"},
    [494] = {name = "Porsche Cayenne"},
    [470] = {name = "GAZ Tigr"},
    [15073] = {name = "Lexus LX570"},
    [502] = {name = "Chevrolet Camaro"},
    [517] = {name = "Toyota Supra A90"},
    [498] = {name = "Mercedes S63 AMG Coupe"},
    [400] = {name = "Mercedes E350D AT"},
    [545] = {name = "Range Rover Velar"},
    [475] = {name = "Mercedes-Benz GL63"},
    [534] = {name = "BMW M4 (G82)"},
    [543] = {name = "Mercedes AMG GT R"},
    [496] = {name = "Audi RS5"},
    [15088] = {name = "Dodge VIper"},
    [505] = {name = "Cadillac Escalade ESV"},
    [456] = {name = "Jeep GC TrackHawk"},
    [506] = {name = "Nissan GT-R R35"},
    [402] = {name = "Mercedes-Benz E63S"},
    [504] = {name = "Dodge Demon"},
    [413] = {name = "Mercedes 300CE"},
    [405] = {name = "Audi RS6"},
    [439] = {name = "Silvia S15 Drift (TUN)"},
    [15068] = {name = "Porsche Panamera"},
    [15069] = {name = "Chevrolet Corvette"},
    [15067] = {name = "DeBerti Mustang"},
    [15076] = {name = "Mercedes C63 AMG BS"},
    [554] = {name = "Mercedes Benz GT63S"},    
    [466] = {name = "BMW M5 F90"}, 
    [426] = {name = "Mercedes Maybach S650"},
    [409] = {name = "RR Phantom"},
    [438] = {name = "Bentley Bentayga"},
    [603] = {name = "Audi R8"},
    [15106] = {name = "BMW X7"},
    [579] = {name = "Mercedes-Benz G65"},
    [480] = {name = "BMW i8"},
    [566] = {name = "BMW M8"},
    [15104] = {name = "Tesla Model S Plaid 2022"},
    [15105] = {name = "Audi e-Tron GT RS 2022"},
    [434] = {name = "Porsche Carrera S"},
    [556] = {name = "Audi RS7 Sportback"},
    [15070] = {name = "Nissan GTR Drift"},
    [508] = {name = "McLaren 570S"},
    [455] = {name = "BMW X6 M-Sport"},
    [518] = {name = "Mercedes-Benz AMG G63"},
    [419] = {name = "Lamborghini Huracan PF"},
    [15085] = {name = "Mercedes-Benz G63 Brabus"},
    [408] = {name = "BMW M5 CS"},
    [436] = {name = "Lamborghini Urus"},
    [415] = {name = "Lamborghini Aventador"},
    [503] = {name = "Rolls Royce Dawn"},
    [451] = {name = "Ferrari 812 Sf"},
    [557] = {name = "Mercedes-Bens G63 6x6"},
    [15103] = {name = "Bentley Continental GT"},
    [15078] = {name = "Rolls Royce Cullinan"},
    [15087] = {name = "Pagani Huayra BC"},
    [572] = {name = "Ferrari SF90 Stradale"},
    [602] = {name = "Bugatti Veyron SS"},
    [15083] = {name = "Bugatti Chiron Sport"},
    [15095] = {name = "Lamborghini Centenario", id = "15095"}    
}

--========================================================MAIN========================================================

function main()
    while not isSampAvailable() do wait(100) end  

    checkUpdate()
    
    hotkey.RegisterCallback("menu", binds.menu.keys, binds.menu.callback)
    hotkey.RegisterCallback("pos", binds.pos.keys, binds.pos.callback)
    hotkey.RegisterCallback("navodki", binds.navodki.keys, binds.navodki.callback)

    sampRegisterChatCommand("pos", function()
        mainIni.pos.x, mainIni.pos.y, mainIni.pos.z = getCharCoordinates(PLAYER_PED)
        inicfg.save(mainIni, "AHelper.ini")
        toast.Show(u8"Вы сохранили свой пост, для телепорта - Page Down", toast.TYPE.INFO, 7, ColorNotification())
    end)
    sampRegisterChatCommand("ahelp", function() 
        config.mainWindow[0] = not config.mainWindow[0]
    end)

    sampAddChatMessage(string.format("[Admin Helper]{FFFFFF} успешно загружен. Активация меню: {7FFFD4}%s", hotkey.GetBindKeys(decodeJson(mainIni.keys.menu))), 0x7FFFD4)

    if sampIsLocalPlayerSpawned() and config.togphone[0] then sampSendChat("/togphone") end

--========================================================WHILE TRUE========================================================

    while true do wait(0)
        sw, sh = getScreenResolution()
        if getCharHealth(PLAYER_PED) < 100 and config.hp[0] then sampSendChat("/hp") end

        if config.checker.setting then
            mainIni.checker.posX, mainIni.checker.posY = getCursorPos()            
        end

        if config.checker.actived[0] then
            local text = "Администрация онлайн:\n"
            for id = 0, 999 do
                if sampIsPlayerConnected(id) then
                    if admins[mainIni.serverInfo.serverPort] then
                        for name, post in pairs(admins[mainIni.serverInfo.serverPort]) do
                            if sampGetPlayerNickname(id) == name then
                                text = string.format("%s%s[%s] - %s\n", text, name, id, post)                            
                            end
                        end
                    else
                        toast.Show(u8"Ошибка в получении данных сервера.", toast.TYPE.INFO, 7, ColorNotification())
                        config.checker.actived[0] = false   
                        break                     
                    end
                end
            end
            renderFontDrawText(fontAdm, text, mainIni.checker.posX, mainIni.checker.posY, 0xFFFFFFFF) 
        end

        if config.carInfo.actived[0] then            
            for k, veh in ipairs(getAllVehicles()) do
                if isCarOnScreen(veh) then
                    if vehicle[getCarModel(veh)] then
                        local cx, cy, cz = getCarCoordinates(veh)
                        local x, y = convert3DCoordsToScreen(cx, cy, cz+0.5) 
                        local text = 
                            (config.carInfo.data.model[0] and string.format("Model: %s | ", vehicle[getCarModel(veh)].name) or "") ..
                            (config.carInfo.data.id[0] and string.format("ID: %s", select(2, sampGetVehicleIdByCarHandle(veh))) or "") .. 
                            (config.carInfo.data.engine[0] and string.format("\nДвигатель: %s", isCarEngineOn(veh) and "Включен" or "Выключен") or "") .. 
                            (config.carInfo.data.hp[0] and string.format("\nHP: %s", getCarHealth(veh)) or "") ..
                            (config.carInfo.data.dist[0] and string.format("\nДистацния: %s", math.floor(getDistanceBetweenCoords3d(cx, cy, cz, getCharCoordinates(PLAYER_PED)))) or "")                              
                                                                                                                                                                                 
                        renderFontDrawText(fontCarInfo, text, x, y, 0xFFFFFFFF) 
                    end                                      
                end
            end
        end

        if isKeyJustPressed(161) and config.airbreak.actived[0] then 
            config.airbreak.AirBreak = not config.airbreak.AirBreak 
            setCharCollision(PLAYER_PED, not config.airbreak.AirBreak)
        end
        if config.airbreak.actived[0] and config.airbreak.AirBreak then            
            if not isKeyDown(161) and not isCharInAnyCar(PLAYER_PED) then
                local x, y, z = getCharCoordinates(PLAYER_PED)
                local camX, camY, camZ = getActiveCameraCoordinates()
                local head = math.rad(getHeadingFromVector2d(x-camX, y-camY))
                if isKeyDown(87) and not sampIsCursorActive() then
                    x = x-math.sin(-head+3.14)*config.airbreak.speed[0]
                    y = y-math.cos(-head+3.14)*config.airbreak.speed[0]
                elseif isKeyDown(83) and not sampIsCursorActive() then
                    x = x+math.sin(-head+3.14)*config.airbreak.speed[0]
                    y = y+math.cos(-head+3.14)*config.airbreak.speed[0]
                end

                if isKeyDown(65) and not sampIsCursorActive() then
                    local head = math.rad(math.deg(head)+90)
                    x = x-math.sin(-head+3.14)*config.airbreak.speed[0]
                    y = y-math.cos(-head+3.14)*config.airbreak.speed[0]
                elseif isKeyDown(68) and not sampIsCursorActive() then
                    local head = math.rad(math.deg(head)-90)
                    x = x-math.sin(-head+3.14)*config.airbreak.speed[0]
                    y = y-math.cos(-head+3.14)*config.airbreak.speed[0]
                end

                if isKeyDown(81) and not sampIsCursorActive() then                    
                    z = z-config.airbreak.speed[0]                    
                elseif isKeyDown(69) and not sampIsCursorActive() then                    
                    z = z+config.airbreak.speed[0]                    
                end                                        
                                
                setCharHeading(PLAYER_PED, math.deg(head))
                setCharCoordinates(PLAYER_PED, x, y, z-1)                    
            end
        end
    end
end

--========================================================FUNCTION========================================

local mainFrame = imgui.OnFrame(
    function() return config.mainWindow[0] end,
    function(player)
        imgui.SetNextWindowPos(imgui.ImVec2(sw / 2, sh / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
        imgui.SetNextWindowSize(imgui.ImVec2(950, 577), imgui.Cond.FirstUseEver) 

        imgui.Begin("Admin Helper", nil, imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize)
        
        imgui.BeginGroup()
            imgui.BeginChild("Groups", imgui.ImVec2(170, -1), true)                
                if imgui.Button(fa.ARROWS_ROTATE, imgui.ImVec2(37, 24)) then thisScript():reload() end
                imgui.SameLine()        
                if imgui.Button(fa.POWER_OFF, imgui.ImVec2(37, 24)) then thisScript():unload() end
                imgui.SameLine()
                if imgui.Button(fa.DOWNLOAD, imgui.ImVec2(37, 24)) then 
                    downloadUrlToFile("https://raw.githubusercontent.com/egaaaaaaaaaaaaaaaaa/AHelper-Namalsk-RP/main/release/AHelper.lua", getWorkingDirectory() .. "/AHelper.lua", function(id, status)
                        if status == downloadStatus.STATUS_ENDDOWNLOADDATA then
                            toast.Show(string.format(u8"Скрипт успешно обновлен", thisScript().version), toast.TYPE.INFO, 7, ColorNotification())
                        end
                    end)
                end

                imgui.Separator()
                imgui.CustomMenu({u8"Настройки", u8"Дополнительно", u8"Кнопочки", u8"Информация"}, config.page, imgui.ImVec2(130, 45))                
            imgui.EndChild()
        imgui.EndGroup()
        
        imgui.SameLine()        
        imgui.BeginChild("Main", imgui.ImVec2(-1, -1), true)
            if config.page[0] == 1 then
                imgui.SetCursorPosX(70)
                if imgui.HeaderButton(config.header.setting[1][0], header_name.setting[1]) then
                    config.header.setting[1][0] = true
                    config.header.setting[2][0] = false
                    config.header.setting[3][0] = false
                    config.header.setting[4][0] = false
                end
                imgui.SameLine()
                if imgui.HeaderButton(config.header.setting[2][0], header_name.setting[2]) then
                    config.header.setting[1][0] = false
                    config.header.setting[2][0] = true
                    config.header.setting[3][0] = false
                    config.header.setting[4][0] = false
                end
                imgui.SameLine()
                if imgui.HeaderButton(config.header.setting[3][0], header_name.setting[3]) then
                    config.header.setting[1][0] = false
                    config.header.setting[2][0] = false
                    config.header.setting[3][0] = true
                    config.header.setting[4][0] = false
                end
                imgui.SameLine()
                if imgui.HeaderButton(config.header.setting[4][0], header_name.setting[4]) then
                    config.header.setting[1][0] = false
                    config.header.setting[2][0] = false
                    config.header.setting[3][0] = false
                    config.header.setting[4][0] = true
                end

                imgui.SetCursorPos(imgui.ImVec2(30, 50))
                imgui.BeginGroup()
                    if config.header.setting[1][0] then                                       
                        imgui.Text(u8"Настройки Wallhack")
                        if imgui.Checkbox(u8"Включить/Выключить##wh", config.wallhack.actived) then
                            toast.Show(config.wallhack.actived[0] and u8"Скрипт WALLHACK успешно включён" or u8"Скрипт WALLHACK успешно выключен", toast.TYPE.INFO, 7, ColorNotification())
                            mainIni.wallhack.actived = config.wallhack.actived[0]
                            inicfg.save(mainIni, "AHelper.ini")
                        end
                        
                        imgui.Separator()
                        imgui.Text(u8"Настройки Afly")
                        if imgui.Checkbox(u8"Включить/Выключить##afly", config.afly) then
                            toast.Show(config.afly[0] and u8"Скрипт AFLY успешно включён" or u8"Скрипт AFLY успешно выключен", toast.TYPE.INFO, 7, ColorNotification())
                            mainIni.config.afly = config.afly[0]
                            inicfg.save(mainIni, "AHelper.ini")
                        end                       

                    elseif config.header.setting[2][0] then                    
                        imgui.BeginChild("Наводки", imgui.ImVec2(550, 150), true)                        
                            imgui.Text(u8"Настройки: Наводки")
                            imgui.SetCursorPos(imgui.ImVec2(0, 37))
                            imgui.Separator()
                            imgui.Text(u8"Принимать наводки:")
                            imgui.SameLine()
                            if imgui.Checkbox(u8"##Navodki", config.navodki.actived) then
                                toast.Show(config.navodki[0] and u8"Наводки включены" or u8"Наводки выключены", toast.TYPE.INFO, 7, ColorNotification())
                                mainIni.navodki.actived = config.navodki.actived[0]
                                inicfg.save(mainIni, "AHelper.ini")
                            end

                            imgui.Text(u8"Клавиша для принятия наводок:")
                            imgui.SameLine()
                            local NewKeys_Navodki = hotkey.KeyEditor("navodki", nil, imgui.ImVec2(100,25))
                            if NewKeys_Navodki then
                                toast.Show(u8"Бинд изменен на: " .. hotkey.GetBindKeys(NewKeys_Navodki), toast.TYPE.INFO, 7, ColorNotification())
                                mainIni.keys.navodki = encodeJson(NewKeys_Navodki)
                                inicfg.save(mainIni, "AHelper.ini")
                            end                        
                            
                            imgui.Text(u8"Времени на отклик (мс)")
                            imgui.SameLine()
                            if imgui.InputInt("##Time", config.navodki.time, sizeof(config.navodki.time)) then
                                mainIni.navodki.time = config.navodki.time[0]
                                inicfg.save(mainIni, "AHelper.ini")
                            end
                        imgui.EndChild()

                        imgui.BeginChild("CarInfo", imgui.ImVec2(550, 220), true) 
                            imgui.Text(u8"Настройки: CarInfo")
                            imgui.Separator()
                            imgui.Text("CarInfo")
                            imgui.SameLine()                        
                            if imgui.Checkbox(u8"##CarInfo", config.carInfo.actived) then
                                toast.Show(config.carInfo.actived[0] and u8"CarInfo включен" or u8"CarInfo выключен", toast.TYPE.INFO, 7, ColorNotification())
                                mainIni.carInfo.actived = config.carInfo.actived[0]
                                inicfg.save(mainIni, "AHelper.ini")
                            end

                            for name, state in pairs(config.carInfo.data) do
                                if imgui.ToggleButton(tostring(name), state) then
                                    mainIni.carInfo[name] = state[0]
                                    inicfg.save(mainIni, "AHelper.ini")
                                end
                            end
                        imgui.EndChild()

                    elseif config.header.setting[3][0] then                    
                        imgui.Text(u8"Настройки серверных приколюх")
                        if imgui.Checkbox(u8"Выключать телефон автоматически при входе", config.togphone) then
                            toast.Show(config.togphone[0] and u8"Теперь при заходе на сервер у вас будет отключаться телефон" or u8"Теперь при заходе на сервер у вас будет включаться телефон", toast.TYPE.INFO, 7, ColorNotification())
                            mainIni.config.togphone = config.togphone[0]
                            inicfg.save(mainIni, "AHelper.ini")
                        end

                        if imgui.Checkbox(u8"Автомат.пополнение ХП", config.hp) then
                            toast.Show(config.hp[0] and u8"Автоматическое поплнение ХП включено" or u8"Автоматическое поплнение ХП выключено", toast.TYPE.INFO, 7, ColorNotification())
                            mainIni.config.hp = config.hp[0]
                            inicfg.save(mainIni, "AHelper.ini")
                        end

                        imgui.Separator()
                        imgui.Text(u8"Настройки чекера СА")
                        if imgui.Checkbox(u8"Включить/Выключить чекер", config.checker.actived) then
                            toast.Show(config.checker.actived[0] and u8"Чекер СА успешно включён" or u8"Чекер СА успешно выключен", toast.TYPE.INFO, 7, ColorNotification())
                            mainIni.checker.actived = config.checker.actived[0]
                            inicfg.save(mainIni, "AHelper.ini")
                        end
                        imgui.SameLine()
                        if imgui.Button(fa.UP_DOWN_LEFT_RIGHT) and config.checker.actived[0] then
                            lua_thread.create(function()
                                config.mainWindow[0] = false
                                wait(0)
                                showCursor(true)
                                config.checker.setting = true
                            end)
                        end
                    else                        
                        imgui.BeginChild("Интерфейс", imgui.ImVec2(-1, 160), true)                        
                            imgui.PushItemWidth(200)
                            if imgui.Combo(u8"Выбор темы", config.style, config.style_combo, #style_list) then
                                mainIni.style.theme = config.style[0]
                                inicfg.save(mainIni, "AHelper.ini")
                                Style()
                            end

                            if imgui.Combo(u8"Стиль элементов", config.twist, config.twist_combo, #twist_list) then
                                mainIni.style.twist = config.twist[0]
                                inicfg.save(mainIni, "AHelper.ini")
                                Style()
                            end

                            imgui.Separator()
                            imgui.Text(u8"Клавиша для открытия меню:")
                            imgui.SameLine()
                            imgui.SetCursorPosX(267)
                            local NewKeys_Menu = hotkey.KeyEditor("menu", nil, imgui.ImVec2(100,25))
                            if NewKeys_Menu then
                                toast.Show(u8"Бинд изменен на: " .. hotkey.GetBindKeys(NewKeys_Menu), toast.TYPE.INFO, 7, ColorNotification())                            
                                mainIni.keys.menu = encodeJson(NewKeys_Menu)
                                inicfg.save(mainIni, "AHelper.ini")
                            end

                            imgui.Separator()
                            imgui.Text(u8"Клавиша для телепортирования на пост:")
                            imgui.SameLine()
                            local NewKeys_pos = hotkey.KeyEditor("pos", nil, imgui.ImVec2(100,25))
                            if NewKeys_pos then
                                toast.Show(u8"Бинд изменен на: " .. hotkey.GetBindKeys(NewKeys_pos), toast.TYPE.INFO, 7, ColorNotification())
                                mainIni.keys.pos = encodeJson(NewKeys_pos)
                                inicfg.save(mainIni, "AHelper.ini")
                            end
                        imgui.EndChild()
                    end
                imgui.EndGroup()

            elseif config.page[0] == 2 then
                imgui.SetCursorPosX(220)
                if imgui.HeaderButton(config.header.additionally[1][0], header_name.additionally[1]) then
                    config.header.additionally[1][0] = true
                    config.header.additionally[2][0] = false
                end
                imgui.SameLine()
                if imgui.HeaderButton(config.header.additionally[2][0], header_name.additionally[2]) then
                    config.header.additionally[1][0] = false
                    config.header.additionally[2][0] = true
                end

                imgui.SetCursorPos(imgui.ImVec2(30, 50))
                if config.header.additionally[1][0] then                    
                    imgui.BeginChild("AirBreak", imgui.ImVec2(300, 110), true)
                        imgui.Text(u8"Настройки: AirBreak")
                        imgui.BeginGroup()
                            imgui.Separator()
                            imgui.SetCursorPos(imgui.ImVec2(221, 45))
                            if imgui.Checkbox("##airbreak", config.airbreak.actived) then --создаём крч бокс на аир(галочка)
                                mainIni.airbreak.actived = config.airbreak.actived[0]
                                inicfg.save(mainIni, "AHelper.ini")
                                toast.Show(config.airbreak.actived[0] and u8"Скрипт Airbreake успешно включён" or u8"Скрипт Airbreake успешкно выключен", toast.TYPE.INFO, 7, ColorNotification())
                            end

                            imgui.PushItemWidth(200)
                            imgui.SetCursorPos(imgui.ImVec2(15, 45))
                            if imgui.SliderFloat("##SpeedAirBreak", config.airbreak.speed, 0.1, 10, "%.1f") then
                                mainIni.airbreak.speed = config.airbreak.speed[0]
                                inicfg.save(mainIni, "AHelper.ini")
                            end
                        imgui.EndGroup()
                    imgui.EndChild()
                else

                end
                
            elseif config.page[0] == 3 then                 
                for k, button in ipairs(fastButton) do
                    if button.name == "Slap Down" then
                        imgui.SetCursorPos(imgui.ImVec2(imgui.GetWindowWidth() - 207, 184))
                    end
                    if imgui.Button(u8(button.name), imgui.ImVec2(160, button.name:find("Slap") and 25 or 60)) then
                        button.func()
                    end
                    if k % 4 ~= 0 then imgui.SameLine() end                       
                end
            else
                imgui.BeginChild("Информация", nil, false)
                    imgui.CenterText(u8"Информация по скрипту для Администрации Namalsk RolePlay - Admin Helper")                    
                    imgui.Separator()
                    imgui.CenterText(u8"Для начала сразу скажу, что да, это копия Atools но со своими доработками.")
                    imgui.CenterText(u8"В данный скрипт во первых был добавлен телепорт на пост для 1 lvl's, НО!.")
                    imgui.CenterText(u8"Для 1 lvl's админов повышенный античит, поэтому на дальних дистанциях - кик.")
                    imgui.CenterText(u8"Данный скрипт не будет как то у вас переставать работать или ещё что-то подобное.")
                    imgui.CenterText(u8"Пока что это лишь ранняя версия скрипта, она будет дорабатываться.")
                    imgui.Separator()
                    imgui.CenterText(u8"Версия скрипта v2.0 от 4.01.2023.")
                    imgui.CenterText(u8"Разработкой скрипта занимались: Bruno_Hardware(Postin) | Ega_Kotikov | Jeremy_Rosalez.")                    
                imgui.EndChild()
            end
        imgui.EndChild()

        imgui.End()
    end
)

local spFrame = imgui.OnFrame(
    function() return config.spWindow[0] and not isGamePaused() end,
    function(player)
        imgui.SetNextWindowPos(imgui.ImVec2(sw/2, sh - 80), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
        imgui.SetNextWindowSize(imgui.ImVec2(880, 130), imgui.Cond.FirstUseEver) 
        imgui.Begin(u8"sp", nil, imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.NoMove)
        
        player.HideCursor = spInfo.cursor

        for k, button in ipairs(spButton.sendChat) do
            if imgui.Button(u8(button.text), imgui.ImVec2(130, 25)) then
                sampSendChat(string.format("/%s %s", button.send, spInfo.id))
            end

            if k % 6 ~= 0 then imgui.SameLine() end
        end

        for k, button in ipairs(spButton.func) do
            if imgui.Button(u8(button.text), imgui.ImVec2(130, 25)) then
                button.func()
            end            
        end

        imgui.SetCursorPosY(imgui.GetWindowSize().y - 30)
        imgui.Text(fa.ANGLE_LEFT)
        if imgui.IsItemClicked(0) then
            spInfo.id = spInfo.id-1
            sampSendChat(string.format("/re %s", spInfo.id))
        end
        imgui.SameLine(imgui.GetWindowWidth()-34)
        imgui.Text(fa.ANGLE_RIGHT)
        if imgui.IsItemClicked(0) then
            spInfo.id = spInfo.id+1
            sampSendChat(string.format("/re %s", spInfo.id))
        end

        imgui.End()
    end
)
--========================================================IMGUI========================================================

imgui.OnInitialize(function()
    fa.Init()
    imgui.GetIO().IniFilename = nil
    imgui.GetStyle().WindowTitleAlign = imgui.ImVec2(0.5, 0.5)
    Style()
end)

function Style()
    local style = imgui.GetStyle()
    local colors = style.Colors
    local clr = imgui.Col
    local ImVec4 = imgui.ImVec4
    
    style.WindowRounding = mainIni.style.twist ~= 1 and 15 or 5
    style.FrameRounding = mainIni.style.twist ~= 1 and 7 or 3
    style.ScrollbarRounding =  mainIni.style.twist ~= 1 and 9 or 3
    style.GrabRounding =  mainIni.style.twist ~= 1 and 3 or 1
    style.ChildRounding =  mainIni.style.twist ~= 1 and 10 or 3

    style.WindowPadding = imgui.ImVec2(15, 15)    
    style.FramePadding = imgui.ImVec2(3, 3)
    style.ItemSpacing = imgui.ImVec2(12, 8)
    style.ItemInnerSpacing = imgui.ImVec2(8, 6)
    style.IndentSpacing = 25.0
    style.ScrollbarSize = 15.0
    style.GrabMinSize = 5.0
    
    if mainIni.style.theme == 0 then
        colors[clr.Text] = ImVec4(0.80, 0.80, 0.83, 1.00)
        colors[clr.TextDisabled] = ImVec4(0.24, 0.23, 0.29, 1.00)
        colors[clr.WindowBg] = ImVec4(0.06, 0.05, 0.07, 1.00)
        colors[clr.ChildBg] = ImVec4(0.06, 0.05, 0.07, 1.00)
        colors[clr.PopupBg] = ImVec4(0.07, 0.07, 0.09, 1.00)
        colors[clr.FrameBg] = ImVec4(0.10, 0.09, 0.12, 1.00)
        colors[clr.FrameBgHovered] = ImVec4(0.24, 0.23, 0.29, 1.00)
        colors[clr.FrameBgActive] = ImVec4(0.56, 0.56, 0.58, 1.00)
        colors[clr.TitleBg] = ImVec4(0.10, 0.09, 0.12, 1.00)
        colors[clr.TitleBgCollapsed] = ImVec4(1.00, 0.98, 0.95, 0.75)
        colors[clr.TitleBgActive] = ImVec4(0.07, 0.07, 0.09, 1.00)
        colors[clr.MenuBarBg] = ImVec4(0.10, 0.09, 0.12, 1.00)
        colors[clr.ScrollbarBg] = ImVec4(0.10, 0.09, 0.12, 1.00)
        colors[clr.ScrollbarGrab] = ImVec4(0.80, 0.80, 0.83, 0.31)
        colors[clr.ScrollbarGrabHovered] = ImVec4(0.56, 0.56, 0.58, 1.00)
        colors[clr.ScrollbarGrabActive] = ImVec4(0.06, 0.05, 0.07, 1.00)
        colors[clr.CheckMark] = ImVec4(0.80, 0.80, 0.83, 0.31)
        colors[clr.SliderGrab] = ImVec4(0.80, 0.80, 0.83, 0.31)
        colors[clr.SliderGrabActive] = ImVec4(0.06, 0.05, 0.07, 1.00)
        colors[clr.Button] = ImVec4(0.10, 0.09, 0.12, 1.00)
        colors[clr.ButtonHovered] = ImVec4(0.24, 0.23, 0.29, 1.00)
        colors[clr.ButtonActive] = ImVec4(0.56, 0.56, 0.58, 1.00)
        colors[clr.Header] = ImVec4(0.10, 0.09, 0.12, 1.00)
        colors[clr.HeaderHovered] = ImVec4(0.56, 0.56, 0.58, 1.00)
        colors[clr.HeaderActive] = ImVec4(0.06, 0.05, 0.07, 1.00)
        colors[clr.ResizeGrip] = ImVec4(0.00, 0.00, 0.00, 0.00)
        colors[clr.ResizeGripHovered] = ImVec4(0.56, 0.56, 0.58, 1.00)
        colors[clr.ResizeGripActive] = ImVec4(0.06, 0.05, 0.07, 1.00)
        colors[clr.PlotLines] = ImVec4(0.40, 0.39, 0.38, 0.63)
        colors[clr.PlotLinesHovered] = ImVec4(0.25, 1.00, 0.00, 1.00)
        colors[clr.PlotHistogram] = ImVec4(0.40, 0.39, 0.38, 0.63)
        colors[clr.PlotHistogramHovered] = ImVec4(0.25, 1.00, 0.00, 1.00)
        colors[clr.TextSelectedBg] = ImVec4(0.25, 1.00, 0.00, 0.43)

    elseif mainIni.style.theme == 1 then
        colors[clr.Text] = ImVec4(0.86, 0.93, 0.89, 0.78)
        colors[clr.TextDisabled] = ImVec4(0.36, 0.42, 0.47, 1.00)
        colors[clr.WindowBg] = ImVec4(0.11, 0.15, 0.17, 1.00)
        colors[clr.ChildBg] = ImVec4(0.11, 0.15, 0.17, 1.00)
        colors[clr.PopupBg] = ImVec4(0.08, 0.08, 0.08, 0.94)
        colors[clr.Border] = ImVec4(0.43, 0.43, 0.50, 0.50)
        colors[clr.BorderShadow] = ImVec4(0.00, 0.00, 0.00, 0.00)
        colors[clr.FrameBg] = ImVec4(0.20, 0.25, 0.29, 1.00)
        colors[clr.FrameBgHovered] = ImVec4(0.12, 0.20, 0.28, 1.00)
        colors[clr.FrameBgActive] = ImVec4(0.09, 0.12, 0.14, 1.00)
        colors[clr.TitleBg] = ImVec4(0.04, 0.04, 0.04, 1.00)
        colors[clr.TitleBgActive] = ImVec4(0.16, 0.48, 0.42, 1.00)
        colors[clr.TitleBgCollapsed] = ImVec4(0.00, 0.00, 0.00, 0.51)
        colors[clr.MenuBarBg] = ImVec4(0.15, 0.18, 0.22, 1.00)
        colors[clr.ScrollbarBg] = ImVec4(0.02, 0.02, 0.02, 0.39)
        colors[clr.ScrollbarGrab] = ImVec4(0.20, 0.25, 0.29, 1.00)
        colors[clr.ScrollbarGrabHovered] = ImVec4(0.18, 0.22, 0.25, 1.00)
        colors[clr.ScrollbarGrabActive] = ImVec4(0.09, 0.21, 0.31, 1.00)
        colors[clr.CheckMark] = ImVec4(0.26, 0.98, 0.85, 1.00)
        colors[clr.SliderGrab] = ImVec4(0.24, 0.88, 0.77, 1.00)
        colors[clr.SliderGrabActive] = ImVec4(0.26, 0.98, 0.85, 1.00)
        colors[clr.Button] = ImVec4(0.26, 0.98, 0.85, 0.30)
        colors[clr.ButtonHovered] = ImVec4(0.26, 0.98, 0.85, 0.50)
        colors[clr.ButtonActive] = ImVec4(0.06, 0.98, 0.82, 0.50)
        colors[clr.Header] = ImVec4(0.26, 0.98, 0.85, 0.31)
        colors[clr.HeaderHovered] = ImVec4(0.26, 0.98, 0.85, 0.80)
        colors[clr.HeaderActive] = ImVec4(0.26, 0.98, 0.85, 1.00)   
        colors[clr.Separator] = ImVec4(0.50, 0.50, 0.50, 1.00)
        colors[clr.SeparatorHovered] = ImVec4(0.60, 0.60, 0.70, 1.00)
        colors[clr.SeparatorActive] = ImVec4(0.70, 0.70, 0.90, 1.00)
        colors[clr.ResizeGrip] = ImVec4(0.26, 0.59, 0.98, 0.25)
        colors[clr.ResizeGripHovered] = ImVec4(0.26, 0.59, 0.98, 0.67)
        colors[clr.ResizeGripActive] = ImVec4(0.06, 0.05, 0.07, 1.00)
        colors[clr.PlotLines] = ImVec4(0.61, 0.61, 0.61, 1.00)
        colors[clr.PlotLinesHovered] = ImVec4(1.00, 0.43, 0.35, 1.00)
        colors[clr.PlotHistogram] = ImVec4(0.90, 0.70, 0.00, 1.00)
        colors[clr.PlotHistogramHovered] = ImVec4(1.00, 0.60, 0.00, 1.00)
        colors[clr.TextSelectedBg] = ImVec4(0.25, 1.00, 0.00, 0.43)
        
    elseif mainIni.style.theme == 2 then
        colors[clr.FrameBg] = ImVec4(0.48, 0.16, 0.16, 0.54)
        colors[clr.FrameBgHovered] = ImVec4(0.98, 0.26, 0.26, 0.40)
        colors[clr.FrameBgActive] = ImVec4(0.98, 0.26, 0.26, 0.67)
        colors[clr.TitleBg] = ImVec4(0.04, 0.04, 0.04, 1.00)
        colors[clr.TitleBgActive] = ImVec4(0.48, 0.16, 0.16, 1.00)
        colors[clr.TitleBgCollapsed] = ImVec4(0.00, 0.00, 0.00, 0.51)
        colors[clr.CheckMark] = ImVec4(0.98, 0.26, 0.26, 1.00)
        colors[clr.SliderGrab] = ImVec4(0.88, 0.26, 0.24, 1.00)
        colors[clr.SliderGrabActive] = ImVec4(0.98, 0.26, 0.26, 1.00)
        colors[clr.Button] = ImVec4(0.98, 0.26, 0.26, 0.40)
        colors[clr.ButtonHovered] = ImVec4(0.98, 0.26, 0.26, 1.00)
        colors[clr.ButtonActive] = ImVec4(0.98, 0.06, 0.06, 1.00)
        colors[clr.Header] = ImVec4(0.98, 0.26, 0.26, 0.31)
        colors[clr.HeaderHovered] = ImVec4(0.98, 0.26, 0.26, 0.80)
        colors[clr.HeaderActive] = ImVec4(0.98, 0.26, 0.26, 1.00)
        colors[clr.Separator] = colors[clr.Border]
        colors[clr.SeparatorHovered] = ImVec4(0.75, 0.10, 0.10, 0.78)
        colors[clr.SeparatorActive] = ImVec4(0.75, 0.10, 0.10, 1.00)
        colors[clr.ResizeGrip] = ImVec4(0.98, 0.26, 0.26, 0.25)
        colors[clr.ResizeGripHovered] = ImVec4(0.98, 0.26, 0.26, 0.67)
        colors[clr.ResizeGripActive] = ImVec4(0.98, 0.26, 0.26, 0.95)
        colors[clr.TextSelectedBg] = ImVec4(0.98, 0.26, 0.26, 0.35)
        colors[clr.Text] = ImVec4(1.00, 1.00, 1.00, 1.00)
        colors[clr.TextDisabled] = ImVec4(0.50, 0.50, 0.50, 1.00)
        colors[clr.WindowBg] = ImVec4(0.06, 0.06, 0.06, 0.94)
        colors[clr.ChildBg] = ImVec4(1.00, 1.00, 1.00, 0.00)
        colors[clr.PopupBg] = ImVec4(0.08, 0.08, 0.08, 0.94)
        colors[clr.Border] = ImVec4(0.43, 0.43, 0.50, 0.50)
        colors[clr.BorderShadow] = ImVec4(0.00, 0.00, 0.00, 0.00)
        colors[clr.MenuBarBg] = ImVec4(0.14, 0.14, 0.14, 1.00)
        colors[clr.ScrollbarBg] = ImVec4(0.02, 0.02, 0.02, 0.53)
        colors[clr.ScrollbarGrab] = ImVec4(0.31, 0.31, 0.31, 1.00)
        colors[clr.ScrollbarGrabHovered] = ImVec4(0.41, 0.41, 0.41, 1.00)
        colors[clr.ScrollbarGrabActive] = ImVec4(0.51, 0.51, 0.51, 1.00)
        colors[clr.PlotLines] = ImVec4(0.61, 0.61, 0.61, 1.00)
        colors[clr.PlotLinesHovered] = ImVec4(1.00, 0.43, 0.35, 1.00)
        colors[clr.PlotHistogram] = ImVec4(0.90, 0.70, 0.00, 1.00)
        colors[clr.PlotHistogramHovered] = ImVec4(1.00, 0.60, 0.00, 1.00)

    elseif mainIni.style.theme == 3 then
        colors[clr.Text] = ImVec4(0.86, 0.93, 0.89, 0.78)
        colors[clr.TextDisabled] = ImVec4(0.36, 0.42, 0.47, 1.00)
        colors[clr.WindowBg] = ImVec4(0.11, 0.15, 0.17, 1.00)
        colors[clr.PopupBg] = ImVec4(0.08, 0.08, 0.08, 0.94)
        colors[clr.Border] = ImVec4(0.43, 0.43, 0.50, 0.50)
        colors[clr.BorderShadow] = ImVec4(0.00, 0.00, 0.00, 0.00)
        colors[clr.FrameBg] = ImVec4(0.20, 0.25, 0.29, 1.00)
        colors[clr.FrameBgHovered] = ImVec4(0.19, 0.12, 0.28, 1.00)
        colors[clr.FrameBgActive] = ImVec4(0.09, 0.12, 0.14, 1.00)
        colors[clr.TitleBg] = ImVec4(0.04, 0.04, 0.04, 1.00)
        colors[clr.TitleBgActive] = ImVec4(0.41, 0.19, 0.63, 1.00)
        colors[clr.TitleBgCollapsed] = ImVec4(0.00, 0.00, 0.00, 0.51)
        colors[clr.MenuBarBg] = ImVec4(0.15, 0.18, 0.22, 1.00)
        colors[clr.ScrollbarBg] = ImVec4(0.02, 0.02, 0.02, 0.39)
        colors[clr.ScrollbarGrab] = ImVec4(0.20, 0.25, 0.29, 1.00)
        colors[clr.ScrollbarGrabHovered] = ImVec4(0.18, 0.22, 0.25, 1.00)
        colors[clr.ScrollbarGrabActive] = ImVec4(0.20, 0.09, 0.31, 1.00)
        colors[clr.CheckMark] = ImVec4(0.59, 0.28, 1.00, 1.00)
        colors[clr.SliderGrab] = ImVec4(0.41, 0.19, 0.63, 1.00)
        colors[clr.SliderGrabActive] = ImVec4(0.41, 0.19, 0.63, 1.00)
        colors[clr.Button] = ImVec4(0.41, 0.19, 0.63, 0.44)
        colors[clr.ButtonHovered] = ImVec4(0.41, 0.19, 0.63, 0.86)
        colors[clr.ButtonActive] = ImVec4(0.64, 0.33, 0.94, 1.00)
        colors[clr.Header] = ImVec4(0.20, 0.25, 0.29, 0.55)
        colors[clr.HeaderHovered] = ImVec4(0.51, 0.26, 0.98, 0.80)
        colors[clr.HeaderActive] = ImVec4(0.53, 0.26, 0.98, 1.00)
        colors[clr.Separator] = ImVec4(0.50, 0.50, 0.50, 1.00)
        colors[clr.SeparatorHovered] = ImVec4(0.60, 0.60, 0.70, 1.00)
        colors[clr.SeparatorActive] = ImVec4(0.70, 0.70, 0.90, 1.00)
        colors[clr.ResizeGrip] = ImVec4(0.59, 0.26, 0.98, 0.25)
        colors[clr.ResizeGripHovered] = ImVec4(0.61, 0.26, 0.98, 0.67)
        colors[clr.ResizeGripActive] = ImVec4(0.06, 0.05, 0.07, 1.00)
        colors[clr.PlotLines] = ImVec4(0.61, 0.61, 0.61, 1.00)
        colors[clr.PlotLinesHovered] = ImVec4(1.00, 0.43, 0.35, 1.00)
        colors[clr.PlotHistogram] = ImVec4(0.90, 0.70, 0.00, 1.00)
        colors[clr.PlotHistogramHovered] = ImVec4(1.00, 0.60, 0.00, 1.00)
        colors[clr.TextSelectedBg] = ImVec4(0.25, 1.00, 0.00, 0.43)

    elseif mainIni.style.theme == 4 then
        colors[clr.Text] = ImVec4(1.00, 1.00, 1.00, 1.00)
        colors[clr.TextDisabled] = ImVec4(0.60, 0.60, 0.60, 1.00)
        colors[clr.WindowBg] = ImVec4(0.09, 0.09, 0.09, 1.00)
        colors[clr.PopupBg] = ImVec4(0.09, 0.09, 0.09, 1.00)
        colors[clr.Border] = ImVec4(0.71, 0.71, 0.71, 0.40)
        colors[clr.BorderShadow] = ImVec4(9.90, 9.99, 9.99, 0.00)
        colors[clr.FrameBg] = ImVec4(0.34, 0.30, 0.34, 0.30)
        colors[clr.FrameBgHovered] = ImVec4(0.22, 0.21, 0.21, 0.40)
        colors[clr.FrameBgActive] = ImVec4(0.20, 0.20, 0.20, 0.44)
        colors[clr.TitleBg] = ImVec4(0.52, 0.27, 0.77, 0.82)
        colors[clr.TitleBgActive] = ImVec4(0.55, 0.28, 0.75, 0.87)
        colors[clr.TitleBgCollapsed] = ImVec4(9.99, 9.99, 9.90, 0.20)
        colors[clr.MenuBarBg] = ImVec4(0.27, 0.27, 0.29, 0.80)
        colors[clr.ScrollbarBg] = ImVec4(0.08, 0.08, 0.08, 0.60)
        colors[clr.ScrollbarGrab] = ImVec4(0.54, 0.20, 0.66, 0.30)
        colors[clr.ScrollbarGrabHovered] = ImVec4(0.21, 0.21, 0.21, 0.40)
        colors[clr.ScrollbarGrabActive] = ImVec4(0.80, 0.50, 0.50, 0.40)
        colors[clr.CheckMark] = ImVec4(0.89, 0.89, 0.89, 0.50)
        colors[clr.SliderGrab] = ImVec4(1.00, 1.00, 1.00, 0.30)
        colors[clr.SliderGrabActive] = ImVec4(0.80, 0.50, 0.50, 1.00)
        colors[clr.Button] = ImVec4(0.48, 0.25, 0.60, 0.60)
        colors[clr.ButtonHovered] = ImVec4(0.67, 0.40, 0.40, 1.00)
        colors[clr.ButtonActive] = ImVec4(0.80, 0.50, 0.50, 1.00)
        colors[clr.Header] = ImVec4(0.56, 0.27, 0.73, 0.44)
        colors[clr.HeaderHovered] = ImVec4(0.78, 0.44, 0.89, 0.80)
        colors[clr.HeaderActive] = ImVec4(0.81, 0.52, 0.87, 0.80)
        colors[clr.Separator] = ImVec4(0.42, 0.42, 0.42, 1.00)
        colors[clr.SeparatorHovered] = ImVec4(0.57, 0.24, 0.73, 1.00)
        colors[clr.SeparatorActive] = ImVec4(0.69, 0.69, 0.89, 1.00)
        colors[clr.ResizeGrip] = ImVec4(1.00, 1.00, 1.00, 0.30)
        colors[clr.ResizeGripHovered] = ImVec4(1.00, 1.00, 1.00, 0.60)
        colors[clr.ResizeGripActive] = ImVec4(1.00, 1.00, 1.00, 0.89)
        colors[clr.PlotLines] = ImVec4(1.00, 0.99, 0.99, 1.00)
        colors[clr.PlotLinesHovered] = ImVec4(0.49, 0.00, 0.89, 1.00)
        colors[clr.PlotHistogram] = ImVec4(9.99, 9.99, 9.90, 1.00)
        colors[clr.PlotHistogramHovered] = ImVec4(9.99, 9.99, 9.90, 1.00)
        colors[clr.TextSelectedBg] = ImVec4(0.54, 0.00, 1.00, 0.34)
    end
end

function ColorNotification()
    local customColors = {}
    if mainIni.style.theme == 0 then
        customColors = {
            back = {0.06, 0.05, 0.07, 1.00},
            text = {0.80, 0.80, 0.83, 1.00},
            icon = {0.80, 0.80, 0.83, 1.00},
            border = {0.06, 0.05, 0.07, 1.00}
        }
    elseif mainIni.style.theme == 1 then
        customColors = {
            back = {0.26, 0.98, 0.85, 0.30},
            text = {0.86, 0.93, 0.89, 0.78},
            icon = {0.86, 0.93, 0.89, 0.78},
            border = {0.26, 0.98, 0.85, 0.30}
        }
    elseif mainIni.style.theme == 2 then
        customColors = {
            back = {0.98, 0.06, 0.06, 1.00},
            text = {1.00, 1.00, 1.00, 1.00},
            icon = {1.00, 1.00, 1.00, 1.00},
            border = {0.98, 0.06, 0.06, 1.00}
        }
    elseif mainIni.style.theme == 3 then
        customColors = {
            back = {0.41, 0.19, 0.63, 0.44},
            text = {0.86, 0.93, 0.89, 0.78},
            icon = {0.86, 0.93, 0.89, 0.78},
            border = {0.41, 0.19, 0.63, 0.44}
        }
    else
        customColors = {
            back = {0.80, 0.50, 0.50, 1.00},
            text = {1.00, 1.00, 1.00, 1.00},
            icon = {1.00, 1.00, 1.00, 1.00},
            border = {0.80, 0.50, 0.50, 1.00}
        }
    end
    return customColors
end

--================================================================================================================

function imgui.ToggleButton(str_id, value)
    local AI_TOGGLE = {}
	local duration = 0.3
	local p = imgui.GetCursorScreenPos()
    local DL = imgui.GetWindowDrawList()
	local size = imgui.ImVec2(40, 20)
    local title = str_id:gsub("##.*$", "")
    local ts = imgui.CalcTextSize(title)
    local cols = {
    	enable = imgui.GetStyle().Colors[imgui.Col.ButtonActive],
    	disable = imgui.GetStyle().Colors[imgui.Col.TextDisabled]	
    }
    local radius = 6
    local o = {
    	x = 4,
    	y = p.y + (size.y / 2)
    }
    local A = imgui.ImVec2(p.x + radius + o.x, o.y)
    local B = imgui.ImVec2(p.x + size.x - radius - o.x, o.y)

    if AI_TOGGLE[str_id] == nil then
        AI_TOGGLE[str_id] = {
        	clock = nil,
        	color = value[0] and cols.enable or cols.disable,
        	pos = value[0] and B or A
        }
    end
    local pool = AI_TOGGLE[str_id]
    
    imgui.BeginGroup()
	    local pos = imgui.GetCursorPos()
	    local result = imgui.InvisibleButton(str_id, imgui.ImVec2(size.x, size.y))
	    if result then
	        value[0] = not value[0]
	        pool.clock = os.clock()
	    end
	    if #title > 0 then
		    local spc = imgui.GetStyle().ItemSpacing
		    imgui.SetCursorPos(imgui.ImVec2(pos.x + size.x + spc.x, pos.y + ((size.y - ts.y) / 2)))
	    	imgui.Text(title)
    	end
    imgui.EndGroup()

 	if pool.clock and os.clock() - pool.clock <= duration then
        pool.color = bringVec4To(
            imgui.ImVec4(pool.color),
            value[0] and cols.enable or cols.disable,
            pool.clock,
            duration
        )

        pool.pos = bringVec2To(
        	imgui.ImVec2(pool.pos),
        	value[0] and B or A,
        	pool.clock,
            duration
        )
    else
        pool.color = value[0] and cols.enable or cols.disable
        pool.pos = value[0] and B or A
    end

	DL:AddRect(p, imgui.ImVec2(p.x + size.x, p.y + size.y), ToU32(pool.color), 10, 15, 1)
	DL:AddCircleFilled(pool.pos, radius, ToU32(pool.color))

    return result
end

function imgui.CustomMenu(labels, selected, size, speed, centering)
    local bool = false
    speed = speed and speed or 0.2
    local radius = size.y * 0.50
    local draw_list = imgui.GetWindowDrawList()
    if LastActiveTime == nil then LastActiveTime = {} end
    if LastActive == nil then LastActive = {} end
    local function ImSaturate(f)
        return f < 0.0 and 0.0 or (f > 1.0 and 1.0 or f)
    end
    for i, v in ipairs(labels) do
        local c = imgui.GetCursorPos()
        local p = imgui.GetCursorScreenPos()
        if imgui.InvisibleButton(v.."##"..i, size) then
            selected[0] = i
            LastActiveTime[v] = os.clock()
            LastActive[v] = true
            bool = true
        end
        imgui.SetCursorPos(c)
        local t = selected[0] == i and 1.0 or 0.0
        if LastActive[v] then
            local time = os.clock() - LastActiveTime[v]
            if time <= 0.3 then
                local t_anim = ImSaturate(time / speed)
                t = selected[0] == i and t_anim or 1.0 - t_anim
            else
                LastActive[v] = false
            end
        end
        local col_bg = imgui.GetColorU32Vec4(selected[0] == i and imgui.GetStyle().Colors[imgui.Col.ButtonActive] or imgui.ImVec4(0,0,0,0))
        local col_box = imgui.GetColorU32Vec4(selected[0] == i and imgui.GetStyle().Colors[imgui.Col.Button] or imgui.ImVec4(0,0,0,0))
        local col_hovered = imgui.GetStyle().Colors[imgui.Col.ButtonHovered]
        local col_hovered = imgui.GetColorU32Vec4(imgui.ImVec4(col_hovered.x, col_hovered.y, col_hovered.z, (imgui.IsItemHovered() and 0.2 or 0)))
        draw_list:AddRectFilled(imgui.ImVec2(p.x-size.x/6, p.y), imgui.ImVec2(p.x + (radius * 0.65) + t * size.x, p.y + size.y), col_bg, 10.0)
        draw_list:AddRectFilled(imgui.ImVec2(p.x-size.x/6, p.y), imgui.ImVec2(p.x + (radius * 0.65) + size.x, p.y + size.y), col_hovered, 10.0)
        draw_list:AddRectFilled(imgui.ImVec2(p.x, p.y), imgui.ImVec2(p.x+5, p.y + size.y), col_box)
        imgui.SetCursorPos(imgui.ImVec2(c.x+(centering and (size.x-imgui.CalcTextSize(v).x)/2 or 15), c.y+(size.y-imgui.CalcTextSize(v).y)/2))
        imgui.Text(v)
        imgui.SetCursorPos(imgui.ImVec2(c.x, c.y+size.y))
    end
    return bool
end

function imgui.HeaderButton(bool, str_id)
    local AI_HEADERBUT = {}
    local DL = imgui.GetWindowDrawList()
    local result = false
    local label = string.gsub(str_id, "##.*$", "")
    local duration = { 0.5, 0.3 }
    local cols = {
        idle = imgui.GetStyle().Colors[imgui.Col.TextDisabled],
        hovr = imgui.GetStyle().Colors[imgui.Col.Text],
        slct = imgui.GetStyle().Colors[imgui.Col.ButtonActive]
    }
    
    if not AI_HEADERBUT[str_id] then
        AI_HEADERBUT[str_id] = {
            color = bool and cols.slct or cols.idle,
            clock = os.clock() + duration[1],
            h = {
                state = bool,
                alpha = bool and 1.00 or 0.00,
                clock = os.clock() + duration[2],
            }
        }
    end

    local pool = AI_HEADERBUT[str_id]
    imgui.BeginGroup()
    local pos = imgui.GetCursorPos()
    local p = imgui.GetCursorScreenPos()
    
    imgui.TextColored(pool.color, label)
    local s = imgui.GetItemRectSize()
    local hovered = isPlaceHovered(p, imgui.ImVec2(p.x + s.x, p.y + s.y))
    local clicked = imgui.IsItemClicked()
    
    if pool.h.state ~= hovered and not bool then
        pool.h.state = hovered
        pool.h.clock = os.clock()
    end
    
    if clicked then
        pool.clock = os.clock()
        result = true
    end
    
    if os.clock() - pool.clock <= duration[1] then
        pool.color = bringVec4To(
            imgui.ImVec4(pool.color),
            bool and cols.slct or (hovered and cols.hovr or cols.idle),
            pool.clock,
            duration[1]
        )
    else
        pool.color = bool and cols.slct or (hovered and cols.hovr or cols.idle)
    end
    
    if pool.h.clock then
        if os.clock() - pool.h.clock <= duration[2] then
            pool.h.alpha = bringFloatTo(
                pool.h.alpha,
                pool.h.state and 1.00 or 0.00,
                pool.h.clock,
                duration[2]
            )
        else
            pool.h.alpha = pool.h.state and 1.00 or 0.00
            if not pool.h.state then
                pool.h.clock = nil
            end
        end
        local max = s.x / 2
        local Y = p.y + s.y + 3
        local mid = p.x + max
        DL:AddLine(imgui.ImVec2(mid, Y), imgui.ImVec2(mid + (max * pool.h.alpha), Y), ToU32(set_alpha(pool.color, pool.h.alpha)), 3)
        DL:AddLine(imgui.ImVec2(mid, Y), imgui.ImVec2(mid - (max * pool.h.alpha), Y), ToU32(set_alpha(pool.color, pool.h.alpha)), 3)
    end
    
    imgui.EndGroup()
    return result
end

function imgui.CenterText(text)
    imgui.SetCursorPosX((imgui.GetWindowWidth() - imgui.CalcTextSize(text).x) / 2)
    imgui.Text(text)
end

function isPlaceHovered(a, b)
    local m = imgui.GetMousePos()
    if m.x >= a.x and m.y >= a.y then
        if m.x <= b.x and m.y <= b.y then
            return true
        end
    end
    return false
end

function set_alpha(color, alpha)
    alpha = alpha and limit(alpha, 0.0, 1.0) or 1.0
    return imgui.ImVec4(color.x, color.y, color.z, alpha)
end

function limit(v, min, max)
    min = min or 0.0
    max = max or 1.0
    return v < min and min or (v > max and max or v)
end
    
function bringFloatTo(from, to, start_time, duration)
    local timer = os.clock() - start_time
    if timer >= 0.00 and timer <= duration then
        local count = timer / (duration / 100)
        return from + (count * (to - from) / 100), true
    end
    return (timer > duration) and to or from, false
end
    
function bringVec4To(from, to, start_time, duration)
    local timer = os.clock() - start_time
    if timer >= 0.00 and timer <= duration then
        local count = timer / (duration / 100)
        return imgui.ImVec4(
            from.x + (count * (to.x - from.x) / 100),
            from.y + (count * (to.y - from.y) / 100),
            from.z + (count * (to.z - from.z) / 100),
            from.w + (count * (to.w - from.w) / 100)
        ), true
    end
    return (timer > duration) and to or from, false
end

function bringVec2To(from, to, start_time, duration)
    local timer = os.clock() - start_time
    if timer >= 0.00 and timer <= duration then
        local count = timer / (duration / 100)
        return imgui.ImVec2(
            from.x + (count * (to.x - from.x) / 100),
            from.y + (count * (to.y - from.y) / 100)
        ), true
    end
    return (timer > duration) and to or from, false
end 

--========================================================HOOK========================================================

function onScriptTerminate(scr, quitGame)
    if scr == thisScript() then
        if not quitGame then
            mainIni.serverInfo.serverIP, mainIni.serverInfo.serverPort = sampGetCurrentServerAddress()

            if config.airbreak.AirBreak and config.airbreak.actived[0] then
                setCharCollision(PLAYER_PED, true)
            end
        end        
    end
end

function onReceiveRpc(id, bs) 
    if id == 162 then
        config.mainWindow[0] = false
    end
end

function onReceivePacket(id, bs) 
    if id == 34 then
        serverIP = raknetBitStreamReadInt32(bs)
        serverPort = raknetBitStreamReadInt16(bs)
    end
end

function hook.onServerMessage(color, text)
    if config.navodki.actived[0] then
        for k, command in ipairs(TriggerCommand) do
            if text:find("%[A%] .+ %w+_%w+%[%d+%]: " .. command .. " %d+ .+") and config.navodki.actived[0] and not isGamePaused() then
                if text:find("%[A%] .+ %w+_%w+%[%d+%]: " .. command .. " %d+ .+ || .+") then
                    config.navodki.data.name, config.navodki.data.id, config.navodki.data.prichina = text:match("%[A%] .+ (%w+_%w+)%[%d+%]: " .. command .. " (%d+) (.+) || .+")
                elseif text:find("%[A%] .+ %w+_%w+%[%d+%]: " .. command .. " %d+ .+ | .+") then
                    config.navodki.data.name, config.navodki.data.id, config.navodki.data.prichina = text:match("%[A%] .+ (%w+_%w+)%[%d+%]: " .. command .. " (%d+) (.+) | .+")
                elseif text:find("%[A%] .+ %w+_%w+%[%d+%]: " .. command .. " %d+ .+ // .+") then
                    config.navodki.data.name, config.navodki.data.id, config.navodki.data.prichina = text:match("%[A%] .+ (%w+_%w+)%[%d+%]: " .. command .. " (%d+) (.+) // .+")
                elseif text:find("%[A%] .+ %w+_%w+%[%d+%]: " .. command .. " %d+ .+ / .+") then
                    config.navodki.data.name, config.navodki.data.id, config.navodki.data.prichina = text:match("%[A%] .+ (%w+_%w+)%[%d+%]: " .. command .. " (%d+) (.+) / .+")
                else
                    config.navodki.data.name, config.navodki.data.id, config.navodki.data.prichina = text:match("%[A%] .+ (%w+_%w+)%[%d+%]: " .. command .. " (%d+) (.+)")
                end
                toast.Show(string.format(u8"Пришла наводка от %s на %s", config.navodki.data.name, command), toast.TYPE.INFO, 5, ColorNotification())
                config.navodki.data.command = command
                lua_thread.create(function()
                    config.navodki.send = true
                    wait(config.navodki.time[0])
                    config.navodki.send = false                                            
                end)   
            end
        end
    end

    local _, myid = sampGetPlayerIdByCharHandle(PLAYER_PED)
    if _ then
        local mynick = sampGetPlayerNickname(myid)
        if text:find("%[A%] %w+_%w+%[%d+%] начал следить за " .. mynick .. "%[" .. myid .. "%]") then
            local nick, pid = text:match("%[A%] (%w+_%w+)%[(%d+)%] начал следить за " .. mynick .. "%[" .. myid .. "%]")            
            toast.Show(u8"За тобой следит " .. nick .. "[" .. pid .. "]", toast.TYPE.INFO, 5, ColorNotification())
        end
    end

    if text:find("Жалоб итого: 5") and not isGamePaused() then
        toast.Show(u8"Надо бы на репорт поотвечать.", toast.TYPE.INFO, 5, ColorNotification())        
    elseif string.rlower(text):find(string.rlower("%[Античит%]")) and not isGamePaused() then
        toast.Show(u8"Пришел AntiCheat!", toast.TYPE.INFO, 5, ColorNotification())
    end
end

function hook.onShowTextDraw(textdrawId, data)
    for id, textdraw in pairs(spTextdraw) do
        if id == textdrawId then
            return false
        end 
    end
end

function hook.onSendCommand(command)
    if not config.spWindow[0] then
        if command:find("/re %d+") or command:find("/sp %d+") then                 
            spInfo.id = command:match("/re (%d+)") or command:match("/sp (%d+)")
            config.spWindow[0] = not config.spWindow[0] 
        end        
    end

    if command:find("/reoff") then
        config.spWindow[0] = false
    end
end

function onWindowMessage(msg, wparam, lparam)
    if not isPauseMenuActive() then
        if msg == 0x100 or msg == 0x101 then
            if wparam == 27 and config.mainWindow[0] then
                consumeWindowMessage(true, false)
                if msg == 0x101 then
                    config.mainWindow[0] = false
                end            
            end    
        end
        
        if msg == 0x0205 then
            if config.spWindow[0] then
                spInfo.cursor = true
            end                        
        elseif msg == 513 then
            if config.spWindow[0] then
                spInfo.cursor = false
            end

            if config.checker.setting then
                config.mainWindow[0] = true
                showCursor(false)
                inicfg.save(mainIni, "AHelper.ini")
                config.checker.setting = false                
            end
        end
    end
end

--========================================================OTHER========================================================

function checkUpdate()
    local updatePath = getWorkingDirectory() .. "/config/update.ini"    
    downloadUrlToFile("https://raw.githubusercontent.com/egaaaaaaaaaaaaaaaaa/AHelper-Namalsk-RP/main/release/config/update.ini", updatePath, function(id, status)
        if status == downloadStatus.STATUS_ENDDOWNLOADDATA then        
            local updateIni = inicfg.load(nil, updatePath)   
            if tostring(updateIni.info.version) > thisScript().version then 
                toast.Show(string.format(u8"Доступна новая версия скрипта %s", updateIni.info.version), toast.TYPE.INFO, 7, ColorNotification())
            end 
            os.remove(updatePath)           
        end
    end)    
end

function freezeChar(actived)
    local bs = raknetNewBitStream()
    raknetBitStreamWriteBool(bs, actived)
    raknetEmulRpcReceiveBitStream(15, bs)
    raknetDeleteBitStream(bs)
end

function random(min, max)
    local kf = math.random(min, max)
    math.randomseed(os.time() * kf)
    local rand = math.random(min, max)
    return tonumber(rand)
end

function shorten(nick)
    if (nick:find(".+_.+")) then
        return ("%s.%s"):format(nick:sub(1,1), nick:sub(nick:find("_") + 1, nick:len()))
    end
    return nick
end

function SearchMarker(posX, posY, posZ, radius, isRace)
    local ret_posX = 0.0
    local ret_posY = 0.0
    local ret_posZ = 0.0
    local isFind = false

    for id = 0, 31 do
        local MarkerStruct = 0
        if isRace then MarkerStruct = 0xC7F168 + id * 56
        else MarkerStruct = 0xC7DD88 + id * 160 end
        local MarkerPosX = representIntAsFloat(readMemory(MarkerStruct + 0, 4, false))
        local MarkerPosY = representIntAsFloat(readMemory(MarkerStruct + 4, 4, false))
        local MarkerPosZ = representIntAsFloat(readMemory(MarkerStruct + 8, 4, false))

        if MarkerPosX ~= 0.0 or MarkerPosY ~= 0.0 or MarkerPosZ ~= 0.0 then
            if getDistanceBetweenCoords3d(MarkerPosX, MarkerPosY, MarkerPosZ, posX, posY, posZ) < radius then
                ret_posX = MarkerPosX
                ret_posY = MarkerPosY
                ret_posZ = MarkerPosZ
                isFind = true
                radius = getDistanceBetweenCoords3d(MarkerPosX, MarkerPosY, MarkerPosZ, posX, posY, posZ)
            end
        end
    end

    return isFind, ret_posX, ret_posY, ret_posZ
end

function string.rlower(s)
    local lower, sub, char, upper = string.lower, string.sub, string.char, string.upper
    local concat = table.concat

    local lu_rus, ul_rus = {}, {}
    for i = 192, 223 do
        local A, a = char(i), char(i + 32)
        ul_rus[A] = a
        lu_rus[a] = A
    end
    local E, e = char(168), char(184)
    ul_rus[E] = e
    lu_rus[e] = E
    
    s = lower(s)
    local len, res = #s, {}
    for i = 1, len do
        local ch = sub(s, i, i)
        res[i] = ul_rus[ch] or ch
    end
    return concat(res)
end