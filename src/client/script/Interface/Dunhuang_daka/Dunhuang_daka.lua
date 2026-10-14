-- 敦煌打卡界面


local g_Dunhuang_daka_Frame_UnifiedPosition

local g_CurSelectObj = -1
local g_CurSelectSubObj = {-1, -1, -1}
local g_CurPress = -1
local g_Dunhuang_daka_Obj_Button = {}
local g_Dunhuang_daka_Select_Button = {}
local g_Dunhuang_daka_YuLan_Image = {}

local g_ObjCared = -1

--底稿
local g_Dunhuang_daka_ImageBK1 = {
	[1] = "set:DunHuang6 image:DH_personbig1",
	[2] = "set:DunHuang7 image:DH_personbig2",
	[3] = "set:DunHuang8 image:DH_personbig3",
}
--上色 云朵
local g_Dunhuang_daka_ImageBK2 = {
	[1]	= "set:DunHuang4 image:DH_cloudbig1",
	[2] = "set:DunHuang4 image:DH_cloudbig2",
	[3] = "set:DunHuang4 image:DH_cloudbig3",
}

--点缀 莲花
local g_Dunhuang_daka_Effect = {
	[1] = "set:DunHuang5 image:DH_Flowerbig1",
	[2] = "set:DunHuang5 image:DH_Flowerbig2",
	[3] = "set:DunHuang5 image:DH_Flowerbig3",
}
--预览图标
--底稿
local g_Dunhuang_daka_YuLan_Image1 = {
	[1] = {normal = "set:DunHuang2 image:DH_person1_normal", disable = "set:DunHuang2 image:DH_person1_disabled"},
	[2] = {normal = "set:DunHuang2 image:DH_person2_normal", disable = "set:DunHuang2 image:DH_person2_disabled"},
	[3] = {normal = "set:DunHuang2 image:DH_person3_normal", disable = "set:DunHuang2 image:DH_person3_disabled"},
}
--点缀 莲花
local g_Dunhuang_daka_YuLan_Image2 = {
	[1] = {normal = "set:DunHuang2 image:DH_Flower1_normal", disable = "set:DunHuang2 image:DH_Flower1_disabled"},
	[2] = {normal = "set:DunHuang2 image:DH_Flower2_normal", disable = "set:DunHuang2 image:DH_Flower2_disabled"},
	[3] = {normal = "set:DunHuang2 image:DH_Flower3_normal", disable = "set:DunHuang2 image:DH_Flower3_disabled"},
}
--上色 云朵
local g_Dunhuang_daka_YuLan_Image3 = {
	[1] = {normal = "set:DunHuang2 image:DH_cloud1_normal", disable = "set:DunHuang2 image:DH_cloud1_disabled"},
	[2] = {normal = "set:DunHuang2 image:DH_cloud2_normal", disable = "set:DunHuang2 image:DH_cloud2_disabled"},
	[3] = {normal = "set:DunHuang2 image:DH_cloud3_normal", disable = "set:DunHuang2 image:DH_cloud3_disabled"},
}

function Dunhuang_daka_PreLoad()
  this:RegisterEvent("UI_COMMAND");

	this:RegisterEvent("SCENE_TRANSED")
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	
end

function Dunhuang_daka_OnLoad()
    g_Dunhuang_daka_Frame_UnifiedPosition = Dunhuang_daka_Frame:GetProperty("UnifiedPosition")
	
	g_Dunhuang_daka_Obj_Button[1] = Dunhuang_daka_digaoButton
	g_Dunhuang_daka_Obj_Button[2] = Dunhuang_daka_dianzhuiButton
	g_Dunhuang_daka_Obj_Button[3] = Dunhuang_daka_shangseButton
	
	g_Dunhuang_daka_Select_Button[1] = Dunhuang_daka_Check01
	g_Dunhuang_daka_Select_Button[2] = Dunhuang_daka_Check02
	g_Dunhuang_daka_Select_Button[3] = Dunhuang_daka_Check03
	
	g_Dunhuang_daka_YuLan_Image[1] = Dunhuang_daka_Button01
	g_Dunhuang_daka_YuLan_Image[2] = Dunhuang_daka_Button02
	g_Dunhuang_daka_YuLan_Image[3] = Dunhuang_daka_Button03
end

