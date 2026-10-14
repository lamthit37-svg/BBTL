local g_Frame_UnifiedXPosition;
local g_Frame_UnifiedYPosition;
local g_Frame_RawSize;
local g_Frame_RawPos;
local g_OpenState = 1;


function BieYe_Mini_PreLoad()

	this:RegisterEvent("SCENE_DATA_READY")
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)

	this:RegisterEvent("UI_COMMAND")

	this:RegisterEvent("BIEYE_OPEN_MINI")

	this:RegisterEvent("BIEYE_OPEN_FURNITURE_BANK")
	this:RegisterEvent("FURNITURE_MINI_SCENE_INIT")
	this:RegisterEvent("SCENE_TRANSED")
end

function BieYe_Mini_OnLoad()
	-- 保存界面的默认相对位置
	g_Frame_UnifiedXPosition	= BieYe_Mini_Frame:GetProperty("UnifiedXPosition");
	g_Frame_UnifiedYPosition	= BieYe_Mini_Frame:GetProperty("UnifiedYPosition");
	g_Frame_RawSize 			= BieYe_Mini_Frame:GetProperty("UnifiedSize");
	g_Frame_RawPos				= BieYe_Mini_Frame:GetProperty("UnifiedPosition");

	BieYe_Mini_Open:SetProperty("UnifiedPosition","{{1.000000,-51.000000},{0.000000,0.000000}}");
	BieYe_Mini_Close:SetProperty("UnifiedPosition","{{1.000000,-51.000000},{0.000000,0.000000}}");
end



