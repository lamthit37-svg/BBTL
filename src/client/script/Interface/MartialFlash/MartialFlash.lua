--******************************
--屏幕闪烁特效
--******************************

local g_MartialFlash_Animate={
[1]={name="MartialSLVictory_Flash",		size="256*128"},--守擂成功
[2]={name="MartialFail_Flash",				size="256*128"},--失败
[3]={name="MartialVictoryDS_Flash",		size="256*128"},--胜者诞生
[4]={name="MartialChallengerDS_Flash",size="256*128"},--擂主诞生
[5]={name="MartialToRob_Flash",				size="256*256"},--开始抢擂
[6]={name="MartialDH_Flash",					size="256*128"},--订婚
[7]={name="MartialDLVictory_Flash",		size="256*128"},--打擂成功
}

function MartialFlash_PreLoad()
	this:RegisterEvent("COMPEMARRY_FLASH")
	--玩家切场景
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
	--this:RegisterEvent("ADJEST_UI_POS",false)
	--this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
end

function MartialFlash_OnLoad()
--	if SystemSetup:IsClassic() == 0 then	--若客户端是唯美版，则重新设置图标资源为唯美版对应的资源
--	end
end


function MartialFlash_OnEvent(event)

	if ( event == "COMPEMARRY_FLASH" ) then
		local nIdx = tonumber(arg0)

		if nIdx<1 or nIdx>table.getn(g_MartialFlash_Animate) then
			return
		end

		if g_MartialFlash_Animate[nIdx].size=="256*128" then
			MartialFlash:SetProperty("UnifiedSize","{{0.000000,256.000000},{0.000000,128.000000}}")
--		MartialFlash:SetProperty("UnifiedPosition","{{0.500000,-200.000000},{0.500000,-64.000000}}")
		else
			MartialFlash:SetProperty("UnifiedSize","{{0.000000,256.000000},{0.000000,256.000000}}")
--		MartialFlash:SetProperty("UnifiedPosition","{{0.500000,-200.000000},{0.500000,-64.000000}}")
		end

		MartialFlash_Animate:SetProperty("Animate", g_MartialFlash_Animate[nIdx].name);
		MartialFlash_Animate:Play(true)
		this:Show()

	elseif event=="HIDE_ON_SCENE_TRANSED"  then
		MartialFlash_CloseUI()
	end

end

function MartialFlash_CloseUI()
	this:Hide()
end
--=========================================================
--界面隐藏
--=========================================================
function MartialFlash_OnHide()
--	PushDebugMessage("MartialFlash_OnHide")
end
