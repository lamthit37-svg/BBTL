-- NewLongMangLiHe
-- !!!reloadscript =NewLongMangLiHe
--

local g_NewLongMangLiHe_Frame_UnifiedPosition
local MAX_OBJ_DISTANCE 		= 3.0
local g_nObjCaredIDClient 	= -1
local g_nServerObjID 		= -1
local bCaredItem 			= 0
local bCaredObj 			= 0
local bCaredMoney 			= 0
local bCaredYuanBao			= 0
local g_nComfirmParam1		= 0
local g_nComfirmParam2		= 0
local g_nComfirmParam3		= 0
local g_nComfirmParam4		= 0

local g_nUICommandID		= 79013001
local g_nComfirmUICommandID	= 79013002


local g_nItemBagPos			= -1
local g_nUseItemID			= -1
local g_nCurPageIndex		= 1
local g_nPetWaiGuan			= -1

local g_cPageButtons		= {}
local g_nMaxPageNum			= 6

-- set:XSYNewBK12 image:XSYNew_WHLM2  二级
-- set:XSYNewBK12 image:XSYNew_WHLM3  三级
-- set:XSYNewBK12 image:XSYNew_WHLM4  四级
-- set:XSYNewBK12 image:XSYNew_WHLM5  五级
-- set:XSYNewBK12 image:XSYNew_WHLM6  六级

local g_tPageShowInfo		= 
{
	[1] = {strPic01 = "set:XSYNewBK09 image:XSYNew_LMLH_1", strPic02 = "set:XSYNewBK09 image:XSYNew_LMLH_2", nWG01 = "#{TLHX_260518_16}", nWG02 = "#{TLHX_260518_17}", },
	[2] = {strPic01 = "set:XSYNewBK12 image:XSYNew_WHLM6", strPic02 = "set:XSYNewBK09 image:XSYNew_LMLH_1", nWG01 = "#{TLHX_260518_22}", nWG02 = "#{TLHX_260518_16}", },
	[3] = {strPic01 = "set:XSYNewBK12 image:XSYNew_WHLM5", strPic02 = "set:XSYNewBK12 image:XSYNew_WHLM6", nWG01 = "#{TLHX_260518_21}", nWG02 = "#{TLHX_260518_22}", },
	[4] = {strPic01 = "set:XSYNewBK12 image:XSYNew_WHLM4", strPic02 = "set:XSYNewBK12 image:XSYNew_WHLM5", nWG01 = "#{TLHX_260518_20}", nWG02 = "#{TLHX_260518_21}", },
	[5] = {strPic01 = "set:XSYNewBK12 image:XSYNew_WHLM3", strPic02 = "set:XSYNewBK12 image:XSYNew_WHLM4", nWG01 = "#{TLHX_260518_19}", nWG02 = "#{TLHX_260518_20}", },
	[6] = {strPic01 = "set:XSYNewBK12 image:XSYNew_WHLM2", strPic02 = "set:XSYNewBK12 image:XSYNew_WHLM3", nWG01 = "#{TLHX_260518_18}", nWG02 = "#{TLHX_260518_19}", },
}

