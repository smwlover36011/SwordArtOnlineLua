--By smwlover at JUL/2015.
--Sword Art Online Project for QSanguosha.
module("extensions.swordartonline",package.seeall)
extension=sgs.Package("swordartonline")

--增加SAO势力
do
    require "lua.config" 
	local config = config
	local kingdoms = config.kingdoms
	table.insert(kingdoms,"sao")
	config.color_de = "#FF00FF"
end
sgs.LoadTranslationTable{
	["sao"] = "剑",
	["swordartonline"] = "刀剑神域",
}

--SAO-103 Lisbeth
Lisbeth = sgs.General(extension,"Lisbeth","sao","3",false)

--Ondo
Ondo = sgs.CreateMasochismSkill{
	name = "LuaOndo",
	on_damaged = function(self, target, damage)
		local source = damage.from
		if source and source:isAlive() and not source:isKongcheng() then
			if target:askForSkillInvoke(self:objectName(), sgs.QVariant("draw:"..source:objectName())) then
				local room = target:getRoom()
				room:showAllCards(source)
				local cards = source:getHandcards() --getHandCards() returns QList<Card*> while handCards() returns QList<int> where "int" is cardId.
				local num = 0
				for _, card in sgs.qlist(cards) do
					if card:isRed() then
						num = num + 1
					end
				end
				if num > 0 then
					if num < 5 then
						target:drawCards(num)
					else
						target:drawCards(5)
					end
				end
			end
		end
		return false
	end
}

--Soubi
SoubiCard = sgs.CreateSkillCard{
	name = "SoubiCard",
	will_throw = false,
	handling_method = sgs.Card_MethodNone,
	filter = function(self, targets, to_select, lisbeth)
		if #targets ~= 0 or to_select:objectName() == lisbeth:objectName() then 
			return false 
		end
		local card = sgs.Sanguosha:getCard(self:getSubcards():first())
		local equip = card:getRealCard():toEquipCard()
		local equip_index = equip:location()
		return to_select:getEquip(equip_index) == nil
	end,
	feasible = function(self, targets)
		return #targets == 1
	end,
	on_effect = function(self, effect)
		local lisbeth = effect.from
		local dist = effect.to
		local room = lisbeth:getRoom()
		room:notifySkillInvoked(lisbeth,"LuaSoubi")
		room:broadcastSkillInvoke("LuaSoubi")
		
		room:moveCardTo(self, lisbeth, dist, sgs.Player_PlaceEquip, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, lisbeth:objectName(), "soubi", ""))
		room:setPlayerMark(lisbeth, "additionalSize", dist:getEquips():length())
	end
}

Soubi = sgs.CreateOneCardViewAsSkill{
	name = "LuaSoubi",	
	filter_pattern = "EquipCard|.|.|.",
	view_as = function(self, card)
		local soubiCard = SoubiCard:clone()
		soubiCard:addSubcard(card)
		soubiCard:setSkillName(self:objectName())
		return soubiCard
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#SoubiCard")
	end
}

SoubiMaxcard = sgs.CreateMaxCardsSkill{
	name = "#LuaSoubiMaxcard",
	extra_func = function(self, target)
		local mark = target:getMark("additionalSize")
		if target:hasSkill(self:objectName()) then
			return mark
		else
			return 0
		end
	end
}

SoubiTrigger=sgs.CreateTriggerSkill{
	name = "#LuaSoubiTrigger",
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local phase = player:getPhase()
		local room = player:getRoom()
		if phase == sgs.Player_Discard then
			local mark = player:getMark("additionalSize")
			if mark == 0 then
				return false
			end
			
			room:notifySkillInvoked(player,"LuaSoubi")
			room:broadcastSkillInvoke("LuaSoubi")
			local log = sgs.LogMessage()
			log.type = "#SoubiMaxcard"
			log.from = player
			log.arg = "LuaSoubi"
			log.arg2 = mark
			room:sendLog(log)
		elseif phase == sgs.Player_Finish then
			room:setPlayerMark(player, "additionalSize", 0)
		end
		return false
	end
}

