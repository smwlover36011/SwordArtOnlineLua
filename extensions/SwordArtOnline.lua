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

Genki = sgs.CreateTriggerSkill {
	name = "LuaGenki",
	events = {sgs.HpRecover},
	view_as_skill = LuaGenkiVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		room:askForUseCard(player, "@@LuaGenki", "@LuaGenki")
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
	["@LuaGenki"]="你可以发动技能“元气偶像”",
	["~LuaGenki"]="选择合理数量的角色→点击“确定”"
	
	["~Silica"]="",
}