
function SweepPageQuest_PreLoad()
	this:RegisterEvent("OPEN_SWEEPPAGE_QUEST");
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false) 
	
	this:RegisterEvent("CANGPIN_SHOW_CLASS_EFFECT", true)
	this:RegisterEvent("CANGPIN_SHOW_SET_EFFECT", true)
end

function SweepPageQuest_OnLoad() 
end

function SweepPageQuest_OnEvent(event)
	if ( event == "OPEN_SWEEPPAGE_QUEST" ) then 
		SweepPageQuest_Open(arg0)
	elseif( event == "HIDE_ON_SCENE_TRANSED" ) then
		this:Hide()
	end
	
	if event == "CANGPIN_SHOW_CLASS_EFFECT" then
		SweepPageQuest_Update_ClassEffect(tonumber(arg0))
		this:Activate()
		this:Show()
		return
	end
	
	if event == "CANGPIN_SHOW_SET_EFFECT" then
		SweepPageQuest_Update_SetEffect(tonumber(arg0))
		this:Activate()
		this:Show()
		return
	end
end

function SweepPageQuest_Open(arg0)
	if arg0 == nil then
		return
	end
	
	if arg0 == "Fuli_NewSalaryTask" or arg0 == "NewSalaryTaskSP" then
		SweepPageQuestGreeting_Desc:Hide()
		SweepPageQuestGreeting_Desc1:Show()
		SweepPageQuest_Title:SetText("#{FLJM_170527_05}")
		SweepPageQuestGreeting_Desc1:ClearAllElement()
		if tonumber(arg1) == 1 then
			SweepPageQuestGreeting_Desc1:AddTextElement("#{GZGZ_171114_63}")
		else
			SweepPageQuestGreeting_Desc1:AddTextElement("#{GZGZ_120514_48}")
		end
	elseif arg0 == "SweepPage" then
		SweepPageQuestGreeting_Desc:Show()
		SweepPageQuestGreeting_Desc1:Hide()
		SweepPageQuest_Title:SetText("#{FBSD_170509_02}")
	elseif arg0 == "ServerNew" then
		local MDEndTime 	= DataPool:Lua_GetServerNewFanLiMDEndTime() 
		local nDay 				= math.mod(MDEndTime,100)
		local nMonth 			= math.mod( math.floor(MDEndTime/100),100)
		
		local msg = ScriptGlobal_Format( "#{YCZJJ_181130_60}", nMonth , nDay)  
		SweepPageQuest_Title:SetText("")
		SweepPageQuestGreeting_Desc:Show()
		SweepPageQuestGreeting_Desc1:Hide()
		SweepPageQuestGreeting_Desc:SetText(tostring(msg))
	elseif arg0 == "Fuli_ZhanLing" then
		SweepPageQuestGreeting_Desc:Hide()
		SweepPageQuestGreeting_Desc1:Show()
		SweepPageQuest_Title:SetText("")
		SweepPageQuestGreeting_Desc1:ClearAllElement()
		SweepPageQuestGreeting_Desc1:AddTextElement("#{TLZL_190802_34}")
	elseif arg0 == "Fuli_ZhanLing2" then
		SweepPageQuestGreeting_Desc:Hide()
		SweepPageQuestGreeting_Desc1:Show()
		SweepPageQuest_Title:SetText("")
		SweepPageQuestGreeting_Desc1:ClearAllElement()
		if Player:GetData("Is2606S") == 1 then
			SweepPageQuestGreeting_Desc1:AddTextElement("#{QXFXG_260703_1}")
		else
			SweepPageQuestGreeting_Desc1:AddTextElement("#{TLZL_190802_101}")
		end
	elseif arg0 == "Calendar_Mileage_Help" then
		SweepPageQuestGreeting_Desc:Hide()
		SweepPageQuestGreeting_Desc1:Show()
		SweepPageQuest_Title:SetText("")
		SweepPageQuestGreeting_Desc1:ClearAllElement()
		SweepPageQuestGreeting_Desc1:AddTextElement("#{SRLQY_201230_09}")
	elseif arg0 == "LongZhengShiZai" then
		SweepPageQuestGreeting_Desc:Hide()
		SweepPageQuestGreeting_Desc1:Show()
		SweepPageQuest_Title:SetText("")
		SweepPageQuestGreeting_Desc1:ClearAllElement()
		SweepPageQuestGreeting_Desc1:AddTextElement("#{YZTX_210310_18}")
	elseif arg0 == "SweepAll_ExplainHelp" then
		SweepPageQuestGreeting_Desc:Hide()
		SweepPageQuestGreeting_Desc1:Show()
		SweepPageQuest_Title:SetText("")
		SweepPageQuestGreeting_Desc1:ClearAllElement()
		local par1 = tonumber(arg1)
		if par1 == 0 then
			if Player:GetData("Is2606S") == 1 then
				SweepPageQuestGreeting_Desc1:AddTextElement("#{QXF_260623_30}")
			else
				SweepPageQuestGreeting_Desc1:AddTextElement("#{FBSD_150126_04}")
			end

		elseif par1 > 0 then
			local nSpecKaJi89 = Player : GetData("SPECKAJI89") 
			if nSpecKaJi89 > 0 then
				SweepPageQuestGreeting_Desc1:AddTextElement("#{GXB_220725_16}")
			elseif Player:GetData("Is2606S") == 1 then
				SweepPageQuestGreeting_Desc1:AddTextElement("#{QXF_260623_35}")
			else
				SweepPageQuestGreeting_Desc1:AddTextElement("#{GXB_220725_10}")
			end		
		end
	elseif arg0 == "SweepAll_ExplainHelp_HuoDongSecKill" then
		SweepPageQuestGreeting_Desc:Hide()
		SweepPageQuestGreeting_Desc1:Show()
		SweepPageQuest_Title:SetText("")
		SweepPageQuestGreeting_Desc1:ClearAllElement()
		if Player:GetData("Is2606S") == 1 then
			SweepPageQuestGreeting_Desc1:AddTextElement("#{QXF_260623_109}")
		else
			SweepPageQuestGreeting_Desc1:AddTextElement("#{SDJF_260113_58}")
		end

	elseif arg0 == "Yure2022Q2_Activity_Help" then
		SweepPageQuestGreeting_Desc:Hide()
		SweepPageQuestGreeting_Desc1:Show()
		SweepPageQuest_Title:SetText("")
		SweepPageQuestGreeting_Desc1:ClearAllElement()
		SweepPageQuestGreeting_Desc1:AddTextElement("#{BBYRHD_220523_18}")

	elseif arg0 == "StarEquip_Main_Help" then
		SweepPageQuestGreeting_Desc:Hide()
		SweepPageQuestGreeting_Desc1:Show()
		SweepPageQuest_Title:SetText("")
		SweepPageQuestGreeting_Desc1:ClearAllElement()
		SweepPageQuestGreeting_Desc1:AddTextElement("#{XFXB_230823_05}")
	elseif arg0 == "ZongMenSkill_SufferHelp" then
		SweepPageQuestGreeting_Desc:Hide()
		SweepPageQuestGreeting_Desc1:Show()
		SweepPageQuest_Title:SetText("")
		SweepPageQuestGreeting_Desc1:ClearAllElement()
		if Player:GetData("Is2606S") == 1 then
			SweepPageQuestGreeting_Desc1:AddTextElement("#{QXDZJY_260707_02}")
		else
			SweepPageQuestGreeting_Desc1:AddTextElement("#{ZMDZ_230703_180}")
		end
	end
	
	if arg0 == "Fashion_Auction_Help" then
		SweepPageQuestGreeting_Desc:Hide()
		SweepPageQuestGreeting_Desc1:Show()
		SweepPageQuest_Title:SetText("")
		SweepPageQuestGreeting_Desc1:ClearAllElement()
		SweepPageQuestGreeting_Desc1:AddTextElement("#{WHTJ_240117_07}")
	end
	
	if arg0 == "NewExterior_Ride_Collection_Help" then
		SweepPageQuestGreeting_Desc:Hide()
		SweepPageQuestGreeting_Desc1:Show()
		SweepPageQuest_Title:SetText("")
		SweepPageQuestGreeting_Desc1:ClearAllElement()
		SweepPageQuestGreeting_Desc1:AddTextElement("#{ZQDC_250326_19}")
	end
	
	if arg0 == "CangPin_ShuXing_Help" then
		SweepPageQuestGreeting_Desc:Hide()
		SweepPageQuestGreeting_Desc1:Show()
		SweepPageQuest_Title:SetText("")
		SweepPageQuestGreeting_Desc1:ClearAllElement()
		SweepPageQuestGreeting_Desc1:AddTextElement("#{CPSJ_260112_167}")
	end
	
	if arg0 == "CangPin_List_Help" then
		SweepPageQuestGreeting_Desc:Hide()
		SweepPageQuestGreeting_Desc1:Show()
		SweepPageQuest_Title:SetText("")
		SweepPageQuestGreeting_Desc1:ClearAllElement()
		SweepPageQuestGreeting_Desc1:AddTextElement("#{CPPH_20260417_30}")
	end

	this:Show();
