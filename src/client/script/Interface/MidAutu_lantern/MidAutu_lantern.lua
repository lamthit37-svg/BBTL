-- 中秋祈福界面


local g_MidAutu_lantern_Frame_UnifiedPosition

local g_CurSelectObj = -1
local g_CurSelectSubObj = {-1, -1, -1}
local g_CurPress = -1
local g_MidAutu_lantern_Obj_Button = {}
local g_MidAutu_lantern_Select_Button = {}
local g_MidAutu_lantern_YuLan_Image = {}

local g_MidAutu_lantern_ImageBK1 = {
	[1] = "set:MidAutu7 image:TuZideng",
	[2] = "set:MidAutu5 image:LianHuadeng",
	[3] = "set:MidAutu5 image:Gongdeng",
}

local g_MidAutu_lantern_ImageBK2_1 = {
	[1]	= "set:MidAutu5 image:Shiju8",
	[2] = "set:MidAutu3 image:Shiju3",
	[3] = "set:MidAutu5 image:Shiju6",
}

local g_MidAutu_lantern_ImageBK2_2 = {
	[1] = "set:MidAutu5 image:Shiju4",
	[2] = "set:MidAutu5 image:Shiju7",
	[3] = "set:MidAutu3 image:Shiju2",
}

local g_MidAutu_lantern_ImageBK2_3 = {
	[1] = "set:MidAutu5 image:Shiju9",
	[2] = "set:MidAutu5 image:Shiju5",
	[3] = "set:MidAutu3 image:Shiju1",
}

local g_MidAutu_lantern_Effect = {
	[1] = "UI_zhongqiuhuadeng_guihua",
	[2] = "UI_zhongqiuhuadeng_hudie",
	[3] = "UI_zhongqiuhuadeng_qianzhihe"
}
--预览图标
local g_MidAutu_lantern_YuLan_Image1 = {
	[1] = {normal = "set:MidAutu4 image:TuZideng_Normal", disable = "set:MidAutu4 image:TuZideng_Disabled"},
	[2] = {normal = "set:MidAutu4 image:LianHuadeng_Normal", disable = "set:MidAutu4 image:LianHuadeng_Disabled"},
	[3] = {normal = "set:MidAutu4 image:Gongdeng_Normal", disable = "set:MidAutu4 image:Gongdeng_Disabled"},
}

local g_MidAutu_lantern_YuLan_Image2 = {
	[1] = {normal = "set:MidAutu4 image:Guihua_Normal", disable = "set:MidAutu4 image:Guihua_Disabled"},
	[2] = {normal = "set:MidAutu4 image:Hudie_Normal", disable = "set:MidAutu4 image:Hudie_Disabled"},
	[3] = {normal = "set:MidAutu4 image:QianZhihe_Normal", disable = "set:MidAutu4 image:QianZhihe_Disabled"},
}

local g_MidAutu_lantern_YuLan_Image3 = {
	[1] = {normal = "set:MidAutu4 image:Yu_Normal", disable = "set:MidAutu4 image:Yu_Disabled"},
	[2] = {normal = "set:MidAutu4 image:Lan_Normal", disable = "set:MidAutu4 image:Lan_Disabled"},
	[3] = {normal = "set:MidAutu4 image:Wei_Normal", disable = "set:MidAutu4 image:Wei_Disabled"},
	
	[4] = {normal = "set:MidAutu4 image:Lu_Normal", disable = "set:MidAutu4 image:Lu_Disabled"},
	[5] = {normal = "set:MidAutu4 image:Xi_Normal", disable = "set:MidAutu4 image:Xi_Disabled"},
	[6] = {normal = "set:MidAutu4 image:Ke_Normal", disable = "set:MidAutu4 image:Ke_Disabled"},
	
	[7] = {normal = "set:MidAutu4 image:Zhi_Normal", disable = "set:MidAutu4 image:Zhi_Disabled"},
	[8] = {normal = "set:MidAutu4 image:Si_Normal", disable = "set:MidAutu4 image:Si_Disabled"},
	[9] = {normal = "set:MidAutu4 image:Ling_Normal", disable = "set:MidAutu4 image:Ling_Disabled"},

}

function MidAutu_lantern_PreLoad()
    this:RegisterEvent("UI_COMMAND");

	this:RegisterEvent("SCENE_TRANSED")
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	
end

