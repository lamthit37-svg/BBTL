
local g_ZongMenSkill_Info_CurType = 1 --1普通 2核心 3装备带技能的
local g_ZongMenSkill_Info_CurIndex = 1
local g_ZongMenSkill_Info_Str = {	
	"#{ZMTF_230628_193}",
	"#{ZMTF_230628_194}",
	"#{ZMTF_230628_195}",
	"#{ZMTF_230628_196}",
	"#{ZMTF_230628_197}",
}
function ZongMenSkill_Info_PreLoad()
	this:RegisterEvent("OPEN_ZONGMENSKILL_INFO",true)
	this:RegisterEvent("CLOSE_ZONGMENSKILL_INFO",false)
end

function ZongMenSkill_Info_OnLoad()	
	
end										

function ZongMenSkill_Info_OnEvent(event)
	if event == "OPEN_ZONGMENSKILL_INFO" then
		if this:IsVisible() then
			this:Hide()
			return
		end
		g_ZongMenSkill_Info_CurType = tonumber(arg0)
		g_ZongMenSkill_Info_CurIndex = tonumber(arg1)
		-- PushDebugMessage("g_ZongMenSkill_Info_CurType:"..tonumber(g_ZongMenSkill_Info_CurType))
		-- PushDebugMessage("g_ZongMenSkill_Info_CurIndex:"..tonumber(g_ZongMenSkill_Info_CurIndex))
		this:Show()
		ZongMenSkill_Info_Open()
	elseif event == "CLOSE_ZONGMENSKILL_INFO" then	
		-- PushDebugMessage("xtc")
		this:Hide()
	end
	
			
end

function ZongMenSkill_Info_Open()
	ZongMenSkill_InfoGreeting_Desc:ClearAllElement()
	-- local color = "#cFFF263"

	for i = 1, 5 do

		if g_ZongMenSkill_Info_CurType == 1 then
			ZongMenSkill_InfoGreeting_Desc:AddTextElement(g_ZongMenSkill_Info_Str[i])
			-- local strTemp = ScriptGlobal_Format(g_ZongMenSkill_Info_Str[i], tostring(DataPool:Lua_GetSectDesc(g_ZongMenSkill_Info_CurIndex-1,i-1, 0)))
			local strTemp = tostring(DataPool:Lua_GetSectDesc(g_ZongMenSkill_Info_CurIndex-1,i-1, 0))
			ZongMenSkill_InfoGreeting_Desc:AddTextElement(strTemp)
			-- ZongMenSkill_InfoGreeting_Desc:AddTextElement("#r")

			local curSkillLevel, requireTalentPoint = DataPool:GetZongMenTalentNormalData(g_ZongMenSkill_Info_CurIndex-1,"CurLevel")
			if curSkillLevel == i then
				ZongMenSkill_InfoGreeting_Desc:AddTextElement("#{ZMTF_230628_198}")
			end

			ZongMenSkill_InfoGreeting_Desc:AddTextElement(" ")
		elseif g_ZongMenSkill_Info_CurType == 2 then
			ZongMenSkill_InfoGreeting_Desc:AddTextElement(g_ZongMenSkill_Info_Str[i])
			-- local strTemp = ScriptGlobal_Format(g_ZongMenSkill_Info_Str[i], tostring(DataPool:Lua_GetSectDesc(g_ZongMenSkill_Info_CurIndex-1,i-1, 1)))
		
			local strTemp = tostring(DataPool:Lua_GetSectDesc(g_ZongMenSkill_Info_CurIndex-1,i-1, 1))
			ZongMenSkill_InfoGreeting_Desc:AddTextElement(strTemp)
			-- ZongMenSkill_InfoGreeting_Desc:AddTextElement("#r")
			local curSkillLevel, requireTalentPoint = DataPool:GetZongMenTalentCoreData(g_ZongMenSkill_Info_CurIndex-1,"CurLevel")
			if curSkillLevel == i then
				ZongMenSkill_InfoGreeting_Desc:AddTextElement("#{ZMTF_230628_198}")
			end
			ZongMenSkill_InfoGreeting_Desc:AddTextElement(" ")
		elseif g_ZongMenSkill_Info_CurType == 3 then
			-- local strTemp = ScriptGlobal_Format(g_ZongMenSkill_Info_Str[i], tostring(DataPool:Lua_GetSectDesc(0,i-1, 2)))
			ZongMenSkill_InfoGreeting_Desc:AddTextElement(g_ZongMenSkill_Info_Str[i])
			local strTemp =  tostring(DataPool:Lua_GetSectDesc(0,i-1, 2))
			ZongMenSkill_InfoGreeting_Desc:AddTextElement(strTemp)
			-- ZongMenSkill_InfoGreeting_Desc:AddTextElement("#r")
			local nSectId, nLogicType, nAddSkill, nSectLevel, nName, nSubTalentType = DataPool:GetSectEquipSkill()
			if nSectLevel == i then
				ZongMenSkill_InfoGreeting_Desc:AddTextElement("#{ZMTF_230628_198}")
			end
			ZongMenSkill_InfoGreeting_Desc:AddTextElement(" ")
		end


	end

end

function ZongMenSkill_Info_OnHidden()

end
