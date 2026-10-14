--查看猫舍

local g_CatBank_Frame_UnifiedPosition;

local g_CatBank_ImageList = {}
local g_CatBank_TipsList = {}
local g_CatBank_NumList = {}

--=========================================================
-- 注册窗口关心的所有事件
--=========================================================
function CatBank_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	
	this:RegisterEvent("ADJEST_UI_POS", false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED", false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
end

--=========================================================
-- 载入初始化
--=========================================================
function CatBank_OnLoad()
	
	g_CatBank_Frame_UnifiedPosition = CatBank_Frame:GetProperty("UnifiedPosition");
	
	g_CatBank_ImageList[1] = CatBank_Cat1Image
	g_CatBank_ImageList[2] = CatBank_Cat2Image
	g_CatBank_ImageList[3] = CatBank_Cat3Image
	g_CatBank_ImageList[4] = CatBank_Cat4Image
	g_CatBank_ImageList[5] = CatBank_Cat5Image
	g_CatBank_ImageList[6] = CatBank_Cat6Image
	g_CatBank_ImageList[7] = CatBank_Cat7Image
	g_CatBank_ImageList[8] = CatBank_Cat8Image
	g_CatBank_ImageList[9] = CatBank_Cat9Image
	g_CatBank_ImageList[10] = CatBank_Cat10Image
	
	g_CatBank_TipsList[1] = CatBank_Cat1Tips
	g_CatBank_TipsList[2] = CatBank_Cat2Tips
	g_CatBank_TipsList[3] = CatBank_Cat3Tips
	g_CatBank_TipsList[4] = CatBank_Cat4Tips
	g_CatBank_TipsList[5] = CatBank_Cat5Tips
	g_CatBank_TipsList[6] = CatBank_Cat6Tips
	g_CatBank_TipsList[7] = CatBank_Cat7Tips
	g_CatBank_TipsList[8] = CatBank_Cat8Tips
	g_CatBank_TipsList[9] = CatBank_Cat9Tips
	g_CatBank_TipsList[10] = CatBank_Cat10Tips
		    
	g_CatBank_NumList[1] = CatBank_Cat1Number	
	g_CatBank_NumList[2] = CatBank_Cat2Number	
	g_CatBank_NumList[3] = CatBank_Cat3Number	
	g_CatBank_NumList[4] = CatBank_Cat4Number	
	g_CatBank_NumList[5] = CatBank_Cat5Number	
	g_CatBank_NumList[6] = CatBank_Cat6Number	
	g_CatBank_NumList[7] = CatBank_Cat7Number	
	g_CatBank_NumList[8] = CatBank_Cat8Number	
	g_CatBank_NumList[9] = CatBank_Cat9Number	
	g_CatBank_NumList[10] = CatBank_Cat10Number	
end

--=========================================================
-- 事件处理
--=========================================================
function CatBank_OnEvent(event)

	if (event == "UI_COMMAND" and tonumber(arg0) == 88843601) then --打开界面
	
		if Get_XParam_INT(0) <= 0 then
			CatBank_CloseFunction()
			return
		end
		
		if Get_XParam_INT(0) == 2 then
			if this:IsVisible() then
				CatBank_Updata()
			end
		else
			CatBank_OnShow()
		end
				
	elseif (event == "UI_COMMAND" and tonumber(arg0) == 88843609) then --URL
		
		GameProduceLogin:OpenURL(GetWeblink("WEB_CKMMDP"))
		
	elseif (event == "UI_COMMAND" and tonumber(arg0) == 88843607) then --寻路
	
		local targetSceneID = Get_XParam_INT(0)
		local targetPosX = Get_XParam_INT(1)
		local targetPosZ = Get_XParam_INT(2)
		AutoRunToTargetEx(targetPosX, targetPosZ, targetSceneID)
		
	elseif event == "HIDE_ON_SCENE_TRANSED"  then	
		this:Hide()
		
	elseif (event == "ADJEST_UI_POS" or event == "VIEW_RESOLUTION_CHANGED") then
		CatBank_Frame_On_ResetPos()
		
	end
	
end

--=========================================================
-- 更新基本显示信息
--=========================================================
function CatBank_OnShow()

	this:Show()

	local nCount = DataPool:LuaFnGetFindCatTableCount(2)
	for idx = 1, nCount do		
		if g_CatBank_TipsList[idx] == nil then
			return
		end
					
		local CatCount, CatFlag, nName, nIcon, nLevel, nLiHui = DataPool:LuaFnGetFindCatTableInfo(2, idx)
		if CatCount >= 0 then	
			
			local str = ScriptGlobal_Format("#{XMWF_210514_75}", tostring(CatCount))	
			g_CatBank_NumList[idx]:SetText(str)
			
			g_CatBank_ImageList[idx]:SetProperty("Image", nLiHui)	
			
			if CatFlag == 1 then
				g_CatBank_TipsList[idx]:Show()
			else
				g_CatBank_TipsList[idx]:Hide()
			end
			
		end
	end
end

--=========================================================
-- 界面控件数据
--=========================================================
function CatBank_Updata()

	local nCount = DataPool:LuaFnGetFindCatTableCount(2)
	for idx = 1, nCount do	
		if g_CatBank_TipsList[idx] == nil then
			return
		end
		
		local CatCount, CatFlag, nName, nIcon, nLevel, nLiHui = DataPool:LuaFnGetFindCatTableInfo(2, idx)
		if CatCount >= 0 then		
			local str = ScriptGlobal_Format("#{XMWF_210514_75}", tostring(CatCount))	
			g_CatBank_NumList[idx]:SetText(str)
			
			if CatFlag == 1 then
				g_CatBank_TipsList[idx]:Show()
			else
				g_CatBank_TipsList[idx]:Hide()
			end
			
		end
	end
	
end

--=========================================================
-- 前往派遣
--=========================================================
function CatBank_UseButtonClk()
	-- 悠游赏乐世
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OnOpenTanBaoUI")
		Set_XSCRIPT_ScriptID(888438)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end

--=========================================================
-- 鼠标滑动
--=========================================================
function CatBank_MouseMove(idx)
	
	if g_CatBank_TipsList[idx] == nil then
		return
	end
	
	local CatCount, CatFlag, nName, nIcon, nLevel, nLiHui = DataPool:LuaFnGetFindCatTableInfo(2, idx)
	if CatCount >= 0 then	
		if CatFlag == 1 then
			g_CatBank_TipsList[idx]:Hide()
		
			Clear_XSCRIPT()
				Set_XSCRIPT_Function_Name("SetCatFlag")
				Set_XSCRIPT_ScriptID(888437)
				Set_XSCRIPT_Parameter( 0, idx )
				Set_XSCRIPT_ParamCount(1)
			Send_XSCRIPT()		
		end
	end
	
end

--=========================================================
-- 关闭界面
--=========================================================
function CatBank_CloseFunction()

	this:Hide()
	
end

function CatBank_OnHiden()

	CatBank_CloseFunction()
	
end

function CatBank_Frame_On_ResetPos()

  CatBank_Frame:SetProperty("UnifiedPosition", g_CatBank_Frame_UnifiedPosition);
  
end