function Dunhuang_daka_OnEvent(event)

	if ( event == "SCENE_TRANSED" ) then
		Dunhuang_daka_OnClosed()

	elseif (event == "ADJEST_UI_POS" ) then
		Dunhuang_daka_On_ResetPos()

	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		Dunhuang_daka_On_ResetPos()
	
	elseif (event == "UI_COMMAND" and tonumber( arg0 ) == 19000101) then
		local showflag = Get_XParam_INT( 0 )
		if showflag == 1 then		--初始
			local targetId = Get_XParam_INT( 1 )
			local objCared = DataPool:GetNPCIDByServerID(targetId);
			if objCared == -1 then
				return;
			end
			g_ObjCared = objCared
			this:CareObject(g_ObjCared, 1, "Dunhuang_daka")
			Dunhuang_daka_Init()
		elseif showflag == 2 and this:IsVisible() then --订制中
			g_CurPress = 2
			Dunhuang_daka_Update()
		elseif showflag == 3 and this:IsVisible() then --确认中
			g_CurPress = 3
			Dunhuang_daka_Update()
		elseif showflag == 0 then --关闭
			Dunhuang_daka_OnClosed()
		end
	end
end

function Dunhuang_daka_Init()
	g_CurPress = 1
	Dunhuang_daka_Update()
	
	this:Show()
end

function Dunhuang_daka_Update()
--	PushDebugMessage("g_CurPress="..g_CurPress)
	if g_CurPress == 1 then
		Dunhuang_daka_Progress1:Show()
		Dunhuang_daka_Progress2:Hide()
		Dunhuang_daka_Progress3:Hide()

		for i = 1, 3 do			
			if g_CurSelectSubObj[i] < 1 or g_CurSelectSubObj[i] > 3 then
				g_CurSelectSubObj[i] = 1
			end
		end
		--底稿
		Dunhuang_daka_ImageDigao1:SetProperty("Image", g_Dunhuang_daka_ImageBK1[g_CurSelectSubObj[1]])
		--点缀
		Dunhuang_daka_ImageDianzhui1:SetProperty("Image", g_Dunhuang_daka_Effect[g_CurSelectSubObj[2]])
		--上色
		Dunhuang_daka_ImageShangse1:SetProperty("Image", g_Dunhuang_daka_ImageBK2[g_CurSelectSubObj[3]])
			
		Dunhuang_daka_Text1:SetText("#{DHDK_200723_47}")		
	elseif g_CurPress == 2 then
		Dunhuang_daka_Progress1:Hide()
		Dunhuang_daka_Progress2:Show()
		Dunhuang_daka_Progress3:Hide()
	
		if g_CurSelectObj < 1 or g_CurSelectObj > 3 then
			g_CurSelectObj = 1
		end
			
		for i = 1, 3 do
			if g_CurSelectObj == i then
				g_Dunhuang_daka_Obj_Button[i]:SetProperty("Selected", "True")			
			else
				g_Dunhuang_daka_Obj_Button[i]:SetProperty("Selected", "False")
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
			--底稿
			Dunhuang_daka_ImageDigao2:SetProperty("Image", g_Dunhuang_daka_ImageBK1[index])	
			for i = 1, 3 do
				if i == index then
					g_Dunhuang_daka_Select_Button[i]:Show()
					g_Dunhuang_daka_Select_Button[i]:SetProperty("Image", g_Dunhuang_daka_YuLan_Image1[i].normal)
					g_Dunhuang_daka_YuLan_Image[i]:Hide()
				else
					g_Dunhuang_daka_YuLan_Image[i]:Show()
					g_Dunhuang_daka_YuLan_Image[i]:SetProperty("Image", g_Dunhuang_daka_YuLan_Image1[i].disable)
					g_Dunhuang_daka_Select_Button[i]:Hide()
				end
			end	
		elseif g_CurSelectObj == 2 then
			index = g_CurSelectSubObj[2]
			--点缀
			Dunhuang_daka_ImageDianzhui2:SetProperty("Image", g_Dunhuang_daka_Effect[index])
			for i = 1, 3 do
				if i == index then
					g_Dunhuang_daka_Select_Button[i]:Show()
					g_Dunhuang_daka_Select_Button[i]:SetProperty("Image", g_Dunhuang_daka_YuLan_Image2[i].normal)
					g_Dunhuang_daka_YuLan_Image[i]:Hide()
				else
					g_Dunhuang_daka_YuLan_Image[i]:Show()
					g_Dunhuang_daka_YuLan_Image[i]:SetProperty("Image", g_Dunhuang_daka_YuLan_Image2[i].disable)
					g_Dunhuang_daka_Select_Button[i]:Hide()
				end
			end	
			
		elseif g_CurSelectObj == 3 then
			index = g_CurSelectSubObj[3]
			Dunhuang_daka_ImageShangse2:SetProperty("Image", g_Dunhuang_daka_ImageBK2[index])
			--上色
			
			for i = 1, 3 do
				if i == index then	
					g_Dunhuang_daka_Select_Button[i]:Show()
					g_Dunhuang_daka_Select_Button[i]:SetProperty("Image", g_Dunhuang_daka_YuLan_Image3[i].normal)
					g_Dunhuang_daka_YuLan_Image[i]:Hide()
				else
					g_Dunhuang_daka_YuLan_Image[i]:Show()
					g_Dunhuang_daka_YuLan_Image[i]:SetProperty("Image", g_Dunhuang_daka_YuLan_Image3[i].disable)
					g_Dunhuang_daka_Select_Button[i]:Hide()
				end
			end	
			
		end
		--始终显示敦煌飞天
