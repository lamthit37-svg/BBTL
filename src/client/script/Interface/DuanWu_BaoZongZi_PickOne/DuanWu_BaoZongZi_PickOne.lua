--端午包粽子

local DuanWu_BaoZongZi_PickOne_Frame_UnifiedPosition;

local DuanWu_BaoZongZi_PickOne_SelectButtons = {}
local DuanWu_BaoZongZi_PickOne_MaskList = {}

local DuanWu_BaoZongZi_PickOne_Type = -1
local DuanWu_BaoZongZi_PickOne_ShowList =
{
	[1] = {
		title = "#{DWPF_190428_55}",
		info = "#{DWPF_190428_56}",
		itemList = {20700055, 38002049, 20700063, 20800033},
		itemNum = {8, 2, 16, 4},
		callScriptId = 505089,
		callFuncName = "OnSelectItem",
	},
	[2] = {
		title = "#{DWKC_190502_71}",
		info = "#{DWKC_190502_72}",
		itemList = {39921741, 39921742, 39921743, 39921744},
		itemNum = {1, 1, 1, 1},
		callScriptId = 505091,
		callFuncName = "OnSelectItem",--英雄志向礼盒
	},
	[3] = {
		title = "#{DWKC_190502_76}",
		info = "#{DWKC_190502_77}",
		itemList = {39921745, 39921746, 39921747, 39921748},
		itemNum = {1, 1, 1, 1},
		callScriptId = 505093,
		callFuncName = "OnSelectItem",--武魂属性书礼盒
	},

	[4] = {
		title = "#{YCLB_190819_43}",
		info = "#{YCLB_190819_44}",
		itemList = {39921939, 39921940, 39921941, 39921942},
		itemNum = {1, 1, 1, 1},
		callScriptId = 893246,
		callFuncName = "OnSelectItem",--武魂减抗礼盒
	},

	[5] = {
		title = "#{XFXS_201231_242}",
		info = "#{XFXS_201231_243}",
		itemList = {39923269, 39923270, 39923271, 39923272},
		itemNum = {1, 1, 1, 1},
		callScriptId = 506103,
		callFuncName = "OnSelectItem",--武魂减抗礼盒
	},

	[6] = {
		title = "#{MDJH_220222_13}",
		info = "#{MDJH_220222_05}",
		itemList = {39923805, 39923806, 39923807, 39923808},
		itemNum = {1, 1, 1, 1},
		callScriptId = 888980,
		callFuncName = "OnSelectItem",--武魂属性书礼盒
	},

	[7] = {
		title = "#{DWPF_190428_55}",
		info = "#{DWPF_190428_56}",
		itemList = {39920394, 39920267, 39920235, 39920085},
		itemNum = {2, 1, 1, 3},
		callScriptId = 998036,
		callFuncName = "OnSelectItem",--武魂属性书礼盒
	},

}


local DuanWu_BaoZongZi_PickOne_CurSelect = -1 -- 选择的物品
local DuanWu_BaoZongZi_PickOne_Item_BagPos = -1