--=========================================================
-- PreLoad
--=========================================================
function NewLongMangLiHe_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("OBJECT_CARED_EVENT", false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", false)
	if 1 == bCaredItem then
		this:RegisterEvent("PACKAGE_ITEM_CHANGED_EX", false)
	end
	if 1 == bCaredMoney then
		this:RegisterEvent("MONEY_CHANGE_EX", false)
		this:RegisterEvent("MONEYJZ_CHANGE_EX", false)
	end
	if 1 == bCaredYuanBao then
		this:RegisterEvent("UPDATE_YUANBAO", false)
	end
	this:RegisterEvent("ADJEST_UI_POS")
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED")
end

--=========================================================
-- OnLoad
--=========================================================
function NewLongMangLiHe_OnLoad()
	g_NewLongMangLiHe_Frame_UnifiedPosition = NewLongMangLiHe_Frame:GetProperty("UnifiedPosition")

	-- NewLongMangLiHe_OK_Button : SetEvent("Clicked", "NewLongMangLiHe_ConfirmClick()")

	-- PET_AI_COWARDICE = 0,	// 胆小
	-- PET_AI_WARINESS,			// 谨慎 1
	-- PET_AI_LOYALISM,			// 忠诚 2
	-- PET_AI_CANNINESS,		// 精明
	-- PET_AI_VALOUR,			// 勇猛

	-- TLHX_260518_24	#G尚未选择
	-- TLHX_260518_25	#cfff263忠诚性格
	-- TLHX_260518_26	#cfff263谨慎性格
	-- 左侧选择
	-- NewLongMangLiHe_LQClinet1_ALLChoice:ComboBoxAddItem("#{TLHX_260518_24}", 0)
	-- NewLongMangLiHe_LQClinet1_ALLChoice:ComboBoxAddItem("#{TLHX_260518_26}", 1)
	-- NewLongMangLiHe_LQClinet1_ALLChoice:ComboBoxAddItem("#{TLHX_260518_25}", 2)
	NewLongMangLiHe_LQClinet1_ALLChoice:ComboBoxAddItem("尚未选择", 0)
	NewLongMangLiHe_LQClinet1_ALLChoice:ComboBoxAddItem("谨慎性格", 1)
	NewLongMangLiHe_LQClinet1_ALLChoice:ComboBoxAddItem("忠诚性格", 2)
	
	-- 右侧选择
	-- NewLongMangLiHe_LQClinet2_ALLChoice:ComboBoxAddItem("#{TLHX_260518_24}", 0)
	-- NewLongMangLiHe_LQClinet2_ALLChoice:ComboBoxAddItem("#{TLHX_260518_26}", 1)
	-- NewLongMangLiHe_LQClinet2_ALLChoice:ComboBoxAddItem("#{TLHX_260518_25}", 2)
	NewLongMangLiHe_LQClinet2_ALLChoice:ComboBoxAddItem("尚未选择", 0)
	NewLongMangLiHe_LQClinet2_ALLChoice:ComboBoxAddItem("谨慎性格", 1)
	NewLongMangLiHe_LQClinet2_ALLChoice:ComboBoxAddItem("忠诚性格", 2)

	g_cPageButtons[1] 		= NewLongMangLiHe_Page1
	g_cPageButtons[2] 		= NewLongMangLiHe_Page2
	g_cPageButtons[3] 		= NewLongMangLiHe_Page3
	g_cPageButtons[4] 		= NewLongMangLiHe_Page4
	g_cPageButtons[5] 		= NewLongMangLiHe_Page5
	g_cPageButtons[6] 		= NewLongMangLiHe_Page6
	
end

--=========================================================
-- OnEvent
--=========================================================
function NewLongMangLiHe_OnEvent(event)
	if ( event == "UI_COMMAND" and tonumber(arg0) == g_nUICommandID ) then
		-- 0 关闭, 1 打开, 2 刷新, 3 二次确认框
		local nOpType 	= Get_XParam_INT(0)

		-- 关闭界面
		if 0 == nOpType then	
			if this:IsVisible() then
				NewLongMangLiHe_OnClose()
			end
		end

		-- 打开界面
		if 1 == nOpType then
			-- 关注npc
			if 1 == bCaredObj then
				local nServerObjID 	= Get_XParam_INT(1)
				if nServerObjID == nil or nServerObjID < 0 then
					if this:IsVisible() then
						NewLongMangLiHe_OnClose()
					end
				end
				g_nServerObjID = nServerObjID
				g_nObjCaredIDClient = DataPool : GetNPCIDByServerID(tonumber(nServerObjID))
				BeginCareObject_NewLongMangLiHe()
			end

			-- 显示界面
			-- 为了解决界面被遮挡的问题，先把界面关了
			-- if this:IsVisible() then
			-- 	NewLongMangLiHe_OnClose()
			-- end
			NewLongMangLiHe_Reset()
			NewLongMangLiHe_Frame_On_ResetPos()
			this:Show()
			NewLongMangLiHe_ParamInit()
			NewLongMangLiHe_MoneyUpdate()
			NewLongMangLiHe_YuanBaoUpdate()
			NewLongMangLiHe_Update(1)
		end
			
		-- 刷新界面
		if 2 == nOpType then
			-- 关注npc
			if 1 == bCaredObj then
				local nServerObjID 	= Get_XParam_INT(1)
				if nServerObjID == nil or nServerObjID < 0 then
					if this:IsVisible() then
						NewLongMangLiHe_OnClose()
					end
				end
			end
			if this:IsVisible() then
				NewLongMangLiHe_ParamInit()
				NewLongMangLiHe_Update(0)
			end
		end

		-- 二次确认框
		-- if 3 == nOpType then
		-- 	local strMsg = Get_XParam_STR(0)
		-- 	-- g_nComfirmParam1 = Get_XParam_INT(1)
		-- 	-- ["Type"] "Ok" "YesNo"
		-- 	MessageBoxSelf3("NewLongMangLiHe_OnComfirmedBack", {["Content"] = strMsg,["Type"] = "YesNo", })
		-- end
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == g_nComfirmUICommandID ) then
			local strMsg = Get_XParam_STR(0)
			g_nComfirmParam1 = Get_XParam_INT(0)
			g_nComfirmParam2 = Get_XParam_INT(1)
			g_nComfirmParam3 = Get_XParam_INT(2)
			g_nComfirmParam4 = Get_XParam_INT(3)
			-- ["Type"] "Ok" "YesNo"
			MessageBoxSelf3("NewLongMangLiHe_OnComfirmedBack", {["Content"] = strMsg,["Type"] = "YesNo", })
	-- ============================================
	-- 通用逻辑
	elseif ( event == "OBJECT_CARED_EVENT" ) and 1 == bCaredObj then
		if(tonumber(arg0) ~= g_nObjCaredIDClient) then
			return
		end
		-- 如果和NPC的距离大于一定距离或者被删除，自动关闭
		if(arg1 == "distance" and tonumber(arg2)>MAX_OBJ_DISTANCE or arg1=="destroy") then
			-- 关闭界面
			NewLongMangLiHe_OnClose()
		end	

	-- 物品改变
	elseif ( event == "PACKAGE_ITEM_CHANGED_EX" and this:IsVisible() and 1 == bCaredItem ) then
		-- 刷新界面
		if this:IsVisible() then
			NewLongMangLiHe_Update(0)
		end

	-- 金钱改变
	elseif (event == "MONEY_CHANGE_EX" or event == "MONEYJZ_CHANGE_EX") and 1 == bCaredMoney then
		NewLongMangLiHe_MoneyUpdate()

	-- 元宝改变
	elseif event == "UPDATE_YUANBAO" and 1 == bCaredYuanBao then
		NewLongMangLiHe_YuanBaoUpdate()

	elseif event == "HIDE_ON_SCENE_TRANSED" then
		NewLongMangLiHe_OnClose()
	
	elseif (event == "ADJEST_UI_POS" ) then
		NewLongMangLiHe_Frame_On_ResetPos()

	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		NewLongMangLiHe_Frame_On_ResetPos()
	end
