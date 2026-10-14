 
local g_Frame_Width = 0
local g_Frame_Height = 0

local g_Frame_SizeRaw = ""
local g_Lace_SizeRaw = ""

local g_Ctl_Corner = {}
local g_cached_textstr="" 
 
local g_X_Offset = 0  --相对目标窗口的偏移
local g_Y_Offset = 0  --同上
local g_Direct   = "" --相对目标窗口的方位

local g_cached_textid = -1

function FreshManGuide_PlayerQuick_PreLoad()
	this:RegisterEvent("OPEN_FRESHMAN_GUIDE_PLAYERQUICK")
	this:RegisterEvent("CLOSE_FRESHMAN_GUIDE_PLAYERQUICK")
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
end

function FreshManGuide_PlayerQuick_OnLoad()

	--note：two varibles below will be set to string in fact, so do not compare with number directly.
	g_Frame_Width  = FreshManGuide_PlayerQuick_Frame:GetProperty("AbsoluteWidth")
	g_Frame_Height = FreshManGuide_PlayerQuick_Frame:GetProperty("AbsoluteHeight")

	g_Frame_SizeRaw = FreshManGuide_PlayerQuick_Frame:GetProperty("UnifiedSize")
	g_Lace_SizeRaw = FreshManGuide_PlayerQuick_Lace:GetProperty("UnifiedSize")

	g_Ctl_Corner = {  --顺时针,四个角
        FreshManGuide_PlayerQuick_UpLeft,
        FreshManGuide_PlayerQuick_UpRight,
        FreshManGuide_PlayerQuick_DownRight,
        FreshManGuide_PlayerQuick_DownLeft,
    }
end

function FreshManGuide_PlayerQuick_OnEvent(event)
	if event == "OPEN_FRESHMAN_GUIDE_PLAYERQUICK" then 
		if 1 ~= FreshManGuide_PlayerQuick_CheckSize(tonumber(arg4), tonumber(arg5)) then 
	        return  -- 客户端主窗口比本界面还小,不予显示了就
	    end 
	    if 3 == tonumber(arg0) then 
            FreshManGuide_PlayerQuick_Reset(tonumber(arg0), tonumber(arg1), tonumber(arg2), tonumber(arg3), tonumber(arg4), tonumber(arg5), arg6)
        end
        return
	end

	if event == "ADJEST_UI_POS" or
	    event == "VIEW_RESOLUTION_CHANGED" or
	    event == "CLOSE_FRESHMAN_GUIDE_PLAYERQUICK" then
		FreshManGuide_PlayerQuick_Close()
        return
	end
end

function FreshManGuide_PlayerQuick_Close()
    if not this:IsVisible() then
        return
    end 
    KillTimer("FreshManGuide_PlayerQuick_Close()")
    this:Hide()
end

function FreshManGuide_PlayerQuick_Reset(ntype, nTextID, nTipPosX, nTipPosY, nClientWidth, nClientHight, szCorner) 

    KillTimer("FreshManGuide_PlayerQuick_Close()")
	if ntype == 1 then 
	elseif ntype == 3 then  
	    local g_Flex		= GetPlayerQuickEnterHide() 
	    if type(g_Flex) ~= "table" then
	    	return
		end 
		local idx = -1
		for index, value in ipairs(g_Flex) do
			if value.ID == nTextID  then
				idx = index
			end
		end

		if idx == -1 then
			--Lua_TDU_Log("idx==-1");
			return
		end
        g_cached_textid  = -1
		g_cached_textstr = g_Flex[idx].FreshStr   
		local fx, fy = Lua_GetQuickEnterOffSet(g_Flex[idx].ID) 
		nTipPosX = fx
		nTipPosY = fy
        SetTimer("FreshManGuide_PlayerQuick", "FreshManGuide_PlayerQuick_Close()", tonumber(g_Flex[idx].FreshFlash)) 
	end

    FreshManGuide_PlayerQuick_Modify(g_cached_textid, g_cached_textstr, nTipPosX, nTipPosY, nClientWidth, nClientHight, szCorner)
	this:Show()
end

