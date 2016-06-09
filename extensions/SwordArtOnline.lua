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

--Skill Anjiang and Synthesis
SkillAnJiang = sgs.General(extension,"SAOSkillAnJiang","sao","5",true,true,true)
Synthesis = sgs.CreateTriggerSkill{
	name = "#LuaSynthesis",
	events = {sgs.GameStart},
	on_trigger = function(self, event, player, data)
		player:gainMark("@synthesis", 1)
		return false
	end
}
SkillAnJiang:addSkill(Synthesis)
sgs.LoadTranslationTable{
	["@synthesis"]="整合",
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
				local cards = source:getHandcards() --getHandcards() returns QList<Card*> while handCards() returns QList<int> where "int" is cardId.
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
	["LuaOndo:draw"]="你可以发动技能“心的温度”令 %src 展示手牌",
	["LuaSoubi"]="锻冶",
	[":LuaSoubi"]="<b>（装备锻冶）</b><font color=\"green\"><b>阶段技，</b></font>你可以将一张装备牌置于一名其他角色的装备区中，然后令你的手牌上限+X（X为该角色装备区中牌的数量），直到回合结束。",
	["#SoubiMaxcard"]="%from 的武将技能“%arg”被触发，手牌上限增加 %arg2",
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
				room:sendCompulsoryTriggerLog(sachi, self:objectName(), true)
				room:notifySkillInvoked(sachi,self:objectName())
				room:broadcastSkillInvoke(self:objectName())
				--Ask for discard:
				if not room:askForCard(sachi, ".|.|.|hand", "@LuaMayou:::"..1, data, self:objectName()) then --The influence of JiLei has already been considered.
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
			if num == 0 and sachi:askForSkillInvoke(self:objectName(), sgs.QVariant("skip")) then
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
	filter = function(self, targets, to_select, sachi)
		return #targets == 0 and to_select:isMale() and to_select:objectName() ~= sachi:objectName()
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
	view_as_skill = LuaTakushiVS,
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
			--Find sachi:
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
	["LuaNegai:skip"]="你可以发动“美丽的祈愿”跳过弃牌阶段",
	["LuaTakushi"]="寄托",
	[":LuaTakushi"]="<b>（心灵寄托）</b><font color=\"red\"><b>限定技，</b></font>出牌阶段，你可以选择一名男性角色。直到游戏结束，每当该角色使用【杀】时，你可以摸一张牌。",
	["@takushi"]="寄托",
	["@takushi_target"]="寄托目标",
	["luatakushi"]="心灵寄托",
	["Takushi$"]="image=image/animate/Sachi.png",

	["~Sachi"]="谢谢你，再见……"
}

--SAO-106 Yui
Yui = sgs.General(extension,"Yui","sao","3",false)

--Tamotsu
Tamotsu = sgs.CreateTriggerSkill{
	name = "LuaTamotsu",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.DamageInflicted},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if damage.nature == sgs.DamageStruct_Thunder or damage.nature == sgs.DamageStruct_Fire then
			--sendLog:
			local log = sgs.LogMessage()
			log.type = "#TamotsuPrevented"
			log.from = player
			log.arg = "LuaTamotsu"
			log.arg2 = damage.damage
			room:sendLog(log)
			room:notifySkillInvoked(player,"LuaTamotsu")
			room:broadcastSkillInvoke("LuaTamotsu")
			return true
		end
		return false
	end
}

--Kanshin
Kanshin = sgs.CreateTriggerSkill{
	name = "LuaKanshin",
	events = {sgs.Damaged},
	can_trigger = function(self, target)
		return target and target:isAlive()
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		--Find yui:
		local yui = room:findPlayerBySkillName(self:objectName())
		if not yui or not yui:isAlive() then
			return false
		end
		if yui:distanceTo(player) > 1 then
			return false
		end
		local damage = data:toDamage()
		local x = damage.damage
		for i = 0, x-1, 1 do
			if not yui or not yui:isAlive() or not player or not player:isAlive() then
				return false
			end
			if yui:askForSkillInvoke(self:objectName(), sgs.QVariant("draw:"..player:objectName())) then
				player:drawCards(1)
			end
		end
		return false
	end
}

--Yobu
YobuCard = sgs.CreateSkillCard{
	name = "LuaYobu",
	target_fixed = true,
	on_use = function(self, room, source, targets)
		room:notifySkillInvoked(source, "LuaYobu")
		room:broadcastSkillInvoke("LuaYobu")
		source:loseMark("@yobu")
		--Turnover:
		source:turnOver()
		--Get a random card:
		local discardPile = room:getDiscardPile()
		local weaponList = sgs.IntList()
		for _,id in sgs.qlist(discardPile) do
			local card = sgs.Sanguosha:getCard(id)
			if card:isKindOf("Weapon") then
				weaponList:append(id)
			end
		end
		if weaponList:isEmpty() then
			return
		end
		local randomNum = math.random(0, weaponList:length()-1)
		local chosenID = weaponList:at(randomNum)
		local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		dummy:addSubcard(chosenID)
		source:obtainCard(dummy) --Default behavior is "unhide this card".
		--Get victims:
		local chosenCard = sgs.Sanguosha:getCard(chosenID):getRealCard():toWeapon()
		local range = chosenCard:getRange()
		room:doLightbox("Yobu$", 2500)
		local victims = sgs.SPlayerList()
		for _, p in sgs.qlist(room:getAlivePlayers()) do
			if p and p:isAlive() and source:distanceTo(p) <= range then
				victims:append(p)
			end
		end
		room:sortByActionOrder(victims)
		--Deal damage:
		for _, p in sgs.qlist(victims) do
			if p and p:isAlive() then
				room:doAnimate(1, source:objectName(), p:objectName()) --Instruct line.
				room:damage(sgs.DamageStruct("LuaYobu", source, p, 1, sgs.DamageStruct_Fire))
			end
		end
	end
}

LuaYobuVS = sgs.CreateViewAsSkill{
	name = "LuaYobu",
	n = 0,
	view_as = function(self, cards)
		local card = YobuCard:clone()
		return card
	end,
	enabled_at_play = function(self, player)
		return player:getMark("@yobu") >= 1
	end
}

Yobu = sgs.CreateTriggerSkill{
	name = "LuaYobu" ,
	frequency = sgs.Skill_Limited,
	limit_mark = "@yobu",
	events = {},
	view_as_skill = LuaYobuVS,
	on_trigger = function()
		return false
	end
}

Yui:addSkill(Tamotsu)
Yui:addSkill(Kanshin)
Yui:addSkill(Yobu)

sgs.LoadTranslationTable{
	["Yui"]="结衣",
	["&Yui"]="结衣",
	["#Yui"]="MHCP001",
	["designer:Yui"]="Smwlover",
	["cv:Yui"]="伊藤加奈惠",
	["illustrator:Yui"]="Pixiv=32238450",

	["LuaTamotsu"]="保护",
	[":LuaTamotsu"]="<b>（系统保护）</b><font color=\"blue\"><b>锁定技，</b></font>每当你受到属性伤害时，防止此伤害。",
	["#TamotsuPrevented"]="%from 的武将技能“%arg”被触发，防止了 %arg2 点伤害",
	["LuaKanshin"]="护理",
	[":LuaKanshin"]="<b>（精神护理）</b>每当一名距离不大于1的角色受到1点伤害后，你可以令该角色摸一张牌。",
	["LuaKanshin:draw"]="你可以发动“精神护理”令 %src 摸一张牌",
	["LuaYobu"]="召唤",
	[":LuaYobu"]="<b>（神器召唤）</b><font color=\"red\"><b>限定技，</b></font>出牌阶段，你可以将武将牌翻面，从弃牌堆中随机获得一张武器牌，然后对距离不大于X的所有角色各造成1点火焰伤害（X为此牌的攻击范围）。",
	["luayobu"]="神器召唤",
	["@yobu"]="召唤",
	["Yobu$"]="image=image/animate/Yui.png",

	["~Yui"]=""
}
--SAO-108 Klein
Klein = sgs.General(extension,"Klein","sao","4",true)

--Honpou
function targetAvailable(player)
	local targets = sgs.PlayerList()
	local list = player:getAliveSiblings()
	for _,target in sgs.qlist(list) do
		if target:objectName() ~= player:objectName() and not target:isKongcheng() then
			targets:append(target)
		end
	end
	return not list:isEmpty()
end

function inSomebodysTurn(player)
	local current = false
	local players = player:getAliveSiblings()
	players:append(player)
	for _, p in sgs.qlist(players) do
		if p:getPhase() ~= sgs.Player_NotActive then
			current = true
			break
		end
	end
	return current
end

HonpouCard = sgs.CreateSkillCard{
	name = "HonpouCard",
	target_fixed = true,
	on_validate = function(self, cardUse)
		local source = cardUse.from
		local room = source:getRoom()
		local targets = sgs.SPlayerList()
		local list = room:getAlivePlayers()
		for _,tar in sgs.qlist(list) do
			if tar:objectName() ~= source:objectName() and not tar:isKongcheng() then
				targets:append(tar)
			end
		end
		local target = room:askForPlayerChosen(source, targets, "LuaHonpou", "@LuaHonpouChoose", true, false)
		if not target then
			return nil
		end
		--From now on, we can assume that the player has already used "LuaHonpou" this turn.
		--So we can attach a flag to the player.
		local log = sgs.LogMessage()
		log.type = "#HonpouInvoked"
		log.from = source
		log.to:append(target)
		log.arg = "LuaHonpou"
		room:sendLog(log)
		room:notifySkillInvoked(source,"LuaHonpou")
		room:broadcastSkillInvoke("LuaHonpou")
		room:setPlayerFlag(source,"HonpouUsed")
		room:doAnimate(1, source:objectName(), target:objectName()) --Instruct line.
		--Pindian:
		local success = source:pindian(target, "LuaHonpou", nil)
		if success then
			local analeptic = sgs.Sanguosha:cloneCard("analeptic", sgs.Card_NoSuit, 0)
			analeptic:setSkillName("LuaHonpou")
			return analeptic
		else
			if source:getPhase() == sgs.Player_Play then
				room:setPlayerCardLimitation(source, "use", "Slash", true) --"True" means for single turn.
			end
		end
		return nil
	end
}

Honpou = sgs.CreateViewAsSkill{
	name = "LuaHonpou",
	n = 0,
	enabled_at_play = function(self, player)
		return inSomebodysTurn(player) and targetAvailable(player) and not player:hasFlag("HonpouUsed") and not player:isKongcheng() and sgs.Analeptic_IsAvailable(player)
	end,
	enabled_at_response = function(self, player, pattern)
		return inSomebodysTurn(player) and targetAvailable(player) and not player:hasFlag("HonpouUsed") and not player:isKongcheng() and string.find(pattern, "analeptic")
	end,
	view_as = function(self, cards)
		local card = HonpouCard:clone()
		return card
	end
}

HonpouClear = sgs.CreateTriggerSkill{
	name = "#LuaHonpouClear",
	events = {sgs.EventPhaseChanging},
	on_trigger = function(self, event, player, data)
		local change = data:toPhaseChange()
		local room = player:getRoom()
		if change.to == sgs.Player_NotActive then
			--Clear Klein's "HonpouUsed" flag.
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if p:hasFlag("HonpouUsed") then
					room:setPlayerFlag(p, "-HonpouUsed")
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end
}

Klein:addSkill(Honpou)
Klein:addSkill(HonpouClear)
extension:insertRelatedSkills("LuaHonpou","#LuaHonpouClear")

