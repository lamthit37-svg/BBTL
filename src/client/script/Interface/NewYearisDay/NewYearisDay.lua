local g_Frame_UnifiedXPosition;
local g_Frame_UnifiedYPosition;
local g_NewYearisDayInfo_Table= {}

local g_NewYearisDay_Zhaocai = 0
local g_NewYearisDay_JinBao = 0
local g_NewYearisDay_YingFu = 0

local g_NewYearisDay_qiaofeng = 0
local g_NewYearisDay_xuzhu = 0
local g_NewYearisDay_duanyu = 0
local g_NewYearisDay_flag = 0

local g_NewYearisDay_OnlineTime = 0
local g_NewYearisDay_ActivePoint = 0


local g_NewYearisDay_NPC = {
[1] = {pMDpos = 3, pSceneId = 0, pFlagvalue = 48104, pstr = "#{YDHD_171206_119}", pname = "#{YDHD_171206_116}"},  --乔峰
[2]	= {pMDpos = 4, pSceneId = 1, pFlagvalue = 48105, pstr = "#{YDHD_171206_121}", pname = "#{YDHD_171206_118}"},  --虚竹
[3] = {pMDpos = 5, pSceneId = 2, pFlagvalue = 48106, pstr = "#{YDHD_171206_120}", pname = "#{YDHD_171206_117}"},  --段誉
}

function NewYearisDay_PreLoad()
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	-- 切场景
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)

	this:RegisterEvent("UI_COMMAND");

end

function NewYearisDay_OnLoad()

	-- 保存界面的默认相对位置
	g_Frame_UnifiedXPosition	= NewYearisDay_Frame:GetProperty("UnifiedXPosition");
	g_Frame_UnifiedYPosition	= NewYearisDay_Frame:GetProperty("UnifiedYPosition");


end

function NewYearisDay_OnEvent(event)

	if( event == "ADJEST_UI_POS" ) then
		NewYearisDay_ResetPos()
	elseif( event == "VIEW_RESOLUTION_CHANGED") then
		NewYearisDay_ResetPos()
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		this : Hide()
	elseif ( event == "UI_COMMAND") and (tonumber(arg0) == 89263702)  then
		g_NewYearisDay_Zhaocai = Get_XParam_INT( 0 );
		g_NewYearisDay_JinBao = Get_XParam_INT( 1 );
		g_NewYearisDay_YingFu = Get_XParam_INT( 2 );
		
		g_NewYearisDay_OnlineTime = Get_XParam_INT( 3 );
		g_NewYearisDay_ActivePoint = Get_XParam_INT( 4 );
		
		g_NewYearisDay_qiaofeng = Get_XParam_INT( 5 );
		g_NewYearisDay_xuzhu = Get_XParam_INT( 6 );
		g_NewYearisDay_duanyu = Get_XParam_INT( 7 );
		
		g_NewYearisDay_flag = Get_XParam_INT( 8 );
		
		if Get_XParam_INT( 9 ) ~= nil and Get_XParam_INT( 9 ) == 2 then			
			NewYearisDay_FreshDate()
			return
		end
		
		NewYearisDay_FreshDate()
		this : Show();
	end

end

--================================================
-- 恢复界面的默认相对位置
--================================================
function NewYearisDay_ResetPos()
	NewYearisDay_Frame:SetProperty("UnifiedXPosition", g_Frame_UnifiedXPosition);
	NewYearisDay_Frame:SetProperty("UnifiedYPosition", g_Frame_UnifiedYPosition);
end

--================================================
-- 初始化数据
--================================================
function NewYearisDay_Init()
	
	NewYearisDay_FreshDate()
end

