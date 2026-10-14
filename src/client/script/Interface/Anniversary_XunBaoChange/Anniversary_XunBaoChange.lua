
local g_Anniversary_XunBaoChange_Frame_UnifiedPosition;  

local g_Anniversary_XunBaoChange_Info = {
	[1] = { nStr = "#{ZNYR_200302_41}", nTo = {0, 0, 0, 0}, nToIdx = 0,
			nImage = "set:Anniversary_XunBao3 image:Anniversary_XunBao_SCup1" },
	[2] = { nStr = "#{ZNYR_200302_44}", nTo = {4, 0, 0, 0}, nToIdx = 1,
			nImage = "set:Anniversary_XunBao3 image:Anniversary_XunBao_SCup2" },
	[3] = { nStr = "#{ZNYR_200302_43}", nTo = {20, 5, 0, 0}, nToIdx = 2,
			nImage = "set:Anniversary_XunBao3 image:Anniversary_XunBao_SCup3" },
	[4] = { nStr = "#{ZNYR_200302_42}", nTo = {80, 20, 4, 0}, nToIdx = 3,  
			nImage = "set:Anniversary_XunBao3 image:Anniversary_XunBao_SCup4" },
}

local g_Anniversary_XunBaoChange_CurDaiBiValue = { 0, 0, 0, 0 }
local g_Anniversary_XunBaoChange_From = -1
local g_Anniversary_XunBaoChange_FromNum = 0
local g_Anniversary_XunBaoChange_To = -1
local g_Anniversary_XunBaoChange_ToNum = 0

function Anniversary_XunBaoChange_PreLoad()
	this:RegisterEvent("UI_COMMAND",true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false); 
	this:RegisterEvent("ADJEST_UI_POS",false) 	    
	-- 进入游戏世界
	this:RegisterEvent("PLAYER_ENTERING_WORLD",false)	
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);	 
end 

function Anniversary_XunBaoChange_OnLoad()
	g_Anniversary_XunBaoChange_Frame_UnifiedPosition = Anniversary_XunBaoChange_Frame:GetProperty("UnifiedPosition"); 	 
end

function Anniversary_XunBaoChange_Frame_On_ResetPos()
  	Anniversary_XunBaoChange_Frame:SetProperty("UnifiedPosition", g_Anniversary_XunBaoChange_Frame_UnifiedPosition);
end

function Anniversary_XunBaoChange_OnEvent(event)

	-- 离开游戏世界
	if ( event == "HIDE_ON_SCENE_TRANSED" or event == "PLAYER_ENTERING_WORLD" ) then
		Anniversary_XunBaoChange_Close_Clicked();
		return
	end
  
    -- 游戏窗口尺寸发生了变化
	if ( event == "ADJEST_UI_POS" or event == "VIEW_RESOLUTION_CHANGED" ) then
		-- 更新背包界面位置
		Anniversary_XunBaoChange_Frame_On_ResetPos()
		return
	end
		 
	-- 打开界面
	if (event == "UI_COMMAND" and tonumber(arg0) == 89340106) then 
		if arg1 ~= nil and tonumber(arg1) ~= 1 then
			Anniversary_XunBaoChange_Close_Clicked()  
			return
		end
		
		g_Anniversary_XunBaoChange_CurDaiBiValue[1] = tonumber(arg2)
		g_Anniversary_XunBaoChange_CurDaiBiValue[2] = tonumber(arg3)
		g_Anniversary_XunBaoChange_CurDaiBiValue[3] = tonumber(arg4)
		g_Anniversary_XunBaoChange_CurDaiBiValue[4] = tonumber(arg5)
		
		Anniversary_XunBaoChange_OnInitial(); 
		this:Show();
		return
	elseif (event == "UI_COMMAND" and tonumber(arg0) == 89340110) then 
		if this:IsVisible() then
			if Get_XParam_INT(0) == 1 then
		
				g_Anniversary_XunBaoChange_From = Get_XParam_INT(1)	
				
				g_Anniversary_XunBaoChange_CurDaiBiValue[1] = Get_XParam_INT(2)
				g_Anniversary_XunBaoChange_CurDaiBiValue[2] = Get_XParam_INT(3)		
				g_Anniversary_XunBaoChange_CurDaiBiValue[3] = Get_XParam_INT(4)
				g_Anniversary_XunBaoChange_CurDaiBiValue[4] = Get_XParam_INT(5)	
			
				Anniversary_XunBaoChange_OnInitial()  
				
			else
				Anniversary_XunBaoChange_Close_Clicked() 
			end
			return
		end
	end  
	
end 

function Anniversary_XunBaoChange_OnInitial()  

	g_Anniversary_XunBaoChange_From = -1
	g_Anniversary_XunBaoChange_FromNum = 0
	g_Anniversary_XunBaoChange_To = -1
	g_Anniversary_XunBaoChange_ToNum = 0 

	Anniversary_XunBaoChange_Item1_Text:ResetList()
	Anniversary_XunBaoChange_Item1_Text:SetText("#{ZNYR_200302_167}")	
	for i = 2, table.getn(g_Anniversary_XunBaoChange_Info) do
		Anniversary_XunBaoChange_Item1_Text:AddTextItem(g_Anniversary_XunBaoChange_Info[i].nStr, i)
	end
	
	Anniversary_XunBaoChange_Item3:Show()
	Anniversary_XunBaoChange_Item2:Hide()
	
	Anniversary_XunBaoChange_Item1Number:SetProperty("DefaultEditBox", "False")
	Anniversary_XunBaoChange_Item1Number:Disable()
	Anniversary_XunBaoChange_Item1Number:SetText("0")
	
