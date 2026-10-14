local g_JiangHuShiJi_XianShi_UnifiedPosition   
local g_JiangHuShiJi_Remain 	= {0,0,0,0,0}
local g_JiangHuShiJi_GiftInfo 	= {
    [1] = {GiftID=38006299, num=1, yuanbao=4000,yuanjia=12000,},
    [2] = {GiftID=38006285, num=4, yuanbao=1200,yuanjia=3200,},
    [3] = {GiftID=38001553, num=25, yuanbao=650,yuanjia=1700,},
    [4] = {GiftID=38001553, num=50, yuanbao=1200,yuanjia=3400,},
    [5] = {GiftID=38000380, num=12, yuanbao=1200,yuanjia=3120,},
}
--=========
-- PreLoad()
--=========
function JiangHuShiJi_XianShi_PreLoad() 
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
	this:RegisterEvent("OPEN_JIANGHUSHIJI_XIANSHI",true)	--进场景关闭界面
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("ADJEST_UI_POS",false)  
	this:RegisterEvent("UI_COMMAND", true)--打开or刷新界面
end

--=========
-- OnLoad()
--=========
function JiangHuShiJi_XianShi_OnLoad() 
	g_JiangHuShiJi_XianShi_UnifiedPosition = JiangHuShiJi_XianShi_Frame:GetProperty("UnifiedPosition") 
end

--=========
-- Event
--=========
function JiangHuShiJi_XianShi_OnEvent(event)
	if ( event == "UI_COMMAND" and tonumber(arg0) == 88892807) then
		for i = 1, table.getn(g_JiangHuShiJi_Remain) do
			g_JiangHuShiJi_Remain[i] = Get_XParam_INT(i-1)    
		end 
		JiangHuShiJi_XianShi_Open()
		this:Show()
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 88892808) then
		this:Hide()
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		JiangHuShiJi_XianShi_On_ResetPos()
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		JiangHuShiJi_XianShi_OnHiden()
	elseif event == "ADJEST_UI_POS" then
        JiangHuShiJi_XianShi_On_ResetPos() 	
	end 

end
 

--=========
-- 重置
--=========
function JiangHuShiJi_XianShi_On_ResetPos()
	JiangHuShiJi_XianShi_Frame:SetProperty("UnifiedPosition", g_JiangHuShiJi_XianShi_UnifiedPosition) 
end

function JiangHuShiJi_XianShi_OnHiden()
    this:Hide()
end

--=========
-- 打开
--=========
function JiangHuShiJi_XianShi_Open() 
	JiangHuShiJi_XianShi_SuperList:Clear()	
	for i = 1, table.getn(g_JiangHuShiJi_Remain) do
		if g_JiangHuShiJi_Remain[i] == 0 then
			continue
		end
		local bar = JiangHuShiJi_XianShi_SuperList:AddChild("JiangHuShiJi_XianShi_SuperList_ItemFrame")
		if not bar then
			PushDebugMessage("break")
		   	break
		end	  
		bar:GetSubItem("JiangHuShiJi_XianShi_Gift3_Btn"):SetEvent("MouseLClick", string.format("JiangHuShiJi_XianShi_GetGift(%d)", i))
		bar:GetSubItem("JiangHuShiJi_XianShi_Gift3_Time"):SetEvent("ReachedZero", string.format("JiangHuShiJi_XianShi_TimeOut(%d)", i))
		bar:GetSubItem("JiangHuShiJi_XianShi_Gift3_Time"):SetProperty("Timer", g_JiangHuShiJi_Remain[i]);
		if g_JiangHuShiJi_Remain[i] > 60*60 then
			local nhour = math.floor(g_JiangHuShiJi_Remain[i] / (60*60))
			local strhou = ScriptGlobal_Format("#{TSFCL_230301_09}", nhour) 
			bar:GetSubItem("JiangHuShiJi_XianShi_Gift3_Text"):SetText(ScriptGlobal_Format("#{TSFCL_230301_09}", nhour)) 
			bar:GetSubItem("JiangHuShiJi_XianShi_Gift3_Text"):Show()
			bar:GetSubItem("JiangHuShiJi_XianShi_Gift3_Time"):Hide()
		elseif g_JiangHuShiJi_Remain[i] > 15*60 then 
			bar:GetSubItem("JiangHuShiJi_XianShi_Gift3_Text"):Hide()
			bar:GetSubItem("JiangHuShiJi_XianShi_Gift3_Time"):SetProperty("TextColor", "FF800000");
			bar:GetSubItem("JiangHuShiJi_XianShi_Gift3_Time"):Show()
		else 
			bar:GetSubItem("JiangHuShiJi_XianShi_Gift3_Text"):Hide()
			bar:GetSubItem("JiangHuShiJi_XianShi_Gift3_Time"):SetProperty("TextColor", "FFFF0000");
			bar:GetSubItem("JiangHuShiJi_XianShi_Gift3_Time"):Show() 
		end
		local GiftID = g_JiangHuShiJi_GiftInfo[i].GiftID
		local num    = g_JiangHuShiJi_GiftInfo[i].num
		local Discount = ScriptGlobal_Format("#{TSFCL_230202_8}",g_JiangHuShiJi_GiftInfo[i].yuanjia, g_JiangHuShiJi_GiftInfo[i].yuanbao)
		if GiftID == 38006299 and Player:GetData("Is2606S") == 1 then
			GiftID = 38008734
			Discount = ScriptGlobal_Format("#{TSFCL_230202_8}", 9000, 3000)
		end
		local theAction = DataPool:CreateActionItemForShow(GiftID, num)
		if theAction:GetID() ~= 0 then
			bar:GetSubItem("JiangHuShiJi_XianShi_XianShi__GiftItem"):SetActionItem(theAction:GetID());
			bar:GetSubItem("JiangHuShiJi_XianShi_XianShi__GiftItem"):Show();
		end
		bar:GetSubItem("JiangHuShiJi_XianShi_Lace1Item"):SetText("#L"..theAction:GetName());   
		bar:GetSubItem("JiangHuShiJi_XianShi_Lace1Item_Tips"):SetText(Discount);
	end
end 
   
function JiangHuShiJi_XianShi_GetGift(idx)
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("GetMaiDianGift")
		Set_XSCRIPT_ScriptID( 888928 )
		Set_XSCRIPT_Parameter( 0, idx ); 
		Set_XSCRIPT_Parameter( 1, 0 ); 
		Set_XSCRIPT_ParamCount( 2 ); 
	Send_XSCRIPT() 
end
function JiangHuShiJi_XianShi_TimeOut(idx)
	Clear_XSCRIPT()
    Set_XSCRIPT_Function_Name( "OpenXianShi" ); 					-- 脚本函数名称
    Set_XSCRIPT_ScriptID( 888928 );											-- 脚本编号 
    Set_XSCRIPT_ParamCount( 0 ); 	-- 参数个数 
    Send_XSCRIPT() 
end