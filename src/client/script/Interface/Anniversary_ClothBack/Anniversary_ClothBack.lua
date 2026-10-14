-- Anniversary_ClothBack 周年庆h5前端
-- !!!reloadscript =Anniversary_2023ZNQ_h5



local g_Anniversary_ClothBack_Frame_UnifiedPosition
local g_nScriptId	= 998460
local g_nUICommandID		= 99846001
local g_ItemID = {38005333,10102885}  		--投票出来的时装id  todo 没用上
local g_Price={25000,12500}   				--投票出来的时装价格 元宝 todo
local g_PerDisCount={10,10} 			--每张折扣券减免比例 %
local g_MaxDisCountNum = {2,2} 			--最大折扣券张数	
local g_DisCountItemId = {38006273,38006274} 		--折扣券id

local g_nZhekouquan_1_Num = 0
local g_nZhekouquan_2_Num = 0
local g_nBuyRecord_1 = 0
local g_nBuyRecord_2 = 0
local g_nClickItemFlag = 0	--点击物品的客户端缓存记录，comfirm后服务器已进行完全的检查
local g_tabZheKouQuanPos = {-1,-1,-1,-1}
--=========================================================
-- PreLoad
--=========================================================
function Anniversary_ClothBack_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", false)
end


--=========================================================
-- OnLoad
--=========================================================
function Anniversary_ClothBack_OnLoad()
	g_Anniversary_ClothBack_Frame_UnifiedPosition =  Anniversary_ClothBack_Frame:GetProperty("UnifiedPosition")


end

--=========================================================
-- OnEvent
--=========================================================
function Anniversary_ClothBack_OnEvent(event)
	if ( event == "UI_COMMAND" and tonumber(arg0) == g_nUICommandID ) then
		-- 0 关闭, 1 打开, 2 刷新
		local nOpType 	= Get_XParam_INT(0)

		-- 关闭界面
		if 0 == nOpType then	
			if this:IsVisible() then
				 Anniversary_ClothBack_OnClose()
			end
		end

		-- 打开界面
		if 1 == nOpType then
			--PushDebugMessage("打开界面")
			
			Anniversary_ClothBack_Reset()
			Anniversary_ClothBack_ParamInit()
			Anniversary_ClothBack_Update()
			this:Show()
		end
		--2 刷新
		if 2 == nOpType then
			Anniversary_ClothBack_ParamInit()
			Anniversary_ClothBack_Update()
		end
		--comfirm
		if 3 == nOpType then
			local strMsg = Get_XParam_STR(0)		
		
			--PushDebugMessage("strMsg="..strMsg)
			MessageBoxSelf3("Anniversary_ClothBack_OnComfirmedBack", {["Content"] = strMsg,["Type"] = "YesNo", })

		end
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		--切换场景关闭界面
		Anniversary_ClothBack_OnClose()	
	end
end

--=========================================================
-- ComfirmedBack
--=========================================================
function Anniversary_ClothBack_OnComfirmedBack(strRet)

	if nil == strRet then
		return
	end

	if "Yes" == strRet or "Ok" == strRet then
		--确认购买
		if g_nClickItemFlag ~= 1 and g_nClickItemFlag ~= 2 then
			return 
		end
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OnBuyComfirm" )
			Set_XSCRIPT_ScriptID(g_nScriptId)			
			Set_XSCRIPT_Parameter(0, g_nClickItemFlag) --点击 1时装2幻武
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
	end

	if "No" == strRet then
		-- 关闭二次确认框就行，返回主界面
	end

end

--=========================================================
-- 界面参数初始化
--=========================================================
function Anniversary_ClothBack_ParamInit()

	g_nZhekouquan_1_Num = 	Get_XParam_INT(1)
	g_nZhekouquan_2_Num = 	Get_XParam_INT(2)
	g_nBuyRecord_1 = 		Get_XParam_INT(3)
	g_nBuyRecord_2 = 		Get_XParam_INT(4)
	g_tabZheKouQuanPos[1] = Get_XParam_INT(5)
	g_tabZheKouQuanPos[2] = Get_XParam_INT(6)
	g_tabZheKouQuanPos[3] = Get_XParam_INT(7)
	g_tabZheKouQuanPos[4] = Get_XParam_INT(8)
