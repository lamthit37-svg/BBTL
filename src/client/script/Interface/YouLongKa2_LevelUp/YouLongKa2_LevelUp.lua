local g_nYuanbao = -2
function YouLongKa2_LevelUp_PreLoad()
	this:RegisterEvent("UI_COMMAND")

end

function YouLongKa2_LevelUp_OnLoad()
end

function YouLongKa2_LevelUp_OnEvent(event)
	if ( event == "UI_COMMAND" ) then
		if tonumber(arg0) == 201205147 then --隐藏或显示该界面（0表示隐藏，1表示显示）
			if Get_XParam_INT(0) == 0 then  
			    this:Hide()
			else
				YouLongKa2_LevelUp_Update()
				this:Show() 
			end
		end
		if tonumber(arg0) == 201205154 then --发送升级消耗元宝数
			g_nYuanbao = Get_XParam_INT(0)
		end
	end
end

--升级响应
function YouLongKa2_LevelUp_Sell_Clicked()
	Clear_XSCRIPT();
		Set_XSCRIPT_Function_Name("IsFarmoreLevelUp");
		Set_XSCRIPT_ScriptID(889678);
		Set_XSCRIPT_ParamCount(0);
	Send_XSCRIPT();	
end

--退出升级
function YouLongKa2_LevelUp_Close_Clicked()
	this:Hide()
end

function YouLongKa2_LevelUp_Update()
	local name = Player:GetName()
	local str = ScriptGlobal_Format("#{GJYLK_120517_77}",name,tostring(g_nYuanbao))
	YouLongKa2_LevelUp_Info:SetText(str)
	YouLongKa2_LevelUp_Text:SetText("#{GJYLK_120517_150}")
end