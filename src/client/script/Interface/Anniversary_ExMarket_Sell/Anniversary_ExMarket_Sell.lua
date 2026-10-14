--  周年庆刷新集市 售卖界面客户端脚本

local g_nMyScriptId = 998437
local g_nPriceToday = 0 --今天的售卖价格
local g_nCanSellNum = 0 --可以收购的数量
local g_nPlayerItemNum = 0 --玩家现在拥有的数量
local g_nMaxCanSellItemNum = 0 -- 可以售卖的最大数量
local g_nNPCOwnerName ="" -- 摊主名字
local g_Anniversary_ExMarket_Sell_Frame_UnifiedPosition
local g_nUICommandID		= 79009003
local g_nObjCaredIDClient 	= -1
local g_nServerObjID 		= -1
local MAX_OBJ_DISTANCE 		= 3.0
--=========================================================
-- PreLoad
--=========================================================
function Anniversary_ExMarket_Sell_PreLoad()
	this:RegisterEvent("UI_COMMAND")
  	this:RegisterEvent("OBJECT_CARED_EVENT", false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", false)
end


--=========================================================
-- OnLoad
--=========================================================
function Anniversary_ExMarket_Sell_OnLoad()
	g_Anniversary_ExMarket_Sell_Frame_UnifiedPosition =  Anniversary_ExMarket_Sell_Frame:GetProperty("UnifiedPosition")
	
	g_nPriceToday = 0 
	g_nCanSellNum = 0 
	g_nPlayerItemNum = 0 
	g_nMaxCanSellItemNum = 0
	g_nNpcId 	= 0 
	g_nNPCOwnerName ="" 
	
	Anniversary_ExMarket_Sell_InsertNumBox:SetProperty("DefaultEditBox", "True");--设置输入框为默认输入框
	Anniversary_ExMarket_Sell_InsertNumBox:SetText("tostring(1)")	--默认输入为1
	Anniversary_ExMarket_Sell_InsertNumBox:SetSelected( 0, -1 );

	
end

--=========================================================
-- OnEvent
--=========================================================
function Anniversary_ExMarket_Sell_OnEvent(event)

	if ( event == "UI_COMMAND" and tonumber(arg0) == g_nUICommandID ) then
		-- 0 关闭, 1 打开, 2 刷新
		local nOpType 	= Get_XParam_INT(0)

		--PushDebugMessage("UI_COMMAND nOpType"..nOpType)

		-- 关闭界面
		if 0 == nOpType then	
			if this:IsVisible() then
				 Anniversary_ExMarket_Sell_Close()
			end
		end

		-- 打开界面
		if 1 == nOpType then
			--PushDebugMessage("打开界面")
			--关注npc
			local nServerObjID 	= Get_XParam_INT(5)
			if nServerObjID == nil or nServerObjID < 0 then
				if this:IsVisible() then
					Anniversary_ExMarket_Sell_Close()
				end
			end
			g_nServerObjID = nServerObjID
			g_nObjCaredIDClient = DataPool : GetNPCIDByServerID(tonumber(nServerObjID))
			BeginCareObject_Anniversary_ExMarket_Sell()
			
				
			Anniversary_ExMarket_Sell_Reset()
			Anniversary_ExMarket_Sell_ParamInit()
			Anniversary_ExMarket_Sell_Update()
			this:Show()
		end
		
		if 2 == nOpType then
				local nServerObjID 	= Get_XParam_INT(5)
				if nServerObjID == nil or nServerObjID < 0 then
					if this:IsVisible() then
						Anniversary_ExMarket_Sell_Close()
					end
				end
				
			Anniversary_ExMarket_Sell_ParamInit()
			Anniversary_ExMarket_Sell_Update()
		end
		
	elseif ( event == "OBJECT_CARED_EVENT" )  then
		if(tonumber(arg0) ~= g_nObjCaredIDClient) then
			return
		end
		-- 如果和NPC的距离大于一定距离或者被删除，自动关闭
		if(arg1 == "distance" and tonumber(arg2)>MAX_OBJ_DISTANCE or arg1=="destroy") then
			-- 关闭界面
			Fuli_ZhanLing_DiscountBuy_OnClose()
		end 
		
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		--切换场景关闭界面
		Anniversary_ExMarket_Sell_Close()
	end
end

--=========================================================
-- 界面参数初始化
--=========================================================
function Anniversary_ExMarket_Sell_ParamInit()
	g_nPriceToday 			= Get_XParam_INT(1)
	g_nCanSellNum			= Get_XParam_INT(2)
	g_nPlayerItemNum 		= Get_XParam_INT(3) 
	g_nMaxCanSellItemNum 	= Get_XParam_INT(4)
	g_nNpcId 				= Get_XParam_INT(5)
	g_nNPCOwnerName			= Get_XParam_STR(0)

end

--=========================================================
-- 界面更新
--=========================================================
function Anniversary_ExMarket_Sell_Update()
	Anniversary_ExMarket_Sell_DragTitle:SetText(ScriptGlobal_Format("#{ZNJS_230220_73}",g_nNPCOwnerName))  --#gFF0FA0%s0的摊位	
	Anniversary_ExMarket_Sell_PriceText:SetText(ScriptGlobal_Format("#{ZNJS_230220_75}",g_nPriceToday)) -- 今日收购价格：%s0活动代币A
	Anniversary_ExMarket_Sell_AmountText:SetText(ScriptGlobal_Format("#{ZNJS_230220_76}",g_nMaxCanSellItemNum - g_nCanSellNum))  -- 今日已收购：%s0个
	Anniversary_ExMarket_Sell_RestText:SetText(ScriptGlobal_Format("#{ZNJS_230220_77}",g_nCanSellNum))  -- 今日剩余可收购：%s0个
	Anniversary_ExMarket_Sell_PresentNumText:SetText(ScriptGlobal_Format("#{ZNJS_230220_80}",g_nPlayerItemNum))  -- 您当前持有的货物数量：%s0	
	Anniversary_ExMarket_Sell_PredictedText:SetText(ScriptGlobal_Format("#{ZNJS_230220_79}",0))  -- 预计收入：%s0
	Anniversary_ExMarket_Sell_InsertNumBox:SetText(tostring(1))
end
--=========================================================
-- 点击最大 直接把有的都填上
--=========================================================
function  Anniversary_ExMarket_Sell_Max_Clicked()   
	 if 0 <= g_nPlayerItemNum then
			Anniversary_ExMarket_Sell_InsertNumBox:SetText(tostring(g_nPlayerItemNum))
	 end
end
--=========================================================
-- 重置界面参数（归零）
--=========================================================
function Anniversary_ExMarket_Sell_Reset()
	g_nPriceToday = 0 
	g_nCanSellNum = 0 
	g_nPlayerItemNum = 0 
	g_nMaxCanSellItemNum = 0
	g_nNpcId = 0
	g_nNPCOwnerName ="" 
end

--=========================================================
-- TextChange
--=========================================================
function Anniversary_ExMarket_Sell_InsertBox()
	local count = tonumber(Anniversary_ExMarket_Sell_InsertNumBox:GetText())

	if count == nil or count < 0  then
		count = 0 
	end
	--if g_nPlayerItemNum < count then
	--	PushDebugMessage("#{ZNJS_230220_107}")
	--	return
	--end
	Anniversary_ExMarket_Sell_PredictedText:SetText(ScriptGlobal_Format("#{ZNJS_230220_79}",count*g_nPriceToday)) 
	Anniversary_ExMarket_Sell_PredictedText:Show()
end

--=========================================================
--点击售卖
--=========================================================
function Anniversary_ExMarket_Sell_OK_Clicked()
	
	local count = tonumber(Anniversary_ExMarket_Sell_InsertNumBox:GetText())
	if  count == nil or count < 0 then -- 0也可以售卖
		return
    end 
	--if g_nPlayerItemNum < count then
	--	PushDebugMessage("#{ZNJS_230220_107}")
	--	return
	--end
	Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OnRecMessage" )
			Set_XSCRIPT_ScriptID(g_nMyScriptId)			
			Set_XSCRIPT_Parameter(0, 20) --ntype	
			Set_XSCRIPT_Parameter(1, count)
			Set_XSCRIPT_Parameter(2, g_nNpcId)
			Set_XSCRIPT_ParamCount(3)
	Send_XSCRIPT()
end
--=========================================================
-- 关心操作
--=========================================================
function BeginCareObject_Anniversary_ExMarket_Sell()
	-- 关心
	this:CareObject(g_nObjCaredIDClient, 1, "Fuli_ZhanLing_DiscountBuy")
end

function StopCareObject_Anniversary_ExMarket_Sell()
	-- 取消关心
	if nil ~= g_nObjCaredIDClient and g_nObjCaredIDClient > 0 then
		this:CareObject(g_nObjCaredIDClient, 0, "Fuli_ZhanLing_DiscountBuy")
	end
	g_nServerObjID = -1
end

--=========================================================
-- 帮助
--=========================================================
function Anniversary_ExMarket_Sell_Help()
	-- 借用一下别人的通道
	--if KaJi:LuaFnIsKaJiServer() == 1 then
	--	PushEvent("CCSHOP_HELP", 182)
	--else
	--	PushEvent("CCSHOP_HELP", 183)
	--end
end
--=========================================================
-- 关闭界面
--=========================================================
function Anniversary_ExMarket_Sell_Cancel_Clicked()
	
	-- 重置
	this:Hide()
	Anniversary_ExMarket_Sell_Reset()
	
end
--=========================================================
-- 关闭界面
--=========================================================
function Anniversary_ExMarket_Sell_Close()
	
	-- 重置
	this:Hide()
	Anniversary_ExMarket_Sell_Reset()
	
end

function Anniversary_ExMarket_Sell_OnShown()
	this:Show()
end

--========================================================
-- 界面位置
--=========================================================
function Anniversary_ExMarket_Sell_Frame_On_ResetPos()
	Anniversary_ExMarket_Sell_Frame:SetProperty("UnifiedPosition", g_Anniversary_ExMarket_Sell_Frame_UnifiedPosition)
end