function BieYe_Mini_OnEvent(event)

	if( event == "ADJEST_UI_POS" ) then
		BieYe_Mini_ResetPos()
	elseif( event == "VIEW_RESOLUTION_CHANGED") then
		BieYe_Mini_ResetPos()
	elseif( event == "SCENE_DATA_READY" ) or  (event == "FURNITURE_MINI_SCENE_INIT" )then
	--第一次进别墅场景FURNITURE_MINI_SCENE_INIT会在别墅guid初始化之后触发，但是SCENE_DATA_READY触发的时候，guid还没有初始化
	--之后再切出场景的时候FURNITURE_MINI_SCENE_INIT 不会触发，但是SCENE_DATA_READY会触发。所以这两个事件都需要用，做好互斥即可
		if ( BieYeFurniture:IsBieYeScene() ) then

			--------------是否有操作权限
			local BieYeGuid = BieYeUI:GetBieYeBaseInfo("Guid")
			local myGuid = Player:GetGUID();
				--婚姻组

			local isHaveSpouse , spouseGuid = Friend:Lua_GetSpouseGuid()

			local bIsMyBieye = 0
			if BieYeGuid == myGuid then
				bIsMyBieye = 1
			elseif BieYeGuid == spouseGuid then
				bIsMyBieye = 2
			else
				this:Hide()
				return
			end
			--------------是否有操作权限

			if (true == this:IsVisible()) or (IsWindowShow("BieYeFurnitureBank")) then
				--其中一个能看见
				BieYe_Mini_Opentips()
				return
			end

			BieYe_Mini_UpdateOpenState()
			this:Show()
			BieYe_Mini_Opentips()
			--BieYe_Mini_Bk:SetToolTip("#{BYFUR_160531_63}")

		else

			if (false == this:IsVisible()) and (IsWindowShow("BieYeFurnitureBank") == false) then
				--两个都看不见了
				return
			end
			this:Hide()
		end

	elseif( event == "BIEYE_OPEN_MINI" ) then

		if(IsWindowShow("BieYeFurnitureBank")) then
		   CloseWindow("BieYeFurnitureBank", true);
		else
			BieYe_Mini_Opentips()
		end
		BieYe_Mini_UpdateOpenState()
		--------------是否有操作权限
		local BieYeGuid = BieYeUI:GetBieYeBaseInfo("Guid")
		local myGuid = Player:GetGUID();
			--婚姻组

		local isHaveSpouse , spouseGuid = Friend:Lua_GetSpouseGuid()

		local bIsMyBieye = 0
		if BieYeGuid == myGuid then
			bIsMyBieye = 1
		elseif BieYeGuid == spouseGuid then
			bIsMyBieye = 2
		else
			this:Hide()
			return
		end
		--------------是否有操作权限
		this:Show()

		--BieYe_Mini_Bk:SetToolTip("#{BYFUR_160531_63}");
	elseif( event == "SCENE_TRANSED" ) then
		g_OpenState = 1
		--萌宠养成接受任务
	elseif event == "UI_COMMAND" and tonumber(arg0) == 892510001 then
		local BieYeGuid = BieYeUI:GetBieYeBaseInfo("Guid")
		local myGuid = Player:GetGUID()
		if myGuid == BieYeGuid then
			CloseFreshManGuide()
			local nType = Get_XParam_INT(0)
			local fX, fY = this:GetChildOffset("BieYe_Mini_D")
			OpenFreshManGuide(1, 180, fX+10, fY+10, "BieYe_Mini", "northwest")
		end

	elseif event == "UI_COMMAND" and tonumber(arg0) == 892513001 then
		local BieYeGuid = BieYeUI:GetBieYeBaseInfo("Guid")
		local myGuid = Player:GetGUID()
		if myGuid == BieYeGuid then
			CloseFreshManGuide()
			local nType = Get_XParam_INT(0)
			local fX, fY = this:GetChildOffset("BieYe_Mini_D")
			OpenFreshManGuide(1, 220, fX+10, fY+10, "BieYe_Mini", "northwest")
		end


	elseif event == "UI_COMMAND" and tonumber(arg0) == 892511001 then
		local BieYeGuid = BieYeUI:GetBieYeBaseInfo("Guid")
		local myGuid = Player:GetGUID()
		if myGuid == BieYeGuid then
			CloseFreshManGuide()
			local nType = Get_XParam_INT(0)
			local fX, fY = this:GetChildOffset("BieYe_Mini_D")
			OpenFreshManGuide(1, 183, fX+10, fY+10, "BieYe_Mini", "northwest")
		end

	elseif event == "UI_COMMAND" and tonumber(arg0) == 892512001 then
		local BieYeGuid = BieYeUI:GetBieYeBaseInfo("Guid")
		local myGuid = Player:GetGUID()
		if myGuid == BieYeGuid then
			CloseFreshManGuide()
			local nType = Get_XParam_INT(0)
			local fX, fY = this:GetChildOffset("BieYe_Mini_D")
			OpenFreshManGuide(1, 185, fX+10, fY+10, "BieYe_Mini", "northwest")
		end

	elseif event == "UI_COMMAND" and tonumber(arg0) == 201611032 then
		CloseFreshManGuide()
		local nType = Get_XParam_INT(0)
		if nType == 1 then
			local fX, fY = this:GetChildOffset("BieYe_Mini_A")
	    	OpenFreshManGuide(1, 119, fX+10, fY+10, "BieYe_Mini", "northwest")
		elseif nType == 2 then
			local fX, fY = this:GetChildOffset("BieYe_Mini_B")
	    	OpenFreshManGuide(1, 126, fX+10, fY+10, "BieYe_Mini", "northwest")
		end


	elseif event == "UI_COMMAND" and tonumber(arg0) == 20170110 then

		local nPage = Get_XParam_INT(0)
		local nInner = Get_XParam_INT(1)

		if BieYeFurniture:GetCurInner() ~= nInner then
			BieYeFurniture:SetCurInner(nInner);
		end

		BieYeFurniture:SetPageIndex(nPage);
		BieYeFurniture:SetCurRentIndex(13);
		PushEvent("BIEYE_OPEN_FURNITURE_BANK",  0 )
	elseif event == "UI_COMMAND" and tonumber(arg0) == 20170111 then

		local nPage = Get_XParam_INT(0)
		local nInner = Get_XParam_INT(1)

		if BieYeFurniture:GetCurInner() ~= nInner then
			BieYeFurniture:SetCurInner(nInner);
		end

		--BieYeFurniture:SetPageIndex(nPage);
		BieYeFurniture:SetCurRentIndex(nPage);
		PushEvent("BIEYE_OPEN_FURNITURE_BANK",  0 )
	end

