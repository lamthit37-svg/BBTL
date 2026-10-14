-- 快捷功能入口
-- PushDebugMessage
-- this:Show();
-- this:Hide();

local g_nScreenWidthLimit = 1024
local g_nScreenWidth = 1025
local g_nScreenHeight = 0
local BkSize = {
	[1] = {39.4,47},	-- 1024x768分辨率下的frame尺寸
	[2] = {51,61},	-- 非1024x768分辨率以上的frame尺寸
}

local nChangeSceneCount = 0
local g_YingXiong_Rp = 0

function NoDiffMatch_PlayerQuickEnter_UpdateXingZhen()

    NoDiffMatch_PlayerQuickEnter_Image1_Tips:Hide()
	
	if g_YingXiong_Rp == 1 then
		NoDiffMatch_PlayerQuickEnter_Image1_Tips:Show()
		return
	end

	--有星卷可以上阵
	local nHaveXingJuanToSlot = DataPool:LuaFnHaveXingJuanToSlot()
	if nHaveXingJuanToSlot == 1 then
		NoDiffMatch_PlayerQuickEnter_Image1_Tips:Show()
		return
	end
	
	--有技能可以上阵
	local bHaveSkillCardToSlot = 0
	for i = 1, 4 do
		if DataPool:LuaFnHaveSkillCardToSlot(i) == 1 then
			bHaveSkillCardToSlot = 1
			break
		end
	end
	
	if bHaveSkillCardToSlot == 1 then
		NoDiffMatch_PlayerQuickEnter_Image1_Tips:Show()
		return
	end
	
	--有新的星卷
	local nHaveNewXingJuan = DataPool:LuaFnHaveNewXingJuan()
	if nHaveNewXingJuan == 1 then
		NoDiffMatch_PlayerQuickEnter_Image1_Tips:Show()
		return
	end
	
	--有新的技能
	local nHaveNewSkillCard = DataPool:LuaFnHaveNewSkillCard()
	if nHaveNewSkillCard == 1 then
		NoDiffMatch_PlayerQuickEnter_Image1_Tips:Show()
		return
	end
	
	if DataPool:LuaFnHaveXingJuanToUpgrade() == 1 then
		NoDiffMatch_PlayerQuickEnter_Image1_Tips:Show()
		return
	end
	
	if DataPool:LuaFnHaveXingJuanToUnLock() == 1 then	
		NoDiffMatch_PlayerQuickEnter_Image1_Tips:Show()
		return
	end
	
	--有技能可以升级
	if DataPool:LuaFnHaveSkillCardToLevelUp() == 1 then
		NoDiffMatch_PlayerQuickEnter_Image1_Tips:Show()
		return
	end

end


function NoDiffMatch_PlayerQuickEnter_OpenXingZhen()
	
	LuaFnOpenXingZhen(true, 0, 1)
end


--**********************************
-- PRELOAD
--**********************************
function NoDiffMatch_PlayerQuickEnter_PreLoad()
	
	this:RegisterEvent("ZBS_SPECIALSERVER_2018")
	this:RegisterEvent("DFS_SPECIALSERVER")
	this:RegisterEvent("YINGXIONG_REDPOINT")
	this:RegisterEvent("XINGZHEN_UPDATE")
	this:RegisterEvent("XINGZHEN_REMOVE_NEW")
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false);	-- 游戏分辨率发生了变化

end


--**********************************
-- ONLOAD
--**********************************
function NoDiffMatch_PlayerQuickEnter_OnLoad()
end

--**********************************
-- ONEvent
--**********************************
function NoDiffMatch_PlayerQuickEnter_OnEvent( event )

	if DataPool:LuaFnGetGMVisibleType() ~= 0 then
		this:Hide()
		return
	end
	
	local bSpecialServer = IsZbs2018SpeicalServer()
	if bSpecialServer <= 0 and IsDfsSpeicalServer() <= 0 then
		this:Hide()
		return
	end

	if (event == "ZBS_SPECIALSERVER_2018") then
		if this:IsVisible() == true then
			return
		end
 
		NoDiffMatch_PlayerQuickEnter_Show( )
	elseif ( event == "DFS_SPECIALSERVER" ) then	
		if this:IsVisible() == true then
			return
		end
 
		NoDiffMatch_PlayerQuickEnter_Show( )
		
	elseif ( event == "VIEW_RESOLUTION_CHANGED" ) then
		g_nScreenWidth = tonumber(arg1)/10000;					--width为游戏屏幕宽度
		g_nScreenHeight = math.mod( tonumber(arg1), 10000 );		--height为游戏屏幕宽度
		g_nScreenWidth = math.floor( g_nScreenWidth );
		g_nScreenHeight = math.floor( g_nScreenHeight );
		NoDiffMatch_PlayerQuickEnter_UpdateUIPos()
		
	elseif event == "YINGXIONG_REDPOINT" then
		if tonumber(arg0)==1 or tonumber(arg1)==1 or tonumber(arg2) == 1 then 
			g_YingXiong_Rp = 1
		else
			g_YingXiong_Rp = 0
		end
		NoDiffMatch_PlayerQuickEnter_UpdateXingZhen()
		
	elseif event == "XINGZHEN_UPDATE" or event == "XINGZHEN_REMOVE_NEW" then
		NoDiffMatch_PlayerQuickEnter_UpdateXingZhen()
	end
end


--**********************************
-- 显示
--**********************************
function NoDiffMatch_PlayerQuickEnter_Show( )
	NoDiffMatch_PlayerQuickEnter_UpdateUIPos()
	
	NoDiffMatch_PlayerQuickEnter_Image1_Tips:Hide()
	this:Show()
end

--**********************************
-- UI位置
--**********************************
function NoDiffMatch_PlayerQuickEnter_UpdateUIPos()
	--先判定一下游戏是否在主流程，并且自己是否有效
	if(Player:IsVaild() ~= 1 ) then
		return
	end

	local nSizeIndex = 1
	if ( g_nScreenWidth <= g_nScreenWidthLimit ) then
		nSizeIndex = 1
	else
		nSizeIndex = 2
	end

	local nMinimapWidth = 251
	local nNextIndex = 1
	-- Frame
	NoDiffMatch_PlayerQuickEnter_Frame:SetProperty( "UnifiedPosition", "{{1.000000, "..tostring(-1 * ( nNextIndex + 1 ) * BkSize[nSizeIndex][1] - nMinimapWidth).."},{0.000000,3}}" )
	NoDiffMatch_PlayerQuickEnter_Frame:SetProperty( "AbsoluteSize", "w:"..( nNextIndex + 1 ) * BkSize[nSizeIndex][1].." h:"..BkSize[nSizeIndex][2].."" )
	

	NoDiffMatch_PlayerQuickEnter_Bk1:SetProperty( "UnifiedPosition", "{{0.000000,"..nNextIndex * BkSize[nSizeIndex][1].."},{0.000000,0}}" )
	NoDiffMatch_PlayerQuickEnter_Bk1:SetProperty( "UnifiedSize", "{{0.000000,"..BkSize[nSizeIndex][1].."},{0.000000,"..BkSize[nSizeIndex][2].."}}" )
	-- Image
	NoDiffMatch_PlayerQuickEnter_Image1:SetProperty( "UnifiedSize", "{{0.000000,"..BkSize[nSizeIndex][1].."},{0.000000,"..BkSize[nSizeIndex][2].."}}" )

end