Lisbeth:addSkill(Ondo)
Lisbeth:addSkill(Soubi)
Lisbeth:addSkill(SoubiMaxcard)
Lisbeth:addSkill(SoubiTrigger)
extension:insertRelatedSkills("LuaSoubi","#LuaSoubiMaxcard")
extension:insertRelatedSkills("LuaSoubi","#LuaSoubiTrigger")

sgs.LoadTranslationTable{	
	["Lisbeth"]="莉兹贝特",
	["&Lisbeth"]="莉兹",
	["#Lisbeth"]="锻造师",
	["designer:Lisbeth"]="Smwlover",
	["cv:Lisbeth"]="高垣彩阳",
	["illustrator:Lisbeth"]="Pixiv=49511537",
	
	["LuaOndo"]="温度",
	[":LuaOndo"]="<b>（心的温度）</b>每当你受到伤害后，你可以令伤害来源展示所有手牌，其中每有一张红色牌，你摸一张牌（至多五张）。",
	["LuaOndo:draw"]="你可以对 %src 发动技能“心的温度”",
	["LuaSoubi"]="锻冶",
	[":LuaSoubi"]="<b>（装备锻冶）</b><font color=\"green\"><b>阶段技，</b></font>你可以将一张装备牌置于一名其他角色的装备区中，然后令你的手牌上限+X（X为该角色装备区中牌的数量），直到回合结束。",
	["#SoubiMaxcard"]="%from 的武将技能 %arg 被触发，手牌上限增加 %arg2",
	["soubi"]="装备锻冶",
	
	["~Lisbeth"]=""
}

--SAO-104 Silica
Silica = sgs.General(extension,"Silica","sao","3",false)

--Mamori
Mamori = sgs.CreateTriggerSkill{
	name = "LuaMamori",
	events = {sgs.EventPhaseStart},
	frequency = sgs.Skill_Frequent,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() ~= sgs.Player_Start then
			return false
		end
		local silica = room:findPlayerBySkillName(self:objectName())
		if not silica or not silica:isAlive() then
			return false
		end
		if silica:isWounded() then
			if room:askForSkillInvoke(silica, self:objectName(), sgs.QVariant("recover")) then
				local judge = sgs.JudgeStruct()
				judge.pattern = ".|heart"
				judge.good = true
				judge.reason = self:objectName()
				judge.who = silica
				room:judge(judge)
				if judge:isGood() then
					room:recover(silica, sgs.RecoverStruct(silica))
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target and target:isAlive()
	end
}

--Genki
GenkiCard = sgs.CreateSkillCard{
	name = "LuaGenki",
	filter = function(self, targets, to_select, player)
		return #targets < player:getHp()
	end,
	feasible = function(self, targets)
		return #targets > 0 and #targets <= sgs.Self:getHp()
	end,	
	on_use = function(self, room, source, targets)
		room:notifySkillInvoked(source,"LuaGenki")
		room:broadcastSkillInvoke("LuaGenki")
		for i=1, #targets, 1 do
			targets[i]:drawCards(1)
		end
	end
}

LuaGenkiVS = sgs.CreateViewAsSkill{
	name = "LuaGenki",
	response_pattern = "@@LuaGenki",
	n = 0,
	view_as = function(self, cards)
		local genkiCard = GenkiCard:clone()
		return genkiCard
	end
}

Genki = sgs.CreateTriggerSkill{
	name = "LuaGenki",
	events = {sgs.HpRecover},
	view_as_skill = LuaGenkiVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		room:askForUseCard(player, "@@LuaGenki", "@LuaGenki:::"..player:getHp())
		return false
	end
}

Silica:addSkill(Mamori)
Silica:addSkill(Genki)

sgs.LoadTranslationTable{	
	["Silica"]="西莉卡",
	["&Silica"]="西莉卡",
	["#Silica"]="龙使",
	["designer:Silica"]="Smwlover",
	["cv:Silica"]="日高里菜",
	["illustrator:Silica"]="Pixiv=30844223",
	
	["LuaMamori"]="守护",
	[":LuaMamori"]="<b>（毕娜的守护）</b>一名角色的准备阶段开始时，若你已受伤，你可以进行一次判定，若判定结果为红桃，你回复1点体力。",
	["LuaMamori:recover"]="你可以发动技能“毕娜的守护”",
	["LuaGenki"]="元气",
	[":LuaGenki"]="<b>（元气偶像）</b>每当你回复体力后，你可以令至多X名角色各摸一张牌（X为你的体力值）。",
	["luagenki"]="元气偶像",
	["@LuaGenki"]="你可以对至多 %arg 名角色发动技能“元气偶像”",
	["~LuaGenki"]="选择目标角色→点击“确定”",
	
	["~Silica"]=""
}