sgs.LoadTranslationTable{
	["Klein"]="克莱因",
	["&Klein"]="克莱因",
	["#Klein"]="武士之风",
	["designer:Klein"]="Smwlover",
	["cv:Klein"]="平田广明",
	["illustrator:Klein"]="Pixiv=34275976",

	["LuaHonpou"]="豪情",
	[":LuaHonpou"]="<b>（豪情烈胆）</b>每名角色的回合限一次，每当你需要使用【酒】时，你可以与一名其他角色拼点。若你赢，视为你使用了一张【酒】；若你没赢且此时在你的出牌阶段内，你无法使用【杀】直到回合结束。",
	["@LuaHonpouChoose"]="请选择一名角色与其拼点",
	["#HonpouInvoked"]="%from 发动技能“%arg”对 %to 进行拼点",

	["~Klein"]=""
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
		if not card or card:getSkillName() ~= "boueki" then
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
	["illustrator:Agil"]="官方",

	["LuaBoueki"]="精明",
	[":LuaBoueki"]="<b>（精明的商人）</b><font color=\"green\"><b>阶段技，</b></font>你可以展示一张红色手牌并选择一名手牌数不小于你的其他角色，令该角色选择任意数量的点数之和不小于X的手牌（不足则全部选择，X为你展示的牌的点数），然后将这些牌与你展示的牌交换。",
	["boueki"]="精明的商人",
	["@LuaBoueki"]="请选择任意数量的点数之和不小于 %arg 的手牌，或者你的全部手牌",
	["~LuaBoueki"]="选择手牌→点击“确定”",
	["bouekigive"]="支付费用",

	["~Agil"]=""
}

--SAO-110 Kuradeel
Kuradeel = sgs.General(extension,"Kuradeel","sao","4",true)

--Boukun
Boukun = sgs.CreateTriggerSkill{
	name = "LuaBoukun",
	frequency = sgs.Skill_Frequent,
	events = {sgs.Dying},
	on_trigger = function(self, event, player, data)
		local dying = data:toDying()
		local who = dying.who
		local damage = dying.damage
		local from = damage.from
		local card = damage.card
		if who:objectName() == player:objectName() then
			return false
		end
		if not from:hasSkill(self:objectName()) or from:objectName() ~= player:objectName() then
			return false
		end
		if card:isKindOf("Slash") then
			if from:askForSkillInvoke(self:objectName(), sgs.QVariant("draw")) then
				from:drawCards(1)
			end
		end
		return false
	end
}

--Nikushimi
NikushimiCard = sgs.CreateSkillCard{
	name = "LuaNikushimi",
	will_throw = false,
	target_fixed = true,
	handling_method = sgs.Card_MethodNone,
	on_use = function(self, room, source, targets)
		room:notifySkillInvoked(source,"LuaNikushimi")
		room:broadcastSkillInvoke("LuaNikushimi")

		local card = self:getSubcards():first()
		local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_REMOVE_FROM_PILE, "", self:objectName(), "")
		room:throwCard(sgs.Sanguosha:getCard(card), reason, nil)
	end
}

LuaNikushimiVS = sgs.CreateOneCardViewAsSkill{
	name = "LuaNikushimi",
	response_pattern = "@@LuaNikushimi",
	filter_pattern = ".|.|.|nikushimi",
	expand_pile = "nikushimi",
	view_as = function(self, card)
		local nikushimiCard = NikushimiCard:clone()
		nikushimiCard:addSubcard(card)
		return nikushimiCard
	end
}

NikushimiAddPile = sgs.CreateMasochismSkill{
	name = "#LuaNikushimiAddPile",
	on_damaged = function(self, player, damage)
		local room = player:getRoom()
		if player:askForSkillInvoke("LuaNikushimi", sgs.QVariant("addPile")) then
			local id = room:drawCard()
			player:addToPile("nikushimi", id)
		end
		return false
	end
}

Nikushimi = sgs.CreateTriggerSkill{
	name = "LuaNikushimi",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.DamageCaused},
	view_as_skill = LuaNikushimiVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if not damage.card or not damage.card:isKindOf("Slash") then
			return false
		end
		if damage.chain or damage.transfer or not damage.by_user then
			return false
		end
		if damage.from and damage.from:isAlive() and not damage.from:getPile("nikushimi"):isEmpty() then
			local used = room:askForUseCard(damage.from, "@@LuaNikushimi", "@LuaNikushimi:"..damage.to:objectName(), -1, sgs.Card_MethodNone)
			if used then
				damage.damage = damage.damage + 1
				data:setValue(damage)
			end
		end
		return false
	end
}

Kuradeel:addSkill(Boukun)
Kuradeel:addSkill(Nikushimi)
Kuradeel:addSkill(NikushimiAddPile)
extension:insertRelatedSkills("LuaNikushimi","#LuaNikushimiAddPile")

sgs.LoadTranslationTable{
	["Kuradeel"]="克拉帝尔",
	["&Kuradeel"]="克拉帝尔",
	["#Kuradeel"]="深仇大恨",
	["designer:Kuradeel"]="Smwlover",
	["cv:Kuradeel"]="游佐浩二",
	["illustrator:Kuradeel"]="官方",

	["LuaNikushimi"]="仇恨",
	[":LuaNikushimi"]="<b>（不共戴天）</b>每当你受到伤害后，你可以将牌堆顶的一张牌置于武将牌上，称为“仇”；每当你使用【杀】对目标角色造成伤害时，你可以将一张“仇”置入弃牌堆，令此伤害+1。",
	["LuaNikushimi:addPile"]="你可以发动技能“不共戴天”",
	["nikushimi"]="仇",
	["luanikushimi"]="不共戴天",
	["@LuaNikushimi"]="你可以对 %src 发动技能“不共戴天”",
	["~LuaNikushimi"]="选择一张“仇”→点击“确定”",
	["LuaBoukun"]="狂暴",
	[":LuaBoukun"]="<b>（暴君之龙）</b>每当其他角色因受到你使用【杀】造成的伤害而进入濒死状态时，你可以摸一张牌。",
	["LuaBoukun:draw"]="你可以发动“暴君之龙”摸一张牌",

	["~Kuradeel"]=""
}

--SAO-201 Kirito(ALO)
KiritoALO = sgs.General(extension,"KiritoALO","sao","4",true)

--Rengeki
Rengeki = sgs.CreateTriggerSkill{
	name = "LuaRengeki",
	frequency = sgs.Skill_Frequent,
	priority = -100,
	events = {sgs.PreDamageDone, sgs.EventPhaseStart, sgs.EventPhaseEnd},
	on_trigger = function(self, event, player, data)
		if event == sgs.EventPhaseStart then
			if player:hasSkill(self:objectName()) then
				if player:getPhase() == sgs.Player_Play then
					player:gainMark("@phaseNum")
				elseif player:getPhase() == sgs.Player_NotActive then
					player:loseAllMarks("@phaseNum")
				end
			end
		elseif event == sgs.PreDamageDone then
			local damage = data:toDamage()
			local from = damage.from
			if from and from:getPhase() == sgs.Player_Play and from:hasSkill(self:objectName()) then
				from:setMark("DamageDealt", from:getMark("DamageDealt") + damage.damage)
			end
		elseif event == sgs.EventPhaseEnd then
			if player:hasSkill(self:objectName()) then
				if player:getPhase() == sgs.Player_Play then
					local curDamage = player:getMark("DamageDealt")
					local curTurn = player:getMark("@phaseNum")
					--Clear player's mark:
					player:setMark("DamageDealt", 0)
					if curDamage >= curTurn then
						if player:askForSkillInvoke(self:objectName(), sgs.QVariant("extra")) then
							player:drawCards(curTurn)
							local room = player:getRoom()
							local log = sgs.LogMessage()
							log.type = "#RengekiExtra"
							log.from = player
							log.arg = "play"
							room:sendLog(log)
							player:insertPhase(sgs.Player_Play)
						end
					end
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target and target:isAlive()
	end
}

KiritoALO:addSkill(Rengeki)

sgs.LoadTranslationTable{
	["KiritoALO"]="桐人ALO",
	["&KiritoALO"]="桐人",
	["#KiritoALO"]="黑色剑士",
	["designer:KiritoALO"]="Smwlover",
	["cv:KiritoALO"]="松冈祯丞",
	["illustrator:KiritoALO"]="Pixiv=45122640",

	["LuaRengeki"]="连携",
	[":LuaRengeki"]="<b>（剑技连携）</b>出牌阶段结束后，若本阶段内你造成了至少X点伤害，你可以摸X张牌，然后执行一个额外的出牌阶段（X为本回合内你执行过的出牌阶段数量）。",
	["LuaRengeki:extra"]="你可以发动技能“剑技连携”进行一个额外的出牌阶段",
	["#RengekiExtra"]="%from 进行一个额外的 %arg 阶段",
	["@phaseNum"]="阶段",

	["~KiritoALO"]=""
}

--SAO-202 Asuna(ALO)
AsunaALO = sgs.General(extension,"AsunaALO","sao","3",false)

--Berserker
BerserkerCard = sgs.CreateSkillCard{
	name = "BerserkerCard",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:isWounded()
	end,
	feasible = function(self, targets)
		return #targets == 1
	end,
	on_use = function(self, room, source, targets)
		room:notifySkillInvoked(source,"LuaBerserker")
		room:broadcastSkillInvoke("LuaBerserker")
		--Recover:
		local target = targets[1]
		local recover = sgs.RecoverStruct()
		recover.who = source
		room:recover(target, recover)
		--If target is still wounded:
		if target and target:isAlive() and target:isWounded() then
			local slashTargets = sgs.SPlayerList()
			local list = room:getAlivePlayers()
			for _,slashTarget in sgs.qlist(list) do
				if source:canSlash(slashTarget, nil, false) then
					slashTargets:append(slashTarget)
				end
			end
			if slashTargets:isEmpty() then
				return false
			end
			local slashTarget = room:askForPlayerChosen(source, slashTargets, "LuaBerserker", "@BerserkerChoose", true, false)
			if not slashTarget then
				return false
			end
			--Use slash to slashTarget:
			local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			slash:setSkillName("LuaBerserker")
			local card_use = sgs.CardUseStruct()
			card_use.card = slash
			card_use.from = source
			card_use.to:append(slashTarget)
			room:useCard(card_use, false)
		end
	end
}

Berserker = sgs.CreateViewAsSkill{
	name = "LuaBerserker",
	n = 1,
	view_filter = function(self, selected, to_select)
		return #selected == 0 and to_select:isRed() and not sgs.Self:isJilei(to_select)
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local card = BerserkerCard:clone()
			card:addSubcard(cards[1])
			card:setSkillName(self:objectName())
			return card
		end
		return nil
	end,
	enabled_at_play = function(self, player)
		--Is there any wounded player?
		local enabled = false
		for _, p in sgs.qlist(player:getAliveSiblings()) do
			if p:isWounded() then
				enabled = true
				break
			end
		end
		enabled = enabled or player:isWounded()
		return enabled and player:canDiscard(player, "he") and not player:hasUsed("#BerserkerCard")
	end
}

