-- 春日百花图 折花沽酒
local g_ZheHuaGuJiu_UnifiedPosition
local g_ZheHuaGuJiu_YingXiangZhi_Count = 0
local g_ZheHuaGuJiuUITalbe = {}
local g_ZheHuaGuJiu_IsGotTalbe = {}

local g_ZheHuaGuJiu_Kaji = 
{
	[0] = {
		--当未达到对应进度时显示
		[1] = {[1]="#{ZHGJ_211227_12}", [2]="#{ZHGJ_211227_14}", [3]="#{ZHGJ_211227_16}", [4]="#{ZHGJ_211227_18}", [5]="#{ZHGJ_211227_20}", [6]="#{ZHGJ_211227_55}"},
		--当进度达到时，鼠标放上显示tips
		[2] = {[1]= "#{ZHGJ_211227_22}", [2]= "#{ZHGJ_211227_24}", [3]="#{ZHGJ_211227_26}", [4]= "#{ZHGJ_211227_28}", [5]= "#{ZHGJ_211227_30}", [6]="#{ZHGJ_211227_53}"},
	},
	[1] = {
		--当未达到对应进度时显示
		[1] = {[1]="#{ZHGJ_211227_13}", [2]="#{ZHGJ_211227_15}", [3]="#{ZHGJ_211227_17}", [4]="#{ZHGJ_211227_19}", [5]="#{ZHGJ_211227_21}", [6]="#{ZHGJ_211227_56}"},
		--当进度达到时，鼠标放上显示tips
		[2] = {[1]= "#{ZHGJ_211227_23}", [2]= "#{ZHGJ_211227_25}", [3]="#{ZHGJ_211227_27}", [4]= "#{ZHGJ_211227_29}", [5]= "#{ZHGJ_211227_31}", [6]="#{ZHGJ_211227_54}"},
	}
} 

local g_ZheHuaGuJiu_OriginalJDTips = 
{
	--当未达到对应进度时显示
	[1] = {[1]="#{ZHGJ_260226_02}", [2]="#{ZHGJ_260226_03}", [3]="#{ZHGJ_260226_04}", [4]="#{ZHGJ_260226_05}", [5]="#{ZHGJ_260226_06}", [6]="#{ZHGJ_260226_07}"},
	--当进度达到时，鼠标放上显示tips
	[2] = {[1]= "#{ZHGJ_260226_08}", [2]= "#{ZHGJ_260226_09}", [3]="#{ZHGJ_260226_10}", [4]= "#{ZHGJ_260226_11}", [5]= "#{ZHGJ_260226_12}", [6]="#{ZHGJ_260226_13}"},
	
}