--SAO-105 Sachi
Sachi = sgs.General(extension,"Sachi","sao","3",false)

--Mayou
Mayou = sgs.CreateTriggerSkill{
	name = "LuaMayou",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.TargetConfirmed},
	on_trigger = function(self, event, sachi, data)
		local room = sachi:getRoom()
		local use = data:toCardUse()
		local card = use.card
		if sachi:objectName() == use.from:objectName() then
			if card:isKindOf("Slash") then
				--sendLog:
				local log = sgs.LogMessage()
				log.type = "#TriggerSkill"
				log.from = sachi
				log.arg = self:objectName()
				room:sendLog(log)
				
				if not room:askForCard(sachi, ".", "@LuaMayou:::"..1, data, self:objectName()) then
					local nullified_list = use.nullified_list
					for _, p in sgs.qlist(use.to) do
						table.insert(nullified_list, p:objectName())
					end
					use.nullified_list = nullified_list
					data:setValue(use)
				end
			end
		end
	end
}

--Negai
Negai = sgs.CreateTriggerSkill{
	name = "LuaNegai",
	events = {sgs.EventPhaseChanging},
	on_trigger = function(self, event, sachi, data)
		local change = data:toPhaseChange()
		if change.to == sgs.Player_Discard then
			if sachi:isKongcheng() then
				return false
			end
			local cards = sachi:getHandcards()
			local num = 0
			for _, card in sgs.qlist(cards) do
				if card:isKindOf("Slash") then
					num = num + 1
				end
			end
			if num == 0 and sachi:askForSkillInvoke(self:objectName()) then
				local room = sachi:getRoom()
				room:showAllCards(sachi)
				sachi:skip(sgs.Player_Discard)
			end
		end
		return false
	end
}

--Takushi
TakushiCard = sgs.CreateSkillCard{
	name = "LuaTakushi",
	target_fixed = false,
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:isMale() and to_select:objectName() ~= self:objectName()
	end,
	on_use = function(self, room, source, targets)
		room:notifySkillInvoked(source, "LuaTakushi")
		room:broadcastSkillInvoke("LuaTakushi")
		room:doLightbox("Takushi$", 2500)
	
		source:loseMark("@takushi")
		targets[1]:gainMark("@takushi_target")
	end
}

LuaTakushiVS = sgs.CreateViewAsSkill{
	name = "LuaTakushi",
	n = 0,
	view_as = function(self, cards)
		local card = TakushiCard:clone()
		return card
	end,
	enabled_at_play = function(self, player)
		return player:getMark("@takushi") >= 1
	end
}

Takushi = sgs.CreateTriggerSkill{
	name = "LuaTakushi" ,
	frequency = sgs.Skill_Limited,
	limit_mark = "@takushi",
	events = {},
	view_as_skill = LuaTakushiVS ,
	on_trigger = function()
		return false
	end
}

TakushiDraw = sgs.CreateTriggerSkill{
	name = "#LuaTakushiDraw",
	events = {sgs.CardUsed} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if use.card:isKindOf("Slash") then
			local sachi = room:findPlayerBySkillName(self:objectName())
			if not sachi or not sachi:isAlive() then
				return false
			end
			
			--sendLog:
			local log = sgs.LogMessage()
			log.type = "#TriggerSkill"
			log.from = sachi
			log.arg = "LuaTakushi"
			room:sendLog(log)
			room:notifySkillInvoked(sachi, "LuaTakushi")
			room:broadcastSkillInvoke("LuaTakushi")
			sachi:drawCards(1, "LuaTakushi")
		end
		return false
	end,
	can_trigger = function(self, target)
		return target and target:isAlive() and target:getMark("@takushi_target") >= 1
	end
}