end


--================================================
-- 恢复界面的默认相对位置
--================================================
function BieYe_Mini_ResetPos()
	BieYe_Mini_Frame:SetProperty("UnifiedXPosition", g_Frame_UnifiedXPosition);
	BieYe_Mini_Frame:SetProperty("UnifiedYPosition", g_Frame_UnifiedYPosition);
end

function BieYe_Mini_OpenFame()
	--打开大的UI
	if (IsWindowShow("BieYeFurnitureBank") == false ) then
		PushEvent("BIEYE_OPEN_FURNITURE_BANK",  0 )
	end
	--this:Hide()
end




function BieYe_Mini_Sub(n)
	if n == 1 then

		if BieYeFurniture:GetCurInner() == 1 then
			BieYeFurniture:SetPageIndex(1);
			BieYeFurniture:SetCurRentIndex(1);
		end

		BieYeFurniture:SetCurInner(0)
		PushEvent("BIEYE_OPEN_FURNITURE_BANK",  0 )
	elseif n == 2 then

		if BieYeFurniture:GetCurInner() == 0 then
			BieYeFurniture:SetPageIndex(1);
			BieYeFurniture:SetCurRentIndex(1);
		end

		BieYeFurniture:SetCurInner(1)
		PushEvent("BIEYE_OPEN_FURNITURE_BANK",  0 )
	elseif n == 3 then
		Clear_XSCRIPT();
			Set_XSCRIPT_Function_Name("ClientBieYeBaseUI")
			Set_XSCRIPT_ScriptID(891872)
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT();
	elseif n == 4 then
		CloseFreshManGuide()
			--------------是否有操作权限
			local BieYeGuid = BieYeUI:GetBieYeBaseInfo("Guid")
			local myGuid = Player:GetGUID();
				--婚姻组

			local isHaveSpouse , spouseGuid = Friend:Lua_GetSpouseGuid()

			local bIsMyBieye = 0
			if BieYeGuid == myGuid then
				bIsMyBieye = 1
			elseif BieYeGuid == spouseGuid then
				bIsMyBieye = 2
			else
				PushDebugMessage("#{MCJC_170727_02}")
				return
			end
			--------------是否有操作权限


			local bIsOutter = BieYeMengChong:Lua_isOutter()
			if bIsOutter == 0 then
				PushDebugMessage("#{MCJC_170727_119}")
				return
			end

		PushEvent("BIEYE_OPEN_MENGCHONG_BANK")
	elseif n == 5 then

			--------------是否有操作权限
			local BieYeGuid = BieYeUI:GetBieYeBaseInfo("Guid")
			local myGuid = Player:GetGUID();
				--婚姻组

			local isHaveSpouse , spouseGuid = Friend:Lua_GetSpouseGuid()

			local bIsMyBieye = 0
			if BieYeGuid == myGuid then
				bIsMyBieye = 1
			elseif BieYeGuid == spouseGuid then
				bIsMyBieye = 2
			else
				PushDebugMessage("#{MCJC_170727_02}")
				return
			end
			--------------是否有操作权限


			local bIsOutter = BieYeMengChong:Lua_isOutter()
			if bIsOutter == 0 then
				PushDebugMessage("#{MCJC_170727_119}")
				return
			end


	local bHaveChong = 0
	for i=1, 6 do
		if BieYeMengChong:Lua_HaveXiaoWoChong(i) > 0 then
			bHaveChong = 1
		end
	end
	if bHaveChong == 0 then
		PushDebugMessage("#{MCJC_170727_45}")
		return
	end


	Clear_XSCRIPT();
			Set_XSCRIPT_Function_Name("CallMengChong");
			Set_XSCRIPT_ScriptID(891900);
			--Set_XSCRIPT_Parameter(0,g_NPC_ID);
			--Set_XSCRIPT_Parameter(1,g_ValidEquipPos[actionidx]);
			--Set_XSCRIPT_Parameter(2,g_Enchange_Item2);
			Set_XSCRIPT_ParamCount(0);
	Send_XSCRIPT();

	end
