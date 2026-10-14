--2026Q2武神坛打卡

local g_Frame_UnifiedPosition

--数据
local g_objCared = -1

--=========
-- PreLoad()
--=========
function WuShenTan_DaKa_Over_PreLoad()

	this:RegisterEvent("UI_COMMAND",true)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("OBJECT_CARED_EVENT",false)

end

--=========
-- OnLoad()
--=========
function WuShenTan_DaKa_Over_OnLoad()

	g_Frame_UnifiedPosition = WuShenTan_DaKa_Over_Frame:GetProperty("UnifiedPosition")
	g_objCared = -1

end

--=========
-- Event
--=========
function WuShenTan_DaKa_Over_OnEvent(event)

	if event == "UI_COMMAND" and tonumber(arg0) == 89362702 then
			
		local nType = Get_XParam_INT(0)
		if nType == 0 then --关闭界面
			WuShenTan_DaKa_Over_OnHide()
			return
		elseif nType == 1 then --打开界面
			g_objCared = DataPool:GetNPCIDByServerID(Get_XParam_INT(1))
			this:CareObject(g_objCared, 1, "WuShenTan_DaKa_Over")
			--文字
			local num = Get_XParam_INT(2)
			local str = ""
			if num>=4 then
				str = "#{WSDK_260327_67}"
			elseif num>=2 then
				str = ScriptGlobal_Format("#{WSDK_260327_68}",num)
			else
				str = "#{WSDK_260327_69}"
			end
			WuShenTan_DaKa_Over_Info:SetText(str)
			--倒计时
			WuShenTan_DaKa_Over_Info_Time:SetProperty("Timer", tostring(Get_XParam_INT(3)))
		else
			return
		end	
		this:Show()

	elseif event == "HIDE_ON_SCENE_TRANSED" then

		WuShenTan_DaKa_Over_OnHide()

	elseif event == "VIEW_RESOLUTION_CHANGED" then

		WuShenTan_DaKa_Over_ResetPos()

	elseif event == "ADJEST_UI_POS" then

		WuShenTan_DaKa_Over_ResetPos()
		
    elseif ( event == "OBJECT_CARED_EVENT" and this:IsVisible() ) then
		if(tonumber(arg0) ~= g_objCared) then
			return
		end
		-- 如果和NPC的距离大于一定距离或者被删除，自动关闭
        if(arg1 == "distance" and tonumber(arg2)>15 or arg1=="destroy") then
            WuShenTan_DaKa_Over_OnHide()
        end
		--取消关心
		this:CareObject(g_objCared, 0, "WuShenTan_DaKa_Over");		
	end

end

--*********************************
--打开界面：每次打开，都要重置数据
--*********************************
function WuShenTan_DaKa_Over_OpenUI()

end

--*****************************************
--根据server下发的答案，判断对错，更新界面
--*****************************************
function WuShenTan_DaKa_Over_UpdateUI()

end

function WuShenTan_DaKa_Over_ResetPos()

	WuShenTan_DaKa_Over_Frame:SetProperty("UnifiedPosition", g_Frame_UnifiedPosition)

end

function WuShenTan_DaKa_Over_OnTimer()
	WuShenTan_DaKa_Over_OnHide()
end

function WuShenTan_DaKa_Over_OnHide()
	--取消关心
	this:CareObject(g_objCared, 0, "WuShenTan_DaKa_Over");
	g_objCared = -1
	CloseWindow("MessageBox_Self",true);
	this:Hide()
end


