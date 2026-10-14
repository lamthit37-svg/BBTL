
--藏宝图 自选宝箱
local g_CangPin_AwardChoices_Frame_UnifiedPosition


-- 界面名称
local g_CangPin_DrawText = 
{
	[38008544] = {msg = "#{CPBT_260115_135}",npage = 3,},
	[38008545] = {msg = "#{CPBT_260115_136}",npage = 3,},
	[38008546] = {msg = "#{CPBT_260115_137}",npage = 1,},
	[38008547] = {msg = "#{CPBT_260115_138}",npage = 2,},
}

local g_CangPinRewardInfo =
{
	[38008544] = {
		[1] = {id = 37000003, num = 1,},  --
		[2] = {id = 37000004, num = 1,},  --
		[3] = {id = 37001001, num = 1,},  --
		[4] = {id = 37001002, num = 1,},  --
		[5] = {id = 37001003, num = 1,},  --
		[6] = {id = 37001004, num = 1,},  --
		[7] = {id = 37002003, num = 1,},  --
		[8] = {id = 37002004, num = 1,},  --
		[9] = {id = 37003002, num = 1,},  --
		[10] = {id = 37003003, num = 1,},  --				
	},
	[38008545] = {
		[1] = {id = 37000101, num = 1,},  --
		[2] = {id = 37000103, num = 1,},  --
		[3] = {id = 37001101, num = 1,},  --
		[4] = {id = 37001102, num = 1,},  --
		[5] = {id = 37001208, num = 1,},  --
		[6] = {id = 37002102, num = 1,},  --
		[7] = {id = 37002103, num = 1,},  --
		[8] = {id = 37003101, num = 1,},  --
		[9] = {id = 37003102, num = 1,},  --
		[10] = {id = 37003103, num = 1,},  --				
	},
	[38008546] = {
		[1] = {id = 37000202, num = 1,},  --
		[2] = {id = 37001201, num = 1,},  --
		[3] = {id = 37001202, num = 1,},  --
		[4] = {id = 37001203, num = 1,},  --
		[5] = {id = 37001204, num = 1,},  --
		[6] = {id = 37001207, num = 1,},  --
		[7] = {id = 37003202, num = 1,},  --
		[8] = {id = 37002201, num = 1,},  --
		[9] = {id = 37002202, num = 1,},  --				
	},
	[38008547] = {
		[1] = {id = 37001301, num = 1,},  --
		[2] = {id = 37001206, num = 1,},  --
		[3] = {id = 37002301, num = 1,},  --
		[4] = {id = 37002302, num = 1,},  --
		[5] = {id = 37002303, num = 1,},  --
		[6] = {id = 37002304, num = 1,},  --				
	},			
}

local g_CangPinItemId = -1
local g_CangPinBagIndex = -1
local g_CangPinSelect = 0

local g_CangPinItemInfo = {}
local g_CangPinPage = {}

local g_CangPinItemInfo1 = {}
local g_CangPinItemInfo2 = {}
local g_CangPinItemInfo3 = {}

local g_CangPinMaskInfo1 = {}
local g_CangPinMaskInfo2 = {}
local g_CangPinMaskInfo3 = {}

local g_CangPinTips1 ={}
local g_CangPinTips2 ={}
local g_CangPinTips3 ={}

