--2022熊猫外观

local g_Frame_UnifiedPosition

--图标数量
local g_MaxCount = 5

--图标数据
local g_MDData = -1
--领奖标记
local g_MFValue = -1
--时装小红点是否显示
local g_TipShow = 0

--未开启图片
local g_DarkImages = {}
--图标按钮
local g_PicImages = {}
--图标动画
--local g_Animates = {}

--奖励展示
local g_itemid = 39923857

--=========
-- PreLoad()
--=========
function Panda_Guide_PreLoad()

	this:RegisterEvent("UI_COMMAND", true)--打开or刷新界面
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("ADJEST_UI_POS",false)

end

--=========
-- OnLoad()
--=========
function Panda_Guide_OnLoad()
	
	g_Frame_UnifiedPosition = Panda_Guide_Frame:GetProperty("UnifiedPosition")
	
	g_DarkImages[1] = Panda_Guide_Shizhuang_N
	g_DarkImages[2] = Panda_Guide_Shizhuang_RanSe_N
	g_DarkImages[3] = Panda_Guide_BeiShi_N
	g_DarkImages[4] = Panda_Guide_Wuqi_N
	g_DarkImages[5] = Panda_Guide_TouShi_N
		
	g_PicImages[1] = Panda_Guide_Shizhuang_H
	g_PicImages[2] = Panda_Guide_Shizhuang_RanSe_H
	g_PicImages[3] = Panda_Guide_BeiShi_H
	g_PicImages[4] = Panda_Guide_Wuqi_H
	g_PicImages[5] = Panda_Guide_TouShi_H
	
	--g_Animates[1] = Panda_Guide_Shizhuang_Animate
	--g_Animates[2] = Panda_Guide_Shizhuang_RanSe_Animate
	--g_Animates[3] = Panda_Guide_BeiShi_Animate
	--g_Animates[4] = Panda_Guide_Wuqi_Animate
	--g_Animates[5] = Panda_Guide_TouShi_Animate

end

--=========
-- Event
--=========
function Panda_Guide_OnEvent(event)

	if(event == "UI_COMMAND" and tonumber(arg0) == 88896601) then
	
		local bShow = Get_XParam_INT(0)
		if bShow == 1 then--打开界面
			g_MDData = Get_XParam_INT(1)
			g_MFValue = Get_XParam_INT(2)
			g_TipShow = Get_XParam_INT(3)
			Panda_Guide_Open()
			this:Show()
		elseif bShow == 2 then--关闭界面
			Panda_Guide_Close()
		elseif bShow == 3 then--刷新界面
			if this:IsVisible() then
				g_MDData = Get_XParam_INT(1)
				g_MFValue = Get_XParam_INT(2)
				g_TipShow = Get_XParam_INT(3)
				Panda_Guide_Open()
			end
		end
		
	elseif event == "HIDE_ON_SCENE_TRANSED" then

		Panda_Guide_Close()

	elseif event == "VIEW_RESOLUTION_CHANGED" then
	
		Panda_Guide_On_ResetPos()

	elseif event == "ADJEST_UI_POS" then

		Panda_Guide_On_ResetPos()

	end
	
end

--=========
-- OnHiden
--=========
function Panda_Guide_OnHiden()
	Panda_Guide_Icons_Btn:SetActionItem(-1)
end

--=========
-- Close
--=========
function Panda_Guide_Close()

	Panda_Guide_OnHiden()
	this:Hide()

end

--=========
-- 重置
--=========
function Panda_Guide_On_ResetPos()

	Panda_Guide_Frame:SetProperty("UnifiedPosition", g_Frame_UnifiedPosition)

end

