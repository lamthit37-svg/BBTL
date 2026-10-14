local g_DoubleExperienceGet_CurIndex = 0
local g_DoubleExperienceGet_ItemIndex_1 = 38000360
local g_DoubleExperienceGet_ItemIndex_2 = 38000361

local g_Object_DoubleExperienceGet = -1;

function DoubleExperienceGet_PreLoad()
	this:RegisterEvent("UI_COMMAND")
end

function DoubleExperienceGet_OnLoad()
end

function DoubleExperienceGet_OnEvent(event)
	
	if (event == "UI_COMMAND") and (arg0 == "201205150") then  --显示或隐藏该界面
		if Get_XParam_INT(0) == 0 then  --隐藏该界面
			 DoubleExperienceGet_Close()
		else  --显示该界面
			local str = ""
			if g_DoubleExperienceGet_CurIndex == g_DoubleExperienceGet_ItemIndex_1 then
				str = ScriptGlobal_Format("#{GJYLK_120517_59}",tonumber(Get_XParam_INT(1)))
		    else
				str = ScriptGlobal_Format("#{GJYLK_120517_60}",tonumber(Get_XParam_INT(1)))
		    end 
		    DoubleExperienceGet_Text3:SetText(str);
		    BeginCareObject_DoubleExperienceGet(Get_XParam_INT(2))
		    this:Show()
		end

	end
	
	if (event == "UI_COMMAND") and (arg0 == "201205146") then  --获取当前使用的月卡索引
		g_DoubleExperienceGet_CurIndex = Get_XParam_INT(0)
		Player:SetMCardIndex(Get_XParam_INT(0))
	end
end

function DoubleExperienceGet_Close()
	DoubleExperienceGet_Moral_Value:SetText("");
	DoubleExperienceGet_Text3:SetText("");
	this:Hide()
end

function DoubleExperienceGet_OK_Clicked()
	local nHour = DoubleExperienceGet_Moral_Value:GetText()
	local nCount = tonumber(nHour)
	if nCount == nil or nCount <= 0 then
		PushDebugMessage( "#{GJYLK_120517_152}" )
		return
	end

	Clear_XSCRIPT();
		Set_XSCRIPT_Function_Name("ConfirmTakeDE");
		Set_XSCRIPT_ScriptID(311002);
		Set_XSCRIPT_Parameter(0,nCount);
		Set_XSCRIPT_ParamCount(1);
	Send_XSCRIPT();

	DoubleExperienceGet_Close()
end

--开始关心NPC
function BeginCareObject_DoubleExperienceGet(objCared_DoubleExperienceGetId)
	g_Object_DoubleExperienceGet = DataPool : GetNPCIDByServerID(objCared_DoubleExperienceGetId);
	this:CareObject(g_Object_DoubleExperienceGet, 1);

end