end

--=========================================================
-- 重置界面参数（归零）
--=========================================================
function Anniversary_ClothBack_Reset()
	g_nZhekouquan_1_Num = 	0
	g_nZhekouquan_2_Num = 	0
	g_nBuyRecord_1 = 		0
	g_nBuyRecord_2 = 		0
	g_nClickItemFlag	=	0
	g_tabZheKouQuanPos[1] = -1
	g_tabZheKouQuanPos[2] = -1
	g_tabZheKouQuanPos[3] = -1
	g_tabZheKouQuanPos[4] = -1
end
--=========================================================
-- 界面更新
--=========================================================
function Anniversary_ClothBack_Update()
	-- 锁住道具
	if g_tabZheKouQuanPos[1] >= 0 then
			LifeAbility : Lock_Packet_Item( g_tabZheKouQuanPos[1], 1 )
	end
	if g_tabZheKouQuanPos[2] >= 0 then
			LifeAbility : Lock_Packet_Item( g_tabZheKouQuanPos[2], 1 )
	end
	if g_tabZheKouQuanPos[3] >= 0 then
			LifeAbility : Lock_Packet_Item( g_tabZheKouQuanPos[3], 1 )
	end
	if g_tabZheKouQuanPos[4] >= 0 then
			LifeAbility : Lock_Packet_Item( g_tabZheKouQuanPos[4], 1 )
	end

	
	if g_nZhekouquan_1_Num > g_MaxDisCountNum[1] then
		g_nZhekouquan_1_Num = g_MaxDisCountNum[1] 
	end
	--Anniversary_ClothBack_Pic_text2:SetText(ScriptGlobal_Format("#{ZNQSZ_230301_11}",g_nZhekouquan_1_Num)) -- 华裳折扣令：%s0  图里有了
	Anniversary_ClothBack_Pic_text2:Show() -- 华裳折扣令
	
	Anniversary_ClothBack_Pic_text2:SetProperty("Image", "set:Anniversary_ClothBack1 image:Anniversary_ClothBack_NoDiscount")
	--道具1
	if g_nBuyRecord_1 == 0 then  
		--未购买
		if g_nZhekouquan_1_Num <= 0 then
			--无折扣券 只展示原价
			Anniversary_ClothBack_Pic_Jiage2:Show()--无折扣券
			Anniversary_ClothBack_Pic_Jiage1:Hide()
			Anniversary_ClothBack_Pic_Jiage2_Text4:SetText(ScriptGlobal_Format("#{ZNQSZ_230301_28}",g_Price[1])) 
			Anniversary_ClothBack_Pic_Jiage2_Text4:Show()
			Anniversary_ClothBack_Pic_Jiage2_YuanJiaBK:Show()
		else
			--有折扣券 原价划线  +折扣价
			local zhekoujia = g_Price[1]*(100 - g_nZhekouquan_1_Num * g_PerDisCount[1])/100
			Anniversary_ClothBack_Pic_Jiage1:Show() --有折扣券
			Anniversary_ClothBack_Pic_Jiage2:Hide()
			Anniversary_ClothBack_Pic_Jiage1_Text4:SetText(ScriptGlobal_Format("#{ZNQSZ_230301_23}",g_Price[1])) 
			Anniversary_ClothBack_Pic_Jiage1_Text4:Show()
			Anniversary_ClothBack_Pic_Jiage1_Text3:SetText(ScriptGlobal_Format("#{ZNQSZ_230301_28}",zhekoujia))  
			Anniversary_ClothBack_Pic_Jiage1_Text3:Show()
			Anniversary_ClothBack_Pic_Jiage1_Text4_OriginalLine:Show()
			
			Anniversary_ClothBack_Pic_Jiage1_YuanJiaBK:Show()
			
			if g_nZhekouquan_1_Num == 1 then
				Anniversary_ClothBack_Pic_text2:SetProperty("Image", "set:Anniversary_ClothBack1 image:Anniversary_ClothBack_9zhe")
			end
			if g_nZhekouquan_1_Num >= 2 then
				Anniversary_ClothBack_Pic_text2:SetProperty("Image", "set:Anniversary_ClothBack1 image:Anniversary_ClothBack_8zhe")
			end
		end
		Anniversary_ClothBack_Pic_text1bk:Hide() -- 已购买角标
		Anniversary_ClothBack_Pic_Btn:Show()-- 购买按钮
	else 
		Anniversary_ClothBack_Pic_text1bk:Show() --“已购买”图标
		Anniversary_ClothBack_Pic_Btn:Hide()	 -- 购买按钮
		--Anniversary_ClothBack_Pic_Jiage1:Hide()
		--Anniversary_ClothBack_Pic_Jiage2:Hide()
		--Anniversary_ClothBack_Pic_text2:Hide()
		
		--只展示原价
			Anniversary_ClothBack_Pic_Jiage2:Show()--无折扣券
			Anniversary_ClothBack_Pic_Jiage1:Hide()
			Anniversary_ClothBack_Pic_Jiage2_Text4:SetText(ScriptGlobal_Format("#{ZNQSZ_230301_28}",g_Price[1])) 
			Anniversary_ClothBack_Pic_Jiage2_Text4:Show()
			Anniversary_ClothBack_Pic_Jiage2_YuanJiaBK:Show()
			Anniversary_ClothBack_Pic_text2:Hide()
			
	end
	
	
	if g_nZhekouquan_2_Num > g_MaxDisCountNum[2] then
		g_nZhekouquan_2_Num = g_MaxDisCountNum[2] 
	end
	Anniversary_ClothBack_Pic1_text2:Show()-- 幻武折扣令
	Anniversary_ClothBack_Pic1_text2:SetProperty("Image", "set:Anniversary_ClothBack1 image:Anniversary_ClothBack_NoDiscount")
	--道具2
	if g_nBuyRecord_2 == 0 then  
		--未购买
		if g_nZhekouquan_2_Num <= 0 then
			--无折扣券 只展示原价
			Anniversary_ClothBack_Pic1_Jiage2:Show()--无折扣券
			Anniversary_ClothBack_Pic1_Jiage1:Hide()
			Anniversary_ClothBack_Pic1_Jiage2_Text4:SetText(ScriptGlobal_Format("#{ZNQSZ_230301_28}",g_Price[2]))  
			Anniversary_ClothBack_Pic1_Jiage2_Text4:Show()
			Anniversary_ClothBack_Pic1_Jiage2_YuanJiaBK:Show()
		else
			--有折扣券 原价划线  +折扣价
			local zhekoujia = g_Price[2]*(100 - g_nZhekouquan_2_Num * g_PerDisCount[2])/100
			Anniversary_ClothBack_Pic1_Jiage1:Show() --有折扣券
			Anniversary_ClothBack_Pic1_Jiage2:Hide()
			Anniversary_ClothBack_Pic1_Jiage1_Text4:SetText(ScriptGlobal_Format("#{ZNQSZ_230301_23}",g_Price[2])) 
			Anniversary_ClothBack_Pic1_Jiage1_Text4:Show()
			Anniversary_ClothBack_Pic1_Jiage1_Text3:SetText(ScriptGlobal_Format("#{ZNQSZ_230301_28}",zhekoujia))  
			Anniversary_ClothBack_Pic1_Jiage1_Text3:Show()
			Anniversary_ClothBack_Pic1_Jiage1_Text4_OriginalLine:Show()
			
			Anniversary_ClothBack_Pic1_Jiage1_YuanJiaBK:Show()
			if g_nZhekouquan_2_Num == 1 then
				Anniversary_ClothBack_Pic1_text2:SetProperty("Image", "set:Anniversary_ClothBack1 image:Anniversary_ClothBack_9zhe")
			end
			if g_nZhekouquan_2_Num >= 2 then
				Anniversary_ClothBack_Pic1_text2:SetProperty("Image", "set:Anniversary_ClothBack1 image:Anniversary_ClothBack_8zhe")
			end
		end
		Anniversary_ClothBack_Pic1_text1bk:Hide() -- 已购买角标
		Anniversary_ClothBack_Pic1_Btn:Show()-- 购买按钮
	else 
		Anniversary_ClothBack_Pic1_text1bk:Show() --“已购买”图标
		Anniversary_ClothBack_Pic1_Btn:Hide()	 -- 购买按钮
		--Anniversary_ClothBack_Pic1_Jiage1:Hide()
		--Anniversary_ClothBack_Pic1_Jiage2:Hide()
		--Anniversary_ClothBack_Pic1_text2:Hide()
		
			--只展示原价
			Anniversary_ClothBack_Pic1_Jiage2:Show()--无折扣券
			Anniversary_ClothBack_Pic1_Jiage1:Hide()
			Anniversary_ClothBack_Pic1_Jiage2_Text4:SetText(ScriptGlobal_Format("#{ZNQSZ_230301_28}",g_Price[2])) 
			Anniversary_ClothBack_Pic1_Jiage2_Text4:Show()
			Anniversary_ClothBack_Pic1_Jiage2_YuanJiaBK:Show()
			Anniversary_ClothBack_Pic1_text2:Hide()
			
	end