end

function SweepPageQuest_Closed()
		this:Hide();
end



function SweepPageQuest_OnHidden()
		this:Hide()
end

function SweepPageQuest_Update_ClassEffect(iClass)

	SweepPageQuestGreeting_Desc:Hide()
	SweepPageQuestGreeting_Desc1:Show()
	SweepPageQuest_Title:SetText("")
	SweepPageQuestGreeting_Desc1:ClearAllElement()
	
	if tonumber(iClass) ~= nil then
		local collect_val = DataPool:LuaFnGetCangPinClassCollectValue(iClass)
		local collect_level, _, _ = LuaFnGetCangPinClassLevel(collect_val)
		local strClassEffect = LuaFnGetCangPinClassEffectDesc(iClass, collect_level)
		SweepPageQuestGreeting_Desc1:AddTextElement(tostring(strClassEffect))
	end
end

function SweepPageQuest_Update_SetEffect(iSet)
	SweepPageQuestGreeting_Desc:Hide()
	SweepPageQuestGreeting_Desc1:Show()
	SweepPageQuest_Title:SetText("")
	SweepPageQuestGreeting_Desc1:ClearAllElement()
	
	SweepPageQuestGreeting_Desc1:AddTextElement("#{CPSJ_260112_19}")

	local set_lv = DataPool:LuaFnGetCangPinSetEffectLevel(iSet)
	local xj_level = DataPool:LuaFnGetCangPinSetXianJieLevel(iSet)
	
	local lv_str = {"#{CPSJ_260112_133}", "#{CPSJ_260112_134}", "#{CPSJ_260112_135}", "#{CPSJ_260112_136}", "#{CPSJ_260112_137}"}
	if tonumber(iSet) ~= nil then
		for i = 1, 5 do
			local set_effect_desc = LuaFnGetCangPinSetEffectDesc(iSet, i)
			local strTmp = ScriptGlobal_Format(lv_str[i], tostring(set_effect_desc))  
			if set_lv == i then
				SweepPageQuestGreeting_Desc1:AddTextElement("#G"..tostring(strTmp))
			else
				SweepPageQuestGreeting_Desc1:AddTextElement("#W"..tostring(strTmp))
			end
		end
		
		for i = 1, 1 do
			local xj_effect_desc = LuaFnGetCangPinSetXianJieEffectDesc(iSet, i)
			if xj_level == i and set_lv ~= 0 then
				SweepPageQuestGreeting_Desc1:AddTextElement("#G"..tostring(xj_effect_desc))
			else
				SweepPageQuestGreeting_Desc1:AddTextElement("#W"..tostring(xj_effect_desc))
			end
		end
	end
end