function MidAutu_lantern_OnLoad()
    g_MidAutu_lantern_Frame_UnifiedPosition = MidAutu_lantern_Frame:GetProperty("UnifiedPosition")
	
	g_MidAutu_lantern_Obj_Button[1] = MidAutu_lantern_ButtonA
	g_MidAutu_lantern_Obj_Button[2] = MidAutu_lantern_ButtonB
	g_MidAutu_lantern_Obj_Button[3] = MidAutu_lantern_ButtonC
	
	g_MidAutu_lantern_Select_Button[1] = MidAutu_lantern_Check01
	g_MidAutu_lantern_Select_Button[2] = MidAutu_lantern_Check02
	g_MidAutu_lantern_Select_Button[3] = MidAutu_lantern_Check03
	
	g_MidAutu_lantern_YuLan_Image[1] = MidAutu_lantern_Button01
	g_MidAutu_lantern_YuLan_Image[2] = MidAutu_lantern_Button02
	g_MidAutu_lantern_YuLan_Image[3] = MidAutu_lantern_Button03
end

function MidAutu_lantern_OnEvent(event)

	if ( event == "SCENE_TRANSED" ) then
		MidAutu_lantern_OnClosed()

	elseif (event == "ADJEST_UI_POS" ) then
		MidAutu_lantern_On_ResetPos()

	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		MidAutu_lantern_On_ResetPos()
	
	elseif (event == "UI_COMMAND" and tonumber( arg0 ) == 89316101) then
		local showflag = Get_XParam_INT( 0 )
		if showflag == 1 then		--初始
			MidAutu_lantern_Init()
		elseif showflag == 2 and this:IsVisible() then --订制中
			g_CurPress = 2
			MidAutu_lantern_Update()
		elseif showflag == 3 and this:IsVisible() then --确认中
			g_CurPress = 3
			MidAutu_lantern_Update()
		elseif showflag == 0 then --关闭
			MidAutu_lantern_OnClosed()
		end
	end
end

function MidAutu_lantern_Init()
	g_CurPress = 1
	MidAutu_lantern_Update()
	
	this:Show()
end