--=========================================================
-- 注册窗口关心的所有事件
--=========================================================
function DuanWu_BaoZongZi_PickOne_PreLoad()
	this:RegisterEvent("UI_COMMAND")

	this:RegisterEvent("ADJEST_UI_POS", false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED", false)
	this:RegisterEvent( "HIDE_ON_SCENE_TRANSED" );		-- 离开场景

end

--=========================================================
-- 载入初始化
--=========================================================
function DuanWu_BaoZongZi_PickOne_OnLoad()

	DuanWu_BaoZongZi_PickOne_SelectButtons[1] = DuanWu_BaoZongZi_PickOne_Item1
	DuanWu_BaoZongZi_PickOne_SelectButtons[2] = DuanWu_BaoZongZi_PickOne_Item2
	DuanWu_BaoZongZi_PickOne_SelectButtons[3] = DuanWu_BaoZongZi_PickOne_Item3
	DuanWu_BaoZongZi_PickOne_SelectButtons[4] = DuanWu_BaoZongZi_PickOne_Item4

	DuanWu_BaoZongZi_PickOne_MaskList[1] = DuanWu_BaoZongZi_PickOne_Item1_Mask
	DuanWu_BaoZongZi_PickOne_MaskList[2] = DuanWu_BaoZongZi_PickOne_Item2_Mask
	DuanWu_BaoZongZi_PickOne_MaskList[3] = DuanWu_BaoZongZi_PickOne_Item3_Mask
	DuanWu_BaoZongZi_PickOne_MaskList[4] = DuanWu_BaoZongZi_PickOne_Item4_Mask

	DuanWu_BaoZongZi_PickOne_Frame_UnifiedPosition = DuanWu_BaoZongZi_PickOne_Frame:GetProperty("UnifiedPosition");

end

--=========================================================
-- 事件处理
--=========================================================
function DuanWu_BaoZongZi_PickOne_OnEvent(event)

	if (event == "UI_COMMAND" and tonumber(arg0) == 50508901) then --打开界面

		DuanWu_BaoZongZi_PickOne_Clear( )
		DuanWu_BaoZongZi_PickOne_Type = 1
		DuanWu_BaoZongZi_PickOne_Init( )
		this:Show()
	elseif (event == "UI_COMMAND" and tonumber(arg0) == 50509101) then --打开界面

		DuanWu_BaoZongZi_PickOne_Clear( )
		DuanWu_BaoZongZi_PickOne_Type = 2
		DuanWu_BaoZongZi_PickOne_Init( )
		this:Show()
	elseif (event == "UI_COMMAND" and tonumber(arg0) == 50509301) then --打开界面

		DuanWu_BaoZongZi_PickOne_Clear( )
		DuanWu_BaoZongZi_PickOne_Type = 3
		DuanWu_BaoZongZi_PickOne_Init( )
		this:Show()
	elseif (event == "UI_COMMAND" and tonumber(arg0) == 91020910) then --打开界面

		DuanWu_BaoZongZi_PickOne_Clear( )
		DuanWu_BaoZongZi_PickOne_Type = 4
		DuanWu_BaoZongZi_PickOne_Init( )
		this:Show()
	elseif (event == "UI_COMMAND" and tonumber(arg0) == 50508902) then --关闭界面

		if this:IsVisible() == true then
			DuanWu_BaoZongZi_PickOne_Close()
		end
	elseif (event == "UI_COMMAND" and tonumber(arg0) == 50610301) then --打开界面

		DuanWu_BaoZongZi_PickOne_Clear( )
		DuanWu_BaoZongZi_PickOne_Type = 5
		DuanWu_BaoZongZi_PickOne_Init( )
		this:Show()
	elseif (event == "UI_COMMAND" and tonumber(arg0) == 88898001) then --打开界面

		DuanWu_BaoZongZi_PickOne_Clear( )
		DuanWu_BaoZongZi_PickOne_Type = 6
		DuanWu_BaoZongZi_PickOne_Init( )
		this:Show()
	elseif (event == "UI_COMMAND" and tonumber(arg0) == 99803601) then --打开界面

		DuanWu_BaoZongZi_PickOne_Clear( )
		DuanWu_BaoZongZi_PickOne_Type = 7
		DuanWu_BaoZongZi_PickOne_Init( )
		this:Show()
	elseif (event == "ADJEST_UI_POS" ) then
		DuanWu_BaoZongZi_PickOne_On_ResetPos()

	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		DuanWu_BaoZongZi_PickOne_On_ResetPos()
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		DuanWu_BaoZongZi_PickOne_Close()
	end
end

function DuanWu_BaoZongZi_PickOne_Clear( )
	DuanWu_BaoZongZi_PickOne_Type = -1
	DuanWu_BaoZongZi_PickOne_CurSelect = -1 -- 选择的物品
	DuanWu_BaoZongZi_PickOne_Item_BagPos = -1

	for i=1, table.getn(DuanWu_BaoZongZi_PickOne_MaskList) do
		DuanWu_BaoZongZi_PickOne_MaskList[i]:Hide()
	end
end


--=========================================================
-- 界面控件数据
--=========================================================
function DuanWu_BaoZongZi_PickOne_Init( )
	--
	if DuanWu_BaoZongZi_PickOne_Type == -1 then
		return
	end

	local showInfo = DuanWu_BaoZongZi_PickOne_ShowList[ DuanWu_BaoZongZi_PickOne_Type ]
	if showInfo == nil then
		return
	end

	DuanWu_BaoZongZi_PickOne_DragTitle:SetText( showInfo.title )
	DuanWu_BaoZongZi_PickOne_Info:SetText( showInfo.info )

	for i=1, table.getn(showInfo.itemList) do

		local num = showInfo.itemNum[i]
		local itemAction = DataPool:CreateActionItemForShow(showInfo.itemList[i], num)
		if itemAction:GetID() == 0 then
			return
		end
		DuanWu_BaoZongZi_PickOne_SelectButtons[i]:SetActionItem( itemAction:GetID() )

		DuanWu_BaoZongZi_PickOne_MaskList[i]:Hide()
	end

	DuanWu_BaoZongZi_PickOne_Item_BagPos = Get_XParam_INT(0)
end


function DuanWu_BaoZongZi_PickOne_Select_Clicked( index )
	DuanWu_BaoZongZi_PickOne_CurSelect = index

	for i=1, table.getn(DuanWu_BaoZongZi_PickOne_MaskList) do
		DuanWu_BaoZongZi_PickOne_MaskList[i]:Hide()
	end

	DuanWu_BaoZongZi_PickOne_MaskList[index]:Show()
end


--=========================================================
-- 确定执行功能
--=========================================================
function DuanWu_BaoZongZi_PickOne_OK_Clicked()

	if DuanWu_BaoZongZi_PickOne_Type == -1 then
		return
	end

	local showInfo = DuanWu_BaoZongZi_PickOne_ShowList[ DuanWu_BaoZongZi_PickOne_Type ]
	if showInfo == nil then
		return
	end

	--
	-- 判断是否为安全时间
	if (tonumber(DataPool:GetLeftProtectTime()) > 0) then
		PushDebugMessage("#{KPWFS_131112_20}")
		return
	end

	--判断电话密保和二级密码保护
	if CheckPhoneMibaoAndMinorPassword() ~= 1 then
		return
	end

	--- 角色当前未处于全沉迷或半沉迷状态；
	if IsInFatigueState() <= 0 then
		PushDebugMessage( "#{FCMX_90609_22}" )
		return
	end


	if DuanWu_BaoZongZi_PickOne_CurSelect == -1 then
		PushDebugMessage( "#{MHZD_190501_104}" )
		return
	end

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( showInfo.callFuncName )
		Set_XSCRIPT_ScriptID( showInfo.callScriptId )
		Set_XSCRIPT_Parameter(0, DuanWu_BaoZongZi_PickOne_Item_BagPos)
		Set_XSCRIPT_Parameter(1, DuanWu_BaoZongZi_PickOne_CurSelect)
		Set_XSCRIPT_ParamCount( 2 )
	Send_XSCRIPT()
end



--=========================================================
-- 关闭界面
--=========================================================
function DuanWu_BaoZongZi_PickOne_Close()
	this:Hide()
	return
end


function DuanWu_BaoZongZi_PickOne_On_ResetPos()
  DuanWu_BaoZongZi_PickOne_Frame:SetProperty("UnifiedPosition", DuanWu_BaoZongZi_PickOne_Frame_UnifiedPosition);
end