end

function Anniversary_XunBaoChange_OK_Clicked()

	if g_Anniversary_XunBaoChange_From <= 0 then
		PushDebugMessage("#{ZNYR_200302_111}")
		return
	end
	
	if g_Anniversary_XunBaoChange_To <= 0 then
		PushDebugMessage("#{ZNYR_200302_148}")
		return
	end
	
	if g_Anniversary_XunBaoChange_FromNum <= 0 then
		PushDebugMessage("#{ZNYR_200302_147}")
		return
	end
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "AnniPreExchangeDB" )
		Set_XSCRIPT_ScriptID( 893401 )
		Set_XSCRIPT_Parameter(0, g_Anniversary_XunBaoChange_From)
		Set_XSCRIPT_Parameter(1, g_Anniversary_XunBaoChange_FromNum)
		Set_XSCRIPT_Parameter(2, g_Anniversary_XunBaoChange_To)
		Set_XSCRIPT_Parameter(3, 1)
		Set_XSCRIPT_ParamCount(4)
	Send_XSCRIPT()	

end

function Anniversary_XunBaoChange_Close_Clicked()  
	Anniversary_XunBaoChange_Item1_Text:ResetList()
	
	this:Hide(); 
end 

function Anniversary_XunBaoChange_EditEnter()
	local szName, nIndex = Anniversary_XunBaoChange_Item1_Text:GetCurrentSelect();
	if( nIndex and nIndex > 1 ) then	
		local numstr = Anniversary_XunBaoChange_Item1Number:GetText()
		if numstr == nil then
			return
		end
		
		local num = tonumber(numstr)
		if num == 0 or num == nil then
			g_Anniversary_XunBaoChange_FromNum = 0
			Anniversary_XunBaoChange_Item2Changed()
			return
		end
		
		if num < 0 then
			Anniversary_XunBaoChange_Item1Number:SetText("0")
			g_Anniversary_XunBaoChange_FromNum = 0
		end
		
		g_Anniversary_XunBaoChange_FromNum = num
		
		if g_Anniversary_XunBaoChange_CurDaiBiValue[nIndex] ~= nil and num > g_Anniversary_XunBaoChange_CurDaiBiValue[nIndex] then
			Anniversary_XunBaoChange_Item1Number:SetText(tostring(g_Anniversary_XunBaoChange_CurDaiBiValue[nIndex]))
			g_Anniversary_XunBaoChange_FromNum = g_Anniversary_XunBaoChange_CurDaiBiValue[nIndex]
		end
		
		Anniversary_XunBaoChange_Item2Changed()
	end
end

function Anniversary_XunBaoChange_Item1Changed()
	local szName, nIndex = Anniversary_XunBaoChange_Item1_Text:GetCurrentSelect();
	if( nIndex and nIndex > 1 ) then	
	
		Anniversary_XunBaoChange_Item3:Hide()
		Anniversary_XunBaoChange_Item2:Show()
		
		Anniversary_XunBaoChange_Item1Number:SetProperty("DefaultEditBox", "True")
		Anniversary_XunBaoChange_Item1Number:Enable()
	
		g_Anniversary_XunBaoChange_From = nIndex
		g_Anniversary_XunBaoChange_FromNum = 0
		
		--if (g_Anniversary_XunBaoChange_CurDaiBiValue[nIndex] ~= nil) and (g_Anniversary_XunBaoChange_CurDaiBiValue[nIndex] > 0) then
			Anniversary_XunBaoChange_Item1Number:SetText("0")
		--	g_Anniversary_XunBaoChange_FromNum = 0
		--end
		
		if g_Anniversary_XunBaoChange_Info[nIndex] ~= nil then
		
			g_Anniversary_XunBaoChange_To = -1
			g_Anniversary_XunBaoChange_ToNum = 0 
			
			Anniversary_XunBaoChange_Item1Number_CoinPic:SetProperty("Image", g_Anniversary_XunBaoChange_Info[nIndex].nImage)
			
			local toIdx = g_Anniversary_XunBaoChange_Info[nIndex].nToIdx
			if g_Anniversary_XunBaoChange_Info[toIdx] ~= nil then
				
				g_Anniversary_XunBaoChange_To = toIdx
			
				Anniversary_XunBaoChange_Item2Name:SetText( g_Anniversary_XunBaoChange_Info[toIdx].nStr )
				
				Anniversary_XunBaoChange_Item2Number_CoinPic:SetProperty("Image", g_Anniversary_XunBaoChange_Info[toIdx].nImage)
				
				Anniversary_XunBaoChange_Item2Number:SetText( "0" )
			end
		end
	else
		PushDebugMessage("#{ZNYR_200302_111}")
	end
end

function Anniversary_XunBaoChange_Item2Changed()
	if g_Anniversary_XunBaoChange_Info[g_Anniversary_XunBaoChange_From] ~= nil 
		and g_Anniversary_XunBaoChange_FromNum >= 0 
		and g_Anniversary_XunBaoChange_Info[g_Anniversary_XunBaoChange_From].nTo[g_Anniversary_XunBaoChange_To] ~= nil then
		
		local nToNum = g_Anniversary_XunBaoChange_FromNum * g_Anniversary_XunBaoChange_Info[g_Anniversary_XunBaoChange_From].nTo[g_Anniversary_XunBaoChange_To]
		
		Anniversary_XunBaoChange_Item2Number:SetText( tostring(nToNum) )
		
		g_Anniversary_XunBaoChange_ToNum = tonumber(nToNum)
		
	end
end

 