--Mizuiro
Mizuiro = sgs.CreateTriggerSkill{
	name = "LuaMizuiro",
	events = {sgs.CardEffected},
	can_trigger = function(self, target)
		return target and target:isAlive()
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local effect = data:toCardEffect()
		local victim = effect.to
		local card = effect.card
		if not card or not card:isNDTrick() or not card:isBlack() then
			return false
		end
		--Find Asuna:
		local asuna = room:findPlayerBySkillName(self:objectName())
		if not asuna or not asuna:isAlive() then
			return false
		end
		if asuna:distanceTo(victim) > 1 then
			return false
		end
		if asuna:askForSkillInvoke(self:objectName(), sgs.QVariant("prevent:"..victim:objectName())) then
			local msg = sgs.LogMessage()
			msg.type = "#MizuiroPrevent"
			msg.from = effect.from
			msg.to:append(victim)
			msg.arg = card:objectName()
			room:sendLog(msg)
			return true
		end
		return false
	end
}

AsunaALO:addSkill(Berserker)
AsunaALO:addSkill(Mizuiro)

sgs.LoadTranslationTable{
	["AsunaALO"]="亚丝娜ALO",
	["&AsunaALO"]="亚丝娜",
	["#AsunaALO"]="狂暴补师",
	["designer:AsunaALO"]="Smwlover",
	["cv:AsunaALO"]="户松遥",
	["illustrator:AsunaALO"]="Pixiv=45620938",

	["LuaBerserker"]="补师",
	[":LuaBerserker"]="<b>（狂暴补师）</b><font color=\"green\"><b>阶段技，</b></font>你可以弃置一张红色牌，令一名已受伤的角色回复1点体力，然后若该角色仍处于受伤状态，你可以视为对一名其他角色使用了一张【杀】。",
	["berserker"]="狂暴补师",
	["@BerserkerChoose"]="你可以选择一名其他角色视为对其使用【杀】",
	["LuaMizuiro"]="屏障",
	[":LuaMizuiro"]="<b>（水色屏障）</b>每当一名距离不大于1的角色成为黑色非延时类锦囊牌的目标后，你可以令此牌对该角色无效。",
	["LuaMizuiro:prevent"]="你可以对 %src 发动技能“水色屏障”",
	["#MizuiroPrevent"]="%from 使用的【%arg】对 %to 无效",

	["~AsunaALO"]=""
}

--SAO-203 Leafa
Leafa = sgs.General(extension,"Leafa","sao","3",false)

--Mimamoru
MimamoruCard = sgs.CreateSkillCard{
	name = "MimamoruCard",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select, player)
		return #targets == 0 and to_select:isWounded() and to_select:objectName() ~= player:objectName()
	end,
	feasible = function(self, targets)
		return #targets == 1
	end,
	on_effect = function(self, effect)
		local source = effect.from
		local dest = effect.to
		local room = source:getRoom()
		dest:obtainCard(self)
		--Recover:
		local recover = sgs.RecoverStruct()
		recover.who = source
		room:recover(dest, recover)
	end
}

Mimamoru = sgs.CreateViewAsSkill{
	name = "LuaMimamoru",
	n = 1,
	view_filter = function(self, selected, to_select)
		return to_select:getSuit() == sgs.Card_Heart
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local mimamoruCard = MimamoruCard:clone()
			mimamoruCard:addSubcard(cards[1])
			return mimamoruCard
		end
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#MimamoruCard")
	end
}

--Kendou
Kendou = sgs.CreateTriggerSkill{
	name = "LuaKendou",
	events = {sgs.CardFinished},
	can_trigger = function(self, target)
		return target and target:isAlive()
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if use.card:isKindOf("EquipCard") then
			--Find Leafa:
			local leafa = room:findPlayerBySkillName(self:objectName())
			if not leafa or not leafa:isAlive() or leafa:objectName() == player:objectName() then
				return false
			end
			local equip = use.card:getRealCard():toEquipCard()
			local index = equip:location()
			if leafa:getEquip(index) == nil then
				return false
			end
			--Ask leafa for choice:
			local choice = room:askForChoice(leafa, self:objectName(), "draw_None+draw_Self+draw_Other", data)
			if choice ~= "draw_None" then
				room:notifySkillInvoked(leafa, self:objectName())
				room:broadcastSkillInvoke(self:objectName())
				--Sendlog:
				local log = sgs.LogMessage()
				log.type = "#TriggerSkill"
				log.from = leafa
				log.arg = self:objectName()
				room:sendLog(log)
				if choice == "draw_Self" then
					leafa:drawCards(1)
				elseif choice == "draw_Other" then
					player:drawCards(1)
				end
			end
		end
		return false
	end
}

Leafa:addSkill(Mimamoru)
Leafa:addSkill(Kendou)

sgs.LoadTranslationTable{
	["Leafa"]="莉法",
	["&Leafa"]="莉法",
	["#Leafa"]="绿之剑士",
	["designer:Leafa"]="Smwlover",
	["cv:Leafa"]="竹达彩奈",
	["illustrator:Leafa"]="Pixiv=31393729",

	["LuaMimamoru"]="守望",
	[":LuaMimamoru"]="<b>（守望的心）</b><font color=\"green\"><b>阶段技，</b></font>你可以将一张红桃牌交给一名其他角色，令其回复1点体力。",
	["mimamoru"]="守望的心",
	["LuaKendou"]="剑道",
	[":LuaKendou"]="<b>（剑道少女）</b>每当其他角色使用一张装备牌后，若你的装备区中有相同种类的装备牌，你可以令你或该角色摸一张牌。",
	["draw_None"]="不发动",
	["draw_Self"]="令你摸一张牌",
	["draw_Other"]="令该角色摸一张牌",

	["~Leafa"]=""
}

--SAO-206 Obeiron
Obeiron = sgs.General(extension,"Obeiron","sao","4",true)

--Akuma
Akuma = sgs.CreateFilterSkill{
	name = "LuaAkuma",
	view_filter = function(self, to_select)
		return to_select:getSuit() == sgs.Card_Heart
	end,
	view_as = function(self, card)
		local id = card:getEffectiveId()
		local new_card = sgs.Sanguosha:getWrappedCard(id)
		new_card:setSkillName(self:objectName())
		new_card:setSuit(sgs.Card_Spade)
		new_card:setModified(true)
		return new_card
	end
}

--Fushoku
FushokuCard = sgs.CreateSkillCard{
	name = "FushokuCard",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select, player)
		return #targets == 0 and to_select:objectName() ~= player:objectName()
	end,
	feasible = function(self, targets)
		return #targets == 1
	end,
	on_effect = function(self, effect)
		local source = effect.from
		local dest = effect.to
		local room = source:getRoom()
		dest:obtainCard(self)
		--Discard a handcard from dest.
		if source:isAlive() and dest:isAlive() and source:canDiscard(dest, "h") then
			local card_id = room:askForCardChosen(source, dest, "h", "LuaFushoku", false, sgs.Card_MethodDiscard)
			local card = sgs.Sanguosha:getCard(card_id)
			if not dest:isJilei(card) then
				room:throwCard(card_id, dest, source)
			else
				room:showCard(dest, card_id)
			end
			--Is the card a spade card?
			if card:getSuit() ~= sgs.Card_Spade then
				room:damage(sgs.DamageStruct("LuaFushoku", source, dest))
			end
		end
	end
}

Fushoku = sgs.CreateViewAsSkill{
	name = "LuaFushoku",
	n = 1,
	view_filter = function(self, selected, to_select)
		return to_select:getSuit() == sgs.Card_Spade
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local fushokuCard = FushokuCard:clone()
			fushokuCard:addSubcard(cards[1])
			return fushokuCard
		end
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#FushokuCard")
	end
}

Obeiron:addSkill(Akuma)
Obeiron:addSkill(Fushoku)

sgs.LoadTranslationTable{
	["Obeiron"]="奥伯龙",
	["&Obeiron"]="奥伯龙",
	["#Obeiron"]="精灵王",
	["designer:Obeiron"]="Smwlover",
	["cv:Obeiron"]="子安武人",
	["illustrator:Obeiron"]="官方",

	["LuaAkuma"]="恶毒",
	[":LuaAkuma"]="<b>（恶毒之心）</b><font color=\"blue\"><b>锁定技，</b></font>你的红桃牌均视为黑桃牌。",
	["LuaFushoku"]="侵蚀",
	[":LuaFushoku"]="<b>（心智侵蚀）</b><font color=\"green\"><b>阶段技，</b></font>你可以将一张黑桃牌交给一名其他角色，然后弃置该角色的一张手牌，若此牌不为黑桃，你对该角色造成1点伤害。",
	["fushoku"]="心智侵蚀",

	["~Obeiron"]=""
}

--SAO-303 DeathGun
DeathGun = sgs.General(extension,"DeathGun","sao","4",true)

--Toumei
Toumei = sgs.CreateProhibitSkill{
	name = "LuaToumei",
	is_prohibited = function(self, from, to, card)
		if to:hasSkill(self:objectName()) and to:getMark("@toumei") > 0 then
			return (card:isKindOf("TrickCard") or card:isKindOf("Slash") or card:isKindOf("QiceCard")) and card:isBlack() and card:getSkillName() ~= "nosguhuo"
		end
	end
}

ToumeiTrigger = sgs.CreateTriggerSkill{
	name = "#LuaToumeiTrigger",
	events = {sgs.GameStart, sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.GameStart then
			player:gainMark("@toumei", 1)
		elseif event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_RoundStart then
				if player:getMark("@toumei") > 0 then
					player:loseAllMarks("@toumei")
				end
			end
		end
		return false
	end
}

--Maboroshi
Maboroshi = sgs.CreateTriggerSkill{
	name = "LuaMaboroshi",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.DamageCaused},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if damage.card and damage.card:isKindOf("Slash") and damage.by_user and not damage.chain and not damage.transfer then
			if player:askForSkillInvoke(self:objectName(), sgs.QVariant("prevent:"..damage.to:objectName())) then
				local to = damage.to
				local msg = sgs.LogMessage()
				msg.type = "#MaboroshiPrevent"
				msg.to:append(to)
				msg.arg = damage.card:objectName()
				room:sendLog(msg)
				--Gain a "Death" mark.
				to:gainMark("@death", 1)
				if to:getMark("@death") >= 3 then
					room:killPlayer(to)
				end
				return true
			end
		end
		return false
	end
}

DeathGun:addSkill(Toumei)
DeathGun:addSkill(ToumeiTrigger)
DeathGun:addSkill(Maboroshi)
extension:insertRelatedSkills("LuaToumei","#LuaToumeiTrigger")

sgs.LoadTranslationTable{
	["DeathGun"]="新川昌一",
	["&DeathGun"]="新川昌一",
	["#DeathGun"]="死枪",
	["designer:DeathGun"]="Smwlover",
	["cv:DeathGun"]="大原崇",
	["illustrator:DeathGun"]="官方",

	["LuaToumei"]="隐身",
	[":LuaToumei"]="<b>（隐身斗篷）</b><font color=\"blue\"><b>锁定技，</b></font>你无法成为黑色【杀】或黑色锦囊牌的目标，直到你的第一个回合开始。",
	["@toumei"]="隐身",
	["LuaMaboroshi"]="死枪",
	[":LuaMaboroshi"]="<b>（幻之铳弹）</b>每当你使用【杀】对目标角色造成伤害时，你可以防止此伤害并令该角色获得1枚“死亡”标记，然后若该角色的“死亡”标记数量不小于3，该角色立即死亡。",
	["LuaMaboroshi:prevent"]="你可以对 %src 发动技能“幻之铳弹”",
	["#MaboroshiPrevent"]="防止 %to 受到的【%arg】的伤害",
	["@death"]="死亡",

	["~DeathGun"]=""
}

--SAO-304 ShinkawaKyouni
ShinkawaKyouni = sgs.General(extension,"ShinkawaKyouni","sao","3",true)