Sachi:addSkill(Mayou)
Sachi:addSkill(Negai)
Sachi:addSkill(Takushi)
Sachi:addSkill(TakushiDraw)
extension:insertRelatedSkills("LuaTakushi","#LuaTakushiDraw")

sgs.LoadTranslationTable{	
	["Sachi"]="幸",
	["&Sachi"]="幸",
	["#Sachi"]="逝去的温柔",
	["designer:Sachi"]="Smwlover",
	["cv:Sachi"]="早见沙织",
	["illustrator:Sachi"]="Pixiv=46959959",
	
	["LuaMayou"]="徘徊",
	[":LuaMayou"]="<b>（徘徊歧路）</b><font color=\"blue\"><b>锁定技，</b></font>每当你使用【杀】指定目标后，你须弃置一张手牌，否则此【杀】对目标角色无效。",
	["@LuaMayou"]="你需要弃置 %arg 张手牌",
	["LuaNegai"]="祈愿",
	[":LuaNegai"]="<b>（美丽的祈愿）</b>弃牌阶段开始前，若你的手牌中没有【杀】，你可以展示所有手牌（至少一张），然后跳过本回合的弃牌阶段。",
	["LuaTakushi"]="寄托",
	[":LuaTakushi"]="<b>（心灵寄托）</b><font color=\"red\"><b>限定技，</b></font>出牌阶段，你可以选择一名男性角色。直到游戏结束，每当该角色使用【杀】时，你可以摸一张牌。",
	["@takushi"]="寄托",
	["@takushi_target"]="寄托目标",
	["luatakushi"]="心灵寄托",
	["Takushi$"]="image=image/animate/Sachi.png",
	
	["~Sachi"]="谢谢你，再见……"
}

--SAO-109 Agil
Agil = sgs.General(extension,"Agil","sao","4",true)

--Boueki
BouekiCard = sgs.CreateSkillCard{
	name = "BouekiCard",
	will_throw = false,
	handling_method = sgs.Card_MethodNone,
	filter = function(self, targets, to_select, player)
		return #targets == 0 and to_select:getHandcardNum() >= player:getHandcardNum() and to_select:objectName() ~= player:objectName()
	end,
	feasible = function(self, targets)
		return #targets == 1
	end,
	on_use = function(self, room, source, targets)
		room:notifySkillInvoked(source,"LuaBoueki")
		room:broadcastSkillInvoke("LuaBoueki")
		room:showCard(source, self:getEffectiveId()) --showCard
	end
}

BouekiGiveCard = sgs.CreateSkillCard{
	name = "BouekiGiveCard",
	will_throw = false,
	target_fixed = true,
	handling_method = sgs.Card_MethodNone,
	on_use = function(self, room, source, targets)
		--Find Agil:
		local agil = nil
		local card = sgs.Card_Parse(source:property("BouekiShowedCard"):toString())
		for _, p in sgs.qlist(room:getAlivePlayers()) do
			if p:hasFlag("BouekiInvoker") then
				agil = p
				break
			end
		end
		--Exchange:
		if agil and agil:isAlive() and card then
			local a = agil
			local b = source
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if p:objectName() ~= a:objectName() and p:objectName() ~= b:objectName() then
					room:doNotify(p, sgs.CommandType.S_COMMAND_EXCHANGE_KNOWN_CARDS, json.encode({a:objectName(), b:objectName()}))
				end
			end
			local exchangeMove = sgs.CardsMoveList()
			local move1 = sgs.CardsMoveStruct(card:getId(), b, sgs.Player_PlaceHand, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_SWAP, a:objectName(), b:objectName(), "LuaBoueki", ""))
			local move2 = sgs.CardsMoveStruct(self:getSubcards(), a, sgs.Player_PlaceHand, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_SWAP, b:objectName(), a:objectName(), "LuaBoueki", ""))
			exchangeMove:append(move1)
			exchangeMove:append(move2)
			room:moveCardsAtomic(exchangeMove, false);
		end
	end
}

