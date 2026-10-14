--GiveGift.lua
--星阵-赠礼界面
local g_Frame_UnifiedPosition
local g_NpcTarget_Id = 0
local g_YingXiong_Id = 0
local g_Interests_Id = 0

local g_YingXiongLevel_Flag = {
	"set:Rune_Star01 image:JiaoBiao1",
	"set:Rune_Star01 image:JiaoBiao4",
	"set:Rune_Star01 image:JiaoBiao5",
	"set:Rune_Star01 image:JiaoBiao3",
	"set:Rune_Star01 image:JiaoBiao2",
}
--预加载函数，可以而且只能在这里注册脚本关心的事件
function GiveGift_PreLoad()
	this:RegisterEvent("SCENE_TRANSED",false)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("YINGXIONG_CHANGE",false)
	this:RegisterEvent("PACKAGE_ITEM_CHANGED_EX",false)
	this:RegisterEvent("GIVEGIFT_OPEN_CLOSE",false)
end

--加载窗口的时候调用的函数，加载窗口时调用一次
function GiveGift_OnLoad()
	g_Frame_UnifiedPosition = GiveGift_Frame:GetProperty("UnifiedPosition")
end

--响应事件的函数，当注册的事件发生时会调用的函数
function GiveGift_OnEvent(event)
	if (event == "ADJEST_UI_POS" or event == "VIEW_RESOLUTION_CHANGED") then
		GiveGift_Frame:SetProperty("UnifiedPosition", g_Frame_UnifiedPosition)
	elseif ( event == "SCENE_TRANSED" ) then
		this:Hide()
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 14260001 ) then
		local nTargetId = Get_XParam_INT(0)
		if nTargetId ~= 0 then 
			g_NpcTarget_Id = tonumber( nTargetId )
			local targetObj = Target:GetServerId2ClientId( g_NpcTarget_Id );
			this:CareObject(targetObj, 1, "GiveGift");
		end
		if Get_XParam_INT( 1 ) == 0 then 
			this:Hide()
			return
		end
		g_YingXiong_Id = Get_XParam_INT( 2 )
		g_Interests_Id = Get_XParam_INT( 3 )

		GiveGift_FullUpInfo()
		GiveGift_FullUpAwardInfo()
		if this:IsVisible() then
			this:Hide();
		end
		this:Show()
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 14260002 ) then
		local gift_flag = Get_XParam_INT( 0 )
		local level_flag = Get_XParam_INT( 1 )
		local attr_flag = Get_XParam_INT( 2 ) 
		PushEvent("YINGXIONG_REDPOINT", gift_flag, level_flag, attr_flag) 
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 14260003 ) then
		if g_YingXiong_Id ~= Get_XParam_INT( 0 ) then return end
		GiveGift_FullUpAwardInfo()
	elseif ( event == "YINGXIONG_CHANGE" ) then
		-- PushDebugMessage("GiveGift_OnEvent:==:YINGXIONG_CHANGE:"..(arg0 or "nil"))
		if tonumber(arg0) ~= g_YingXiong_Id then return end
		GiveGift_FullUpInfo()
	elseif ( event == "PACKAGE_ITEM_CHANGED_EX" ) then 
		GiveGift_FullUpInfo()
	elseif ( event == "GIVEGIFT_OPEN_CLOSE" ) then 
		this:Hide()
	end 
end

--以下是用户自定义的函数
function GiveGift_OnHidden()
	this:Hide()
end
function GiveGift_GetTijiaoAward()
	local nYingXiongId = g_YingXiong_Id
	local nInterestsId = g_Interests_Id
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "Gift_GetTJAward" ); 		-- 脚本号
		Set_XSCRIPT_ScriptID( 888052 );						-- 脚本编号
		Set_XSCRIPT_Parameter( 0, nYingXiongId );
		Set_XSCRIPT_Parameter( 1, nInterestsId );
		Set_XSCRIPT_ParamCount( 2 );						-- 参数个数
	Send_XSCRIPT()
end
function GiveGift_GiveOneTime()
	local nYingXiongId = g_YingXiong_Id
	local nInterestsId = g_Interests_Id
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "Gift_GiveOneTime" ); 		-- 脚本号
		Set_XSCRIPT_ScriptID( 888052 );						-- 脚本编号
		Set_XSCRIPT_Parameter( 0, g_NpcTarget_Id );
		Set_XSCRIPT_Parameter( 1, nYingXiongId );
		Set_XSCRIPT_Parameter( 2, nInterestsId );
		Set_XSCRIPT_ParamCount( 3 );						-- 参数个数
	Send_XSCRIPT()
end
function GiveGift_GiveTenTime()
	local nYingXiongId = g_YingXiong_Id
	local nInterestsId = g_Interests_Id
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "Gift_GiveTenTime" ); 		-- 脚本号
		Set_XSCRIPT_ScriptID( 888052 );						-- 脚本编号
		Set_XSCRIPT_Parameter( 0, g_NpcTarget_Id );
		Set_XSCRIPT_Parameter( 1, nYingXiongId );
		Set_XSCRIPT_Parameter( 2, nInterestsId );
		Set_XSCRIPT_ParamCount( 3 );						-- 参数个数
	Send_XSCRIPT()
end
function GiveGift_GetYingXiongLevel_Flag(nYingXiongLevel)
	local nIndex
	if nYingXiongLevel >= 10000 then 
		nIndex = 5
	elseif nYingXiongLevel >= 8000 then 
		nIndex = 4
	elseif nYingXiongLevel >= 5000 then 
		nIndex = 3
	elseif nYingXiongLevel >= 2000 then 
		nIndex = 2
	else
		nIndex = 1
	end
	return g_YingXiongLevel_Flag[nIndex]