--Urami
Urami = sgs.CreateTriggerSkill{
	name = "LuaUrami",
	events = {sgs.CardsMoveOneTime},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local move = data:toMoveOneTime()
		if move.from and move.from:objectName() == player:objectName() and move.from_places:contains(sgs.Player_PlaceHand) and move.is_last_handcard then
			--Get the player with the most handcard number.
			local other_players = room:getOtherPlayers(player)
			local most = 0
			for _, p in sgs.qlist(other_players) do
				most = math.max(p:getHandcardNum(), most)
			end
			if most == 0 then
				return false
			end
			local availableTarget = sgs.SPlayerList()
			for _,tar in sgs.qlist(other_players) do
				if tar:getHandcardNum() == most then
					availableTarget:append(tar)
				end
			end
			local target = room:askForPlayerChosen(player, availableTarget, self:objectName(), "@UramiChoose", true, false)
			if target then
				local log = sgs.LogMessage()
				log.type = "#UramiInvoke"
				log.from = player
				log.to:append(target)
				log.arg = self:objectName()
				room:sendLog(log)
				--Instruct Line:
				room:doAnimate(1, player:objectName(), target:objectName())
				room:notifySkillInvoked(player,self:objectName())
				room:broadcastSkillInvoke(self:objectName())

				local id = room:askForCardChosen(player, target, "h", self:objectName())
				local card = sgs.Sanguosha:getCard(id)
				player:obtainCard(card)
			end
		end
		return false
	end
}

--Warui
WaruiList = {}
Warui = sgs.CreateTriggerSkill{
	name = "LuaWarui",
	events = {sgs.CardUsed, sgs.PreDamageDone, sgs.CardFinished, sgs.EventPhaseChanging},
	can_trigger = function(self, target)
		return target and target:isAlive()
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardUsed then
			if not player:hasSkill(self:objectName()) and player:getPhase() == sgs.Player_Play then
				local use = data:toCardUse()
				if use.card and use.card:isKindOf("Slash") then
					table.insert(WaruiList, use.card)
				end
			end
		elseif event == sgs.PreDamageDone then
			local damage = data:toDamage()
			if damage.card and damage.card:isKindOf("Slash") then
				for _, card in ipairs(WaruiList) do
					if card:getEffectiveId() == damage.card:getEffectiveId() then
						table.removeOne(WaruiList,card)
						break
					end
				end
			end
		elseif event == sgs.CardFinished then
			if player and player:isAlive() and not player:hasSkill(self:objectName()) then
				local use = data:toCardUse()
				if use.card and use.card:isKindOf("Slash") then
					canInvoke = false
					for _, card in ipairs(WaruiList) do
						if card:getEffectiveId() == use.card:getEffectiveId() then
							table.removeOne(WaruiList,card)
							if player:getPhase() == sgs.Player_Play then
								canInvoke = true
							end
							break
						end
					end
					--Shinkawa Kyouni can invoke his skill.
					if canInvoke then
						local shinkawa = room:findPlayerBySkillName(self:objectName())
						if not shinkawa or not shinkawa:isAlive() then
							return false
						end
						local card = room:askForCard(shinkawa, ".|.|.|.", "@WaruiGive:" .. player:objectName(), data, sgs.Card_MethodNone)
						if card then
							local log = sgs.LogMessage()
							log.type = "#UramiInvoke"
							log.from = shinkawa
							log.to:append(player)
							log.arg = self:objectName()
							room:sendLog(log)
							--Instruct Line:
							room:doAnimate(1, shinkawa:objectName(), player:objectName())
							room:notifySkillInvoked(shinkawa,self:objectName())
							room:broadcastSkillInvoke(self:objectName())

							player:obtainCard(card)
							room:addPlayerMark(player, "WaruiAdditional")
						end
					end
				end
			end
		elseif event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.from == sgs.Player_Play then
				if player:getMark("WaruiAdditional") > 0 then
					room:setPlayerMark(player, "WaruiAdditional", 0)
				end
			end
		end
		return false
	end
}

WaruiAdditional = sgs.CreateTargetModSkill{
	name = "#LuaWaruiAdditional",
	residue_func = function(self, from)
		return from:getMark("WaruiAdditional")
	end
}

ShinkawaKyouni:addSkill(Urami)
ShinkawaKyouni:addSkill(Warui)
ShinkawaKyouni:addSkill(WaruiAdditional)
extension:insertRelatedSkills("LuaWarui","#LuaWaruiAdditional")

sgs.LoadTranslationTable{
	["ShinkawaKyouni"]="新川恭二",
	["&ShinkawaKyouni"]="新川恭二",
	["#ShinkawaKyouni"]="为虎作伥",
	["designer:ShinkawaKyouni"]="Smwlover",
	["cv:ShinkawaKyouni"]="花江夏树",
	["illustrator:ShinkawaKyouni"]="官方",

	["LuaUrami"]="怀恨",
	[":LuaUrami"]="<b>（怀恨在心）</b>每当你失去所有手牌后，你可以获得一名手牌数最多的角色的一张手牌。",
	["@UramiChoose"]="你可以发动技能“怀恨在心”获得一名手牌数最多的角色的一张手牌",
	["#UramiInvoke"]="%from 对 %to 发动了技能“%arg”",
	["LuaWarui"]="作伥",
	[":LuaWarui"]="<b>（为虎作伥）</b>每当其他角色于出牌阶段内使用的【杀】结算完毕后，若此【杀】没有造成伤害，你可以将一张牌交给该角色，然后令此阶段内该角色使用【杀】的次数上限+1。",
	["@WaruiGive"]="你可以发动“为虎作伥”交给 %src 一张手牌",

	["~ShinkawaKyouni"]=""
}

--SAO-401 Administrator
Administrator = sgs.General(extension,"Administrator","sao","3",false)

--Fuuin
Fuuin = sgs.CreateTriggerSkill{
	name = "LuaFuuin",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.DamageInflicted, sgs.GameStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.GameStart then
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if p:objectName() ~= player:objectName() then
					room:setPlayerMark(p, "fuuinNum", p:getMark("fuuinNum")+1)
					if not p:hasSkill("LuaFuuinToppa") then
						room:attachSkillToPlayer(p,"LuaFuuinToppa")
					end
				end
			end
		elseif event == sgs.DamageInflicted then
			local damage = data:toDamage()
			if damage.from and damage.from:getMark("@fuuinToppa") == 0 then
				--sendLog:
				local log = sgs.LogMessage()
				log.type = "#TamotsuPrevented"
				log.from = player
				log.arg = self:objectName()
				log.arg2 = damage.damage
				room:sendLog(log)
				room:notifySkillInvoked(player,self:objectName())
				room:broadcastSkillInvoke(self:objectName())
				return true
			end
		end
		return false
	end
}

FuuinAttach = sgs.CreateTriggerSkill{
	name = "#LuaFuuinAttach",
	events = {sgs.EventAcquireSkill, sgs.EventLoseSkill, sgs.Death},
	global = true,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventAcquireSkill then
			local name = data:toString()
			if name == "LuaFuuin" then
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if p:objectName() ~= player:objectName() then
						room:setPlayerMark(p, "fuuinNum", p:getMark("fuuinNum")+1)
						if not p:hasSkill("LuaFuuinToppa") then
							room:attachSkillToPlayer(p,"LuaFuuinToppa")
						end
					end
				end
			end
		elseif event == sgs.EventLoseSkill then
			local name = data:toString()
			if name == "LuaFuuin" then
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if p:objectName() ~= player:objectName() then
						room:setPlayerMark(p, "fuuinNum", p:getMark("fuuinNum")-1)
						if p:getMark("fuuinNum") == 0 then
							room:detachSkillFromPlayer(p, "LuaFuuinToppa", true)
						end
					end
				end
			end
		elseif event == sgs.Death then
			local death = data:toDeath()
			local who = death.who
			if who:hasSkill("LuaFuuin") and player:objectName() ~= who:objectName() then
				room:setPlayerMark(player, "fuuinNum", player:getMark("fuuinNum")-1)
				if player:getMark("fuuinNum") == 0 then
					room:detachSkillFromPlayer(player, "LuaFuuinToppa", true)
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end
}

FuuinToppaCard = sgs.CreateSkillCard{
	name = "FuuinToppaCard",
	target_fixed = true,
	on_use = function(self, room, source, targets)
		room:notifySkillInvoked(source,"LuaFuuin")
		room:broadcastSkillInvoke("LuaFuuin")
		room:loseHp(source)
		source:gainMark("@fuuinToppa")
	end
}

FuuinToppa = sgs.CreateZeroCardViewAsSkill{
	name = "LuaFuuinToppa",
	view_as = function()
		return FuuinToppaCard:clone()
	end,
	enabled_at_play = function(self, player)
		return player:getMark("@fuuinToppa") == 0
	end
}

--Kumiai
LuaKumiaiCard = sgs.CreateSkillCard{
	name = "LuaKumiaiCard",
	target_fixed = false,
	will_throw = false,
	handling_method = sgs.Card_MethodPindian,
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName() and not to_select:isKongcheng() and to_select:getMark("@synthesis") == 0
	end,
	on_use = function(self, room, source, targets)
		room:notifySkillInvoked(source,"LuaKumiai")
		room:broadcastSkillInvoke("LuaKumiai")
		local target = targets[1]
		local success = source:pindian(target, "LuaKumiai")
		if success then
			target:gainMark("@synthesis", 1)
		else
			room:setPlayerFlag(source, "skipPlay")
		end
	end
}

LuaKumiaiVS = sgs.CreateZeroCardViewAsSkill{
	name = "LuaKumiai",
	response_pattern = "@@LuaKumiai",
	view_as = function(self)
		return LuaKumiaiCard:clone()
	end,
}

Kumiai = sgs.CreateTriggerSkill{
	name = "LuaKumiai",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseStart},
	view_as_skill = LuaKumiaiVS,
	on_trigger = function(self, event, player, data)
		if player:getPhase() == sgs.Player_Play then
			local room = player:getRoom()
			local can_invoke = false
			local other_players = room:getOtherPlayers(player)
			for _,p in sgs.qlist(other_players) do
				if p:getMark("@synthesis") == 0 and not p:isKongcheng() then
					can_invoke = true
					break
				end
			end
			if can_invoke and not player:isKongcheng() then
				room:askForUseCard(player, "@@LuaKumiai", "@LuaKumiai", -1, sgs.Card_MethodPindian)
			end
			if player:hasFlag("skipPlay") then
				return true
			end
		end
		return false
	end
}

--Saikou
SaikouCard = sgs.CreateSkillCard{
	name = "SaikouCard",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select, player)
		local availableTargets = player:property("available_targets"):toString():split("+")
		return #targets == 0 and table.contains(availableTargets, to_select:objectName())
	end,
	feasible = function(self, targets)
		return #targets == 1
	end,
	on_use = function(self, room, source, targets)
		room:notifySkillInvoked(source,"LuaSaikou")
		room:broadcastSkillInvoke("LuaSaikou")
		room:setPlayerFlag(targets[1],"slashTarget")
	end
}

LuaSaikouVS = sgs.CreateViewAsSkill{
	name = "LuaSaikou",
	response_pattern = "@@LuaSaikou",
	n = 1,
	view_filter = function(self, selected, to_select)
		return #selected == 0 and not sgs.Self:isJilei(to_select)
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local card = SaikouCard:clone()
			card:addSubcard(cards[1])
			card:setSkillName("LuaSaikou")
			return card
		end
		return nil
	end
}

