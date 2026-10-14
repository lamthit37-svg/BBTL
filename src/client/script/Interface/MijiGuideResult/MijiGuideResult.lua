-- 武林秘籍引导任务三成功和失败的界面
-- MijiGuideResult.layout.xml	MijiGuideResult.lua
-- PushDebugMessage()
--------------------------------------------------------------------------------------------------

--~ local ICON = {
--~ 	[1] = {imagename = "set:FightSkillTianShan image:FightSkillTianShan_2"} ,	-- 失败
--~ 	[2] = {imagename = "set:FightSkillTianShan image:FightSkillTianShan_3"} ,	-- 成功
--~ }


function MijiGuideResult_PreLoad()
	this:RegisterEvent("UI_COMMAND")
end

function MijiGuideResult_OnLoad()
end

function MijiGuideResult_OnEvent( event )

	if ( event == "UI_COMMAND" and tonumber( arg0 ) == 2013031401 ) then
		local bOpenUI = Get_XParam_INT( 0 );	-- 是否开启UI
		if( bOpenUI == nil or bOpenUI < 0 or bOpenUI > 1 ) then
			return
		end

		if( bOpenUI == 1 ) then
			local bOK = Get_XParam_INT( 1 );		-- 成功 还是 失败
			if ( bOK == nil or bOK < 0 or bOK > 1 ) then
				return
			end

			if( bOK == 1 ) then	-- 成功
				MijiGuideResult_Win:Show();
				MijiGuideResult_Lost:Hide();
			elseif( bOK == 0 ) then	-- 失败
				MijiGuideResult_Win:Hide();
				MijiGuideResult_Lost:Show();
			end
			SetTimer( "MijiGuideResult", "MijiGuideResult_OnTimeOver()", 3000 );	-- 设置定时器, 3秒关闭UI
			this:Show();
		else
			this:Hide();
		end
	end

end

function MijiGuideResult_OnTimeOver()

	KillTimer( "MijiGuideResult_OnTimeOver()" );	-- 关闭定时器
	MijiGuideResult_Win:Hide();
	MijiGuideResult_Lost:Hide();
	this:Hide()

end
