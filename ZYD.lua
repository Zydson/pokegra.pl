ZYD = {}
ZYD.Proxies = {}
ZYD.OperatingSystem = ""
ZYD.LastMessage = ""
ZYD.CaptchaApiKey = "x"  -- 2captcha.com api key
ZYD.StartTime = os.time()
ZYD.Solved = false
ZYD.Statistics = {
	["Mobs_killed"] = 0,
	["Captchas_solved"] = 0,
}
-- Enter your PHPSESSID here
ZYD.Headers = [[
accept: application/json, text/javascript, */*; q=0.01
accept-language: en-US,en;q=0.9
content-type: application/x-www-form-urlencoded;charset=UTF-8
cookie: PHPSESSID=x; _ga=GA1.1.1727065598.1678817780; __utmc=228978461; __utmz=228978461.1678817780.1.1.utmcsr=(direct)|utmccn=(direct)|utmcmd=(none); __gads=ID=32c71b51b9458c31-2230b85132dc007a:T=1678817788:RT=1678817788:S=ALNI_MZ-A_GD3lySwe65RKjas0BsTto4Xw; location=0; __utma=228978461.1727065598.1678817780.1679084385.1679206462.7; __gpi=UID=00000becef628d28:T=1678817788:RT=1679206481:S=ALNI_MaWGNUXcD6b_6GeeBU4VPrPsiOeaQ; __utmt_UA-43254740-2=1; __utmb=228978461.45.10.1679206462; _ga_N1GS3919D3=GS1.1.1679206461.6.1.1679208943.0.0.0
referer: https://www.pokegra2.pl/?x=teren
sec-ch-ua: "Not=A?Brand";v="8", "Chromium";v="110", "Opera GX";v="96"
sec-ch-ua-mobile: ?0
sec-ch-ua-platform: "Windows"
sec-fetch-dest: empty
sec-fetch-mode: cors
sec-fetch-site: same-origin
user-agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/110.0.0.0 Safari/537.36 OPR/96.0.0.0
x-requested-with: XMLHttpRequest
]]
ZYD.CurlHeaders = ""
for line in string.gmatch(ZYD.Headers,'[^\r\n]+') do 
	ZYD.CurlHeaders = ZYD.CurlHeaders .. " " .. '-H "'..line..'"'
end

if tostring(package.cpath:match("%p[\\|/]?%p(%a+)")) == "dll" then
	ZYD.OperatingSystem = "Windows"
else
	ZYD.OperatingSystem = "Linux"
end

ZYD.Errors = {
	["Count"] = 0,
	["Threeshold"] = 10
}

local json = require "modules/json/json" -- Json Library
--local effil = require "effil"          -- Multi-Threading support
math.randomseed(os.time())

ZYD.Error = function(text,functionName, critical, count)
	if count then
		ZYD.Errors["Count"] = ZYD.Errors["Count"] + 1
	end
	if critical then
		print("Critical error occured: "..text.." - [Function: "..functionName.."]")
		print("killing process...")
		os.exit()
	end
	if functionName ~= nil then
		print("Error occured: "..text.." - [Function: "..functionName.."]")
	else
		print("Error occured: "..text)
	end
	if ZYD.Errors["Count"] >= ZYD.Errors["Threeshold"] then
		print("Error threeshold has been reached, killing process")
		os.exit()
	end
end

ZYD.LoadProxies = function(file,tabName)
  for line in io.lines(file) do
    table.insert(ZYD.Proxies[tabName],line)
  end
end

ZYD.Download = function(url, path) -- Can't be done with pcall, sadge
	if ZYD.OperatingSystem == "Linux" then
		if path == nil then
			os.execute("wget "..url)
		else
			os.execute("wget -P "..path.." "..url)
		end
	else
		-- TODO: Windows support (prolly it should be done with curl)
	end
end

ZYD.HTTP_GetRequest = function(url)
  local hand = assert(io.popen("curl "..url.." -s"))
  local response = hand:read("*all")
  io.close(hand)
  return response
end

-- application/json / application/x-www-form-urlencoded
ZYD.HTTP_PostRequest = function(url)
  if url ~= nil then
    local handler = assert(io.popen("curl -s -m 3 -X POST "..url))
    local response = handler:read("*all")
	io.close(handler)
    return response
  end
end

ZYD.Execute = function(command)
	os.execute(command)
end

ZYD.WaitPC = function(ms)
	if ZYD.OperatingSystem == "Linux" then
		local sec = tonumber(ms/1000)
		ZYD.Execute("sleep "..sec)
	else
		ZYD.Execute("timeout "..ms.." > nul") -- Seconds acctually because it does not support ms
	end
end

ZYD.Wait = function(ms)
	if type(ms) == "number" then
		pcall(ZYD.WaitPC, ms)
	else
		ZYD.Error("expected number not ["..type(ms).."] args[ms]", "ZYD.Wait", false)
		return "Error"
	end
end

ZYD.JsonValidation = function(text)
	json.decode(text)
	return true
end

ZYD.LoadJsonFile =  function(file)
  local fileJ = io.open(file, "r")
	if not fileJ then
		ZYD.Error("can't find ["..file.."]", "ZYD.SaveJson", true)
	end
  if fileJ ~= nil then
    local jsonT = fileJ:read("*all")
	  io.close(fileJ)
    if pcall(ZYD.JsonValidation, jsonT) then
      return json.decode(jsonT)
    else
      if string.len(jsonT) == 0 then
        return "free"
      else
        ZYD.Error("can't decode ["..file.."]-'possible syntax error'", "ZYD.SaveJson", true)
        return "Validiation error"
      end
    end
  end
end

ZYD.SaveJson = function(file, tab, new)
	local currentJ = ZYD.LoadJsonFile(file)
	if currentJ == "Validiation error" then
		--pass
	elseif currentJ == "free" or new then
		local jsonG = io.open(file, "w+")
    if jsonG ~= nil then
		  jsonG:write(json.encode(tab))
    end
		io.close(jsonG)
	elseif currentJ == "no file" then
		--pass
	else
		local tempTab = {}
		for a,b in pairs(currentJ) do
			table.insert(tempTab,b)
		end
		for a,b in pairs(tab) do
			table.insert(tempTab,b)
		end
		local jsonG = io.open(file, "w+")
    if jsonG ~= nil then
		  jsonG:write(json.encode(tempTab))
    end
		io.close(jsonG)
	end
end

ZYD.Average = function(tab)
	if type(tab) == "table" then
		local overall = 0
		for a,b in ipairs(tab) do
			if type(b) == "number" then
				overall = overall + b
			end
		end
		return (overall/#tab)
	else
		ZYD.Error("expected table not ["..type(tab).."] args[tab]","ZYD.Average",false)
		return "Error"
	end
end

ZYD.Parse = function(tar, _type, jsonInd, leftstring, rightstring)
	if tar ~= nil then
		if _type == "json" and pcall(ZYD.JsonValidation, tar) then
			local out = json.decode(tar)
			if out[jsonInd] ~= nil then
				return out[jsonInd]
			end
		elseif _type == "string" and type(tar) == "string" then
			local _ls = string.find(tar,leftstring)
			local toright = string.sub(tar, _ls+#leftstring, #tar)
			local _rs = string.find(toright,rightstring)
			if _ls ~= nil and _rs ~= nil then
				return string.sub(tar, _ls+#leftstring, _rs-2+_ls+#leftstring)
			else
				return "Parse error"
			end
		end
	else
		ZYD.Error("args[tar] cant be nil","ZYD.Parse",false)
		return "Error"
	end
end

ZYD.KillAllMobs = function(map,x,y,minLevel,maxLevel,drop)
	itemUsed = false
	ZYD.MoveChar(map,x,y) -- After update at 12.03.2023 we need to be at the specific square to get data from it (there is threeshold +-4 XY)
	local res = ZYD.GetMobsAtXY(map,x,y)
	if pcall(ZYD.JsonValidation, res:sub(4,#res)) then
		local toJson = json.decode(res:sub(4,#res))
		for a,b in pairs(toJson["stworzenia"]) do
			if tonumber(b["poziom"]) <= tonumber(maxLevel) and tonumber(b["poziom"]) >= tonumber(minLevel) then
				local found
				if drop ~= nil then
					if type(drop) == "table" then
						for c,d in pairs(drop) do
							if d == b["nazwa"] then
								found = true
							end
						end
					else
						if drop ~= b["nazwa"] then
							found = true
						end
					end
				end
				if found ~= true and drop ~= nil then
					break
				end
				local attack = ZYD.HTTP_GetRequest('"https://www.pokegra2.pl/ajax/atak.php?typ=1&id='..b["id"]..'&mapa='..map..'&x='..x..'&y='..y..'&time='..os.time()..'"'..ZYD.CurlHeaders)
				ZYD.Statistics["Mobs_killed"] = ZYD.Statistics["Mobs_killed"] + 1
				if pcall(ZYD.JsonValidation, attack:sub(4,#attack)) then
					local attackJson = json.decode(attack:sub(4,#attack))
					if attackJson["captcha"] == 1 then
						if not ZYD.Solved then
							ZYD.Solved = true
							local res = ZYD.HTTP_GetRequest('"http://2captcha.com/in.php?key='..ZYD.CaptchaApiKey..'&method=userrecaptcha&googlekey=6LfDL0EUAAAAAOdJ5Buw2_uw1CGoeoy3dxj2vB4w&pageurl=https://www.pokegra2.pl/?x=captcha"')
							print("Trying to solve captcha ".. os.date("[%H:%M]"))
							if string.find(res,"OK|") then
								local token = string.sub(res,4,#res)
								local solve
								local timeout = 0
								repeat
									solve = ZYD.HTTP_GetRequest('"http://2captcha.com/res.php?key='..ZYD.CaptchaApiKey..'&action=get&id='..token..'"')
									ZYD.Wait(2)
									timeout = timeout + 1
									if timeout == 120 then
										solve = false
										ZYD.Solved = false
										break
									end
								until solve ~= "CAPCHA_NOT_READY"
								if solve then
									local res = ZYD.HTTP_PostRequest('"https://www.pokegra2.pl/?x=captcha"'..ZYD.CurlHeaders..' -d "g-recaptcha-response='..string.sub(solve,4,#solve)..'&texttyped2=-132%7C330-116%7C338-743%7C200-682%7C233-623%7C265-571%7C288-534%7C302-510%7C309-494%7C310-486%7C310-478%7C307-447%7C308-433%7C311-418%7C311-405%7C310-389%7C304-329%7C369-322%7C364-322%7C362-325%7C361-326%7C359-327%7C357-327%7C356-326%7C356-322%7C356-314%7C356-303%7C358-289%7C355-279%7C350-272%7C347-267%7C344-266%7C341-266%7C339-266%7C338-266%7C336-266%7C334-266%7C332-266%7C330-266%7C328-267%7C328-269%7C327-270%7C325-270%7C324-270%7C323-272%7C322-272%7C321-273%7C320-274%7C319B274C319"')
									ZYD.Statistics["Captchas_solved"] = ZYD.Statistics["Captchas_solved"] + 1
									print("Captcha solved ".. os.date("[%H:%M]"))
									ZYD.Solved = false
								end
							end
							break
						end
					end
					if attackJson["zmeczenie"] == 95 then
						if not itemUsed then
							itemUsed = true
							ZYD.UseItem(21)
						end
					end
				end
				ZYD.Wait(1)
			end
		end
	end
end

ZYD.FindMobXY = function(map,x,y,name)
	ZYD.MoveChar(map,x,y)
	local res = ZYD.GetMobsAtXY(map,x,y)
	if pcall(ZYD.JsonValidation, res:sub(4,#res)) then
		local toJson = json.decode(res:sub(4,#res))
		for a,b in pairs(toJson["stworzenia"]) do
			if string.find(b["nazwa"],name) ~= nil then
				print("Name: "..b["nazwa"].."\nMap: "..ZYD.MapsLabel[map].."\nx: "..x.."\ny: "..y.."\n------------")
			end
		end
	end
end

ZYD.SearchForMob = function(map,name)
	for c,d in pairs(ZYD.Maps[map]) do
		ZYD.FindMobXY(map, d[1], d[2], name)
	end
end

ZYD.ScanMapForSpots = function(map)
	tempSpots = "{"
	for x=1,40 do
		print(x)
		for y=1,40 do
			ZYD.MoveChar(map,x,y)
			local res = ZYD.GetMobsAtXY(map,x,y)
			if pcall(ZYD.JsonValidation, res:sub(4,#res)) then
				local toJson = json.decode(res:sub(4,#res))
				if #toJson["stworzenia"] ~= 0 then
					tempSpots = tempSpots.."{"..x..","..y.."},"
				end
			end
		end
	end
	print("Map: "..map)
	print(tempSpots.."}")
end

ZYD.BuyItemFromAH = function(id,count)
	local getAC = ZYD.HTTP_GetRequest('"https://www.pokegra2.pl/ajax/aukcje/getPrzedmiot.php?id='..id..'"'..ZYD.CurlHeaders)
	if string.find(getAC,"Nie ma takiego przedmiotu") == nil then
		if type(count) == "number" then
			local itemName = ZYD.Parse(getAC,type(getAC),0,"'aukcje_nazwa'>","<br>")
			if itemName ~= nil then
				ZYD.HTTP_PostRequest('"https://www.pokegra2.pl/ajax/aukcje/buySomePrzedmiot.php?id='..id..'&token=757895c63b4b4f1d3b19e75936e164b4"'..ZYD.CurlHeaders..' -d "textText='..count..'"') -- Token is unique for every player player_token
			end
		else
			ZYD.Error("expected number not ["..type(count).."] args[count]","ZYD.BuyItemFromAH",false)
			return "Error"
		end
	else
		ZYD.Error("wrong auction id ["..id.."] args[id]", "ZYD.BuyItemFromAH", false)
		return "Error"
	end
end

ZYD.PutItemOnAH = function(name,count,price)
	local getItems = ZYD.HTTP_GetRequest('"https://www.pokegra2.pl/ajax/npc.php?type=5&pokaz=1"'..ZYD.CurlHeaders)
	local tempParsed = ZYD.Parse(getItems,type(getItems),0,"<option value='","'>"..name)
	if tempParsed ~= "Parse error" then
		local itemId = string.sub(tempParsed,#tempParsed-7,#tempParsed)
		local tempParsed
		if type(count) == "number" then
			if type(price) == "number" then
				local res = ZYD.HTTP_GetRequest('"https://www.pokegra2.pl/ajax/npc.php?type=5&wystaw=2&przedmiot='..itemId..'&ilosc='..count..'&cena='..price..'"'..ZYD.CurlHeaders)
				if string.find(res,"wielu aukcji") ~= nil then
					ZYD.Error("you cant put that many items on ah","ZYD.PutItemOnAH",false)
					return "Error"
				end
			else
				ZYD.Error("expected number not ["..type(price).."] args[price]","ZYD.PutItemOnAH",false)
				return "Error"
			end
		else
			ZYD.Error("expected number not ["..type(count).."] args[count]","ZYD.PutItemOnAH",false)
			return "Error"
		end
	else
		ZYD.Error("wrong item name or you dont have any in the inventory ["..name.."] args[name]", "ZYD.PutItemOnAH", false)
		return "Error"
	end
end

ZYD.UseItem = function(id)
	if type(id) == "number" then
		print("Used "..id)
		ZYD.HTTP_GetRequest('"https://www.pokegra2.pl/?x=ekwipunek&id='..id..'&act=uzyj"'..ZYD.CurlHeaders)
	else
		ZYD.Error("expected number not ["..type(id).."] args[id]","ZYD.UseItem",false)
		return "Error"
	end
end

ZYD.MoveChar = function(map,x,y)
	if type(map) == "number" and type(x) == "number" and type(y) == "number" then
		local res = ZYD.HTTP_PostRequest('"https://www.pokegra2.pl/ajax/poruszanie.php"'..ZYD.CurlHeaders..' -d "przesuniecie=2&mapa='..map..'&x='..x..'&y='..y..'"')
	else
		ZYD.Error("expected args[map] args[x] args[y] to all of them be numbers and they are not","ZYD.MoveChar",false)
		return
	end
end

ZYD.GetMobsAtXY = function(map,x,y)
	if type(map) == "number" and type(x) == "number" and type(y) == "number" then
		return ZYD.HTTP_GetRequest('"https://www.pokegra2.pl/ajax/pola2.php?mapa='..map..'&x='..x..'&y='..y..'"'..ZYD.CurlHeaders..'')
	else
		ZYD.Error("expected args[map] args[x] args[y] to all of them be numbers and they are not","ZYD.GetMobsAtXY",false)
		return
	end
end

ZYD.SendProximityMessage = function(message)
	if message ~= nil then
		ZYD.HTTP_PostRequest('"https://www.pokegra2.pl/ajax/czat2.php"'..ZYD.CurlHeaders..' -d "wpisy=0&tresc='..message..'"')
	else
		ZYD.Error("args[message] cant be nil","ZYD.SendProximityMessage",false)
		return "Error"
	end
end

ZYD.CheckLastMessage = function()
	local messages = ZYD.HTTP_GetRequest('"https://www.pokegra2.pl/?x=poczta"'..ZYD.CurlHeaders)
	local last = ZYD.Parse(messages,type(messages),0,'<span class="poczta_itemtresc">','</span>')
	if ZYD.LastMessage == "" then
		ZYD.LastMessage = last
	else
		if ZYD.LastMessage ~= last then
			print("New private message detected")
			ZYD.LastMessage = last
		end
	end
end

SzulerOverall = 0
ZYD.NPC_Szuler = function()
	local Szuler = ZYD.HTTP_GetRequest('"https://www.pokegra2.pl/ajax/npc.php?type=24&oddam=1"'..ZYD.CurlHeaders)
	if string.find(Szuler,"Przeg") ~= nil then
		SzulerOverall = SzulerOverall - 10
	else
		SzulerOverall = SzulerOverall + 10
	end
	print(SzulerOverall)
end

ZYD.NPC_Torin = function()
	local Options = ZYD.HTTP_GetRequest('"https://www.pokegra2.pl/ajax/npc.php?type=6&pokaz=1"'..ZYD.CurlHeaders)
	local Check = ZYD.HTTP_GetRequest('"https://www.pokegra2.pl/ajax/npc.php?type=6&zgadywanie=1&1&zgadnij=1&stworzenie='..ZYD.Parse(Mobs,type(Mobs),0,"<option value='","'>")..'"'..ZYD.CurlHeaders)
end

ZYD.BuyLotteryTicket = function()
	ZYD.HTTP_GetRequest('"https://www.pokegra2.pl/?x=tablica&loteria=buy"'..ZYD.CurlHeaders)
end

ZYD.DepositMoney = function(money)
	if type(money) == "number" then
		ZYD.HTTP_PostRequest('"https://www.pokegra2.pl/?x=depozyt"'..ZYD.CurlHeaders..' -d "zdeponuj='..money..'"')
	else
		ZYD.Error("expected number not ["..type(money).."] args[money]","ZYD.DepositMoney",false)
		return "Error"
	end
end

ZYD.MapsLabel = {
	[1] = "Miasto Viridian",
	[2] = "Las Arianski",
	[5] = "Dolina Lodu", -- scan
	[7] = "Ptasia Knieja",
	[8] = "Cieniste rowniny",
	[14] = "Wybrzeze Johto",
	[18] = "Park Johto",
	[32] = "Wyspa wirow #2",
	[39] = "Dolina Lawy",
	[40] = "Wzgorze Piorunow", -- scan
	[60] = "Okolice Sandgem #2",
	[64] = "Las Unova",
	[65] = "Miasto Unova"
}

ZYD.Maps = {
	[1] = {{8,10},{8,11},{9,10},{9,11},{10,5},{10,6},{11,5},{11,6},{17,11},{18,11},{19,10},{19,11},{20,21},{20,22},{21,21},{21,22},{21,28},{21,29},{21,30},{22,13},{22,21},{22,22},{22,28},{22,29},{22,30},{23,13},{23,14},{23,21},{23,22},{23,28},{23,29},{23,30},{24,13},{24,14},{24,28},{24,29},{24,30},{25,13},{25,14},{26,13},{26,14},{27,13},{30,14},{30,15},{31,14},{31,15},{32,14},{32,15},{33,14},{33,15},{34,14},{34,15},{35,14},{35,15},{38,31},{38,32},{38,33},{38,34},{39,31},{39,32},{39,33},{39,34}},
	[2] = {{5,25},{5,26},{6,25},{6,26},{7,23},{7,24},{7,26},{8,23},{8,24},{8,25},{8,26},{9,23},{9,24},{9,25},{9,26},{10,23},{10,24},{10,25},{10,26},{11,22},{11,23},{11,24},{11,25},{11,26},{12,22},{12,23},{12,24},{12,25},{12,26},{13,22},{13,23},{13,24},{14,21},{14,22},{14,23},{15,21},{15,22},{22,35},{23,31},{23,34},{23,35},{24,33},{24,34},{24,35},{25,32},{25,33},{25,34},{25,35},{26,32},{26,33},{26,34},{26,35},{27,32},{27,33},{28,32},{28,33},{31,13},{31,14},{32,13},{32,16},{33,20},{33,21},{33,22},{34,20},{34,21},{34,22},{35,16},{35,21},{35,22},{36,21},{36,22},{36,23},{37,22},{37,23},{37,24},{38,17},{38,23},{38,24},{39,17},{39,18},{39,23},{39,24},{40,17},{40,18},{40,23}},
	[7] = {{5,8},{5,9},{5,10},{6,8},{6,9},{6,10},{6,20},{6,21},{6,26},{7,8},{7,9},{7,10},{7,25},{7,26},{7,27},{8,8},{8,9},{8,25},{8,26},{8,27},{9,25},{9,26},{9,27},{10,25},{10,26},{10,27},{15,26},{15,27},{16,6},{16,7},{16,26},{16,27},{17,6},{17,7},{17,23},{17,24},{17,25},{17,26},{17,27},{17,28},{17,29},{17,30},{17,31},{18,6},{18,7},{18,23},{18,24},{18,25},{18,26},{18,27},{18,28},{18,29},{18,30},{18,31},{19,23},{19,24},{19,25},{19,26},{19,27},{19,28},{19,29},{19,30},{19,31},{20,23},{20,24},{20,25},{20,26},{20,27},{20,28},{20,29},{20,30},{20,31},{20,32},{21,6},{21,7},{21,8},{21,30},{21,31},{21,32},{22,6},{22,7},{22,8},{22,33},{23,6},{23,7},{23,8},{23,30},{23,31},{23,32},{23,33},{24,6},{24,7},{24,8},{24,30},{24,31},{24,32},{24,33},{25,6},{25,7},{25,8},{25,30},{25,31},{25,32},{25,33},{26,6},{26,7},{26,8},{26,30},{26,31},{26,32},{27,6},{27,7},{27,8},{27,30},{27,31},{28,6},{28,7},{28,8},{29,7},{29,8},{29,11},{29,12},{30,6},{30,7},{30,8},{30,11},{30,12},{30,13},{31,6},{31,7},{31,8},{31,10},{31,11},{31,12},{31,13},{31,30},{31,31},{32,10},{32,11},{32,12},{32,30},{32,31},{32,32},{32,33},{33,10},{33,11},{33,12},{33,15},{33,28},{33,29},{33,30},{33,31},{33,32},{33,33},{34,15},{34,28},{34,29},{34,30},{34,31},{34,32},{35,10},{35,28},{35,29},{35,30},{35,31},{36,28},{36,29},{37,10},{37,28},{37,30}},
	[8] = {{6,17},{6,18},{6,31},{6,33},{6,34},{7,17},{7,18},{7,29},{7,30},{7,31},{7,32},{7,33},{7,34},{8,32},{8,33},{8,34},{21,3},{22,3},{22,4},{22,21},{22,22},{23,3},{23,4},{23,5},{23,6},{23,21},{23,22},{24,3},{24,4},{24,5},{24,6},{31,3},{31,4},{32,3},{32,4},{32,5},{32,6},{33,3},{33,4},{33,5},{33,6},{33,7},{33,8},{33,9},{34,8},{34,9},{35,8},{35,9},{35,23},{35,24},{35,25},{35,26},{35,27},{36,8},{36,9},{36,23},{36,24},{36,25},{36,26},{36,27},{37,8},{37,9},{37,23},{37,24},{37,25},{37,26},{37,27},{38,23},{38,24},{38,25},{38,26},{38,27},{39,18},{39,19},{39,20},{39,21},{39,22},{39,23},{39,24},{39,25},{39,26},{39,27},{40,18},{40,19},{40,20},{40,21},{40,22},{40,23}},
	[14] = {{1,38},{1,39},{1,40},{2,38},{2,39},{2,40},{3,38},{3,39},{3,40},{4,38},{4,39},{4,40},{5,38},{5,39},{5,40},{6,38},{6,39},{6,40},{7,38},{7,39},{7,40},{8,38},{8,39},{8,40},{9,38},{9,39},{9,40},{10,38},{10,39},{10,40},{11,28},{11,33},{11,38},{11,39},{11,40},{12,10},{12,11},{12,12},{12,28},{12,29},{12,30},{12,31},{12,32},{12,33},{12,38},{12,39},{12,40},{13,10},{13,11},{13,12},{13,28},{13,29},{13,30},{13,31},{13,32},{13,33},{13,38},{13,39},{13,40},{14,9},{14,10},{14,11},{14,12},{14,28},{14,29},{14,30},{14,31},{14,32},{14,33},{14,38},{14,39},{14,40},{15,9},{15,10},{15,11},{15,28},{15,29},{15,30},{15,31},{15,32},{15,33},{15,38},{15,39},{15,40},{16,9},{16,10},{16,11},{16,12},{16,20},{16,21},{16,28},{16,29},{16,30},{16,31},{16,32},{16,33},{16,38},{16,39},{16,40},{17,9},{17,10},{17,11},{17,12},{17,38},{17,39},{17,40},{18,9},{18,10},{18,11},{18,12},{18,38},{18,39},{18,40},{19,9},{19,10},{19,11},{19,12},{19,38},{19,39},{19,40},{20,9},{20,10},{20,11},{20,12},{20,38},{20,39},{20,40},{21,4},{21,9},{21,10},{21,11},{21,12},{21,38},{21,39},{21,40},{22,9},{22,10},{22,11},{22,12},{22,38},{22,39},{22,40},{23,9},{23,10},{23,11},{23,12},{23,38},{23,39},{23,40},{24,9},{24,10},{24,11},{24,12},{24,13},{24,14},{24,15},{24,16},{24,18},{24,19},{24,20},{24,21},{24,22},{24,23},{24,24},{24,25},{24,26},{24,27},{24,28},{24,38},{24,39},{24,40},{25,9},{25,10},{25,11},{25,12},{25,13},{25,14},{25,15},{25,16},{25,18},{25,19},{25,20},{25,21},{25,22},{25,23},{25,24},{25,25},{25,26},{25,27},{25,28},{25,38},{25,39},{25,40},{26,18},{26,19},{26,20},{26,21},{26,22},{26,23},{26,24},{26,25},{26,26},{26,27},{26,28},{26,38},{26,39},{26,40},{27,10},{27,12},{27,13},{27,14},{27,15},{27,16},{27,17},{27,18},{27,19},{27,20},{27,21},{27,22},{27,23},{27,24},{27,25},{27,26},{27,27},{27,38},{27,39},{27,40},{28,9},{28,10},{28,11},{28,12},{28,13},{28,14},{28,15},{28,16},{28,17},{28,18},{28,19},{28,20},{28,21},{28,22},{28,23},{28,24},{28,25},{28,26},{28,27},{28,28},{28,38},{28,39},{28,40},{29,9},{29,10},{29,11},{29,12},{29,13},{29,17},{29,18},{29,19},{29,20},{29,21},{29,22},{29,23},{29,24},{29,25},{29,26},{29,27},{29,28},{29,38},{29,39},{29,40},{30,9},{30,10},{30,11},{30,12},{30,17},{30,18},{30,19},{30,20},{30,21},{30,22},{30,23},{30,24},{30,25},{30,26},{30,27},{30,28},{30,38},{30,39},{30,40},{31,9},{31,10},{31,11},{31,12},{31,22},{31,23},{31,24},{31,25},{31,26},{31,27},{31,28},{31,38},{31,39},{31,40},{32,9},{32,10},{32,11},{32,12},{32,22},{32,23},{32,24},{32,25},{32,26},{32,27},{32,28},{32,38},{32,39},{32,40},{33,9},{33,10},{33,11},{33,12},{33,22},{33,23},{33,24},{33,25},{33,26},{33,27},{33,28},{33,38},{33,39},{33,40},{34,11},{34,12},{34,13},{34,15},{34,16},{34,22},{34,23},{34,24},{34,25},{34,26},{34,27},{34,28},{34,38},{34,39},{34,40},{35,13},{35,14},{35,15},{35,16},{35,21},{35,22},{35,23},{35,24},{35,25},{35,26},{35,27},{35,28},{35,38},{35,39},{35,40},{36,13},{36,14},{36,15},{36,16},{36,17},{36,18},{36,19},{36,20},{36,21},{36,22},{36,23},{36,24},{36,25},{36,26},{36,27},{36,28},{36,38},{36,39},{36,40},{37,13},{37,14},{37,15},{37,16},{37,17},{37,18},{37,19},{37,20},{37,21},{37,22},{37,23},{37,24},{37,25},{37,26},{37,27},{37,28},{37,38},{37,39},{37,40},{38,20},{38,21},{38,22},{38,23},{38,24},{38,25},{38,26},{38,27},{38,28},{38,38},{38,39},{38,40},{39,20},{39,21},{39,22},{39,23},{39,24},{39,25},{39,26},{39,27},{39,28},{39,38},{39,39},{39,40},{40,20},{40,22},{40,24},{40,25},{40,26},{40,27},{40,28},{40,38},{40,39},{40,40}},
	[18] = {{2,9},{3,2},{3,9},{3,14},{3,15},{3,21},{3,22},{4,2},{4,14},{4,15},{4,21},{4,22},{5,2},{5,8},{5,14},{5,15},{5,21},{5,22},{6,2},{6,8},{6,9},{6,10},{6,14},{6,15},{6,21},{6,22},{7,2},{7,8},{7,14},{7,15},{7,21},{7,22},{8,2},{8,9},{8,10},{8,14},{8,15},{8,21},{8,22},{9,2},{9,9},{9,10},{9,14},{9,15},{9,21},{9,22},{10,2},{10,9},{10,10},{10,14},{10,15},{10,21},{10,22},{11,2},{11,9},{11,10},{11,14},{11,15},{11,22},{12,2},{12,5},{12,9},{12,10},{12,14},{12,15},{12,22},{13,2},{13,9},{13,10},{13,14},{13,15},{13,22},{14,2},{14,9},{14,10},{14,14},{14,15},{15,2},{15,9},{15,10},{15,14},{15,15},{16,2},{16,9},{16,10},{16,14},{16,15},{17,2},{17,9},{17,10},{17,14},{17,15},{17,21},{18,9},{18,10},{18,14},{18,15},{18,21},{19,2},{19,9},{19,10},{19,14},{19,15},{19,21},{19,22},{20,2},{20,9},{20,10},{20,14},{20,15},{20,21},{20,22},{21,2},{21,10},{21,14},{21,15},{21,21},{21,22},{22,9},{22,10},{22,14},{22,21},{22,22},{23,9},{23,10},{23,21},{23,22},{24,9},{24,10},{24,21},{24,22},{25,9},{25,10},{25,19},{25,21},{25,22},{26,2},{26,6},{26,9},{26,10},{26,21},{26,22},{27,2},{27,9},{27,10},{27,21},{27,22},{28,2},{28,3},{28,4},{28,5},{28,6},{28,7},{28,21},{28,22}},
	[32] = {{2,1},{2,6},{2,10},{2,11},{2,12},{2,13},{2,14},{2,15},{2,16},{2,17},{2,18},{3,1},{3,2},{3,10},{3,11},{3,12},{3,13},{3,14},{3,17},{4,1},{4,2},{4,10},{4,11},{4,12},{4,13},{4,14},{4,15},{4,16},{4,17},{4,18},{5,1},{5,2},{5,10},{5,11},{5,12},{5,13},{5,14},{5,15},{5,16},{5,17},{5,18},{6,1},{6,2},{6,7},{6,10},{6,11},{6,12},{6,13},{6,14},{6,15},{6,16},{6,17},{6,18},{7,1},{7,2},{7,10},{7,11},{7,12},{7,13},{7,14},{7,15},{7,16},{7,17},{7,18},{8,1},{8,2},{8,10},{8,11},{8,12},{8,13},{8,14},{8,15},{8,16},{8,17},{8,18},{9,2},{9,10},{9,11},{9,12},{9,13},{9,14},{9,15},{9,16},{9,17},{9,18},{10,1},{10,2},{10,10},{10,11},{10,12},{10,13},{10,14},{10,15},{10,16},{10,17},{10,18},{11,1},{11,2},{11,5},{11,10},{11,11},{11,12},{11,13},{11,14},{11,15},{11,16},{11,17},{11,18},{12,1},{12,2},{12,10},{12,11},{12,12},{12,13},{12,14},{12,15},{12,16},{12,17},{12,18},{13,1},{13,2},{13,8},{13,9},{13,10},{13,11},{13,12},{13,13},{13,14},{13,15},{13,16},{13,17},{13,18},{14,1},{14,2},{14,8},{14,10},{14,11},{14,12},{14,13},{14,14},{14,15},{14,16},{14,17},{14,18},{15,1},{15,2},{15,8},{15,10},{15,11},{15,12},{15,13},{15,14},{15,15},{15,16},{15,17},{15,18},{16,1},{16,10},{16,11},{16,12},{16,13},{16,14},{16,15},{16,16},{16,17},{16,18},{17,1},{17,2},{17,10},{17,11},{17,12},{17,13},{17,14},{17,15},{17,16},{17,17},{17,18},{19,2},{19,12},{20,2},{20,3},{20,4},{20,5},{20,6},{20,7},{20,8},{20,9},{20,10},{20,11},{20,12},{20,13},{21,2},{21,3},{21,4},{21,5},{21,6},{21,7},{21,8},{21,9},{21,10},{21,11},{21,12},{21,13},{22,2},{22,3},{22,4},{22,5},{22,6},{22,7},{22,8},{22,9},{22,10},{22,11},{22,12},{22,13},{23,2},{23,3},{23,4},{23,5},{23,6},{23,7},{23,8},{23,9},{23,10},{23,11},{23,12},{23,13},{23,15},{24,2},{25,2},{25,3},{25,4},{25,5},{25,6},{25,7},{25,8},{25,9},{25,10},{25,11},{25,12},{25,13},{25,20}},
	[39] = {{8,26},{20,13},{20,14},{20,15},{20,16},{20,17},{20,18},{20,19},{20,20},{20,21},{20,22},{20,23},{20,24},{20,25},{20,26},{20,27},{20,28},{20,29},{20,30},{21,13},{21,14},{21,15},{21,16},{21,17},{21,18},{21,19},{21,20},{21,21},{21,22},{21,23},{21,24},{21,25},{21,26},{21,27},{21,28},{21,29},{21,30},{22,14},{22,15},{22,16},{22,17},{22,18},{22,19},{22,20},{22,21},{22,22},{22,23},{22,24},{22,25},{22,26},{22,27},{22,28},{22,29},{22,30},{23,13},{23,14},{23,15},{23,16},{23,17},{23,18},{23,19},{23,20},{23,21},{23,22},{23,23},{23,24},{23,25},{23,26},{23,27},{23,28},{23,29},{23,30},{24,27},{24,28},{24,29},{24,30},{25,27},{25,28},{25,29},{25,30},{26,27},{26,28},{26,29},{26,30},{27,27},{27,28},{27,29},{27,30},{28,29},{28,30},{29,26},{29,27},{29,28},{29,29},{29,30},{30,26},{30,27},{30,28},{30,29},{30,30},{31,26},{31,27},{31,28},{31,29},{31,30},{32,26},{32,27},{32,28},{32,29},{32,30},{33,26},{33,27},{33,28},{33,29},{33,30},{34,26},{34,27},{34,28},{34,29},{34,30},{35,26},{35,27},{35,28},{35,29},{35,30},{36,26},{36,27},{36,28},{36,29},{36,30}},
	[60] = {{2,3},{2,4},{2,5},{2,6},{2,7},{2,8},{2,9},{2,24},{2,25},{2,26},{2,27},{2,28},{3,3},{3,4},{3,5},{3,6},{3,7},{3,8},{3,9},{3,24},{3,25},{3,26},{3,27},{3,28},{4,3},{4,4},{4,5},{4,6},{4,7},{4,8},{4,9},{4,24},{4,25},{4,26},{4,27},{4,28},{5,3},{5,4},{5,5},{5,6},{5,7},{5,8},{5,9},{5,24},{5,25},{5,26},{5,27},{5,28},{6,3},{6,4},{6,5},{6,6},{6,7},{6,8},{6,9},{6,24},{6,25},{6,26},{6,27},{6,28},{7,3},{7,4},{7,5},{7,6},{7,7},{7,8},{7,9},{8,3},{8,4},{8,5},{8,6},{8,7},{8,8},{8,9},{9,6},{9,7},{9,8},{9,9},{25,3},{25,4},{25,5},{25,6},{25,7},{25,8},{26,3},{26,4},{26,5},{26,6},{26,7},{26,8},{27,3},{27,4},{27,5},{27,6},{27,7},{27,8},{28,3},{28,4},{28,5},{28,6},{28,7},{28,8},{28,9},{28,13},{28,14},{28,15},{28,16},{28,17},{28,18},{28,19},{28,20},{28,21},{28,22},{29,3},{29,4},{29,5},{29,6},{29,7},{29,8},{29,9},{29,13},{29,14},{29,15},{29,16},{29,17},{29,18},{29,19},{29,20},{29,21},{29,22},{30,3},{30,4},{30,5},{30,6},{30,7},{30,8},{30,9},{30,13},{30,14},{30,15},{30,16},{30,17},{30,18},{30,19},{30,20},{30,21},{30,22},{31,3},{31,4},{31,5},{31,6},{31,7},{31,8},{31,9},{31,13},{31,14},{31,15},{31,16},{31,17},{31,18},{31,19},{31,20},{31,21},{31,22},{31,23},{31,24},{32,13},{32,14},{32,15},{32,16},{32,17},{32,18},{32,19},{32,20},{32,21},{32,22},{32,23},{32,24},{33,13},{33,14},{33,15},{33,16},{33,17},{33,18},{33,19},{33,20},{33,21},{33,22},{33,23},{33,24},{34,13},{34,14},{34,15},{34,16},{34,17},{34,18},{34,19},{34,20},{34,21},{34,22},{34,23},{34,24},{35,13},{35,14},{35,15},{35,16},{35,17},{35,18},{35,19},{35,20},{35,21},{35,23},{35,24},{35,25},{35,26},{36,13},{36,14},{36,15},{36,16},{36,17},{36,18},{36,19},{36,20},{36,21},{36,22},{36,23},{36,24},{36,26},{37,13},{37,14},{37,15},{37,16},{37,17},{37,18},{37,19},{37,20},{37,21},{37,22},{37,23},{37,24},{37,25},{37,26},{38,13},{38,14},{38,15},{38,16},{38,17},{38,18},{38,19},{38,20},{38,21},{38,22},{38,23},{38,24},{38,25},{38,26},{38,27},{39,13},{39,14},{39,15},{39,16},{39,17},{39,18},{39,19},{39,20},{39,21},{39,22},{39,23},{39,24},{39,25},{39,26},{39,27},{40,13},{40,14},{40,15},{40,16},{40,17},{40,18},{40,19},{40,20},{40,21},{40,22},{40,23},{40,24},{40,25},{40,26},{40,27}},
	[64] = {{21,33},{21,34},{21,35},{21,36},{22,33},{22,34},{22,35},{22,36},{23,33},{23,34},{23,35},{23,36},{24,33},{24,34},{24,35},{24,36},{25,32},{25,33},{25,34},{25,35},{25,36},{26,32},{26,33},{26,34},{27,32},{27,33},{27,34},{28,25},{28,26},{28,32},{28,33},{28,34},{28,35},{29,25},{29,26},{29,31},{30,25},{30,26},{30,31},{30,32},{30,33},{30,34},{30,35},{31,25},{31,26},{31,31},{31,32},{31,33},{31,34},{32,25},{32,26},{32,31},{32,32},{32,33},{32,34},{33,22},{33,23},{33,24},{33,25},{33,26},{33,31},{33,32},{33,33},{33,34},{34,22},{34,23},{34,24},{34,25},{34,26},{34,31},{34,32},{34,33},{34,34},{35,13},{35,22},{35,23},{35,24},{35,25},{35,26},{36,13},{36,14},{36,15},{36,16},{36,17},{36,18},{36,22},{36,23},{36,24},{36,25},{36,26},{37,13},{37,14},{37,15},{37,16},{37,17},{37,18},{37,22},{37,23},{37,24},{37,25},{37,26},{38,13},{38,14},{38,15},{38,16},{38,17},{38,18},{39,17},{39,18},{40,17},{40,18}},
	[65] = {{11,31},{11,32},{12,31},{12,32},{13,31},{13,32},{13,33},{31,15},{31,16},{32,15},{32,16},{32,17},{33,15},{33,16},{33,17},{34,15},{34,16},{34,17},{34,23},{34,24},{34,25},{35,15},{35,16},{35,17},{35,23},{35,24},{35,25},{36,23},{36,24},{36,25}},
}

ZYD.DropList = {
	["Klepsydra"] = {"Bronzong","Gible","Prinplup","Drifblim","Shinx","Luxio","Purugly","Riolu","Lopunny","Lucario","Yanmega","Togekiss","Magmortar","Electivire","Tangrowth","Weavile","Abomasnow","Toxicroak","Croagunk"}
}

while true do
	local map = 60
	for a,b in pairs(ZYD.Maps[map]) do
		ZYD.KillAllMobs(map, b[1], b[2], 1, 165, ZYD.DropList["Klepsydra"])
	end
	print("\n--------QUICK RECAP--------")
	print("Captchas solved: "..ZYD.Statistics["Captchas_solved"])
	print("Mobs killed: "..ZYD.Statistics["Mobs_killed"])
	print("Program running for "..os.time()-ZYD.StartTime.." seconds")
	print("Current date "..os.date("[%d.%m.%y %H:%M]"))
	print("--------QUICK RECAP--------\n")
	ZYD.Wait(5)
	ZYD.Solved = false
end