Saikou = sgs.CreateTriggerSkill{
	name = "LuaSaikou",
	events = {sgs.CardUsed},
	view_as_skill = LuaSaikouVS,
	can_trigger = function(self, target)
		return target and target:isAlive()
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if use.card:isKindOf("Slash") and player:getMark("@synthesis") > 0 then
			local administrator = room:findPlayerBySkillName(self:objectName())
			if not administrator or not administrator:isAlive() or player:objectName() == administrator:objectName() or administrator:isNude() or not administrator:canDiscard(administrator, "he") then
				return false
			end
			local available_targets = sgs.SPlayerList()
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if not use.to:contains(p) and not room:isProhibited(player, p, use.card) and use.card:targetFilter(sgs.PlayerList(), p, player) then
					available_targets:append(p)
				end
			end
			if not available_targets:isEmpty() then
				--Transform qlist into table:
				local targets = {}
				for _, t in sgs.qlist(available_targets) do
					table.insert(targets, t:objectName())
				end
				room:setPlayerProperty(administrator, "available_targets", sgs.QVariant(table.concat(targets, "+")))
				room:askForUseCard(administrator, "@@LuaSaikou", "@LuaSaikou:"..player:objectName())
				room:setPlayerProperty(administrator, "available_targets", sgs.QVariant(""))
				--Find the player with flag "slashTarget"
				local tar = nil
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if p:hasFlag("slashTarget") then
						room:setPlayerFlag(p, "-slashTarget")
						tar = p
						break
					end
				end
				if tar then
					use.to:append(tar)
					room:sortByActionOrder(use.to)
					data:setValue(use)
					--sendLog
					local log = sgs.LogMessage()
					log.type = "#SaikouExtra"
					log.to:append(tar)
					log.arg = "slash"
					room:sendLog(log)
				end
			end
		end
		return false
	end
}

Administrator:addSkill(Fuuin)
Administrator:addSkill(Saikou)
Administrator:addSkill(Kumiai)
SkillAnJiang:addSkill(FuuinToppa)
local skill=sgs.Sanguosha:getSkill("#LuaFuuinAttach")
if not skill then
	local skillList=sgs.SkillList()
	skillList:append(FuuinAttach)
	sgs.Sanguosha:addSkills(skillList)
end

sgs.LoadTranslationTable{
	["Administrator"]="奎涅拉",
	["&Administrator"]="奎涅拉",
	["#Administrator"]="管理者",
	["designer:Administrator"]="Smwlover",
	["illustrator:Administrator"]="官方",
	["cv:Administrator"]="无",

	["LuaFuuin"]="封印",
	[":LuaFuuin"]="<b>（右眼的封印）</b><font color=\"blue\"><b>锁定技，</b></font>每当你受到其他角色造成的伤害时，防止此伤害。其他角色于其各自的出牌阶段内，可以失去1点体力，令此技能对该角色无效，直到游戏结束。",
	["LuaFuuinToppa"]="封印",
	[":LuaFuuinToppa"]="<b>（封印之突破）</b>出牌阶段，你可以失去1点体力，令<b>“右眼的封印”</b>对你无效，直到游戏结束。",
	["fuuintoppa"]="封印之突破",
	["@fuuinToppa"]="突破",
	["LuaKumiai"]="整合",
	[":LuaKumiai"]="<b>（整合秘仪）</b>出牌阶段开始时，你可以与一名其他角色拼点。若你赢，该角色成为<b>整合骑士</b>，直到游戏结束；若你没赢，你结束出牌阶段。",
	["luakumiai"]="整合秘仪",
	["@LuaKumiai"]="你可以对一名其他角色发动技能“整合秘仪”",
	["~LuaKumiai"]="选择一名角色→点击“确定”",
	["LuaSaikou"]="最高",
	[":LuaSaikou"]="<b>（最高祭司）</b>每当一名<b>整合骑士</b>使用【杀】时，你可以弃置一张牌，然后为此【杀】额外选择一名合理的目标（有距离限制）。",
	["@LuaSaikou"]="你可以为 %src 使用的【杀】额外选择一个目标",
	["~LuaSaikou"]="选择要弃置的牌→选择额外的目标→点击“确定”",
	["saikou"]="最高祭司",
	["#SaikouExtra"]="%to 被指定为此【%arg】的额外目标",

	["~Administrator"]=""
}

--SAO-402 Cardinal
Cardinal = sgs.General(extension,"Cardinal","sao","3",false)

--Shujin
Shujin = sgs.CreateTriggerSkill{
	name = "LuaShujin",
	events = {sgs.Dying},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local dying = data:toDying()
		local who = dying.who
		if who:objectName() ~= player:objectName() then
			return false
		end
		if player:askForSkillInvoke(self:objectName(), sgs.QVariant("draw")) then
			player:drawCards(2)
			player:turnOver()
		end
		return false
	end
}

--Oshie
Oshie = sgs.CreateTriggerSkill{
	name = "LuaOshie",
	events = {sgs.EventPhaseChanging, sgs.EventPhaseStart, sgs.PreCardUsed},
	can_trigger = function(self, target)
		return target and target:isAlive()
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.PreCardUsed then
			if player:getPhase() ~= sgs.Player_NotActive then
				local card = data:toCardUse().card
				if card and card:isKindOf("TrickCard") then
					room:setPlayerFlag(player, "TrickUsed")
				end
			end
		elseif event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_NotActive then
				room:setPlayerFlag(player, "-TrickUsed")
			end
		elseif event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Finish then
				if not player:hasFlag("TrickUsed") then
					--Find Cardinal:
					local cardinal = room:findPlayerBySkillName(self:objectName())
					if not cardinal or not cardinal:isAlive() then
						return false
					end
					if cardinal:askForSkillInvoke(self:objectName(), sgs.QVariant("draw:"..player:objectName())) then
						--Get a random trick card from the discard pile:
						local discardPile = room:getDiscardPile()
						local trickList = sgs.IntList()
						for _,id in sgs.qlist(discardPile) do
							local card = sgs.Sanguosha:getCard(id)
							if card:isKindOf("TrickCard") then
								trickList:append(id)
							end
						end
						if trickList:isEmpty() then
							return false
						end
						local randomNum = math.random(0, trickList:length()-1)
						local chosenID = trickList:at(randomNum)
						local chosenCard = sgs.Sanguosha:getCard(chosenID)
						local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
						dummy:addSubcard(chosenID)
						player:obtainCard(dummy)
						--Player can use this card immediately:
						if chosenCard:objectName() ~= "nullification" then
							room:askForUseCard(player, chosenID, "@LuaOshie:::"..chosenCard:objectName(), -1, sgs.Card_MethodUse)
						end
						--[[
						About the function "askForUseCard":
						const Card *askForUseCard(ServerPlayer *player, const char *pattern, const char *prompt, int notice_index = -1, Card::HandlingMethod method = Card::MethodUse, bool addHistory = true);
						About the variable "pattern":
						Please refer to src/package/exppattern.cpp.
						]]
					end
				end
			end
		end
		return false
	end
}

Cardinal:addSkill(Shujin)
Cardinal:addSkill(Oshie)

sgs.LoadTranslationTable{
	["Cardinal"]="卡迪纳尔",
	["&Cardinal"]="卡迪纳尔",
	["#Cardinal"]="小贤者",
	["designer:Cardinal"]="Smwlover",
	["illustrator:Cardinal"]="Pixiv=52393205",
	["cv:Cardinal"]="无",

	["LuaShujin"]="密室",
	[":LuaShujin"]="<b>（密室的主人）</b>每当你进入濒死状态时，你可以摸两张牌，然后将武将牌翻面。",
	["LuaShujin:draw"]="你可以发动技能“密室的主人”",
	["LuaOshie"]="教诲",
	[":LuaOshie"]="<b>（贤者的教诲）</b>一名角色的结束阶段开始时，若此回合内该角色没有使用过锦囊牌，你可以令该角色从弃牌堆中随机获得一张锦囊牌，然后该角色可以使用此牌。",
	["LuaOshie:draw"]="你可以对 %src 发动技能“贤者的教诲”",
	["@LuaOshie"]="你可以使用此【%arg】",

	["~Cardinal"]=""
}

--SAO-403 Beierkuli
Beierkuli = sgs.General(extension,"Beierkuli","sao","4",true)

--Tsuranuku
TsuranukuCard = sgs.CreateSkillCard{
	name = "LuaTsuranuku",
	will_throw = false,
	handling_method = sgs.Card_MethodNone,
	target_fixed = true,
	on_use = function(self, room, source)
		room:notifySkillInvoked(source,"LuaTsuranuku")
		room:broadcastSkillInvoke("LuaTsuranuku")
		source:addToPile("yaiba", self)
	end
}

TsuranukuVS = sgs.CreateOneCardViewAsSkill{
	name = "LuaTsuranuku",
	response_pattern = "@@LuaTsuranuku",
	view_filter = function(self, card)
		return card:isKindOf("Slash")
	end,
	view_as = function(self, card)
		local tsuranukuCard = TsuranukuCard:clone()
		tsuranukuCard:addSubcard(card)
		return tsuranukuCard
	end
}

Tsuranuku = sgs.CreatePhaseChangeSkill{
	name = "LuaTsuranuku",
	view_as_skill = TsuranukuVS,
	can_trigger = function(self, target)
		return target and target:isAlive()
	end,
	on_phasechange = function(self, player)
		local room = player:getRoom()
		if player:hasSkill(self:objectName()) and player:getPhase() == sgs.Player_Finish then
			--Does player have slash in his hand?
			local canTrigger = false
			local cards = player:getHandcards()
			for _, card in sgs.qlist(cards) do
				if card:isKindOf("Slash") then
					canTrigger = true
					break
				end
			end
			if canTrigger then
				room:askForUseCard(player, "@@LuaTsuranuku", "@LuaTsuranuku")
			end
		elseif player:hasSkill(self:objectName()) and player:getPhase() == sgs.Player_RoundStart and player:getPile("yaiba"):length() > 0 then
			room:sendCompulsoryTriggerLog(player, self:objectName(), true)
			local cardId = player:getPile("yaiba"):first()
			local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_REMOVE_FROM_PILE, "", self:objectName(), "")
			room:throwCard(sgs.Sanguosha:getCard(cardId), reason, nil)
		elseif player:getPhase() == sgs.Player_RoundStart then
			--Find Beierkuli:
			local beierkuli = room:findPlayerBySkillName(self:objectName())
			if not beierkuli or not beierkuli:isAlive() or beierkuli:getPile("yaiba"):length() == 0 then
				return false
			end
			if beierkuli:askForSkillInvoke(self:objectName(), sgs.QVariant("slash:"..player:objectName())) then
				local cardId = beierkuli:getPile("yaiba"):first()
				local card = sgs.Sanguosha:getCard(cardId)
				local colorStr = card:isRed() and "red" or "black"
				--Judge:
				local judge = sgs.JudgeStruct()
				judge.pattern = ".|"..colorStr
				judge.good = false
				judge.reason = self:objectName()
				judge.who = player
				room:judge(judge)
				--Generate slash:
				local slash = sgs.Sanguosha:cloneCard(card:objectName(), card:getSuit(), card:getNumber())
				if judge:isBad() and beierkuli:canSlash(player, slash, false) then
					--Use slash to player:
					slash:setSkillName("LuaTsuranuku")
					local card_use = sgs.CardUseStruct()
					card_use.card = slash
					card_use.from = beierkuli
					card_use.to:append(player)
					room:useCard(card_use, false)
				end
			end
		end
		return false
	end
}