end
function GiveGift_FullUpInfo()
	local nYingXiongId = g_YingXiong_Id
	local nInterestsId = g_Interests_Id
	local nItemId = DataPool:LuaFnGetXingZhen_InterestsInfo(nInterestsId, "Shouli_ItemId1")

	GiveGift_HeroInfo_HeroHead:SetProperty( "Image", DataPool:LuaFnGetXingZhen_YingXiongInfo(nYingXiongId, "HeadImage") )
	GiveGift_HeroInfo_HeroName:SetText( DataPool:LuaFnGetXingZhen_YingXiongInfo(nYingXiongId, "Name") )
	-- GiveGift_Gift_Name:SetText( DataPool:LuaFnGetXingZhen_InterestsInfo(nInterestsId, "Name") )
	local objAction = DataPool:CreateActionItemForShow(nItemId, 1)
	GiveGift_HeroInfo_GiftIcon:SetActionItem(objAction:GetID());
	local nItemId2 = DataPool:LuaFnGetXingZhen_InterestsInfo(nInterestsId, "Zengli_ShowId")
	local objAction = DataPool:CreateActionItemForShow(nItemId2, 1)
	GiveGift_BonusIcon:SetActionItem(objAction:GetID());

	local itemCount	= PlayerPackage:CountAvailableItemByIDTable(nItemId) + PlayerPackage:Lua_GetLockItemCount(nItemId)
	GiveGift_HeroInfo_GiftIcon_Num:SetText(tostring(itemCount))
	-- 提交次数
	local nGiveNum = DataPool:LuaFnGetXingZhen_InterestsGiveNum(nInterestsId)
	GiveGift_GiftAccumulative:SetText(ScriptGlobal_Format("#{XZYX_200309_17}", 10-nGiveNum))
	-- 英雄好感度
	local nYingXiongLevel = DataPool:LuaFnGetXingZhen_YingXiongHaoganLevel(nYingXiongId)
	GiveGift_HeroInfo_HeroIntimacy:SetText(ScriptGlobal_Format("#{XZYX_200309_54}", nYingXiongLevel))
	GiveGift_LikeLevel:SetProperty( "Image", GiveGift_GetYingXiongLevel_Flag(nYingXiongLevel) );
	-- 受礼次数
	local nMaxLevel = DataPool:LuaFnGetXingZhen_InterestsInfo(nInterestsId, "MaxLevel")
	local nTotalGiveNum = DataPool:LuaFnGetXingZhen_InterestsTotalGiveNum(nInterestsId)
	GiveGift_GiftItem1_TotalGive:SetText(ScriptGlobal_Format("#{XZYX_200309_334}", nTotalGiveNum, nMaxLevel*10))

	if nTotalGiveNum == nMaxLevel*10 then
		GiveGift_BonusIcon:Hide()
		GiveGift_GiftAccumulative:Hide()
	else
		GiveGift_BonusIcon:Show()
		GiveGift_GiftAccumulative:Show()
	end
end

function GiveGift_HelpInfo_Clicked()
	local nYingXiongId = g_YingXiong_Id
	local nAward_MaxLevel = DataPool:LuaFnGetXingZhen_YingXiongAwardLevel(nYingXiongId)
	local nGroupId = DataPool:LuaFnGetXingZhen_YingXiongInfo(nYingXiongId, "AwardIndex")
	local nNextLevel = DataPool:LuaFnGetXingZhen_YingXiongNextAwardLevel(nGroupId, 0)
	local szInfo = "#{XZJC_202106_370}"
	while nNextLevel do 
		local scID, scLevel = DataPool:LuaFnGetXingZhen_YingXiongAwardInfo(nGroupId,nNextLevel)
		local scName = DataPool:LuaFnGetSkillCardInfo(scID, "Name")		
		szInfo = szInfo..ScriptGlobal_Format("#r#{XZJC_202106_371}", nNextLevel, tostring(scName), tostring(scLevel))
		
		if nAward_MaxLevel >= nNextLevel then
			szInfo = szInfo.."#{XZYX_200309_53}"
		end
		nNextLevel = DataPool:LuaFnGetXingZhen_YingXiongNextAwardLevel(nGroupId, nNextLevel)
	end

	PushEvent( "RUNE_STARS_TEXTINFO", "GiveGift", szInfo, "#{XZYX_200309_383}")
end
function GiveGift_FullUpAwardInfo()
	local nYingXiongId = g_YingXiong_Id
	local nAward_MaxLevel = DataPool:LuaFnGetXingZhen_YingXiongAwardLevel(nYingXiongId)
	local nGroupId = DataPool:LuaFnGetXingZhen_YingXiongInfo(nYingXiongId, "AwardIndex")
	local nNextLevel = DataPool:LuaFnGetXingZhen_YingXiongNextAwardLevel(nGroupId, nAward_MaxLevel)
	if not nNextLevel then 
		GiveGift_HaoGanDu2:Hide()
		GiveGift_HeroInfo_QuestionMark:Hide()
		
		local scID = DataPool:LuaFnGetXingZhen_YingXiongInfo(nYingXiongId, "SkillIndex")
		local strName = DataPool:LuaFnGetSkillCardInfo(scID, "Name")
		GiveGift_HaoGanDu:SetText(ScriptGlobal_Format("#{XZJC_202106_368}", strName))
	else
		GiveGift_HaoGanDu2:Hide()
		GiveGift_HeroInfo_QuestionMark:Show()
		
		local scID, scLevel = DataPool:LuaFnGetXingZhen_YingXiongAwardInfo(nGroupId, nNextLevel)
		local strName = DataPool:LuaFnGetSkillCardInfo(scID, "Name")
		GiveGift_HaoGanDu:SetText(ScriptGlobal_Format("#{XZJC_202106_367}", nNextLevel, strName, tostring(scLevel)))
	end
end