end
--=========================================================
-- 点击购买时装
--=========================================================
function Anniversary_ClothBack_OnBuy()	
	g_nClickItemFlag	=	1
	Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OnBuy" )
			Set_XSCRIPT_ScriptID(g_nScriptId)			
			Set_XSCRIPT_Parameter(0, 1) --ntype	
			Set_XSCRIPT_ParamCount(1) 
	Send_XSCRIPT()
end

--=========================================================
-- 点击购买幻武
--=========================================================
function Anniversary_ClothBack_OnBuy1()	
	g_nClickItemFlag	=	2
	Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OnBuy" )
			Set_XSCRIPT_ScriptID(g_nScriptId)			
			Set_XSCRIPT_Parameter(0, 2) --ntype	
			Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end



--=========================================================
-- 点击帮助
--=========================================================
function Anniversary_ClothBack_OnHelp()	
	


end

--=========================================================
-- 关闭界面
--=========================================================
function Anniversary_ClothBack_OnClose()	

	if g_tabZheKouQuanPos[1] >= 0 then
			LifeAbility : Lock_Packet_Item( g_tabZheKouQuanPos[1], 0 )
	end
	if g_tabZheKouQuanPos[2] >= 0 then
			LifeAbility : Lock_Packet_Item( g_tabZheKouQuanPos[2], 0 )
	end
	if g_tabZheKouQuanPos[3] >= 0 then
			LifeAbility : Lock_Packet_Item( g_tabZheKouQuanPos[3], 0 )
	end
	if g_tabZheKouQuanPos[4] >= 0 then
			LifeAbility : Lock_Packet_Item( g_tabZheKouQuanPos[4], 0 )
	end

	this:Hide()	
end


--=========================================================
-- 界面隐藏
--=========================================================
function Anniversary_ClothBack_OnHidden()
	-- 重置
	if g_tabZheKouQuanPos[1] >= 0 then
			LifeAbility : Lock_Packet_Item( g_tabZheKouQuanPos[1], 0 )
	end
	if g_tabZheKouQuanPos[2] >= 0 then
			LifeAbility : Lock_Packet_Item( g_tabZheKouQuanPos[2], 0 )
	end
	if g_tabZheKouQuanPos[3] >= 0 then
			LifeAbility : Lock_Packet_Item( g_tabZheKouQuanPos[3], 0 )
	end
	if g_tabZheKouQuanPos[4] >= 0 then
			LifeAbility : Lock_Packet_Item( g_tabZheKouQuanPos[4], 0 )
	end

	this:Hide()

end