--=========
-- 打开
--=========
function Panda_Guide_Open()

	local activeCount = 0
	
	-- 图标+动画
	for nIndex=1, g_MaxCount do
		-- 图标
		if Panda_Guide_GetActiveFlag(nIndex) == 1 then
			activeCount = activeCount + 1
			-- 已激活
			g_PicImages[nIndex]:Show()
			g_DarkImages[nIndex]:Hide()
			--动画
			if Panda_Guide_GetAnimateFlag(nIndex) == 1 then
				-- 不需要播放
				--g_Animates[nIndex]:Play(false)
			else
				-- 需要播放
				--g_Animates[nIndex]:Play(true)
				-- 已播放
				Panda_Guide_OnAnimate( nIndex )
			end
		else
			-- 未激活
			g_PicImages[nIndex]:Hide()
			g_DarkImages[nIndex]:Show()
			-- 不需要播放动画
			--g_Animates[nIndex]:Play(false)
		end
	end

	--全部激活
	--if activeCount == g_MaxCount then
	--	Panda_Guide_Libao_N:Hide()
	--	Panda_Guide_Libao_H:Show()
	--else
	--	Panda_Guide_Libao_N:Show()
	--	Panda_Guide_Libao_H:Hide()
	--end
		
	-- 按钮+名称
	if g_MFValue ~= 1 then
		--按钮
		Panda_Guide_InsButton01:Enable()
		--小红点
		if activeCount == g_MaxCount then
			Panda_Guide_InsButton01_Tips:Show()
		else
			Panda_Guide_InsButton01_Tips:Hide()
		end
	else
		--按钮
		Panda_Guide_InsButton01:Disable()
		--小红点
		Panda_Guide_InsButton01_Tips:Hide()
	end
	
	-- 时装小红点
	if g_TipShow == 1 then
		Panda_Guide_Shizhuang_Tips:Show()
	else
		Panda_Guide_Shizhuang_Tips:Hide()
	end
	
	-- 奖励展示
	Panda_Guide_Icons_Btn:SetActionItem(-1)
	local theAction = DataPool:CreateActionItemForShow(g_itemid, 1)
	if theAction:GetID() ~= 0 then
		Panda_Guide_Icons_Btn:SetActionItem(theAction:GetID())
		Panda_Guide_Icons_Btn:Show()
	end

end	

--=========
-- 已播放动画
--=========
function Panda_Guide_OnAnimate( nIndex )

	if nIndex == nil or nIndex <= 0 or nIndex > g_MaxCount then
		return
	end
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OnAnimate" )
		Set_XSCRIPT_ScriptID( 888966 )
		Set_XSCRIPT_Parameter(0, nIndex)
		Set_XSCRIPT_ParamCount( 1 )
	Send_XSCRIPT()	
	
end

--=========
-- 点击领奖
--=========
function Panda_Guide_BtnClick(  )

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "GetPrize" )
		Set_XSCRIPT_ScriptID( 888966 )
		Set_XSCRIPT_ParamCount( 0 )
	Send_XSCRIPT()	
	
end

--=========
-- 打开获取途径界面
--=========
function Panda_Guide_OnPreview( nIndex )

	if nIndex == nil or nIndex < 1 or nIndex > 2 then
		return
	end
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OnOpenUI" )
		Set_XSCRIPT_ScriptID( 888967 )
		Set_XSCRIPT_Parameter(0, nIndex)
		Set_XSCRIPT_ParamCount( 1 )
	Send_XSCRIPT()	
	
end

--=========
-- 问号帮助
--=========
function Panda_Guide_HelpClick()
	PushEvent("CCSHOP_HELP", 154)
end
	
--=========
-- 某个图标是否已激活
--=========
function Panda_Guide_GetActiveFlag(nIndex)

	if nIndex == nil then
		return 0
	end
	
	if nIndex <= 0 or nIndex > g_MaxCount then
		return 0
	end
	
	local bRet, bActive = GetBitValueInUINT(g_MDData, (nIndex-1)*2, 1)
	if bRet ~= 1 or bActive < 0 or bActive > 1 then
		return 0
	end
	
	return bActive
	
end
	
--=========
-- 某个图标是否已播放动画
--=========
function Panda_Guide_GetAnimateFlag(nIndex)

	if nIndex == nil then
		return 0
	end
	
	if nIndex <= 0 or nIndex > g_MaxCount then
		return 0
	end
	
	local bRet, bAnimate = GetBitValueInUINT(g_MDData, (nIndex-1)*2+1, 1)
	if bRet ~= 1 or bAnimate < 0 or bAnimate > 1 then
		return 0
	end
	
	return bAnimate
	
end
