-- Design and program by YuukiMikan.
-- Sword Art Online project (2014 - 2017).

module("extensions.swordartonline", package.seeall)
extension = sgs.Package("swordartonline")

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
		local list = room:getOtherPlayers(source)
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
			if i == 1 or (source:isAlive() and i > 1 and source:askForSkillInvoke("LuaTianchuanjian", sgs.QVariant("continue"))) then
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
			end
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
	["LuaTianchuanjian:continue"]="你可以继续发动“天穿剑”",
	[":LuaTianchuanjian"]="<b>（天穿剑）</b><font color=\"red\"><b>限定技，</b></font>出牌阶段，你可以重复以下流程至多X次（X为场上角色数）：随机选择一名角色，然后你对该角色造成1点伤害。",
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
		--Draw 3 cards:
		source:drawCards(3)
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
	[":LuaShougeki"]="<b>（烈焰冲击）</b><font color=\"red\"><b>限定技，</b></font>出牌阶段，若你装备区中牌的数量不小于三张，你可以弃置装备区中的所有牌，对至多三名相邻的角色各造成1点火焰伤害，然后摸三张牌。",
	["luashougeki"]="烈焰冲击",
	["@shougeki"]="冲击",
	["Shougeki$"]="image=image/animate/Disuoerbade.png",

	["~Disuoerbade"]=""
}

--SAO-407 Alice
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

Alice = sgs.General(extension,"Alice","sao","3",false)

--Hanaben
Hanaben = sgs.CreateViewAsSkill{
	name = "LuaHanaben",
	n = 4,
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
		return inSomebodysTurn(player) and not player:hasFlag("HanabenUsed") and not player:isKongcheng() and sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE and pattern == "slash"
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
	end,
	distance_limit_func = function(self, player, card)
		if player:hasSkill(self:objectName()) and card:getSkillName() == "LuaHanaben" then
			local number = card:getSubcards():length()
			return number - 1
		end
		return 0
	end,
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
	[":LuaHanaben"]="<b>（繁花之舞）</b>每名角色的回合限一次，你可以将任意数量的花色各不相同的手牌当作【杀】使用，此【杀】的目标数量上限至少为X，且你使用此【杀】的攻击范围+X（X为这些牌的数量）。",

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
		return #selected == 0 and to_select:isBlack() and not sgs.Self:isJilei(to_select)
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

sgs.LoadTranslationTable{
	["Aierduoliye"]="艾尔多利耶",
	["&Aierduoliye"]="艾尔多利耶",
	["#Aierduoliye"]="以身为盾",
	["designer:Aierduoliye"]="Smwlover",
	["illustrator:Aierduoliye"]="官方",
	["cv:Aierduoliye"]="无",

	["LuaHoshishimo"]="霜鳞",
	[":LuaHoshishimo"]="<b>（霜鳞鞭）</b><font color=\"green\"><b>阶段技，</b></font>你可以弃置一张黑色牌，将至多X名角色的武将牌横置（X为你已损失的体力值），若其中有角色的武将牌已横置，改为你令该角色失去1点体力。",
	["#HoshishimoChain"]="%to 将武将牌横置",
	["hoshishimo"]="霜鳞鞭",

	["~Aierduoliye"]=""
}