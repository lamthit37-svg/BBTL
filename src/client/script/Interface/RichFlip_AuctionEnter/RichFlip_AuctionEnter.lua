----------------------
-- RichFlip_AuctionEnter ---
----------------------

local g_Cooldown = 4*1000		--4s按钮冷却
local g_InCooldown = 0			--是否在冷却

local g_PlayWarning = 10*1000		--10s闪烁按钮冷却
local g_InPlayWarning = 1			--是否在闪烁冷却

local g_LevelLimit = 30	--显示按钮的最小等级

local g_RichFilpEnter_Tip = 0 --红点标记
--===============================================
-- PreLoad()
--===============================================
function RichFlip_AuctionEnter_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("HIDE_TLBB_MAIN")
	this:RegisterEvent("HIDE_THIS_UI")
end

--===============================================
-- OnLoad()
--===============================================
function RichFlip_AuctionEnter_OnLoad()

end

--===============================================
-- OnEvent()
--===============================================
function RichFlip_AuctionEnter_OnEvent(event)
	if (event  == "UI_COMMAND") and (tonumber(arg0) == 99944106) then
		local bFlash = Get_XParam_INT(0)
		RichFlip_AuctionEnter_ShowIcon(bFlash)
	end
	
	if ( event == "HIDE_TLBB_MAIN" ) then
		if this:IsVisible() then
			this:Hide()
		end
	end
	
	if event == "HIDE_THIS_UI" then
		if this:IsVisible() then
			this:Hide()
		end
	end
	
	if (event  == "UI_COMMAND") and (tonumber(arg0) == 99944110) then

		if this:IsVisible() then
			g_RichFilpEnter_Tip = tonumber(Get_XParam_INT(0))
			RichFlip_AuctionEnter_ShowTips()
		end
	end
end

--===============================================
-- OnShow()
--===============================================
function RichFlip_AuctionEnter_ShowIcon(bFlash)
	if bFlash == nil then
		return
	end
	
	--关闭界面
	if bFlash == 2 then
		if this:IsVisible() then
			this:Hide()
		end
	elseif bFlash == 0 or bFlash == 1 then--显示界面
		if this:IsVisible() then
			--不处理
		else
			local curDay = tonumber(DataPool:GetServerDayTime());
			--界面显示		
			RichFlip_AuctionEnter_Icon : SetToolTip("#{FPLS_240715_01}")
		
			this:Show()
			RichFlip_AuctionEnter_Tips:Hide()	
			--闪烁时间判断
			if bFlash == 1 then
				--图标闪烁			
				--RichFlip_AuctionEnter_Icon : PlayWarning( 1 )
				RichFlip_AuctionEnter_Animate:Play(true)
				--开启tips
				--local fX, fY = this:GetChildOffset("PlayerFrame_SongjincansiButton")
				--OpenFreshManGuide(1, 279, fX + 39, fY + 39, "RichFlip_AuctionEnter", "northeast")
				--RichFlip_AuctionEnter_Icon : SetToolTip("")
				--设置闪烁冷却时间
				g_InPlayWarning = 1
				SetTimer("RichFlip_AuctionEnter", "RichFlip_AuctionEnter_g_PlayWarning()",g_PlayWarning)
				if(curDay >= 20251031 and curDay <= 20251112) then
					SetTimer("RichFlip_AuctionEnter", "RichFlip_AuctionEnter_g_FreshGuide()",5*1000)
				end
			end
		end
	end
end

function RichFlip_AuctionEnter_ShowTips()
	if g_RichFilpEnter_Tip == 1 then
		RichFlip_AuctionEnter_Tips:Show()
	else
		RichFlip_AuctionEnter_Tips:Hide()
	end
end
--===============================================
-- OnClick()
--===============================================
function RichFlip_AuctionEnter_OnClick()
	--等级判断
	local nLevel = Player:GetData( "LEVEL" )
	if( nLevel < g_LevelLimit ) then
		PushDebugMessage("#{FPLS_240715_05}")
		return
	end

	--图标闪烁消失			
	--RichFlip_AuctionEnter_Icon : PlayWarning( 0 )
	RichFlip_AuctionEnter_Animate:Play(false)
	--浮动tips消失
	if "RichFlip_AuctionEnter" == GetFreshManGuideOwner() then
		CloseFreshManGuide()      --当引导ui指向本界面,才需要响应
  	end
	--RichFlip_AuctionEnter_Icon : SetToolTip("#{FPLS_240715_01}")
	
	--判断窗口是否打开
	if(IsWindowShow("RichFlip")) then
		CloseWindow("RichFlip", true)
		return
	end
	
	--请求服务器数据
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OpenUI" )
		Set_XSCRIPT_ScriptID( 999441 )
		Set_XSCRIPT_Parameter(0,0)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end

--===============================================
-- 冷却计时结束()
--===============================================
function RichFlip_AuctionEnter_g_Cooldown()
	g_InCooldown = 0
	KillTimer("RichFlip_AuctionEnter_g_Cooldown()")
end

--===============================================
-- 闪烁计时结束()
--===============================================
function RichFlip_AuctionEnter_g_PlayWarning()
	--图标闪烁消失			
	--RichFlip_AuctionEnter_Icon : PlayWarning( 0 )
	RichFlip_AuctionEnter_Animate:Play(false)
	--浮动tips消失
	--if "RichFlip_AuctionEnter" == GetFreshManGuideOwner() then
	--	CloseFreshManGuide()      --当引导ui指向本界面,才需要响应
  --end
  
  --RichFlip_AuctionEnter_Icon : SetToolTip("#{FPLS_240715_01}")
	--闪烁计时停止
	g_InPlayWarning = 0
	KillTimer("RichFlip_AuctionEnter_g_PlayWarning()")
end

function RichFlip_AuctionEnter_g_FreshGuide()
	--开启tips
	local fX, fY = this:GetChildOffset("PlayerFrame_SongjincansiButton")
	OpenFreshManGuide(1, 279, fX + 39, fY + 39, "RichFlip_AuctionEnter", "northeast")
	--RichFlip_AuctionEnter_Icon : SetToolTip("")
			
	KillTimer("RichFlip_AuctionEnter_g_FreshGuide()")
end