end

--=========================================================
-- 界面参数初始化
--=========================================================
function NewLongMangLiHe_ParamInit()
	g_nUseItemID 	= Get_XParam_INT(1)
	g_nItemBagPos 	= Get_XParam_INT(2)
	g_nCurPageIndex = Get_XParam_INT(3)
end

--=========================================================
-- 二次确认框回调 ["Type"] "Ok"的返回值有"Ok"； ["Type"] "YesNo"的返回值有 "Yes" "No"
--=========================================================
function NewLongMangLiHe_OnComfirmedBack(strRet)
	if nil == strRet then
		return
	end

	if "Yes" == strRet or "Ok" == strRet then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OnItemUseFromClient" )
			Set_XSCRIPT_ScriptID(790130)
			Set_XSCRIPT_Parameter(0, g_nComfirmParam1)					
			Set_XSCRIPT_Parameter(1, g_nComfirmParam2)				
			Set_XSCRIPT_Parameter(2, g_nComfirmParam3)				
			Set_XSCRIPT_Parameter(3, g_nComfirmParam4)				
			Set_XSCRIPT_Parameter(4, 1)				
			Set_XSCRIPT_ParamCount(5)
		Send_XSCRIPT()
	end

	if "No" == strRet then
		
	end
end

--=========================================================
-- 界面更新
--=========================================================
-- !!!reloadscript =NewLongMangLiHe
function NewLongMangLiHe_Update(bOpen)

	-- 性格
	if 1 == bOpen then
		NewLongMangLiHe_LQClinet1_ALLChoice : SetCurrentSelect(0) 
		NewLongMangLiHe_LQClinet2_ALLChoice : SetCurrentSelect(0) 
	end

	-- 根据页签显示不同的展示图和领取字典
	for i = 1, g_nMaxPageNum do
		g_cPageButtons[i] : SetCheck(0)
	end

	g_cPageButtons[g_nCurPageIndex] : SetCheck(1)

	local tCurPageInfo = g_tPageShowInfo[g_nCurPageIndex]
	if nil == tCurPageInfo then
		NewLongMangLiHe_OnClose()
	end

	NewLongMangLiHe_Pet1_image : SetProperty( "Image", tCurPageInfo.strPic01 )
	NewLongMangLiHe_Pet2_image : SetProperty( "Image", tCurPageInfo.strPic02 )
	NewLongMangLiHe_Button1 : SetText( tCurPageInfo.nWG01 )
	NewLongMangLiHe_Button2 : SetText( tCurPageInfo.nWG02 )
