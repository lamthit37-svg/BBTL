--新手战令购买界面
--!!!reloadscript =FreshMan_GamePass_GradeBuy
local g_FreshMan_GamePass_Frame_UnifiedPosition = 0

--===============================================
-- PreLoad()
--===============================================
function FreshMan_GamePass_GradeBuy_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)		--离开场景
	this:RegisterEvent("ADJEST_UI_POS",false)				-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)	-- 游戏分辨率发生了变化
	
	this:RegisterEvent("UPDATE_YUANBAO");--刷新元宝
	this:RegisterEvent("OPEN_WINDOW")--打开界面事件
	this:RegisterEvent("CLOSE_WINDOW")--关闭界面事件

end

--===============================================
-- OnLoad()
--===============================================
function FreshMan_GamePass_GradeBuy_OnLoad()	
	g_FreshMan_GamePass_Frame_UnifiedPosition = FreshMan_GamePass_GradeBuy_Function_Frame:GetProperty("UnifiedPosition")

end

--===============================================
-- OnEvent()
--===============================================
function FreshMan_GamePass_GradeBuy_OnEvent(event)
	if event == "HIDE_ON_SCENE_TRANSED" and this:IsVisible()then
		this:Hide();
	elseif event == "ADJEST_UI_POS" and this:IsVisible()then
		FreshMan_GamePass_Frame_On_ResetPos()
	elseif event == "VIEW_RESOLUTION_CHANGED" and this:IsVisible()then
		FreshMan_GamePass_Frame_On_ResetPos()
	elseif (event == "UPDATE_YUANBAO" and this:IsVisible() ) then
		FreshMan_GamePass_GradeBuy_HaveNum:SetText(ScriptGlobal_Format("#{XSZL_220511_19}", Player:GetData("YUANBAO")))
	end
	
	if event == "OPEN_WINDOW" then --界面打开事件
		if( arg0 ~= "FreshMan_GamePass_GradeBuy") then
            return;
        end
		if(IsWindowShow("FreshMan_GamePass_GradeBuy")) then
			this:Hide()
            return;
		end
		FreshMan_GamePass_GradeBuy_ItemNumText:SetProperty("DefaultEditBox", "True");
		FreshMan_GamePass_GradeBuy_ItemNumText:SetSelected( 0, -1 );
		FreshMan_GamePass_GradeBuy_ItemNumText:SetText("1")
		FreshMan_GamePass_GradeBuy_PriceNum:SetText(ScriptGlobal_Format("#{XSZL_220511_19}", "500"))
		FreshMan_GamePass_GradeBuy_HaveNum:SetText(ScriptGlobal_Format("#{XSZL_220511_19}", Player:GetData("YUANBAO")))
		
        this:Show();
	elseif event == "CLOSE_WINDOW" then --界面关闭事件
		this:Hide()
	end
end

function FreshMan_GamePass_GradeBuy_Buy_Click()
	PushEvent("XINSHOUZHANLING_BUY",1,tonumber(FreshMan_GamePass_GradeBuy_ItemNumText:GetText()))
end

function FreshMan_GamePass_GradeBuy_Changed()
	local level = tonumber(FreshMan_GamePass_GradeBuy_ItemNumText:GetText())
	if( level ~= nil)then
		local levelMax = 100 - LuaFnXinShouZhanLing_GetLevel() 
		local canbuylevel = math.floor(Player:GetData("YUANBAO")/500)
		if(canbuylevel < levelMax)then
			levelMax = canbuylevel
		end
		if(levelMax < 1)then
			levelMax = 1
		end
		if(level > levelMax)then
			FreshMan_GamePass_GradeBuy_ItemNumText:SetText(levelMax)
			level = levelMax
		end
		FreshMan_GamePass_GradeBuy_PriceNum:SetText(ScriptGlobal_Format("#{XSZL_220511_19}", tostring(level * 500)))
	else
		if(FreshMan_GamePass_GradeBuy_ItemNumText:GetText() ~= "")then
			FreshMan_GamePass_GradeBuy_ItemNumText:SetText("0")
		end
		FreshMan_GamePass_GradeBuy_PriceNum:SetText(ScriptGlobal_Format("#{XSZL_220511_19}", 0))
	end
end

function FreshMan_GamePass_GradeBuy_Max_Clicked()
	local level = 100 - LuaFnXinShouZhanLing_GetLevel()
	FreshMan_GamePass_GradeBuy_ItemNumText:SetText(tostring(level))
end

--=========================================================
-- 界面位置
--=========================================================
function FreshMan_GamePass_Frame_On_ResetPos()
	FreshMan_GamePass_GradeBuy_Function_Frame:SetProperty("UnifiedPosition", g_FreshMan_GamePass_Frame_UnifiedPosition)
end