function MidAutu_lantern_Update()
	
	if g_CurPress == 1 then
		MidAutu_lantern_Progress1:Show()
		MidAutu_lantern_Progress2:Hide()
	
		MidAutu_lantern_Begin:Show()
		MidAutu_lantern_Return:Hide()
		MidAutu_lantern_Get:Hide()		
		
		for i = 1, 3 do			
			if g_CurSelectSubObj[i] < 1 or g_CurSelectSubObj[i] > 3 then
				g_CurSelectSubObj[i] = 1
			end
		end
		MidAutu_lantern_ImageC1:SetProperty("Image", g_MidAutu_lantern_ImageBK1[g_CurSelectSubObj[1]])
		MidAutu_lantern_ImageB1:replayEffect(g_MidAutu_lantern_Effect[g_CurSelectSubObj[2]])
		local index = g_CurSelectSubObj[3]
		if g_CurSelectSubObj[1] == 1 then
			MidAutu_lantern_ImageD1:SetProperty("Image", g_MidAutu_lantern_ImageBK2_1[index])
		elseif g_CurSelectSubObj[1] == 2 then	
			MidAutu_lantern_ImageD1:SetProperty("Image", g_MidAutu_lantern_ImageBK2_2[index])
		elseif g_CurSelectSubObj[1] == 3 then	
			MidAutu_lantern_ImageD1:SetProperty("Image", g_MidAutu_lantern_ImageBK2_3[index])
		end
			
		MidAutu_lantern_Text1:SetText("#{ZQQF_190724_74}")		
	elseif g_CurPress == 2 then
		MidAutu_lantern_Progress1:Hide()
		MidAutu_lantern_Progress2:Show()
	
		if g_CurSelectObj < 1 or g_CurSelectObj > 3 then
			g_CurSelectObj = 1
		end
			
		for i = 1, 3 do
			if g_CurSelectObj == i then
				g_MidAutu_lantern_Obj_Button[i]:SetProperty("Selected", "True")			
			else
				g_MidAutu_lantern_Obj_Button[i]:SetProperty("Selected", "False")
			end
		end

		for i = 1, 3 do			
			if g_CurSelectSubObj[i] < 1 or g_CurSelectSubObj[i] > 3 then
				g_CurSelectSubObj[i] = 1
			end
		end
		
		local index = -1
		if g_CurSelectObj == 1 then
			index = g_CurSelectSubObj[1]
			MidAutu_lantern_ImageC2:SetProperty("Image", g_MidAutu_lantern_ImageBK1[index])	
			for i = 1, 3 do
				if i == index then
					g_MidAutu_lantern_Select_Button[i]:Show()
					g_MidAutu_lantern_Select_Button[i]:SetProperty("Image", g_MidAutu_lantern_YuLan_Image1[i].normal)
					g_MidAutu_lantern_YuLan_Image[i]:Hide()
				else
					g_MidAutu_lantern_YuLan_Image[i]:Show()
					g_MidAutu_lantern_YuLan_Image[i]:SetProperty("Image", g_MidAutu_lantern_YuLan_Image1[i].disable)
					g_MidAutu_lantern_Select_Button[i]:Hide()
				end
			end	
		elseif g_CurSelectObj == 2 then
			index = g_CurSelectSubObj[2]
			MidAutu_lantern_ImageB2:replayEffect(g_MidAutu_lantern_Effect[index])
			for i = 1, 3 do
				if i == index then
					g_MidAutu_lantern_Select_Button[i]:Show()
					g_MidAutu_lantern_Select_Button[i]:SetProperty("Image", g_MidAutu_lantern_YuLan_Image2[i].normal)
					g_MidAutu_lantern_YuLan_Image[i]:Hide()
				else
					g_MidAutu_lantern_YuLan_Image[i]:Show()
					g_MidAutu_lantern_YuLan_Image[i]:SetProperty("Image", g_MidAutu_lantern_YuLan_Image2[i].disable)
					g_MidAutu_lantern_Select_Button[i]:Hide()
				end
			end	
			
		elseif g_CurSelectObj == 3 then
			index = g_CurSelectSubObj[3]
			if g_CurSelectSubObj[1] == 1 then
				MidAutu_lantern_ImageD2:SetProperty("Image", g_MidAutu_lantern_ImageBK2_1[index])
			elseif g_CurSelectSubObj[1] == 2 then	
				MidAutu_lantern_ImageD2:SetProperty("Image", g_MidAutu_lantern_ImageBK2_2[index])
			elseif g_CurSelectSubObj[1] == 3 then	
				MidAutu_lantern_ImageD2:SetProperty("Image", g_MidAutu_lantern_ImageBK2_3[index])
			end
			
			for i = 1, 3 do
				local subIndex = (g_CurSelectSubObj[1]-1)*3+i
				if i == index then	
					g_MidAutu_lantern_Select_Button[i]:Show()
					g_MidAutu_lantern_Select_Button[i]:SetProperty("Image", g_MidAutu_lantern_YuLan_Image3[subIndex].normal)
					g_MidAutu_lantern_YuLan_Image[i]:Hide()
				else
					g_MidAutu_lantern_YuLan_Image[i]:Show()
					g_MidAutu_lantern_YuLan_Image[i]:SetProperty("Image", g_MidAutu_lantern_YuLan_Image3[subIndex].disable)
					g_MidAutu_lantern_Select_Button[i]:Hide()
				end
			end	
			
		end
		
		if g_CurSelectSubObj[1] == 1 then
			MidAutu_lantern_MingText:SetText("#{ZQQF_190724_96}")
		elseif g_CurSelectSubObj[1] == 2 then
			MidAutu_lantern_MingText:SetText("#{ZQQF_190724_97}")
		elseif g_CurSelectSubObj[1] == 3 then
			MidAutu_lantern_MingText:SetText("#{ZQQF_190724_98}")
		end
		--预览
		--if index > 0 then
		--	for i = 1, 3 do
		--		if index == i then
		--			g_MidAutu_lantern_Select_Button[i]:Show()
		--		else
		--			g_MidAutu_lantern_Select_Button[i]:Hide()
		--		end
		--	end
		--end
	elseif g_CurPress == 3 then
		MidAutu_lantern_Progress1:Show()
		MidAutu_lantern_Progress2:Hide()
	
		MidAutu_lantern_Begin:Hide()
		MidAutu_lantern_Return:Show()
		MidAutu_lantern_Get:Show()
	
		for i = 1, 3 do			
			if g_CurSelectSubObj[i] < 1 or g_CurSelectSubObj[i] > 3 then
				g_CurSelectSubObj[i] = 1
			end
		end
		MidAutu_lantern_ImageC1:SetProperty("Image", g_MidAutu_lantern_ImageBK1[g_CurSelectSubObj[1]])
		MidAutu_lantern_ImageB1:replayEffect(g_MidAutu_lantern_Effect[g_CurSelectSubObj[2]])
		local index = g_CurSelectSubObj[3]
		if g_CurSelectSubObj[1] == 1 then
			MidAutu_lantern_ImageD1:SetProperty("Image", g_MidAutu_lantern_ImageBK2_1[index])
		elseif g_CurSelectSubObj[1] == 2 then	
			MidAutu_lantern_ImageD1:SetProperty("Image", g_MidAutu_lantern_ImageBK2_2[index])
		elseif g_CurSelectSubObj[1] == 3 then	
			MidAutu_lantern_ImageD1:SetProperty("Image", g_MidAutu_lantern_ImageBK2_3[index])
		end
		MidAutu_lantern_Text1:SetText("#{ZQQF_190724_99}")	
	end