--		if g_CurSelectSubObj[1] == 1 then
--			Dunhuang_daka_MingText:SetText("#{ZQQF_190724_96}")
--		elseif g_CurSelectSubObj[1] == 2 then
--			Dunhuang_daka_MingText:SetText("#{ZQQF_190724_97}")
--		elseif g_CurSelectSubObj[1] == 3 then
--			Dunhuang_daka_MingText:SetText("#{ZQQF_190724_98}")
--		end
	elseif g_CurPress == 3 then
		Dunhuang_daka_Progress1:Hide()
		Dunhuang_daka_Progress2:Hide()
		Dunhuang_daka_Progress3:Show()

		for i = 1, 3 do			
			if g_CurSelectSubObj[i] < 1 or g_CurSelectSubObj[i] > 3 then
				g_CurSelectSubObj[i] = 1
			end
		end
		Dunhuang_daka_ImageDigao3:SetProperty("Image", g_Dunhuang_daka_ImageBK1[g_CurSelectSubObj[1]])
		Dunhuang_daka_ImageDianzhui3:SetProperty("Image", g_Dunhuang_daka_Effect[g_CurSelectSubObj[2]])
		Dunhuang_daka_ImageShangse3:SetProperty("Image", g_Dunhuang_daka_ImageBK2[g_CurSelectSubObj[3]])
		Dunhuang_daka_Text2:SetText("#{DHDK_200723_66}")	
	end
end

--开始绘制
function Dunhuang_daka_Start_Clicked()
	if g_CurPress ~= 1 then
		return
	end
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "Confirm" )
		Set_XSCRIPT_ScriptID( 190001 )
		Set_XSCRIPT_Parameter( 0, 2 )
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
	
end

--选择对象
function Dunhuang_daka_Obj_Clicked(type)
	g_CurSelectObj = type
	Dunhuang_daka_Update()
end


--确认
function Dunhuang_daka_Confirm_Clicked()
	if g_CurPress ~= 2 then
		return
	end
		
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "Confirm" )
		Set_XSCRIPT_ScriptID( 190001 )
		Set_XSCRIPT_Parameter( 0, 3 )
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end

--结束
function Dunhuang_daka_Finish_Clicked()
	if g_CurPress ~= 3 then
		return
	end
	
	local subIndex = (g_CurSelectSubObj[1]-1)*3+g_CurSelectSubObj[3]
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "MadeFinish" )
		Set_XSCRIPT_ScriptID( 190001 )
		Set_XSCRIPT_Parameter( 0, g_CurSelectSubObj[1] )
		Set_XSCRIPT_Parameter( 1, g_CurSelectSubObj[2] )
		Set_XSCRIPT_Parameter( 2, subIndex )
		Set_XSCRIPT_ParamCount(3)
	Send_XSCRIPT()
end

--返回 重新绘制
function Dunhuang_daka_ReBuild_Clicked()
	if g_CurPress ~= 3 then
		return
	end
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "Confirm" )
		Set_XSCRIPT_ScriptID( 190001 )
		Set_XSCRIPT_Parameter( 0, 2 )
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()	

end

function Dunhuang_daka_Left_Clicked()
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
	
	Dunhuang_daka_Update()
end

function Dunhuang_daka_Right_Clicked()
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
	
	Dunhuang_daka_Update()
end

function Dunhuang_daka_OnClosed()
	g_CurPress = -1
	g_ObjCared = -1
	this:Hide()
end

function Dunhuang_daka_On_ResetPos()
    Dunhuang_daka_Frame:SetProperty("UnifiedPosition", g_Dunhuang_daka_Frame_UnifiedPosition)
end