--Shini
ShiniCard = sgs.CreateSkillCard{
	name = "ShiniCard",
	target_fixed = false,
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName() and sgs.Self:inMyAttackRange(to_select)
	end,
	feasible = function(self, targets)
		return #targets == 1
	end,
	on_use = function(self, room, source, targets)
		room:notifySkillInvoked(source, "LuaShini")
		room:broadcastSkillInvoke("LuaShini")
		room:doLightbox("Shini$", 2500)
		source:loseMark("@shini")
		room:damage(sgs.DamageStruct("LuaShini", source, targets[1], 2))
		room:killPlayer(source)
	end,
}

LuaShiniVS = sgs.CreateViewAsSkill{
	name = "LuaShini",
	n = 0,
	view_as = function(self, cards)
		local card = ShiniCard:clone()
		return card
	end,
	enabled_at_play = function(self, player)
		return player:getMark("@shini") >= 1
	end
}

Shini = sgs.CreateTriggerSkill{
	name = "LuaShini",
	frequency = sgs.Skill_Limited,
	limit_mark = "@shini",
	events = {},
	view_as_skill = LuaShiniVS,
	on_trigger = function()
		return false
	end
}

Beierkuli:addSkill(Tsuranuku)
Beierkuli:addSkill(Shini)
Beierkuli:addSkill("#LuaSynthesis")

sgs.LoadTranslationTable{
	["Beierkuli"]="贝尔库利",
	["&Beierkuli"]="贝尔库利",
	["#Beierkuli"]="传说的英雄",
	["designer:Beierkuli"]="Smwlover",
	["illustrator:Beierkuli"]="Pixiv=49578000",
	["cv:Beierkuli"]="无",

	["LuaTsuranuku"]="时穿",
	[":LuaTsuranuku"]="<b>（时穿剑）</b>结束阶段开始时，你可以将一张【杀】置于武将牌上，称为“刃”；准备阶段开始时，将“刃”置入弃牌堆。其他角色的准备阶段开始时，若你有“刃”，你可以令该角色进行一次判定，若判定结果与“刃”颜色相同，视为你对该角色使用了一张与“刃”的牌面完全相同的【杀】。",
	["luatsuranuku"]="时穿剑",
	["yaiba"]="刃",
	["LuaTsuranuku:slash"]="你可以对 %src 发动技能“时穿剑”",
	["@LuaTsuranuku"]="你可以发动技能“时穿剑”将一张【杀】置于武将牌上",
	["~LuaTsuranuku"]="选中一张【杀】→点“确定”",
	["LuaShini"]="心意",
	[":LuaShini"]="<b>（心意之一击）</b><font color=\"red\"><b>限定技，</b></font>出牌阶段，你可以对攻击范围内的一名其他角色造成2点伤害，然后你立即死亡。",
	["@shini"]="心意",
	["shini"]="心意之一击",
	["Shini$"]="image=image/animate/Beierkuli.png",

	["~Beierkuli"]=""
}

--SAO-404 Fanatiou
Fanatiou = sgs.General(extension,"Fanatiou","sao","4",false)

--Sixuanjian
SixuanjianCard = sgs.CreateSkillCard{
	name = "SixuanjianCard",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select)
		return #targets == 0
	end,
	feasible = function(self, targets)
		return #targets == 1
	end,
	on_use = function(self, room, source, targets)
		room:notifySkillInvoked(source,"LuaSixuanjian")
		room:broadcastSkillInvoke("LuaSixuanjian")
		local target = targets[1]
		local players = sgs.SPlayerList()
		local list = room:getAlivePlayers()
		for _,tar in sgs.qlist(list) do
			if target:objectName() ~= tar:objectName() and tar:inMyAttackRange(target) then
				players:append(tar)
			end
		end
		--Use slash to target?
		if players:isEmpty() then
			return
		end
		for _,tar in sgs.qlist(players) do
			if not tar:isAlive() or not target:isAlive() or not room:askForUseSlashTo(tar, target, "@SixuanjianSlash:"..target:objectName()..":"..source:objectName()) then
				source:drawCards(1)
			end
		end
	end
}

Sixuanjian = sgs.CreateViewAsSkill{
	name = "LuaSixuanjian",
	n = 1,
	view_filter = function(self, selected, to_select)
		return #selected == 0 and to_select:isKindOf("EquipCard") and not sgs.Self:isJilei(to_select)
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local card = SixuanjianCard:clone()
			card:addSubcard(cards[1])
			card:setSkillName(self:objectName())
			return card
		end
		return nil
	end,
	enabled_at_play = function(self, player)
		return player:canDiscard(player, "he") and not player:hasUsed("#SixuanjianCard")
	end
}

--Tianchuanjian
TianchuanCard = sgs.CreateSkillCard{
	name = "LuaTianchuanjian",
	target_fixed = true,
	on_use = function(self, room, source, targets)
		room:notifySkillInvoked(source, "LuaTianchuanjian")
		room:broadcastSkillInvoke("LuaTianchuanjian")
		room:doLightbox("Tianchuan$", 2500)
		source:loseMark("@tianchuan")
		--Get the number of players:
		local num = room:alivePlayerCount()
		for i=1, num, 1 do
			--Choose a random alive player:
			local list = room:getAlivePlayers()
			local length = list:length()
			local randomNum = math.random(0, length-1)
			local victim = list:at(randomNum)
			--Instruct line and deal 1 damage:
			if source:isAlive() then
				room:doAnimate(1, source:objectName(), victim:objectName()) --Instruct line.
			end
			room:damage(sgs.DamageStruct("LuaTianchuanjian", source, victim))
			room:getThread():delay(1500)
		end
	end
}

LuaTianchuanjianVS = sgs.CreateViewAsSkill{
	name = "LuaTianchuanjian",
	n = 0,
	view_as = function(self, cards)
		local card = TianchuanCard:clone()
		return card
	end,
	enabled_at_play = function(self, player)
		return player:getMark("@tianchuan") >= 1
	end
}

Tianchuanjian = sgs.CreateTriggerSkill{
	name = "LuaTianchuanjian",
	frequency = sgs.Skill_Limited,
	limit_mark = "@tianchuan",
	events = {},
	view_as_skill = LuaTianchuanjianVS,
	on_trigger = function()
		return false
	end
}

Fanatiou:addSkill(Sixuanjian)
Fanatiou:addSkill(Tianchuanjian)
Fanatiou:addSkill("#LuaSynthesis")

sgs.LoadTranslationTable{
	["Fanatiou"]="法娜提欧",
	["&Fanatiou"]="法娜提欧",
	["#Fanatiou"]="铿锵玫瑰",
	["designer:Fanatiou"]="Smwlover",
	["illustrator:Fanatiou"]="官方",
	["cv:Fanatiou"]="无",

	["LuaSixuanjian"]="四旋",
	[":LuaSixuanjian"]="<b>（四旋剑）</b><font color=\"green\"><b>阶段技，</b></font>你可以弃置一张装备牌并选择一名角色，令攻击范围内含有该角色的所有角色（该角色除外）依次选择一项：对该角色使用一张【杀】（不计入使用次数限制）；或者令你摸一张牌。",
	["sixuanjian"]="四旋剑",
	["@SixuanjianSlash"]="你可以对 %src 使用一张【杀】，或者令 %dest 摸一张牌",
	["LuaTianchuanjian"]="天穿",
	[":LuaTianchuanjian"]="<b>（天穿剑）</b><font color=\"red\"><b>限定技，</b></font>出牌阶段，你可以将以下流程重复X次（X为场上角色数且至多为5）：随机选择一名角色并对其造成1点伤害。",
	["@tianchuan"]="天穿",
	["luatianchuanjian"]="天穿剑",
	["Tianchuan$"]="image=image/animate/Fanatiou.png",

	["~Fanatiou"]=""
}

--SAO-405 Disuoerbade
Disuoerbade = sgs.General(extension,"Disuoerbade","sao","4",true)

--Honoo
Honoo = sgs.CreateOneCardViewAsSkill{
	name = "LuaHonoo",
	view_filter = function(self, card)
		return card:getSuit() == sgs.Card_Heart
	end,
	enabled_at_play = function(self, player)
		return sgs.Slash_IsAvailable(player)
	end,
	enabled_at_response = function(self, player, pattern)
		return sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE and pattern == "slash"
	end,
	view_as = function(self, card)
		local fireSlash = sgs.Sanguosha:cloneCard("fire_slash", card:getSuit(), card:getNumber())
		fireSlash:addSubcard(card)
		fireSlash:setSkillName(self:objectName())
		return fireSlash
	end
}

HonooTargetMod = sgs.CreateTargetModSkill{
	name = "#LuaHonooTargetMod",
	distance_limit_func = function(self, player, card)
		if player:hasSkill(self:objectName()) and card:isKindOf("FireSlash") then
			return 1000
		else
			return 0
		end
	end,
	residue_func = function(self, player)
		if player:hasSkill(self:objectName()) then
			return player:getMark("HonooAdditional")
		end
	end
}

HonooDamage = sgs.CreateTriggerSkill{
	name = "#LuaHonooDamage",
	events = {sgs.PreDamageDone, sgs.EventPhaseChanging},
	can_trigger = function(self, target)
		return target and target:isAlive()
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.PreDamageDone then
			local damage = data:toDamage()
			local from = damage.from
			if from and from:isAlive() and from:getPhase() == sgs.Player_Play and from:hasSkill(self:objectName()) then
				if damage.nature == sgs.DamageStruct_Fire then
					--sendLog:
					local log = sgs.LogMessage()
					log.type = "#TriggerSkill"
					log.from = from
					log.arg = "LuaHonoo"
					room:sendLog(log)
					room:notifySkillInvoked(from,"LuaHonoo")
					room:broadcastSkillInvoke("LuaHonoo")
					room:addPlayerMark(from, "HonooAdditional")
				end
			end
		elseif event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.from == sgs.Player_Play then
				if player:getMark("HonooAdditional") > 0 then
					room:setPlayerMark(player, "HonooAdditional", 0)
				end
			end
		end
		return false
	end
}

--Shougeki
ShougekiCard = sgs.CreateSkillCard{
	name = "LuaShougeki",
	target_fixed = false,
	filter = function(self, targets, to_select, player)
		if #targets == 0 then
			return true
		elseif #targets == 1 then
			return to_select:isAdjacentTo(targets[1])
		elseif #targets == 2 then
			return to_select:isAdjacentTo(targets[1]) or to_select:isAdjacentTo(targets[2])
		else
			return false
		end
	end,
	on_use = function(self, room, source, targets)
		room:notifySkillInvoked(source, "LuaShougeki")
		room:broadcastSkillInvoke("LuaShougeki")
		room:doLightbox("Shougeki$", 2500)
		source:loseMark("@shougeki")
		--Discard all equipments and deal damage:
		source:throwAllEquips()
		for i=1, #targets, 1 do
			room:damage(sgs.DamageStruct("LuaShougeki", source, targets[i], 1, sgs.DamageStruct_Fire))
		end
	end
}

LuaShougekiVS = sgs.CreateViewAsSkill{
	name = "LuaShougeki",
	n = 0,
	view_as = function(self, cards)
		local card = ShougekiCard:clone()
		return card
	end,
	enabled_at_play = function(self, player)
		return player:getMark("@shougeki") >= 1 and player:getEquips():length() >= 3
	end
}

