--活动按钮:百战英杰铸精通

function GoldTopList_AnNiu_PreLoad()
	this:RegisterEvent("UI_COMMAND")
end

function GoldTopList_AnNiu_OnLoad()
	this:Hide()
end

function GoldTopList_AnNiu_OnEvent(event)
	if (event == "UI_COMMAND") and (arg0 == "2015112401") then
		if Get_XParam_INT(0) == 1 then
			this:Show()
			--显示tips
			local fX = 0
			local fY = 0
			fX, fY = this:GetChildOffset("GoldTopList_AnNiu_Icon")
			fX = fX + 10
			fY = fY + 30
			OpenFreshManGuide(1, 89, fX, fY, "GoldTopList_AnNiu", "southwest")
			--闪烁
			GoldTopList_AnNiu_Icon:PlayWarning( 1 )
			--计时器
			SetTimer("GoldTopList_AnNiu", "GoldTopList_AnNiu_Flashdown()",10*1000)
		elseif Get_XParam_INT(0) == 2 then
			this:Show()
			--浮动tips消失
			GoldTopList_AnNiu_Flashdown()
			if "GoldTopList_AnNiu" == GetFreshManGuideOwner() then
				CloseFreshManGuide()      --当引导ui指向本界面,才需要响应
		  end		
		else
			--浮动tips消失
			GoldTopList_AnNiu_Flashdown()
			this:Hide()
		end
	end
end

function GoldTopList_AnNiu_Flashdown()
	--tips
	--CloseFreshManGuide()
	--闪烁
	GoldTopList_AnNiu_Icon:PlayWarning( 0 )
	--计时器
	KillTimer("GoldTopList_AnNiu_Flashdown()")
end

function GoldTopList_AnNiu_OnClick()
	--浮动tips消失
	GoldTopList_AnNiu_Flashdown()
	if "GoldTopList_AnNiu" == GetFreshManGuideOwner() then
		CloseFreshManGuide()      --当引导ui指向本界面,才需要响应
  end
	
	--关闭界面
	if(IsWindowShow("GoldTopList")) then
		CloseWindow("GoldTopList", true)
		return
	end

	--请求打开界面
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "ShowYingJieUI" )
		Set_XSCRIPT_ScriptID(891723)
		Set_XSCRIPT_Parameter(0,1)--默认打开页面1
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()

end

