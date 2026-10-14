--******************************
--屏幕闪烁特效
--******************************

local g_Anniversary_Flash_Animate={
[1]={name="MartialVictory_Flash",		size="256*128"},--成功
}

--金枫祈愿
local g_Anniversary_Animate = {
	[1]="JinfengBegin",
	[2]="BieYePartyDrumVictory",
	[3]="BieYePartyDrumFailure",
}

function Anniversary_Flash_PreLoad()
	this:RegisterEvent("UI_COMMAND",true)
	--玩家切场景
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
end

function Anniversary_Flash_OnLoad()
--	if SystemSetup:IsClassic() == 0 then	--若客户端是唯美版，则重新设置图标资源为唯美版对应的资源
--	end
end


function Anniversary_Flash_OnEvent(event)

	if ( event == "UI_COMMAND" and tonumber(arg0) == 89273002) then
		local nIdx = tonumber(Get_XParam_INT(0))

		if nIdx<1 or nIdx>table.getn(g_Anniversary_Flash_Animate) then
			return
		end

		if g_Anniversary_Flash_Animate[nIdx].size=="256*128" then
			Anniversary_Flash:SetProperty("UnifiedSize","{{0.000000,256.000000},{0.000000,128.000000}}")
		else
			Anniversary_Flash:SetProperty("UnifiedSize","{{0.000000,256.000000},{0.000000,256.000000}}")
		end

		Anniversary_Flash_Animate:SetProperty("Animate", g_Anniversary_Flash_Animate[nIdx].name);
		Anniversary_Flash_Animate:Play(true)
		this:Show()

	--金枫祈愿 : 5秒倒计时	
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 89288502) then
		if Get_XParam_INT(0) == 1 then
			Anniversary_Flash_Animate:SetProperty("Animate", g_Anniversary_Animate[1]);
			Anniversary_Flash_Animate:Play(true)
			SetTimer("Anniversary_Flash","Anniversary_Flash_Animate_Close()", 5*1000)
			this:Show()	
		end
	
	--金枫祈愿 : 打开胜利或失败界面：并倒计时5秒后关闭
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 89288504) then
		local Victory = Get_XParam_INT(0)
		if Victory == 1 then
			Anniversary_Flash_Animate:SetProperty("Animate", g_Anniversary_Animate[2]);
		else
			Anniversary_Flash_Animate:SetProperty("Animate", g_Anniversary_Animate[3]);
		end
		
		Anniversary_Flash_Animate:Play(true)
		SetTimer("Anniversary_Flash","Anniversary_Flash_Animate_Close()", 1*1000)
		this:Show()	
		
	--执手共御: 打开胜利或失败界面：并倒计时1秒后关闭
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 88876904) then
		local Victory = Get_XParam_INT(0)
		if Victory == 1 then
			Anniversary_Flash_Animate:SetProperty("Animate", g_Anniversary_Animate[2]);
		else
			Anniversary_Flash_Animate:SetProperty("Animate", g_Anniversary_Animate[3]);
		end
		
		Anniversary_Flash_Animate:Play(true)
		SetTimer("Anniversary_Flash","Anniversary_Flash_Animate_Close()", 1*1000)
		this:Show()					
	
	elseif event=="HIDE_ON_SCENE_TRANSED"  then
		Anniversary_Flash_CloseUI()
	end

end

function Anniversary_Flash_Animate_Close()
	KillTimer("Anniversary_Flash_Animate_Close()")	
	--停止倒计时动画
	Anniversary_Flash_Animate:Play(false)	
end

function Anniversary_Flash_CloseUI()
	this:Hide()
end
--=========================================================
--界面隐藏
--=========================================================
function Anniversary_Flash_OnHide()

end