end

function BieYe_Mini_UpdateOpenState()
	if g_OpenState == 0 then
		BieYe_Mini_Open:Show()
		BieYe_Mini_Close:Hide()
		BieYe_Mini_Frame:SetProperty("UnifiedSize","{{0.000000,53.000000},{0.000000,61.000000}}")
		BieYe_Mini_Frame:SetProperty("UnifiedPosition","{{1.000000,-127.000000},{1.000000,-250.000000}}")
	else
		BieYe_Mini_Close:Show()
		BieYe_Mini_Open:Hide()
		BieYe_Mini_Frame:SetProperty("UnifiedSize",g_Frame_RawSize)
		BieYe_Mini_Frame:SetProperty("UnifiedPosition",g_Frame_RawPos)
	end

	for i,v in ipairs({"A","B","C"}) do
		if g_OpenState == 0 then
			_G["BieYe_Mini_"..v]:Hide()
		else
			_G["BieYe_Mini_"..v]:Show()
		end
	end
end

function BieYe_Mini_DoFolder(bOpen)
	g_OpenState = bOpen
	BieYe_Mini_UpdateOpenState()
end

function BieYe_Mini_Opentips()
	local posX, posY = Player:GetPos();
	local bIsInner = BieYeUI:GetBieYeAreaType(posX,posY)
	if DataPool:Lua_IsHaveMission(1856) > 0 and bIsInner == 0 then
		local misIndex = DataPool:GetPlayerMissionIndexByID(1856)
		if DataPool:GetPlayerMission_Variable(misIndex, 1) == 0 then
			CloseFreshManGuide()
			local fX, fY = this:GetChildOffset("BieYe_Mini_A")
			OpenFreshManGuide(1, 119, fX+10, fY+10, "BieYe_Mini", "northwest")
		end
	elseif DataPool:Lua_IsHaveMission(1862) > 0 and bIsInner == 1 then
		local misIndex = DataPool:GetPlayerMissionIndexByID(1862)
		if DataPool:GetPlayerMission_Variable(misIndex, 1) == 0 then
			CloseFreshManGuide()
			local fX, fY = this:GetChildOffset("BieYe_Mini_B")
			OpenFreshManGuide(1, 126, fX+10, fY+10, "BieYe_Mini", "northwest")
		end
	end

	local BieYeGuid = BieYeUI:GetBieYeBaseInfo("Guid")
	local myGuid = Player:GetGUID();
	-- 在自己家园才显示
	if BieYeGuid == myGuid then
		if DataPool:Lua_IsHaveMission(1871) > 0  then
			local misIndex = DataPool:GetPlayerMissionIndexByID(1871)
			if DataPool:GetPlayerMission_Variable(misIndex, 1) < 1  then
				CloseFreshManGuide()
				local fX, fY = this:GetChildOffset("BieYe_Mini_D")
				OpenFreshManGuide(1, 180, fX+10, fY+10, "BieYe_Mini", "northwest")
			end

	--	elseif DataPool:Lua_IsHaveMission(1889) > 0  then
	--		local misIndex = DataPool:GetPlayerMissionIndexByID(1889)
	--		if DataPool:GetPlayerMission_Variable(misIndex, 1) < 1  then
	--			CloseFreshManGuide()
	--			local fX, fY = this:GetChildOffset("BieYe_Mini_D")
	--			OpenFreshManGuide(1, 220, fX+10, fY+10, "BieYe_Mini", "northwest")
	--		end
		end
	end
end