Shougeki = sgs.CreateTriggerSkill{
	name = "LuaShougeki" ,
	frequency = sgs.Skill_Limited,
	limit_mark = "@shougeki",
	events = {},
	view_as_skill = LuaShougekiVS,
	on_trigger = function()
		return false
	end
}

Disuoerbade:addSkill(Honoo)
Disuoerbade:addSkill(HonooTargetMod)
Disuoerbade:addSkill(HonooDamage)
Disuoerbade:addSkill(Shougeki)
Disuoerbade:addSkill("LuaSynthesis")
extension:insertRelatedSkills("LuaHonoo","#LuaHonooTargetMod")
extension:insertRelatedSkills("LuaHonoo","#LuaHonooHonooDamage")

sgs.LoadTranslationTable{
	["Disuoerbade"]="迪索尔巴德",
	["&Disuoerbade"]="迪索尔巴德",
	["#Disuoerbade"]="炽焰之使",
	["designer:Disuoerbade"]="Smwlover",
	["illustrator:Disuoerbade"]="刀剑神域OL",
	["cv:Disuoerbade"]="无",

	["LuaHonoo"]="炽焰",
	[":LuaHonoo"]="<b>（炽焰弓）</b>你可以将一张红桃牌当作火【杀】使用；你使用的火【杀】无距离限制；每当你于回合内造成火焰伤害后，本回合你使用【杀】的次数上限+1。",
	["LuaShougeki"]="冲击",
	[":LuaShougeki"]="<b>（烈焰冲击）</b><font color=\"red\"><b>限定技，</b></font>出牌阶段，若你装备区中牌的数量不小于三张，你可以弃置装备区中的所有牌，对至多三名相邻的角色各造成1点火焰伤害。",
	["luashougeki"]="烈焰冲击",
	["@shougeki"]="冲击",
	["Shougeki$"]="image=image/animate/Disuoerbade.png",

	["~Disuoerbade"]=""
}

--SAO-406 Lynel_Fizel
Lynel_Fizel = sgs.General(extension,"Lynel_Fizel","sao","6",false)

--Korosu
Korosu = sgs.CreateTriggerSkill{
	name = "LuaKorosu",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseEnd},
	on_trigger = function(self, event, player, data)
		if player:getPhase() == sgs.Player_Play then
			local room = player:getRoom()
			room:sendCompulsoryTriggerLog(player, self:objectName(), true)
			room:notifySkillInvoked(player,self:objectName())
			room:broadcastSkillInvoke(self:objectName())
			--showAllCards:
			room:showAllCards(player)
			local cards = player:getHandcards()
			local blackCount = 0
			local redCount = 0
			for _, card in sgs.qlist(cards) do
				if card:isRed() then
					redCount = redCount + 1
				else
					blackCount = blackCount + 1
				end
			end
			--If the number of red and black cards are not equal:
			if redCount ~= blackCount then
				room:loseHp(player)
			end
		end
		return false
	end
}

--Ikikaeru
Ikikaeru = sgs.CreateTriggerSkill{
	name = "LuaIkikaeru",
	events = {sgs.Dying},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local dying = data:toDying()
		local who = dying.who
		if who:objectName() ~= player:objectName() then
			return false
		end
		if player:askForSkillInvoke(self:objectName(), sgs.QVariant("recover")) then
			room:loseMaxHp(player)
			room:recover(player, sgs.RecoverStruct(player, nil, 1 - player:getHp()))
			room:setPlayerMark(player, "@limit_akui", player:getMark("@limit_akui")+1)
		end
		return false
	end
}

--Akui
function isAvailable(player, to_select)
	if player:objectName() == to_select:objectName() then
		local cards = player:getHandcards()
		for _, card in sgs.qlist(cards) do
			if not player:isJilei(card) then
				return true
			end
		end
		return false
	end
	return true
end

AkuiCard = sgs.CreateSkillCard{
	name = "AkuiCard",
	target_fixed = false,
	filter = function(self, targets, to_select, player)
		return #targets == 0 and not to_select:isKongcheng() and player:canDiscard(to_select, "h") and isAvailable(player, to_select)
	end,
	feasible = function(self, targets)
		return #targets == 1
	end,
	on_use = function(self, room, source, targets)
		room:notifySkillInvoked(source,"LuaAkui")
		room:broadcastSkillInvoke("LuaAkui")
		room:setPlayerMark(source, "times", source:getMark("times")+1)
		if targets[1]:objectName() == source:objectName() then
			room:askForDiscard(source, "LuaAkui", 1, 1, false, false) --Optional, include_equip
		else
			local card_id = room:askForCardChosen(source, targets[1], "h", "LuaAkui", false, sgs.Card_MethodDiscard)
			local card = sgs.Sanguosha:getCard(card_id)
			if not targets[1]:isJilei(card) then
				room:throwCard(card_id, targets[1], source)
			else
				room:showCard(targets[1], card_id)
			end
		end
	end
}

LuaAkuiVS = sgs.CreateZeroCardViewAsSkill{
	name = "LuaAkui",
	view_as = function()
		return AkuiCard:clone()
	end,
	enabled_at_play = function(self, player)
		return player:getMark("times") < player:getMark("@limit_akui")
	end
}

Akui = sgs.CreateTriggerSkill{
	name = "LuaAkui",
	events = {sgs.EventPhaseChanging},
	view_as_skill = LuaAkuiVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local change = data:toPhaseChange()
		if change.to ~= sgs.Player_NotActive then
			room:setPlayerMark(player, "times", 0)
		end
		return false
	end
}

Lynel_Fizel:addSkill(Korosu)
Lynel_Fizel:addSkill(Ikikaeru)
Lynel_Fizel:addSkill(Akui)
Lynel_Fizel:addSkill("#LuaSynthesis")

sgs.LoadTranslationTable{
	["Lynel_Fizel"]="丽涅尔/菲洁尔",
	["&Lynel_Fizel"]="双子骑士",
	["#Lynel_Fizel"]="双子骑士",
	["designer:Lynel_Fizel"]="Smwlover",
	["illustrator:Lynel_Fizel"]="官方",
	["cv:Lynel_Fizel"]="无",

	["LuaKorosu"]="残杀",
	[":LuaKorosu"]="<b>（自相残杀）</b><font color=\"blue\"><b>锁定技，</b></font>出牌阶段结束时，你须展示你的所有手牌，若其中黑色牌与红色牌的数量不相等，你失去1点体力。",
	["LuaIkikaeru"]="复生",
	[":LuaIkikaeru"]="<b>（死而复生）</b>每当你进入濒死状态时，你可以减少1点体力上限，然后将体力值回复至1点。",
	["LuaIkikaeru:recover"]="你可以发动“死而复生”",
	["@limit_akui"]="发动次数",
	["LuaAkui"]="恶意",
	[":LuaAkui"]="<b>（幼小的恶意）</b>出牌阶段，你可以弃置一名角色的一张手牌，每阶段限X次（X为本局游戏中你发动“死而复生”的次数）。",
	["akui"]="幼小的恶意",

	["~Lynel_Fizel"]=""
}

--SAO-407 Alice
Alice = sgs.General(extension,"Alice","sao","3",false)

--Hanaben
Hanaben = sgs.CreateViewAsSkill{
	name = "LuaHanaben",
	n = 4,
	response_or_use = true,
	view_filter = function(self, selected, to_select)
		local available = true
		for _,p in pairs(selected) do
			if p:getSuit() == to_select:getSuit() then
				available = false
			end
		end
		return available and not to_select:isEquipped()
	end,
	view_as = function(self, cards)
		if #cards == 0 then
			return nil
		else
			local card = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			card:setSkillName(self:objectName())
			for _,c in ipairs(cards) do
				card:addSubcard(c)
			end
			return card
		end
	end,
	enabled_at_play = function(self, player)
		return inSomebodysTurn(player) and not player:hasFlag("HanabenUsed") and not player:isKongcheng() and sgs.Slash_IsAvailable(player)
	end,
	enabled_at_response = function(self, player, pattern)
		return inSomebodysTurn(player) and not player:hasFlag("HanabenUsed") and not player:isKongcheng() and pattern == "slash"
	end
}

HanabenExtra = sgs.CreateTargetModSkill{
	name = "#LuaHanabenExtra" ,
	extra_target_func = function(self, from, card)
		if from:hasSkill(self:objectName()) and card:getSkillName() == "LuaHanaben" then
			local number = card:getSubcards():length()
			return number - 1
		end
		return 0
	end
}

HanabenFlag = sgs.CreateTriggerSkill{
	name = "#LuaHanabenFlag",
	events = {sgs.CardUsed},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if use.card:getSkillName() == "LuaHanaben" then
			room:setPlayerFlag(player, "HanabenUsed")
		end
	end
}

HanabenClear = sgs.CreateTriggerSkill{
	name = "#LuaHanabenClear",
	events = {sgs.EventPhaseChanging},
	on_trigger = function(self, event, player, data)
		local change = data:toPhaseChange()
		local room = player:getRoom()
		if change.to == sgs.Player_NotActive then
			--Clear Alice's "HanabenUsed" flag.
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if p:hasFlag("HanabenUsed") then
					room:setPlayerFlag(p, "-HanabenUsed")
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end
}

--Kouei
function findSuit(suitList, suit)
	for _, thisSuit in ipairs(suitList) do
		if thisSuit == suit then
			return true
		end
	end
	return false
end

Kouei = sgs.CreateMasochismSkill{
	name = "LuaKouei",
	on_damaged = function(self, target, damage)
		local room = target:getRoom()
		repeat
			local available = true
			if target:askForSkillInvoke(self:objectName(), sgs.QVariant("draw")) then
				room:drawCards(target, 1, "LuaKouei")
				room:showAllCards(target)
				--Are the card suits different from each other?
				local suitList = {}
				local cards = damage.to:getHandcards()
				for _, card in sgs.qlist(cards) do
					local suit = card:getSuit()
					if findSuit(suitList, suit) then
						available = false
						break
					end
					table.insert(suitList, suit)
				end
			else
				available = false
			end
		until not available
	end
}

Alice:addSkill(Kouei)
Alice:addSkill(Hanaben)
Alice:addSkill(HanabenExtra)
Alice:addSkill(HanabenFlag)
Alice:addSkill(HanabenClear)
Alice:addSkill("#LuaSynthesis")
extension:insertRelatedSkills("LuaHanaben","#LuaHanabenExtra")
extension:insertRelatedSkills("LuaHanaben","#LuaHanabenFlag")
extension:insertRelatedSkills("LuaHanaben","#LuaHanabenClear")

sgs.LoadTranslationTable{
	["Alice"]="爱丽丝·滋贝鲁库",
	["&Alice"]="爱丽丝",
	["#Alice"]="金色的骑士",
	["designer:Alice"]="Smwlover",
	["illustrator:Alice"]="Pixiv=45412753",
	["cv:Alice"]="无",

	["LuaKouei"]="荣耀",
	[":LuaKouei"]="<b>（荣耀之骑士）</b>每当你受到伤害后，你可以摸一张牌，然后展示所有手牌，若花色各不相同，你可以重复此流程。",
	["LuaKouei:draw"]="你可以发动技能“荣耀之骑士”摸一张牌并展示所有手牌",
	["LuaHanaben"]="花舞",
	[":LuaHanaben"]="<b>（繁花之舞）</b>每名角色的回合限一次，你可以将任意数量的花色各不相同的手牌当作【杀】使用，此【杀】的目标数量上限至少为X（X为这些牌的数量）。",

	["~Alice"]=""
}