function CangPin_AwardChoices_PreLoad()
	this:RegisterEvent("UI_COMMAND", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
	this:RegisterEvent("ADJEST_UI_POS",false)
	
end

function CangPin_AwardChoices_OnLoad()
	g_CangPin_AwardChoices_Frame_UnifiedPosition = CangPin_AwardChoices_Frame:GetProperty("UnifiedPosition")

	g_CangPinPage[1] = CangPin_AwardChoices_Page1_Client
	g_CangPinPage[2] = CangPin_AwardChoices_Page2_Client
	g_CangPinPage[3] = CangPin_AwardChoices_Page3_Client

	g_CangPinItemInfo1[1] = CangPin_AwardChoices_Page1_Lace1Item
	g_CangPinItemInfo1[2] = CangPin_AwardChoices_Page1_Lace2Item
	g_CangPinItemInfo1[3] = CangPin_AwardChoices_Page1_Lace3Item
	g_CangPinItemInfo1[4] = CangPin_AwardChoices_Page1_Lace4Item
	g_CangPinItemInfo1[5] = CangPin_AwardChoices_Page1_Lace5Item
	g_CangPinItemInfo1[6] = CangPin_AwardChoices_Page1_Lace6Item
	g_CangPinItemInfo1[7] = CangPin_AwardChoices_Page1_Lace7Item
	g_CangPinItemInfo1[8] = CangPin_AwardChoices_Page1_Lace8Item
	g_CangPinItemInfo1[9] = CangPin_AwardChoices_Page1_Lace9Item

	g_CangPinItemInfo2[1] = CangPin_AwardChoices_Page2_Lace1Item
	g_CangPinItemInfo2[2] = CangPin_AwardChoices_Page2_Lace2Item
	g_CangPinItemInfo2[3] = CangPin_AwardChoices_Page2_Lace3Item
	g_CangPinItemInfo2[4] = CangPin_AwardChoices_Page2_Lace4Item
	g_CangPinItemInfo2[5] = CangPin_AwardChoices_Page2_Lace5Item
	g_CangPinItemInfo2[6] = CangPin_AwardChoices_Page2_Lace6Item

	g_CangPinItemInfo3[1] = CangPin_AwardChoices_Page3_Lace1Item
	g_CangPinItemInfo3[2] = CangPin_AwardChoices_Page3_Lace2Item
	g_CangPinItemInfo3[3] = CangPin_AwardChoices_Page3_Lace3Item
	g_CangPinItemInfo3[4] = CangPin_AwardChoices_Page3_Lace4Item
	g_CangPinItemInfo3[5] = CangPin_AwardChoices_Page3_Lace5Item
	g_CangPinItemInfo3[6] = CangPin_AwardChoices_Page3_Lace6Item
	g_CangPinItemInfo3[7] = CangPin_AwardChoices_Page3_Lace7Item
	g_CangPinItemInfo3[8] = CangPin_AwardChoices_Page3_Lace8Item
	g_CangPinItemInfo3[9] = CangPin_AwardChoices_Page3_Lace9Item
	g_CangPinItemInfo3[10] = CangPin_AwardChoices_Page3_Lace10Item


	g_CangPinMaskInfo1[1] = CangPin_AwardChoices_Page1_Lace1Item_Mask
	g_CangPinMaskInfo1[2] = CangPin_AwardChoices_Page1_Lace2Item_Mask
	g_CangPinMaskInfo1[3] = CangPin_AwardChoices_Page1_Lace3Item_Mask
	g_CangPinMaskInfo1[4] = CangPin_AwardChoices_Page1_Lace4Item_Mask
	g_CangPinMaskInfo1[5] = CangPin_AwardChoices_Page1_Lace5Item_Mask
	g_CangPinMaskInfo1[6] = CangPin_AwardChoices_Page1_Lace6Item_Mask
	g_CangPinMaskInfo1[7] = CangPin_AwardChoices_Page1_Lace7Item_Mask
	g_CangPinMaskInfo1[8] = CangPin_AwardChoices_Page1_Lace8Item_Mask
	g_CangPinMaskInfo1[9] = CangPin_AwardChoices_Page1_Lace9Item_Mask

	g_CangPinMaskInfo2[1] = CangPin_AwardChoices_Page2_Lace1Item_Mask
	g_CangPinMaskInfo2[2] = CangPin_AwardChoices_Page2_Lace2Item_Mask
	g_CangPinMaskInfo2[3] = CangPin_AwardChoices_Page2_Lace3Item_Mask
	g_CangPinMaskInfo2[4] = CangPin_AwardChoices_Page2_Lace4Item_Mask
	g_CangPinMaskInfo2[5] = CangPin_AwardChoices_Page2_Lace5Item_Mask
	g_CangPinMaskInfo2[6] = CangPin_AwardChoices_Page2_Lace6Item_Mask

	g_CangPinMaskInfo3[1] = CangPin_AwardChoices_Page3_Lace1Item_Mask
	g_CangPinMaskInfo3[2] = CangPin_AwardChoices_Page3_Lace2Item_Mask
	g_CangPinMaskInfo3[3] = CangPin_AwardChoices_Page3_Lace3Item_Mask
	g_CangPinMaskInfo3[4] = CangPin_AwardChoices_Page3_Lace4Item_Mask
	g_CangPinMaskInfo3[5] = CangPin_AwardChoices_Page3_Lace5Item_Mask
	g_CangPinMaskInfo3[6] = CangPin_AwardChoices_Page3_Lace6Item_Mask
	g_CangPinMaskInfo3[7] = CangPin_AwardChoices_Page3_Lace7Item_Mask
	g_CangPinMaskInfo3[8] = CangPin_AwardChoices_Page3_Lace8Item_Mask
	g_CangPinMaskInfo3[9] = CangPin_AwardChoices_Page3_Lace9Item_Mask
	g_CangPinMaskInfo3[10] = CangPin_AwardChoices_Page3_Lace10Item_Mask


	g_CangPinTips1[1] = CangPin_AwardChoices_Page1_Lace1Item_Tip
	g_CangPinTips1[2] = CangPin_AwardChoices_Page1_Lace2Item_Tip
	g_CangPinTips1[3] = CangPin_AwardChoices_Page1_Lace3Item_Tip
	g_CangPinTips1[4] = CangPin_AwardChoices_Page1_Lace4Item_Tip
	g_CangPinTips1[5] = CangPin_AwardChoices_Page1_Lace5Item_Tip
	g_CangPinTips1[6] = CangPin_AwardChoices_Page1_Lace6Item_Tip
	g_CangPinTips1[7] = CangPin_AwardChoices_Page1_Lace7Item_Tip
	g_CangPinTips1[8] = CangPin_AwardChoices_Page1_Lace8Item_Tip
	g_CangPinTips1[9] = CangPin_AwardChoices_Page1_Lace9Item_Tip

	g_CangPinTips2[1] = CangPin_AwardChoices_Page2_Lace1Item_Tip
	g_CangPinTips2[2] = CangPin_AwardChoices_Page2_Lace2Item_Tip
	g_CangPinTips2[3] = CangPin_AwardChoices_Page2_Lace3Item_Tip
	g_CangPinTips2[4] = CangPin_AwardChoices_Page2_Lace4Item_Tip
	g_CangPinTips2[5] = CangPin_AwardChoices_Page2_Lace5Item_Tip
	g_CangPinTips2[6] = CangPin_AwardChoices_Page2_Lace6Item_Tip

	g_CangPinTips3[1] = CangPin_AwardChoices_Page3_Lace1Item_Tip
	g_CangPinTips3[2] = CangPin_AwardChoices_Page3_Lace2Item_Tip
	g_CangPinTips3[3] = CangPin_AwardChoices_Page3_Lace3Item_Tip
	g_CangPinTips3[4] = CangPin_AwardChoices_Page3_Lace4Item_Tip
	g_CangPinTips3[5] = CangPin_AwardChoices_Page3_Lace5Item_Tip
	g_CangPinTips3[6] = CangPin_AwardChoices_Page3_Lace6Item_Tip
	g_CangPinTips3[7] = CangPin_AwardChoices_Page3_Lace7Item_Tip
	g_CangPinTips3[8] = CangPin_AwardChoices_Page3_Lace8Item_Tip
	g_CangPinTips3[9] = CangPin_AwardChoices_Page3_Lace9Item_Tip
	g_CangPinTips3[10] = CangPin_AwardChoices_Page3_Lace10Item_Tip
end

function CangPin_AwardChoices_OnEvent(event)
	if(event == "UI_COMMAND" and tonumber(arg0) == 50714101) then
		if this:IsVisible() then
			this:Hide()
			return
		end

		g_CangPinBagIndex = Get_XParam_INT(0)
		g_CangPinItemId = Get_XParam_INT(1)
		if g_CangPinRewardInfo[g_CangPinItemId] == nil then
			return 
		end

		if CangPin_AwardChoices_Open() == 1 then
			this:Show()
		end
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		CangPin_AwardChoices_On_ResetPos()
	elseif event == "OPEN_ANNIVERSARY_BEFORE" then
		this:Hide()
	elseif event == "ADJEST_UI_POS" then
		CangPin_AwardChoices_On_ResetPos()
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		this:Hide()
	end
	
end

function CangPin_AwardChoices_Open()

	if g_CangPin_DrawText[g_CangPinItemId] == nil then
		return 0
	end

	-- 设置标题
	CangPin_AwardChoices_DragTitle:SetText( g_CangPin_DrawText[g_CangPinItemId].msg)
	CangPin_AwardChoices_PageUpdate()
	return 1
end


function CangPin_AwardChoices_PageUpdate()
	local nPage = g_CangPin_DrawText[g_CangPinItemId].npage
	for i =1, table.getn(g_CangPinPage) do 
		g_CangPinPage[i]:Hide()
	end
	
	g_CangPinPage[nPage]:Show()
	local rewardInfo = g_CangPinRewardInfo[g_CangPinItemId]
	CangPin_AwardChoicesSelectMask(nPage,0)

	if nPage == 1 then
		for i = 1, table.getn(g_CangPinItemInfo1) do 
			if rewardInfo[i] ~= nil then
				local theAction = DataPool:CreateBindActionItemForShow(rewardInfo[i].id, rewardInfo[i].num)
				if theAction:GetID() ~= 0 then	
					g_CangPinItemInfo1[i]:SetActionItem(theAction:GetID())
					local itemName = DataPool:Lua_GetItemNameByIndex(rewardInfo[i].id)
					g_CangPinTips1[i]:SetText( ScriptGlobal_Format( "#{CPBT_260115_141}", itemName )  )
				else
					g_CangPinItemInfo1[i]:SetActionItem(-1)
					g_CangPinTips1[i]:SetText("")
				end
				g_CangPinItemInfo1[i]:Show()
				g_CangPinTips1[i]:Show()
			end
		end

	elseif nPage == 2 then
		for i = 1, table.getn(g_CangPinItemInfo2) do 
			if rewardInfo[i] ~= nil then
				local theAction = DataPool:CreateBindActionItemForShow(rewardInfo[i].id, rewardInfo[i].num)
				if theAction:GetID() ~= 0 then	
					g_CangPinItemInfo2[i]:SetActionItem(theAction:GetID())
					local itemName = DataPool:Lua_GetItemNameByIndex(rewardInfo[i].id)
					g_CangPinTips2[i]:SetText(ScriptGlobal_Format( "#{CPBT_260115_141}", itemName ))
				else
					g_CangPinItemInfo2[i]:SetActionItem(-1)
					g_CangPinTips2[i]:SetText("")
				end
				g_CangPinItemInfo2[i]:Show()
				g_CangPinTips2[i]:Show()
			end
		end
	elseif nPage == 3 then
		for i = 1, table.getn(g_CangPinItemInfo3) do 
			if rewardInfo[i] ~= nil then
				local theAction = DataPool:CreateBindActionItemForShow(rewardInfo[i].id, rewardInfo[i].num)
				if theAction:GetID() ~= 0 then	
					g_CangPinItemInfo3[i]:SetActionItem(theAction:GetID())
					local itemName = DataPool:Lua_GetItemNameByIndex(rewardInfo[i].id)
					g_CangPinTips3[i]:SetText(ScriptGlobal_Format( "#{CPBT_260115_141}", itemName ))
				else
					g_CangPinItemInfo3[i]:SetActionItem(-1)
					g_CangPinTips3[i]:SetText("")
				end
				g_CangPinItemInfo3[i]:Show()
				g_CangPinTips3[i]:Show()
			end
		end
	end
end


function CangPin_AwardChoicesSelectMask(nPage,nSelect)
	if nPage == 1 then
		-- 选项清空
		for i = 1, table.getn(g_CangPinMaskInfo1) do 
			g_CangPinMaskInfo1[i]:Hide()
		end

		if g_CangPinMaskInfo1[nSelect] ~= nil then
			g_CangPinMaskInfo1[nSelect]:Show()
		end
	elseif nPage == 2 then
		-- 选项清空
		for i = 1, table.getn(g_CangPinMaskInfo2) do 
			g_CangPinMaskInfo2[i]:Hide()
		end

		if g_CangPinMaskInfo2[nSelect] ~= nil then
			g_CangPinMaskInfo2[nSelect]:Show()
		end

	elseif nPage == 3 then
		-- 选项清空
		for i = 1, table.getn(g_CangPinMaskInfo3) do 
			g_CangPinMaskInfo3[i]:Hide()
		end

		if g_CangPinMaskInfo3[nSelect] ~= nil then
			g_CangPinMaskInfo3[nSelect]:Show()
		end
	end
end

function CangPin_AwardChoices_On_ResetPos()
	CangPin_AwardChoices_Frame:SetProperty("UnifiedPosition", g_CangPin_AwardChoices_Frame_UnifiedPosition)
end

function CangPin_AwardChoices_Close()
	this:Hide()
end

-- 选择一个选项
function CangPin_AwardChoices_Choice(nselect)
	local nPage = g_CangPin_DrawText[g_CangPinItemId].npage
	local rewardInfo = g_CangPinRewardInfo[g_CangPinItemId]

	local nCurSelect = math.mod(nselect,100)
	if nCurSelect <1 or nCurSelect >  table.getn(rewardInfo) then
		nCurSelect = 1
	end

	g_CangPinSelect = nCurSelect
	CangPin_AwardChoicesSelectMask(nPage,nCurSelect)
end

-- 点击确认
function CangPin_AwardChoices_GetClick()

	if g_CangPinSelect < 1 then
		PushDebugMessage( "#{CPBT_260115_88}")	
		return
	end

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OnPlayerSelectReward" )
		Set_XSCRIPT_ScriptID( 507141 )
		Set_XSCRIPT_Parameter( 0, g_CangPinBagIndex )	
		Set_XSCRIPT_Parameter( 1, g_CangPinItemId )
		Set_XSCRIPT_Parameter( 2, g_CangPinSelect )
		Set_XSCRIPT_ParamCount(3)
	Send_XSCRIPT()

	this:Hide()
end