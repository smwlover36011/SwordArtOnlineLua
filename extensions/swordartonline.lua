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
			player:turnOver()
			if not player:faceUp() then
				player:drawCards(3)
			end
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
	[":LuaShujin"]="<b>（密室的主人）</b>每当你进入濒死状态时，你可以将武将牌翻面，然后若你的武将牌背面朝上，你摸三张牌。",
	["LuaShujin:draw"]="你可以发动技能“密室的主人”",
	["LuaOshie"]="教诲",
	[":LuaOshie"]="<b>（贤者的教诲）</b>一名角色的结束阶段开始时，若此回合内该角色没有使用过锦囊牌，你可以令该角色从弃牌堆中随机获得一张锦囊牌，然后该角色可以使用此牌。",
	["LuaOshie:draw"]="你可以对 %src 发动技能“贤者的教诲”",
	["@LuaOshie"]="你可以使用此【%arg】",

	["~Cardinal"]=""
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

--SAO-406 Lynel_Fizel
Lynel_Fizel = sgs.General(extension,"Lynel_Fizel","sao","6",false)

--Korosu
Korosu = sgs.CreateTriggerSkill{
	name = "LuaKorosu",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		if player:getPhase() == sgs.Player_Discard then
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
			room:recover(player, sgs.RecoverStruct(player, nil, player:getMaxHp() - player:getHp()))
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

sgs.LoadTranslationTable{
	["Lynel_Fizel"]="丽涅尔/菲洁尔",
	["&Lynel_Fizel"]="双子骑士",
	["#Lynel_Fizel"]="双子骑士",
	["designer:Lynel_Fizel"]="Smwlover",
	["illustrator:Lynel_Fizel"]="官方",
	["cv:Lynel_Fizel"]="无",

	["LuaKorosu"]="残杀",
	[":LuaKorosu"]="<b>（自相残杀）</b><font color=\"blue\"><b>锁定技，</b></font>弃牌阶段开始时，你须展示你的所有手牌，若其中黑色牌与红色牌的数量不相等，你失去1点体力。",
	["LuaIkikaeru"]="复生",
	[":LuaIkikaeru"]="<b>（死而复生）</b>每当你进入濒死状态时，你可以减少1点体力上限，然后将体力值回复至体力上限。",
	["LuaIkikaeru:recover"]="你可以发动“死而复生”",
	["@limit_akui"]="发动次数",
	["LuaAkui"]="恶意",
	[":LuaAkui"]="<b>（幼小的恶意）</b>出牌阶段，你可以弃置一名角色的一张手牌，每阶段限X次（X为本局游戏中你发动“死而复生”的次数）。",
	["akui"]="幼小的恶意",

	["~Lynel_Fizel"]=""
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
	[":LuaHanaben"]="<b>（繁花之舞）</b>每名角色的回合限一次，你可以将任意数量的花色各不相同的手牌当作【杀】使用，此【杀】的目标数量上限至少为X，且你使用此【杀】的距离限制+X（X为这些牌的数量）。",

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

--SAO-409 Eugeo
Eugeo = sgs.General(extension,"Eugeo","sao","3",true)

--Koori
LuaKooriCard = sgs.CreateSkillCard{
	name = "LuaKooriCard" ,
	filter = function(self, targets, to_select)
		return (#targets == 0) and (not to_select:isKongcheng()) and (to_select:objectName() ~= sgs.Self:objectName())
	end,
	on_use = function(self, room, source, targets)
		room:notifySkillInvoked(source,"LuaKoori")
		room:broadcastSkillInvoke("LuaKoori")
		source:pindian(targets[1], "LuaKoori", nil)
	end
}

LuaKooriVS = sgs.CreateZeroCardViewAsSkill{
	name = "LuaKoori" ,
	enabled_at_play = function()
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return string.find(pattern, "@@LuaKoori")
	end,
	view_as = function()
		return LuaKooriCard:clone()
	end
}

Koori = sgs.CreateTriggerSkill{
	name = "LuaKoori",
	view_as_skill = LuaKooriVS,
	events = {sgs.EventPhaseStart, sgs.Damaged},
	on_trigger = function(self, event, player, data)
		if event == sgs.Damaged or (event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Play) then
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
				room:askForUseCard(player, "@@LuaKoori", "@LuaKoori")
			end
		end
		return false
	end
}

KooriTrigger = sgs.CreateTriggerSkill{
	name = "#LuaKooriTrigger",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.Pindian},
	on_trigger = function(self, event, player, data)
		local pindian = data:toPindian()
		if pindian.reason == "LuaKoori" then
			local fromNumber = pindian.from_card:getNumber()
			local toNumber = pindian.to_card:getNumber()
			if fromNumber ~= toNumber then
				local winner
				local loser
				if fromNumber > toNumber then
					winner = pindian.from
					loser = pindian.to
				else
					winner = pindian.to
					loser = pindian.from
				end
				loser:drawCards(2)
				loser:turnOver()
			else
				pindian.from:drawCards(2)
				pindian.from:turnOver()
				pindian.to:drawCards(2)
				pindian.to:turnOver()
			end
		end	
		return false
	end,
	can_trigger = function(self, target)
		return target:isAlive()
	end,
	priority = -1
}

--Saki
function recordSakiCardType(room, player, card)
	local typeid = bit32.lshift(1, card:getTypeId())
	local mark = player:getMark("LuaSaki")
	room:setPlayerMark(player, "LuaSaki", bit32.bor(mark, typeid))
end

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
		--Record saki card type:
		local cardId = self:getSubcards():first()
		local card = sgs.Sanguosha:getCard(cardId)
		recordSakiCardType(room, source, card)
	
		room:notifySkillInvoked(source,"LuaSaki")
		room:broadcastSkillInvoke("LuaSaki")
		room:addPlayerMark(targets[1],"@kinshi")
		room:setPlayerCardLimitation(targets[1], "use,response", ".|.|.|hand", false)
	end
}

LuaSakiVS = sgs.CreateViewAsSkill{
	name = "LuaSaki",
	n = 1,
	view_filter = function(self, selected, to_select)
		return #selected == 0 and (bit32.band(sgs.Self:getMark("LuaSaki"), bit32.lshift(1, to_select:getTypeId())) == 0) and not sgs.Self:isJilei(to_select)
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
		if player:getMark("LuaSaki") == 14 then
			return false
		end
		for _, p in sgs.qlist(player:getAliveSiblings()) do
            if (not p:faceUp()) and (p:getMark("@kinshi") == 0) then
				return player:canDiscard(player, "he") and not player:isNude()
			end
		end
		return false
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
		--Clear player marks and card limitations:
		local room = player:getRoom()
		for _, p in sgs.qlist(room:getOtherPlayers(player)) do
			if p:getMark("@kinshi") > 0 then
				room:removePlayerCardLimitation(p, "use,response", ".|.|.|hand")
				room:setPlayerMark(p, "@kinshi", 0)
			end
		end
		if player:getMark("LuaSaki") > 0 then
            room:setPlayerMark(player, "LuaSaki", 0)
        end
		return false
	end,
	can_trigger = function(self, target)
		return target and target:hasSkill(self:objectName())
	end
}

Eugeo:addSkill(Koori)
Eugeo:addSkill(KooriTrigger)
Eugeo:addSkill(Saki)
extension:insertRelatedSkills("LuaKoori","#LuaKooriTrigger")

sgs.LoadTranslationTable{
	["Eugeo"]="尤吉欧",
	["&Eugeo"]="尤吉欧",
	["#Eugeo"]="悲情英雄",
	["designer:Eugeo"]="Smwlover",
	["illustrator:Eugeo"]="Pixiv=37178840",
	["cv:Eugeo"]="无",

	["LuaKoori"]="寒冰",
	[":LuaKoori"]="<b>（冰之藤蔓）</b>出牌阶段开始时或者你受到伤害后，你可以与一名其他角色拼点。没赢的角色摸两张牌并将武将牌翻面。",
	["@LuaKoori"]="你可以发动技能“冰之藤蔓”选择一名角色与其拼点",
	["~LuaKoori"]="选择目标角色→点击“确定”",
	["luakoori"]="冰之藤蔓",
	["LuaSaki"]="蔷薇",
	[":LuaSaki"]="<b>（蔷薇之绽放）</b>出牌阶段，你可以弃置一张与你本回合以此法弃置的牌类别均不相同的牌，令一名武将牌背面朝上的其他角色无法使用或打出手牌，直到回合结束。",
	["saki"]="蔷薇之绽放",
	["@kinshi"]="禁止",

	["~Eugeo"]="我的……剑，已经……折断了啊"
}