--SAO-408 Aierduoliye
Aierduoliye = sgs.General(extension,"Aierduoliye","sao","4",true)

--Hoshishimo
HoshishimoCard = sgs.CreateSkillCard{
	name = "HoshishimoCard",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select, player)
		return #targets < player:getMaxHp() - player:getHp()
	end,
	feasible = function(self, targets)
		return #targets > 0 and #targets <= sgs.Self:getMaxHp() - sgs.Self:getHp()
	end,
	on_use = function(self, room, source, targets)
		room:notifySkillInvoked(source,"LuaHoshishimo")
		room:broadcastSkillInvoke("LuaHoshishimo")
		for i=1, #targets, 1 do
			local dest = targets[i]
			if dest:isChained() then
				room:loseHp(dest)
			else
				local log = sgs.LogMessage()
				log.type = "#HoshishimoChain"
				log.to:append(dest)
				room:sendLog(log)
				--setChained:
				dest:setChained(true)
				room:broadcastProperty(dest, "chained")
				room:setEmotion(dest, "chain")
				room:getThread():trigger(sgs.ChainStateChanged, room, dest)
			end
		end
	end
}

Hoshishimo = sgs.CreateViewAsSkill{
	name = "LuaHoshishimo",
	n = 1,
	view_filter = function(self, selected, to_select)
		return #selected == 0 and to_select:getSuit() == sgs.Card_Club and not sgs.Self:isJilei(to_select)
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local card = HoshishimoCard:clone()
			card:addSubcard(cards[1])
			card:setSkillName(self:objectName())
			return card
		end
		return nil
	end,
	enabled_at_play = function(self, player)
		return player:canDiscard(player, "he") and not player:hasUsed("#HoshishimoCard") and player:isWounded()
	end
}

Aierduoliye:addSkill(Hoshishimo)
Aierduoliye:addSkill("#LuaSynthesis")

sgs.LoadTranslationTable{
	["Aierduoliye"]="艾尔多利耶",
	["&Aierduoliye"]="艾尔多利耶",
	["#Aierduoliye"]="以身为盾",
	["designer:Aierduoliye"]="Smwlover",
	["illustrator:Aierduoliye"]="官方",
	["cv:Aierduoliye"]="无",

	["LuaHoshishimo"]="霜鳞",
	[":LuaHoshishimo"]="<b>（霜鳞鞭）</b><font color=\"green\"><b>阶段技，</b></font>你可以弃置一张梅花牌，将至多X名角色的武将牌横置（X为你已损失的体力值），若其中有角色的武将牌已横置，改为你令该角色失去1点体力。",
	["#HoshishimoChain"]="%to 将武将牌横置",
	["hoshishimo"]="霜鳞鞭",

	["~Aierduoliye"]=""
}

--SAO-409 Eugeo
Eugeo = sgs.General(extension,"Eugeo","sao","3",true)

--Koori
Koori = sgs.CreateMasochismSkill{
	name = "LuaKoori",
	on_damaged = function(self, player, damage)
		local room = player:getRoom()
		local targets = sgs.SPlayerList()
		local list = room:getAlivePlayers()
		for _,tar in sgs.qlist(list) do
			if tar:objectName() ~= player:objectName() and not tar:isKongcheng() then
				targets:append(tar)
			end
		end
		--Choose a target:
		if not player:isKongcheng() and not targets:isEmpty() then
			local target = room:askForPlayerChosen(player, targets, self:objectName(), "@LuaKooriChoose", true, false)
			if target then
				local log = sgs.LogMessage()
				log.type = "#HonpouInvoked"
				log.from = player
				log.to:append(target)
				log.arg = self:objectName()
				room:sendLog(log)
				room:notifySkillInvoked(player,self:objectName())
				room:broadcastSkillInvoke(self:objectName())
				room:doAnimate(1, player:objectName(), target:objectName()) --Instruct line.
				--Pindian:
				local success = player:pindian(target, self:objectName(), nil)
				if success then
					target:drawCards(2)
					target:turnOver()
				else
					player:drawCards(2)
					player:turnOver()
				end
			end
		end
		return false
	end
}

--Saki
SakiCard = sgs.CreateSkillCard{
	name = "SakiCard",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select, player)
		return #targets == 0 and not to_select:faceUp() and to_select:objectName() ~= player:objectName() and to_select:getMark("@kinshi") == 0
	end,
	feasible = function(self, targets)
		return #targets == 1
	end,
	on_use = function(self, room, source, targets)
		room:notifySkillInvoked(source,"LuaSaki")
		room:broadcastSkillInvoke("LuaSaki")
		room:addPlayerMark(targets[1], "@kinshi")
		room:setPlayerCardLimitation(targets[1], "use,response", ".|.|.|hand", false)
		--Set tag:
		local playerData = sgs.QVariant()
		playerData:setValue(source)
		room:settag("LuaSakiInvoker", playerData)
	end
}

LuaSakiVS = sgs.CreateViewAsSkill{
	name = "LuaSaki",
	n = 1,
	view_filter = function(self, selected, to_select)
		return #selected == 0 and not to_select:isKindOf("BasicCard") and not sgs.Self:isJilei(to_select)
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local card = SakiCard:clone()
			card:addSubcard(cards[1])
			card:setSkillName(self:objectName())
			return card
		end
		return nil
	end,
	enabled_at_play = function(self, player)
		return player:canDiscard(player, "he") and not player:isNude()
	end
}

Saki = sgs.CreateTriggerSkill{
	name = "LuaSaki",
	events = {sgs.EventPhaseChanging, sgs.Death},
	view_as_skill = LuaSakiVS,
	on_trigger = function(self, event, player, data)
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to ~= sgs.Player_NotActive then
				return false
			end
		elseif event == sgs.Death then
			local death = data:toDeath()
			if death.who:objectName() ~= player:objectName() then
				return false
			end
		end
		local room = player:getRoom()
		local sakiInvoker = room:getTag("LuaSakiInvoker"):toPlayer()
		if not sakiInvoker or sakiInvoker:objectName() ~= player:objectName() then
			return false
		end
		for _, p in sgs.qlist(room:getOtherPlayers(player)) do
			if p:getMark("@kinshi") > 0 then
				room:removePlayerCardLimitation(p, "use,response", ".|.|.|hand")
				room:setPlayerMark(p, "@kinshi", 0)
			end
		end
		room:removeTag("LuaSakiInvoker")
		return false
	end,
	can_trigger = function(self, target)
		return target
	end
}

Eugeo:addSkill(Koori)
Eugeo:addSkill(Saki)
Eugeo:addSkill("#LuaSynthesis")

sgs.LoadTranslationTable{
	["Eugeo"]="尤吉欧",
	["&Eugeo"]="尤吉欧",
	["#Eugeo"]="悲情英雄",
	["designer:Eugeo"]="Smwlover",
	["illustrator:Eugeo"]="Pixiv=37178840",
	["cv:Eugeo"]="无",

	["LuaKoori"]="寒冰",
	[":LuaKoori"]="<b>（冰之藤蔓）</b>每当你受到伤害后，你可以与一名其他角色拼点。若你赢，该角色摸两张牌并将武将牌翻面；若你没赢，你摸两张牌并将武将牌翻面。",
	["@LuaKooriChoose"]="你可以发动技能“冰之藤蔓”选择一名角色与其拼点",
	["LuaSaki"]="蔷薇",
	[":LuaSaki"]="<b>（蔷薇之绽放）</b>出牌阶段，你可以弃置一张非基本牌，令一名武将牌背面朝上的其他角色无法使用或打出手牌，直到回合结束。",
	["saki"]="蔷薇之绽放",
	["@kinshi"]="禁止",

	["~Eugeo"]="我的……剑，已经……折断了啊"
}

--SAO-410 Vector
Vector = sgs.General(extension,"Vector","sao","4",true)

--Itomeru
ItomeruCard = sgs.CreateSkillCard{
	name = "ItomeruCard",
	target_fixed = false,
	filter = function(self, targets, to_select, player)
		return #targets == 0 and to_select:objectName() ~= player:objectName() and to_select:isWounded()
	end,
	feasible = function(self, targets)
		return #targets == 1
	end,
	on_use = function(self, room, source, targets)
		room:notifySkillInvoked(source,"LuaItomeru")
		room:broadcastSkillInvoke("LuaItomeru")
		room:loseMaxHp(targets[1])
		room:setPlayerProperty(source, "maxhp", sgs.QVariant(source:getMaxHp()+1));
		--sendLog:
		local log = sgs.LogMessage()
		log.type = "#GainMaxHp"
		log.from = source
		log.arg = "1"
		room:sendLog(log)
		--recover:
		room:recover(source, sgs.RecoverStruct(source))
		--getMark:
		room:setPlayerMark(source, "@limit_kuzureru", source:getMark("@limit_kuzureru")+1)
	end
}

Itomeru = sgs.CreateZeroCardViewAsSkill{
	name = "LuaItomeru",
	view_as = function()
		return ItomeruCard:clone()
	end,
	enabled_at_play = function(self, player)
		--Is there any wounded player?
		local enabled = false
		for _, p in sgs.qlist(player:getAliveSiblings()) do
			if p:isWounded() then
				enabled = true
				break
			end
		end
		return enabled and not player:hasUsed("#ItomeruCard")
	end
}

--Kuzureru
Kuzureru = sgs.CreateTriggerSkill{
	name = "LuaKuzureru",
	events = {sgs.DamageInflicted},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local num = player:getMark("@limit_kuzureru")
		local damage = data:toDamage()
		if num > 0 then
			room:sendCompulsoryTriggerLog(player, self:objectName(), true)
			room:notifySkillInvoked(player,self:objectName())
			room:broadcastSkillInvoke(self:objectName())
			--Judge:
			for i=1, num, 1 do
				local judge = sgs.JudgeStruct()
				judge.pattern = ".|spade"
				judge.good = false
				judge.reason = self:objectName()
				judge.who = player
				room:judge(judge)
				if not judge:isGood() then
					local log = sgs.LogMessage()
					log.type = "#KuzureruIncrease"
					log.to:append(player)
					log.arg = damage.damage
					log.arg2 = damage.damage + 1
					room:sendLog(log)
					damage.damage = damage.damage + 1
				end
			end
			data:setValue(damage)
		end
		return false
	end
}

Vector:addSkill(Itomeru)
Vector:addSkill(Kuzureru)

sgs.LoadTranslationTable{
	["Vector"]="加百列·米勒",
	["&Vector"]="加百列",
	["#Vector"]="暗黑神",
	["designer:Vector"]="Smwlover",
	["illustrator:Vector"]="官方",
	["cv:Vector"]="无",

	["LuaItomeru"]="攫取",
	[":LuaItomeru"]="<b>（灵魂攫取）</b><font color=\"green\"><b>阶段技，</b></font>你可以选择一名已受伤的其他角色，令该角色减少1点体力上限，然后你增加1点体力上限并回复1点体力。",
	["itomeru"]="灵魂攫取",
	["LuaKuzureru"]="崩坏",
	[":LuaKuzureru"]="<b>（灵魂崩坏）</b><font color=\"blue\"><b>锁定技，</b></font>每当你受到伤害时，你须进行X次判定（X为本局游戏中你发动“灵魂攫取”的次数），其中每有一次判定的判定结果为黑桃，此伤害便+1。",
	["@limit_kuzureru"]="发动次数",
	["#KuzureruIncrease"]="%to 受到的伤害由 %arg 增加至 %arg2 点",

	["~Vector"]=""
}