end

--=========================================================
-- 问号
--=========================================================
function NewLongMangLiHe_HelpClicked()
	PushEvent("CCSHOP_HELP", 245)
end

--=========================================================
-- 重置界面
--=========================================================
function NewLongMangLiHe_Reset()
	g_nItemBagPos		= -1
	g_nUseItemID		= -1
	g_nCurPageIndex		= 1
	g_nPetWaiGuan		= -1
end

--=========================================================
-- 切换页签
--=========================================================
function NewLongMangLiHe_PageClicked(nPageIndex)

	g_nCurPageIndex = nPageIndex

	NewLongMangLiHe_Update(0)
end

--=========================================================
-- 界面确认按钮
--=========================================================
function NewLongMangLiHe_Select_OK(nOkButtonIndex)

	local nCurXingGeIndex = 0
	if 0 == nOkButtonIndex then
		g_nPetWaiGuan = 1
		local szPet, nSetValue = NewLongMangLiHe_LQClinet1_ALLChoice : GetCurrentSelect()
		nCurXingGeIndex = nSetValue
	end

	if 1 == nOkButtonIndex then
		g_nPetWaiGuan = 2
		local szPet, nSetValue = NewLongMangLiHe_LQClinet2_ALLChoice : GetCurrentSelect()
		nCurXingGeIndex = nSetValue
	end

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OnItemUseFromClient" )
		Set_XSCRIPT_ScriptID(790130)
		Set_XSCRIPT_Parameter(0, g_nItemBagPos)					
		Set_XSCRIPT_Parameter(1, g_nCurPageIndex)				
		Set_XSCRIPT_Parameter(2, g_nPetWaiGuan)				
		Set_XSCRIPT_Parameter(3, nCurXingGeIndex)				
		Set_XSCRIPT_Parameter(4, 0)				
		Set_XSCRIPT_ParamCount(5)
	Send_XSCRIPT()
end

--=========================================================
-- 关闭界面
--=========================================================
function NewLongMangLiHe_OnClose()	
	this:Hide()
	StopCareObject_NewLongMangLiHe()
	-- 重置
	NewLongMangLiHe_Reset()
end

--=========================================================
-- 界面隐藏
-- <Event Name="Hidden" Function="NewLongMangLiHe_OnHidden();" />
--=========================================================
function NewLongMangLiHe_OnHidden()
	StopCareObject_NewLongMangLiHe()
	-- 重置
	NewLongMangLiHe_Reset()
end

--=========================================================
-- 关心操作
--=========================================================
function BeginCareObject_NewLongMangLiHe()
	-- 关心
	this:CareObject(g_nObjCaredIDClient, 1, "NewLongMangLiHe")
end

function StopCareObject_NewLongMangLiHe()
	-- 取消关心
	if nil ~= g_nObjCaredIDClient and g_nObjCaredIDClient > 0 then
		this:CareObject(g_nObjCaredIDClient, 0, "NewLongMangLiHe")
	end
	g_nServerObjID = -1
end

--=========================================================
-- 金钱刷新：界面更新调用一次 金钱事件调用一次
--=========================================================
function NewLongMangLiHe_MoneyUpdate()
	-- NewLongMangLiHe_HaveJiaoZiNum : SetProperty( "MoneyNumber", tostring(Player:GetData("MONEY_JZ")) )
	-- NewLongMangLiHe_HaveGoldNum : SetProperty( "MoneyNumber", tostring(Player:GetData("MONEY")) )
end

--=========================================================
-- 元宝刷新：界面更新调用一次 元宝事件调用一次
--=========================================================
function NewLongMangLiHe_YuanBaoUpdate()
	-- NewLongMangLiHe_HaveYuanBaoNum : SetText (tostring(Player:GetData("YUANBAO")))
end

--=========================================================
-- 界面位置
--=========================================================
function NewLongMangLiHe_Frame_On_ResetPos()
	NewLongMangLiHe_Frame:SetProperty("UnifiedPosition", g_NewLongMangLiHe_Frame_UnifiedPosition)
end