--By smwlover at JUL/2015.
--Sword Art Online Project for QSanguosha.
module("extensions.swordartonline",package.seeall)
extension=sgs.Package("swordartonline")

--增加SAO势力
do
    require  "lua.config" 
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
				local cards = source:getHandcards()
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
	can_trigger = function(self, target)
		return target ~= nil
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() ~= sgs.Player_Start then
			return false
		end
		local silica = room:findPlayerBySkillName(self:objectName())
		if not silica then
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
	end
}

--Genki
GenkiCard = sgs.CreateSkillCard{
	name = "LuaGenki",
	filter = function(self, targets, to_select, player)
		return #targets < sgs.Self:getHp()
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