function ZheHuaGuJiu_PreLoad()
	this:RegisterEvent("UI_COMMAND", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
	this:RegisterEvent("ADJEST_UI_POS",false)
end

function ZheHuaGuJiu_OnLoad()
	g_ZheHuaGuJiu_UnifiedPosition = ZheHuaGuJiu_Frame:GetProperty("UnifiedPosition")
	g_ZheHuaGuJiu_IsGotTalbe = {0,0,0,0,0,0}
	g_ZheHuaGuJiuUITalbe = 
	{
		[1] = 
		{
			UnFinished = ZheHuaGuJiu_TextBK_1,
			Finished = ZheHuaGuJiu_Btn1_Mask,
			DrinkOut = ZheHuaGuJiu_Jiu_Btn1,
			Tips = ZheHuaGuJiu_Jiu_Btn1_Tips,
			NeedCount = 5,
		},
		[2] = 
		{
			UnFinished = ZheHuaGuJiu_TextBK_2,
			Finished = ZheHuaGuJiu_Btn2_Mask,
			DrinkOut = ZheHuaGuJiu_Jiu_Btn2,
			Tips = ZheHuaGuJiu_Jiu_Btn2_Tips,
			NeedCount = 10,
		},
		[3] = 
		{
			UnFinished = ZheHuaGuJiu_TextBK_3,
			Finished = ZheHuaGuJiu_Btn3_Mask,
			DrinkOut = ZheHuaGuJiu_Jiu_Btn3,
			Tips = ZheHuaGuJiu_Jiu_Btn3_Tips,
			NeedCount = 20,
		},
		[4] = 
		{
			UnFinished = ZheHuaGuJiu_TextBK_4,
			Finished = ZheHuaGuJiu_Btn4_Mask,
			DrinkOut = ZheHuaGuJiu_Jiu_Btn4,
			Tips = ZheHuaGuJiu_Jiu_Btn4_Tips,
			NeedCount = 35,
		},
		[5] = 
		{
			UnFinished = ZheHuaGuJiu_TextBK_5,
			Finished = ZheHuaGuJiu_Btn5_Mask,
			DrinkOut = ZheHuaGuJiu_Jiu_Btn5,
			Tips = ZheHuaGuJiu_Jiu_Btn5_Tips,
			NeedCount = 55,
		},
		[6] = 
		{
			UnFinished = ZheHuaGuJiu_TextBK_6,
			Finished = ZheHuaGuJiu_Btn6_Mask,
			DrinkOut = ZheHuaGuJiu_Jiu_Btn6,
			Tips = ZheHuaGuJiu_Jiu_Btn6_Tips,
			NeedCount = 65,
		},
	}
end


function ZheHuaGuJiu_OnEvent(event)
	if(event == "UI_COMMAND" and tonumber(arg0) == 2022012401) then   
		if this:IsVisible() then
			ZheHuaGuJiu_Close()
		end
		g_ZheHuaGuJiu_YingXiangZhi_Count = Get_XParam_INT(0)
		for i = 1, 6 do
			g_ZheHuaGuJiu_IsGotTalbe[i] = Get_XParam_INT(i)
		end
		ZheHuaGuJiu_Open()
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		ZheHuaGuJiu_On_ResetPos()
	elseif event == "ADJEST_UI_POS" then
		ZheHuaGuJiu_On_ResetPos()
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		ZheHuaGuJiu_Close()
	end

end

function ZheHuaGuJiu_On_ResetPos()
	ZheHuaGuJiu_Frame:SetProperty("UnifiedPosition", g_ZheHuaGuJiu_UnifiedPosition)

end

function ZheHuaGuJi_Help()
	if Player:GetData("IsOriginalJD") == 1 then
		PushEvent("CCSHOP_HELP", 242)
	else
		local kjtype   = KaJi:LuaFnGetKaJiType(58)
		if kjtype == 0 then
			PushEvent("CCSHOP_HELP", 156)
		elseif kjtype == 1 then
			PushEvent("CCSHOP_HELP", 157)
		end
	end

end

function ZheHuaGuJiu_DoReward(type)
	Clear_XSCRIPT()
	Set_XSCRIPT_Function_Name( "ZheHuaGuJiuDoReward" ); 					-- 脚本函数名称
	Set_XSCRIPT_ScriptID( 888946 )										-- 脚本编号
	Set_XSCRIPT_Parameter( 0, type)	   
	Set_XSCRIPT_ParamCount( 1 ) 	-- 参数个数  
Send_XSCRIPT()


end

--界面点击关闭按钮
function ZheHuaGuJiu_Close()
	this:Hide()
end

function ZheHuaGuJiu_OnHide()
	g_ZheHuaGuJiu_IsGotTalbe = {0,0,0,0,0,0}
	g_ZheHuaGuJiu_YingXiangZhi_Count = 0
end

function ZheHuaGuJiu_Open()
	this:Show()
	-- ActionSkill_shuzhi02:SetToolTip("#{BSZJPF_130311_11}")
	ZheHuaGuJi_Text:SetText(ScriptGlobal_Format("#{ZHGJ_211227_11}", g_ZheHuaGuJiu_YingXiangZhi_Count))
	local kjtype   = KaJi:LuaFnGetKaJiType(58)
	-- kjtype = 1
	for i = 1, 6 do
		if g_ZheHuaGuJiu_YingXiangZhi_Count >= g_ZheHuaGuJiuUITalbe[i].NeedCount then
			g_ZheHuaGuJiuUITalbe[i].Tips:Show()
			if Player:GetData("IsOriginalJD") == 1 then
				g_ZheHuaGuJiuUITalbe[i].DrinkOut:SetToolTip(g_ZheHuaGuJiu_OriginalJDTips[2][i])
			else
				g_ZheHuaGuJiuUITalbe[i].DrinkOut:SetToolTip(g_ZheHuaGuJiu_Kaji[kjtype][2][i])
			end
		else
			g_ZheHuaGuJiuUITalbe[i].Tips:Hide()
			if Player:GetData("IsOriginalJD") == 1 then
				g_ZheHuaGuJiuUITalbe[i].DrinkOut:SetToolTip(g_ZheHuaGuJiu_OriginalJDTips[1][i])
			else
				g_ZheHuaGuJiuUITalbe[i].DrinkOut:SetToolTip(g_ZheHuaGuJiu_Kaji[kjtype][1][i])
			end
		end

		if g_ZheHuaGuJiu_IsGotTalbe[i] == 1 then
			g_ZheHuaGuJiuUITalbe[i].Finished:Show()
			g_ZheHuaGuJiuUITalbe[i].UnFinished:Hide()
			g_ZheHuaGuJiuUITalbe[i].DrinkOut:Disable()
			g_ZheHuaGuJiuUITalbe[i].Tips:Hide()
		else
			g_ZheHuaGuJiuUITalbe[i].Finished:Hide()
			g_ZheHuaGuJiuUITalbe[i].UnFinished:Show()
			g_ZheHuaGuJiuUITalbe[i].DrinkOut:Enable()
		end
	
	end

	-- g_ZheHuaGuJiuUITalbe[1].DrinkOut:SetToolTip("#{ZHGJ_211227_13}")

end