--================================================
-- 刷新状态
--================================================
function NewYearisDay_FreshDate()
	if g_NewYearisDay_Zhaocai == nil or g_NewYearisDay_JinBao == nil or g_NewYearisDay_YingFu == nil then
		return
	end
	
	if g_NewYearisDay_qiaofeng == nil or g_NewYearisDay_xuzhu == nil or g_NewYearisDay_duanyu == nil then
		return
	end
	
	if g_NewYearisDay_Zhaocai < 0 or g_NewYearisDay_Zhaocai > 2 then
		return
	end
	if g_NewYearisDay_JinBao < 0 or g_NewYearisDay_JinBao > 2 then
		return
	end
	if g_NewYearisDay_YingFu < 0 or g_NewYearisDay_YingFu > 2 then
		return
	end
	if g_NewYearisDay_flag == nil then
		return
	end
	
	NewYearisDay_Frame1_Button:Show()		
	NewYearisDay_Frame2_Button:Show()		
	NewYearisDay_Frame3_Button:Show()
	
	local strTemp = ""
	if g_NewYearisDay_Zhaocai == 2 then
		--已达成 已获得	
		--NewYearisDay_Frame1_Pic1:Hide()
		NewYearisDay_Frame1_Pic2:Show()
		NewYearisDay_Frame1_Button:Hide()
		--NewYearisDay_Frame1_Animate:Play(false)
		NewYearisDay_Frame1_Text:SetText("#G".."#{YDHD_171206_21}")
		NewYearisDay_Frame1_Text1:SetText("#{YDHD_171206_28}")
		NewYearisDay_Frame1_Tex3:SetText("")
		--NewYearisDay_Frame1_Me1:Hide()
	elseif g_NewYearisDay_Zhaocai == 1 then
		---已达成 未获得
		--NewYearisDay_Frame1_Pic1:Show()
		NewYearisDay_Frame1_Pic2:Hide()
		NewYearisDay_Frame1_Button:Enable()
		NewYearisDay_Frame1_Button: SetToolTip("#{YDHD_171206_17}")
		NewYearisDay_Btn1_Point:Show()
		--NewYearisDay_Frame1_Animate:Play(true)
		NewYearisDay_Frame1_Text:SetText("#G".."#{YDHD_171206_21}")
		NewYearisDay_Frame1_Text1:SetText("#{YDHD_171206_27}")
		NewYearisDay_Frame1_Tex3:SetText("")
		--NewYearisDay_Frame1_Me1:Hide()
	elseif g_NewYearisDay_Zhaocai == 0 then
		--未达成 未获得
		--NewYearisDay_Frame1_Pic1:Show()
		NewYearisDay_Frame1_Pic2:Hide()
		NewYearisDay_Frame1_Button:Enable()
		NewYearisDay_Frame1_Button: SetToolTip("#{YDHD_171206_14}")
		NewYearisDay_Btn1_Point:Hide()
		--NewYearisDay_Frame1_Animate:Play(false)
		NewYearisDay_Frame1_Text:SetText("#cfff263".."#{YDHD_171206_21}")
		
		--NewYearisDay_Frame1_Me1:Show()
		--已获得英雄的祝福
		if g_NewYearisDay_flag == 1 and g_NewYearisDay_qiaofeng == 1 then --乔峰
			strTemp = ScriptGlobal_Format("#{YDHD_171206_98}",g_NewYearisDay_NPC[2].pname,g_NewYearisDay_xuzhu)
			NewYearisDay_Frame1_Text1:SetText(strTemp)
			strTemp = ScriptGlobal_Format("#{YDHD_171206_98}",g_NewYearisDay_NPC[3].pname,g_NewYearisDay_duanyu)
			NewYearisDay_Frame1_Tex3:SetText(strTemp)
		elseif g_NewYearisDay_flag == 2 and g_NewYearisDay_xuzhu == 1 then --虚竹
			strTemp = ScriptGlobal_Format("#{YDHD_171206_98}",g_NewYearisDay_NPC[1].pname,g_NewYearisDay_qiaofeng)
			NewYearisDay_Frame1_Text1:SetText(strTemp)
			strTemp = ScriptGlobal_Format("#{YDHD_171206_98}",g_NewYearisDay_NPC[3].pname,g_NewYearisDay_duanyu)
			NewYearisDay_Frame1_Tex3:SetText(strTemp)
		elseif g_NewYearisDay_flag == 3 and g_NewYearisDay_duanyu == 1 then --段誉
			strTemp = ScriptGlobal_Format("#{YDHD_171206_98}",g_NewYearisDay_NPC[1].pname,g_NewYearisDay_qiaofeng)
			NewYearisDay_Frame1_Text1:SetText(strTemp)
			strTemp = ScriptGlobal_Format("#{YDHD_171206_98}",g_NewYearisDay_NPC[2].pname,g_NewYearisDay_xuzhu)
			NewYearisDay_Frame1_Tex3:SetText(strTemp)
		else
			--未获得祝福
			NewYearisDay_Frame1_Text1:SetText("#{YDHD_171206_24}")
			NewYearisDay_Frame1_Tex3:SetText("")
			--NewYearisDay_Frame1_Me1:Hide()

		end		
	end
	
	if g_NewYearisDay_OnlineTime > 60 and g_NewYearisDay_JinBao == 0 then
		g_NewYearisDay_JinBao = 1 
	end
	strTemp = ScriptGlobal_Format("#{YDHD_171206_25}",g_NewYearisDay_OnlineTime)
	if g_NewYearisDay_JinBao == 2 then
		--已达成 已获得			
		--NewYearisDay_Frame2_Pic1:Hide()
		NewYearisDay_Frame2_Pic2:Show()
		NewYearisDay_Frame2_Button:Hide()
	--	NewYearisDay_Frame2_Animate:Play(false)
		NewYearisDay_Frame2_Text:SetText("#G".."#{YDHD_171206_22}")
		NewYearisDay_Frame2_Text1:SetText("#{YDHD_171206_28}")
	elseif g_NewYearisDay_JinBao == 1 then
		--已达成 未获得		
		--NewYearisDay_Frame2_Pic1:Show()
		NewYearisDay_Frame2_Pic2:Hide()
		NewYearisDay_Frame2_Button:Enable()
		NewYearisDay_Frame2_Button: SetToolTip("#{YDHD_171206_18}")
		NewYearisDay_Btn2_Point:Show()
	--	NewYearisDay_Frame2_Animate:Play(true)		
		NewYearisDay_Frame2_Text:SetText("#G".."#{YDHD_171206_22}")
		NewYearisDay_Frame2_Text1:SetText("#{YDHD_171206_27}")
	elseif g_NewYearisDay_JinBao == 0 then
		--未达成 未获得	
		--NewYearisDay_Frame2_Pic1:Show()
		NewYearisDay_Frame2_Pic2:Hide()
		NewYearisDay_Frame2_Button:Enable()
		NewYearisDay_Frame2_Button: SetToolTip("#{YDHD_171206_15}")
		NewYearisDay_Btn2_Point:Hide()
	--	NewYearisDay_Frame2_Animate:Play(false)
		NewYearisDay_Frame2_Text:SetText("#cfff263".."#{YDHD_171206_22}")
		NewYearisDay_Frame2_Text1:SetText("#cfff263"..strTemp)	
	end
	
	strTemp = ScriptGlobal_Format("#{YDHD_171206_26}",g_NewYearisDay_ActivePoint)
	local kajiType = KaJi:LuaFnGetKaJiType(31)
	local textstr = "#{YDHD_171206_23}"
	if kajiType == 1 then
		textstr = "#{YDHD_221201_02}"
	end
	
	if g_NewYearisDay_YingFu == 2 then
		--已领取
		--NewYearisDay_Frame3_Pic1:Hide()
		NewYearisDay_Frame3_Pic2:Show()
		NewYearisDay_Frame3_Button:Hide()
	--	NewYearisDay_Frame3_Animate:Play(false)
		NewYearisDay_Frame3_Text:SetText("#G"..textstr)
		NewYearisDay_Frame3_Text1:SetText("#{YDHD_171206_28}")
	elseif g_NewYearisDay_YingFu == 1 then
		--已达成 未获得	
		--NewYearisDay_Frame3_Pic1:Show()
		NewYearisDay_Frame3_Pic2:Hide()
		NewYearisDay_Frame3_Button:Enable()	
		NewYearisDay_Frame3_Button: SetToolTip("#{YDHD_171206_19}")
		NewYearisDay_Btn3_Point:Show()
	--	NewYearisDay_Frame3_Animate:Play(true)
		NewYearisDay_Frame3_Text:SetText("#G"..textstr)
		NewYearisDay_Frame3_Text1:SetText("#{YDHD_171206_27}")	
	elseif g_NewYearisDay_YingFu == 0 then
		--未达成 未获得	
		--NewYearisDay_Frame3_Pic1:Show()
		NewYearisDay_Frame3_Pic2:Hide()
		NewYearisDay_Frame3_Button:Enable()	
		
		if kajiType == 1 then
			NewYearisDay_Frame3_Button:SetToolTip("#{YDHD_221201_01}")
		else
			NewYearisDay_Frame3_Button:SetToolTip("#{YDHD_171206_16}")
		end	
		NewYearisDay_Btn3_Point:Hide()
	--	NewYearisDay_Frame3_Animate:Play(false)
		NewYearisDay_Frame3_Text:SetText("#cfff263"..textstr)
		NewYearisDay_Frame3_Text1:SetText("#cfff263"..strTemp)	
	end
end

--================================================
-- 关闭界面事件
--================================================
function NewYearisDay_Close()
	this:Hide();
end

--================================================
-- 开福袋
--================================================
function NewYearisDay_Clicked(index)



	Clear_XSCRIPT();
		Set_XSCRIPT_Function_Name("OpenActivityFuDai");
		Set_XSCRIPT_ScriptID(892637);
		Set_XSCRIPT_Parameter(0,index);
		Set_XSCRIPT_ParamCount(1);
	Send_XSCRIPT();

end

function NewYearisDay_Animate_Close()
    if not this:IsVisible() then
        return
    end
	
	NewYearisDay_Frame1_Animate:Play(false)
	NewYearisDay_Frame2_Animate:Play(false)
	NewYearisDay_Frame3_Animate:Play(false)
	
    KillTimer("NewYearisDay_Animate_Close()")
end

function NewYearisDay_Help()
		PushEvent("CCSHOP_HELP", 140)	
end