LuaBouekiVS = sgs.CreateViewAsSkill{
	name = "LuaBoueki",
	n = 999,
	view_filter = function(self, selected, to_select)
		local player = sgs.Self
		if player:hasFlag("BouekiInvoked") then
			return not to_select:isEquipped()
		else
			return #selected == 0 and to_select:isRed() and not to_select:isEquipped()
		end
	end,
	view_as = function(self, cards)
		local player = sgs.Self
		if player:hasFlag("BouekiInvoked") then
			local card = sgs.Card_Parse(player:property("BouekiShowedCard"):toString())
			local num = card:getNumber()
			local total = 0
			for _, c in ipairs(cards) do
				total = total + c:getNumber()
			end
			if total >= num or #cards == player:getHandcardNum() then
				local card = BouekiGiveCard:clone()
				for _, c in ipairs(cards) do
					card:addSubcard(c)
				end
				return card
			end
		else
			if #cards == 1 then
				local card = BouekiCard:clone()
				card:addSubcard(cards[1]) --The SkillName of the card is "boueki"
				return card
			end
		end
		return nil
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#BouekiCard")
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@LuaBoueki!"  
	end
}

Boueki = sgs.CreateTriggerSkill{
	name = "LuaBoueki",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.CardFinished},
	view_as_skill = LuaBouekiVS,
	on_trigger = function(self, event, agil, data)
		local room = agil:getRoom()
		local use = data:toCardUse()
		local source = use.from
		local target = use.to:first()
		local card = use.card
		if not agil:hasSkill(self:objectName()) then
			return false
		end
		if agil:objectName() ~= source:objectName() then
			return false
		end
		if card:getSkillName() ~= "boueki" then
			return false
		end
		if not target or not target:isAlive() then
			return false
		end
		local card = use.card:getSubcards():first()
		local trueCard = sgs.Sanguosha:getCard(card)
		local num = trueCard:getNumber()
		room:setPlayerFlag(source, "BouekiInvoker")
		room:setPlayerFlag(target, "BouekiInvoked")
		room:setPlayerProperty(target, "BouekiShowedCard", sgs.QVariant(trueCard:toString()))
		local used = room:askForUseCard(target, "@@LuaBoueki!", "@LuaBoueki:::"..num, -1, sgs.Card_MethodNone) --"!" means forced.
		if not used then
			--If AI didn't choose any card:
			--First, sort the player's handcards.
			local handcards = target:getHandcards()
			for i = handcards:length()-1, 1, -1 do
				for j = 0, i-1, 1 do
					if handcards:at(j):getNumber() < handcards:at(j+1):getNumber() then
						handcards:swap(j, j+1)
					end
				end
			end
			--Then, choose cards in descending order.
			local index = 0
			local sum = 0
			for i = 0, handcards:length(), 1 do
				sum = sum + handcards:at(i):getNumber()
				index = index + 1
				if sum >= num then
					break
				end
			end
			local toGive = handcards:mid(0, index)
			local giveCard = BouekiGiveCard:clone()
			for _, c in sgs.qlist(toGive) do
				giveCard:addSubcard(c:getId())
			end
			local useTargets = {}
			giveCard:on_use(room, target, useTargets)
		end
		room:setPlayerFlag(source, "-BouekiInvoker")
		room:setPlayerFlag(target, "-BouekiInvoked")
		room:setPlayerProperty(target, "BouekiShowedCard", sgs.QVariant(""))
		return false
	end,
	can_trigger = function(self, target)
		return target and target:isAlive()
	end
}

Agil:addSkill(Boueki)

sgs.LoadTranslationTable{	
	["Agil"]="艾基尔",
	["&Agil"]="艾基尔",
	["#Agil"]="道具商人",
	["designer:Agil"]="Smwlover",
	["cv:Agil"]="安元洋贵",
	["illustrator:Agil"]="",
	
	["LuaBoueki"]="精明",
	[":LuaBoueki"]="<b>（精明的商人）</b><font color=\"green\"><b>阶段技，</b></font>你可以展示一张红色手牌并选择一名手牌数不小于你的其他角色，令该角色选择任意数量的点数之和不小于X的手牌（不足则全部选择，X为你展示的牌的点数），然后将这些手牌与你展示的牌交换。",
	["boueki"]="精明的商人",
	["@LuaBoueki"]="请选择任意数量的点数之和不小于 %arg 的手牌，或者你的全部手牌",
	["~LuaBoueki"]="选择手牌→点击“确定”",
	["bouekigive"]="付款",
	
	["~Agil"]=""
}