--szCorner代表调用者期望的显示方位
--如期望方位显示不下本窗口,才进入自由选择
function FreshManGuide_PlayerQuick_Modify(nTextID, nTextStr, nTipPosX, nTipPosY, nClientWidth, nClientHight, szCorner)
	--Lua_TDU_Log("FreshManGuide_PlayerQuick_Modify nTextID"..nTextID);		     
	--Lua_TDU_Log("FreshManGuide_PlayerQuick_Modify nTextStr"..nTextStr);		     
	FreshManGuide_PlayerQuick_GuideInfo:SetText(nTextStr)

	if nTipPosX ~= -1 or nTipPosY ~= -1 then             --都为-1，表示不改变相对位置
        g_X_Offset = nTipPosX                            --本tip相对于目标窗口的偏移
        g_Y_Offset = nTipPosY
    end
    if szCorner ~= "" then                               --空串,表示方位不变
        g_Direct = szCorner
    end
    local OffsetX, OffsetY = GetWindowPos("PlayerQuicklyEnter") --得到目标窗口相对于底板的偏移
    OffsetX = OffsetX + g_X_Offset                       --本tip相对于客户端窗口底板的偏移
    OffsetY = OffsetY + g_Y_Offset

    if "northwest" == g_Direct and
        OffsetX - g_Frame_Width > 0 and OffsetY - g_Frame_Height > 0 then
        FreshManGuide_PlayerQuick_To(OffsetX - g_Frame_Width, OffsetY - g_Frame_Height)
        FreshManGuide_PlayerQuick_Show_Corner(3)   --左上显示，show右下角
    elseif "northeast" == g_Direct and
        OffsetX + g_Frame_Width - nClientWidth < 0 and OffsetY - g_Frame_Height > 0 then
        FreshManGuide_PlayerQuick_To(OffsetX, OffsetY - g_Frame_Height)
        FreshManGuide_PlayerQuick_Show_Corner(4)   --右上显示，show左下角
    elseif "southeast" == g_Direct and
        OffsetX + g_Frame_Width - nClientWidth < 0 and OffsetY + g_Frame_Height - nClientHight < 0 then
        FreshManGuide_PlayerQuick_To(OffsetX, OffsetY)
        FreshManGuide_PlayerQuick_Show_Corner(1)   --右下显示，show左上角
    elseif "southwest" == g_Direct and
        OffsetX - g_Frame_Width > 0 and OffsetY + g_Frame_Height - nClientHight < 0 then
        FreshManGuide_PlayerQuick_To(OffsetX - g_Frame_Width, OffsetY)
        FreshManGuide_PlayerQuick_Show_Corner(2)   --左下显示，show右上角
    else
        if OffsetX - g_Frame_Width < 0 then
            if OffsetY - g_Frame_Height < 0 then
                FreshManGuide_PlayerQuick_To(OffsetX, OffsetY)
                FreshManGuide_PlayerQuick_Show_Corner(1)
            else
                FreshManGuide_PlayerQuick_To(OffsetX, OffsetY - g_Frame_Height)
                FreshManGuide_PlayerQuick_Show_Corner(4)
            end
        else
            if OffsetY - g_Frame_Height < 0 then
                FreshManGuide_PlayerQuick_To(OffsetX - g_Frame_Width, OffsetY)
                FreshManGuide_PlayerQuick_Show_Corner(2)
            else
                FreshManGuide_PlayerQuick_To(OffsetX - g_Frame_Width, OffsetY - g_Frame_Height)
                FreshManGuide_PlayerQuick_Show_Corner(3)
            end
        end
    end
 
end

function FreshManGuide_PlayerQuick_To(nXPos, nYPos)
    FreshManGuide_PlayerQuick_Frame:SetProperty("AbsoluteXPosition", nXPos)
    FreshManGuide_PlayerQuick_Frame:SetProperty("AbsoluteYPosition", nYPos)
end

function FreshManGuide_PlayerQuick_Show_Corner(nIdx)
    if nil == g_Ctl_Corner[nIdx] then
        return
    end

    for i = 1, table.getn(g_Ctl_Corner) do
       if nIdx == i then
           g_Ctl_Corner[i]:Show()
       else
           g_Ctl_Corner[i]:Hide()
       end
    end
end

function FreshManGuide_PlayerQuick_CheckSize(nClientWidth, nClientHight)
    if g_Frame_Width - nClientWidth > 0 or g_Frame_Height - nClientHight > 0 then
        return 0
    end
    return 1
end

function FreshManGuide_PlayerQuick_CrackSize( nTextID )

	FreshManGuide_PlayerQuick_Frame:SetProperty("UnifiedSize", tostring(g_Frame_SizeRaw) )
	FreshManGuide_PlayerQuick_Lace:SetProperty("UnifiedSize", tostring(g_Lace_SizeRaw) )

	g_Frame_Width  = FreshManGuide_PlayerQuick_Frame:GetProperty("AbsoluteWidth")
	g_Frame_Heigh = FreshManGuide_PlayerQuick_Frame:GetProperty("AbsoluteHeight")

end

