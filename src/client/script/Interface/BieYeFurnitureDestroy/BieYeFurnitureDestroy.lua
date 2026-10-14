local g_Frame_UnifiedXPosition;
local g_Frame_UnifiedYPosition;
local g_nItemSum = 255;
local g_Index;
local g_status = 0;

function BieYeFurnitureDestroy_PreLoad()

	this:RegisterEvent("SCENE_TRANSED")
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	--游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)

	this:RegisterEvent("FURNITURE_REMOVE")
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("BIEYE_OPEN_FURNITURE_BANK")
	this:RegisterEvent("BIEYEFURNITUREREMOVECOMFIRM")
end

function BieYeFurnitureDestroy_OnLoad()
	-- 保存界面的默认相对位置
	g_Frame_UnifiedXPosition	= BieYeFurnitureDestroy_Frame:GetProperty("UnifiedXPosition");
	g_Frame_UnifiedYPosition	= BieYeFurnitureDestroy_Frame:GetProperty("UnifiedYPosition");
	--g_Index = 0
	g_status = 0
end

function BieYeFurnitureDestroy_Close()
	g_status = 0
	this:Hide()	
end

function BieYeFurnitureDestroy_OnEvent(event)

	if( event == "ADJEST_UI_POS" ) then
		BieYeFurnitureDestroy_ResetPos()
	elseif( event == "VIEW_RESOLUTION_CHANGED") then
		BieYeFurnitureDestroy_ResetPos()
	elseif( event == "SCENE_TRANSED" ) then
			g_status = 0
			this:Hide()

	elseif (event == "UI_COMMAND") and tonumber(arg0) == 20160620 then
		local nType = Get_XParam_INT(0)
		
		if nType == 30 then --打开界面
			g_status = 0
			this:Hide()
		end
	elseif(event == "BIEYE_OPEN_FURNITURE_BANK") then
			g_status = 0
			this:Hide()
	elseif(event == "BIEYEFURNITUREREMOVECOMFIRM") then
			g_status = tonumber(arg0)
			
	elseif( event == "FURNITURE_REMOVE" ) then

		g_Index = tonumber(arg0)
		BieYeFurnitureDestroy_Number:SetText("1")
		g_nItemSum = BieYeFurniture:GetFurCntInCangku(g_Index);
		
		local itemcount = BieYeFurniture:GetFurCntInCangku(g_Index)
		local sz_BieYeName = BieYeFurniture:GetBieYeFurnitureInfo(g_Index,2)
		local bInner= BieYeFurniture:GetBieYeFurnitureInfo(g_Index,3)
		local nJiaoZi = BieYeFurniture:GetBieYeFurnitureInfo(g_Index,8)
		local strPutCount = ""
		if bInner == 1 then
			strPutCount = ScriptGlobal_Format("#{BYFUR_160531_275}", itemcount,sz_BieYeName,sz_BieYeName,sz_BieYeName,nJiaoZi)
		else
			strPutCount = ScriptGlobal_Format("#{BYFUR_160531_272}", itemcount,sz_BieYeName,sz_BieYeName,sz_BieYeName,nJiaoZi)
		end

		BieYeFurnitureDestroy_Name:SetText(strPutCount)
		this:Show()


	end
end


--================================================
-- 恢复界面的默认相对位置
--================================================
function BieYeFurnitureDestroy_ResetPos()
	BieYeFurnitureDestroy_Frame:SetProperty("UnifiedXPosition", g_Frame_UnifiedXPosition);
	BieYeFurnitureDestroy_Frame:SetProperty("UnifiedYPosition", g_Frame_UnifiedYPosition);
end

function BieYeFurnitureDestroy_OpenFame()
	--打开大的UI

end

--设置按钮
function BieYeFurnitureDestroy_OK_Click(isComfirm)

	local strWorld = BieYeFurnitureDestroy_Number:GetText();
	
	
	local iLen = string.len(strWorld);
	local nCountLimit = BieYeFurniture:GetBieYeFurnitureLimitByBieYeLevel()	
	if(tonumber(strWorld) > nCountLimit) then
		PushDebugMessage("#{BYFUR_160531_128}")
		BieYeFurnitureDestroy_Number:SetText(1)
		return;
	end;
	if(iLen <= 0 ) then
		PushDebugMessage("#{BYFUR_160531_127}")
		BieYeFurnitureDestroy_Number:SetText(1)
		return;	
	end
	local nCount = BieYeFurniture:GetFurCntInCangku(g_Index)
	if(nCount < tonumber(strWorld) ) then
		PushDebugMessage("#{BYFUR_160531_128}")
		PushDebugMessage("#{BYFUR_160531_274}")
		BieYeFurnitureDestroy_Number:SetText(1)
		return;	
	end

	if tonumber(strWorld) == 0 then
		PushDebugMessage("#{BYFUR_160531_127}")
		BieYeFurnitureDestroy_Number:SetText(1)
		return;			
	end


	local nJiaoZi = BieYeFurniture:GetBieYeFurnitureInfo(g_Index,8)

	local nName = BieYeFurniture:GetBieYeFurnitureInfo(g_Index,2)
	local nTotal  = tonumber(strWorld) * nJiaoZi
	
	if PlayerPackage:IsProtectGoodsByItemTableIndex(g_Index) == 1 and g_status == 0 then
		PushEvent( "BIEYEFURNITUREREMOVECOMFIRM",0)
		return
	end
	
	BieYeFurniture:RemoveFuniture(tonumber(g_Index),tonumber(strWorld))
	g_status = 0
	this:Hide();

end
--===============================================
-- 个数加1
--===============================================
function BieYeFurnitureDestroy_Add_Clicked()
	
	local szNum = BieYeFurnitureDestroy_Number:GetText();
	if szNum == "" then 
		szNum = "0"
	end

	local nNum = szNum + 1;
	
	if( nNum >= g_nItemSum )then
		nNum = g_nItemSum
	end
	
	BieYeFurnitureDestroy_Number:SetText(tostring(nNum));
	
end


--===============================================
-- 个数减1
--===============================================
function BieYeFurnitureDestroy_Mini_Clicked()
	
	local szNum = BieYeFurnitureDestroy_Number:GetText();
	if szNum == "" then 
		szNum = "0"
	end
	
	local nNum = szNum - 1;

	if( nNum < 1 )then
		nNum = 1
	end
	
	BieYeFurnitureDestroy_Number:SetText(tostring(nNum));

end
--===============================================
-- 变化
--===============================================
function BieYeFurnitureDestroy_Check()

	local num = tonumber(BieYeFurnitureDestroy_Number:GetText())
	if(num == nil or num < 1) then
		BieYeFurnitureDestroy_Number:SetText(tostring(1))
		return
	end
	if(num > g_nItemSum) then
		BieYeFurnitureDestroy_Number:SetText(tostring(g_nItemSum))
	end	
	
end