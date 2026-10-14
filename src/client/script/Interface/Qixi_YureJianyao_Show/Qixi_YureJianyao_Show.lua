

function Qixi_YureJianyao_Show_PreLoad()
	this:RegisterEvent("UI_COMMAND", true)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
end

function Qixi_YureJianyao_Show_OnLoad()

end

function Qixi_YureJianyao_Show_OnEvent(event)
	if event == "UI_COMMAND" and tonumber(arg0) == 2026062204 then
		this:Show()
		KillTimer("Qixi_YureJianyao_Show_Success()")
		Qixi_YureJianyao_Show_Animate:Show()
		Qixi_YureJianyao_Show_Animate:Play(true)
		SetTimer("Qixi_YureJianyao_Show","Qixi_YureJianyao_Show_Success()", 3000)
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		this:Hide()
	end
end

function Qixi_YureJianyao_Show_Success()
 	KillTimer("Qixi_YureJianyao_Show_Success()")
 	Qixi_YureJianyao_Show_Animate:Play(false)
 	Qixi_YureJianyao_Show_Animate:Hide()
 	this:Hide()
end



function Qixi_YureJianyao_Show_OnHidden()
	KillTimer("Qixi_YureJianyao_Show_Success()")
end