end

--开始
function MidAutu_lantern_Start_Clicked()
	if g_CurPress ~= 1 then
		return
	end
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "Confirm" )
		Set_XSCRIPT_ScriptID( 893161 )
		Set_XSCRIPT_Parameter( 0, 2 )
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
	
end

--选择对象
function MidAutu_lantern_Obj_Clicked(type)
	g_CurSelectObj = type
	MidAutu_lantern_Update()
end


--确认
function MidAutu_lantern_Confirm_Clicked()
	if g_CurPress ~= 2 then
		return
	end
		
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "Confirm" )
		Set_XSCRIPT_ScriptID( 893161 )
		Set_XSCRIPT_Parameter( 0, 3 )
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end

--结束
function MidAutu_lantern_Finish_Clicked()
	if g_CurPress ~= 3 then
		return
	end
	
	local subIndex = (g_CurSelectSubObj[1]-1)*3+g_CurSelectSubObj[3]
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "MadeFinish" )
		Set_XSCRIPT_ScriptID( 893161 )
		Set_XSCRIPT_Parameter( 0, g_CurSelectSubObj[1] )
		Set_XSCRIPT_Parameter( 1, g_CurSelectSubObj[2] )
		Set_XSCRIPT_Parameter( 2, subIndex )
		Set_XSCRIPT_ParamCount(3)
	Send_XSCRIPT()
end

--返回
function MidAutu_lantern_ReBuild_Clicked()
	if g_CurPress ~= 3 then
		return
	end
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "Confirm" )
		Set_XSCRIPT_ScriptID( 893161 )
		Set_XSCRIPT_Parameter( 0, 2 )
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()	

end

function MidAutu_lantern_Left_Clicked()
	if g_CurPress ~= 2 then
		return
	end
	
	if g_CurSelectObj < 1 or g_CurSelectObj > 3 then
		return
	end
	
	local curindex = g_CurSelectSubObj[g_CurSelectObj]
	if curindex == 1 then
		g_CurSelectSubObj[g_CurSelectObj] = 3
	elseif curindex > 1 and curindex <= 3 then
		g_CurSelectSubObj[g_CurSelectObj] = curindex-1
	end
	
	MidAutu_lantern_Update()
end

function MidAutu_lantern_Right_Clicked()
	if g_CurPress ~= 2 then
		return
	end
	
	if g_CurSelectObj < 1 or g_CurSelectObj > 3 then
		return
	end
	
	local curindex = g_CurSelectSubObj[g_CurSelectObj]
	if curindex == 3 then
		g_CurSelectSubObj[g_CurSelectObj] = 1
	elseif curindex >= 1 and curindex < 3 then
		g_CurSelectSubObj[g_CurSelectObj] = curindex+1
	end
	
	MidAutu_lantern_Update()
end

function MidAutu_lantern_OnClosed()
	g_CurPress = -1

	this:Hide()
end

function MidAutu_lantern_On_ResetPos()
    MidAutu_lantern_Frame:SetProperty("UnifiedPosition", g_MidAutu_lantern_Frame_UnifiedPosition)
end

function MidAutu_lantern_Help_Clicked()
	PushEvent("CCSHOP_HELP", 117)
end