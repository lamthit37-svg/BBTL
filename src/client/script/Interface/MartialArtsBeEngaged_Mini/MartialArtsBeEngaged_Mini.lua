--******************************
--比武招亲：订婚悔婚小界面
--******************************


local g_MartialArtsBeEngaged_Mini_Frame_UnifiedPosition
local g_SponsorOrWinner=0

function MartialArtsBeEngaged_Mini_PreLoad()
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("COMPEMARRY_ENGAGE")
end

function MartialArtsBeEngaged_Mini_OnLoad()
	g_MartialArtsBeEngaged_Mini_Frame_UnifiedPosition=MartialArtsBeEngaged_Mini_Frame:GetProperty("UnifiedPosition");
end

function MartialArtsBeEngaged_Mini_OnEvent(event)
	if event == "HIDE_ON_SCENE_TRANSED" or event == "HIDE_ON_SCENE_TRANSED" then
		local curSceneID = GetSceneID();
		if (curSceneID >=687 and curSceneID <=691 ) then
		else
			this:Hide()
		end
	elseif event == "COMPEMARRY_ENGAGE" then
		--arg0 开启关闭标志；arg1 字符串订婚对象名字；arg2谁的界面(0发起者1胜利者)
		if tostring(arg0) == "open"  then
			if this:IsVisible() then
				this:Hide()
			end
			g_SponsorOrWinner=tonumber(arg2)
		elseif tostring(arg0) == "update" then
			MartialArtsBeEngaged_Mini_Update()
			this:Show()
		elseif tostring(arg0) == "close" then
			this:Hide()
		end
	-- 游戏窗口尺寸发生了变化
	elseif (event == "ADJEST_UI_POS" ) then
		MartialArtsBeEngaged_Mini_ResetPos()
	-- 游戏分辨率发生了变化
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		MartialArtsBeEngaged_Mini_ResetPos()
	end
end
function MartialArtsBeEngaged_Mini_Update()
	if g_SponsorOrWinner==0 then--发起者
		MartialArtsBeEngaged_Mini_Bk:SetToolTip("#{BWZQ_160623_183}")
	else--获胜者
		MartialArtsBeEngaged_Mini_Bk:SetToolTip("#{BWZQ_160623_328}")
	end
end
function MartialArtsBeEngaged_Mini_ResetPos()
	MartialArtsBeEngaged_Mini_Frame:SetProperty("UnifiedPosition", g_MartialArtsBeEngaged_Mini_Frame_UnifiedPosition);
end

function MartialArtsBeEngaged_Mini_Clicked()
	this:Hide()
	PushEvent( "COMPEMARRY_ENGAGE", "update2" )
end

function MartialArtsBeEngaged_Mini_ReachZero()
	if this:IsVisible() then
		this:Hide()
	end
end
