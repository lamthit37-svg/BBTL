local g_FrameInfo = -1;
local g_Item_DJS_Confirm_Frame_UnifiedPosition;

local FrameInfoList =
{
		DJTS_CONFIRM_SETPOS = 265,							--	确认遁甲天书重新定位
		DJQS_CONFIRM_SETPOS = 266,							--	确认遁甲奇书重新定位
		DJTS_CONFIRM_CHUANSONG = 267,						--	确认遁甲天书传送
		DJQS_CONFIRM_CHUANSONG = 268,						--	确认遁甲奇书传送
		DJTS_CONFIRM_BUCHONG = 269,							--	确认遁甲天书补充符咒
		DJQS_CONFIRM_BUCHONG = 270,							--	确认遁甲奇书补充符咒
		
		DJVIP_CONFIRM_SETPOS = 271,							--	确认瞬影符箓重新定位
		DJVIP_CONFIRM_CHUANSONG = 272,						--	确认瞬影符箓传送
		DJTS_CONFIRM_BUCHONG_YUANBAO_BIND = 273,		--用绑定元宝增加彻地符箓的符咒
		DJTS_CONFIRM_BUCHONG_YUANBAO = 274,		--用元宝增加彻地符箓的符咒
		DJTS_CONFIRM_BUCHONG_ITEM_BIND = 275,		--用绑定道具增加彻地符箓的符咒
};

local Client_ItemIndex = -1
local DJS_SelIndex = -1
local g_msgFrameVar = {}

function Item_DJS_Confirm_CancelLastOp(str)
	if(this:IsVisible() and str ~= g_FrameInfo) then
		this:Hide()
	end
end
--===============================================
-- OnLoad()
--===============================================
function Item_DJS_Confirm_PreLoad()
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	--离开游戏
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);

	--遁甲天书定位确认
	this:RegisterEvent( "CONFIRM_SETPOS_DJTS" );
	--遁甲奇书定位确认
	this:RegisterEvent( "CONFIRM_SETPOS_DJQS" );
	--瞬影符箓定位确认
	this:RegisterEvent("CONFIRM_SETPOS_DJVIP");
	--遁甲天书传送确认
	this:RegisterEvent( "CONFIRM_CHUANSONG_DJTS" );
	--遁甲奇书传送确认
	this:RegisterEvent( "CONFIRM_CHUANSONG_DJQS" );
	--瞬影符箓传送确认
	this:RegisterEvent( "CONFIRM_CHUANSONG_DJVIP" );
	--遁甲天书补充符咒确认
	this:RegisterEvent( "CONFIRM_BUCHONG_DJTS" );
	--遁甲奇书补充符咒确认
	this:RegisterEvent( "CONFIRM_BUCHONG_DJQS" );
	this:RegisterEvent("UI_COMMAND");

end

--===============================================
-- OnLoad()
--===============================================
function Item_DJS_Confirm_OnLoad()
  g_Item_DJS_Confirm_Frame_UnifiedPosition=Item_DJS_Confirm_Frame:GetProperty("UnifiedPosition");
end

function  Item_DJS_Confirm_UpdateRect()
	local nWidth, nHeight = Item_DJS_Confirm_Info:GetWindowSize();
	local nTitleHeight = 36;
	local nBottomHeight = 75;
	nWindowHeight = nTitleHeight + nBottomHeight + nHeight;
	--Item_DJS_Confirm_Frame:SetProperty( "AbsoluteHeight", tostring( nWindowHeight ) );
end

--===============================================
-- OnEvent()
--===============================================
function Item_DJS_Confirm_OnEvent(event)

	if (event == "CONFIRM_SETPOS_DJTS") then
        if SystemSetup:IsClassic() == 1 then
            Item_DJS_Confirm_Title:SetProperty("Image","set:Menpaishuxing image:DunJiaShu_Title_Index")--遁甲天书
        else
            Item_DJS_Confirm_Title:SetText("#{UIGZ_130816_2}")--遁甲天书
        end
		
		local itemIdx = tonumber(arg0)
		local szSceneName = tostring(arg1);
		local iSceneId = tonumber(arg2);
		local iPosX = tonumber(arg3);
		local iPosZ = tonumber(arg4);
		local iSelIdx = tonumber(arg5);

		Item_DJS_Confirm_CancelLastOp(FrameInfoList.DJTS_CONFIRM_SETPOS)

		g_FrameInfo = FrameInfoList.DJTS_CONFIRM_SETPOS

		Client_ItemIndex = itemIdx
		DJS_SelIndex = iSelIdx

		local curSceneName = GetCurrentSceneName(0)
		local curPosX, curPosZ, _ = Target:GetMyPos()
		curPosX = math.floor(curPosX)
		curPosZ = math.floor(curPosZ)

		local str = "#{DJTS_110509_12}"..szSceneName.."（"..iPosX.."，"..iPosZ.."）".."#r".."#{DJTS_110509_13}"..curSceneName.."（"..curPosX.."，"..curPosZ.."）"

		if (szSceneName ~= "") then
			Item_DJS_Confirm_Info:SetText(str);
			Item_DJS_Confirm_UpdateRect();
			this:Show();
			return
		else
			Item_DJS_Confirm_Queding_Clicked()
			this:Hide()
			return
		end

	end

	if (event == "CONFIRM_SETPOS_DJQS") then
        if SystemSetup:IsClassic() == 1 then
    		Item_DJS_Confirm_Title:SetProperty("Image","set:Menpaishuxing image:DunJiaShu_Title_Monster") --遁甲奇书
        else
            Item_DJS_Confirm_Title:SetText("#{UIGZ_130816_1}") --遁甲奇书
        end
		
		local itemIdx = tonumber(arg0)
		local szSceneName = tostring(arg1);
		local iSceneId = tonumber(arg2);
		local iPosX = tonumber(arg3);
		local iPosZ = tonumber(arg4);
		local iSelIdx = tonumber(arg5);

		Item_DJS_Confirm_CancelLastOp(FrameInfoList.DJQS_CONFIRM_SETPOS);
		g_FrameInfo = FrameInfoList.DJQS_CONFIRM_SETPOS;

		Client_ItemIndex = itemIdx
		DJS_SelIndex = iSelIdx

		local curSceneName = GetCurrentSceneName(0)
		local curPosX, curPosZ, _ = Target:GetMyPos()
		curPosX = math.floor(curPosX)
		curPosZ = math.floor(curPosZ)

		local str = "#{DJTS_110509_12}"..szSceneName.."（"..iPosX.."，"..iPosZ.."）".."#r".."#{DJTS_110509_13}"..curSceneName.."（"..curPosX.."，"..curPosZ.."）"

		if (szSceneName ~= "") then
			Item_DJS_Confirm_Info:SetText(str)
			Item_DJS_Confirm_UpdateRect();
			this:Show();
			return
		else
			Item_DJS_Confirm_Queding_Clicked()
			this:Hide()
			return
		end

	end
	
	
	if (event == "CONFIRM_SETPOS_DJVIP") then
        if SystemSetup:IsClassic() == 1 then
		    Item_DJS_Confirm_Title:SetProperty("Image","set:Menpaishuxing image:DunJiaShu_Title_VIP") --遁甲书VIP
        else
            Item_DJS_Confirm_Title:SetText("#{UIGZ_130816_3}") --遁甲书VIP
        end
		
		local itemIdx = tonumber(arg0)
		local szSceneName = tostring(arg1);
		local iSceneId = tonumber(arg2);
		local iPosX = tonumber(arg3);
		local iPosZ = tonumber(arg4);
		local iSelIdx = tonumber(arg5);
		
		Item_DJS_Confirm_CancelLastOp(FrameInfoList.DJVIP_CONFIRM_SETPOS);
		g_FrameInfo = FrameInfoList.DJVIP_CONFIRM_SETPOS;

		Client_ItemIndex = itemIdx
		DJS_SelIndex = iSelIdx
		
		local curSceneName = GetCurrentSceneName(0)
		local curPosX, curPosZ, _ = Target:GetMyPos()
		curPosX = math.floor(curPosX)
		curPosZ = math.floor(curPosZ)
		
		local str = "#{DJTS_110509_12}"..szSceneName.."（"..iPosX.."，"..iPosZ.."）".."#r".."#{DJTS_110509_13}"..curSceneName.."（"..curPosX.."，"..curPosZ.."）"
		if (szSceneName ~= "") then
			Item_DJS_Confirm_Info:SetText(str)
			Item_DJS_Confirm_UpdateRect();
			this:Show();
			return
		else
			Item_DJS_Confirm_Queding_Clicked()
			this:Hide()
			return
		end
	end

	if(event == "CONFIRM_CHUANSONG_DJTS") then
        if SystemSetup:IsClassic() == 1 then
		    Item_DJS_Confirm_Title:SetProperty("Image","set:Menpaishuxing image:DunJiaShu_Title_Index")--遁甲天书
        else
            Item_DJS_Confirm_Title:SetText("#{UIGZ_130816_2}")--遁甲天书
        end
		local itemIdx = tonumber(arg0)
		local szSceneName = tostring(arg1);
		local iSceneId = tonumber(arg2);
		local iPosX = tonumber(arg3);
		local iPosZ = tonumber(arg4);
		local iSelIdx = tonumber(arg5);

		Item_DJS_Confirm_CancelLastOp(FrameInfoList.DJTS_CONFIRM_CHUANSONG);
		g_FrameInfo = FrameInfoList.DJTS_CONFIRM_CHUANSONG;

		Client_ItemIndex = itemIdx
		DJS_SelIndex = iSelIdx

		local str = "#{DJTS_110509_14}".."\n"..szSceneName.."（"..iPosX.."，"..iPosZ.."）";
		if (szSceneName ~= "") then
			Item_DJS_Confirm_Info:SetText(str)
			Item_DJS_Confirm_UpdateRect();
			this:Show();
			return
		else
		   PushDebugMessage("#{DJTS_110509_31}")
		   this:Hide()
		   return
		end
	end

	if(event == "CONFIRM_CHUANSONG_DJQS") then
        if SystemSetup:IsClassic() == 1 then
		    Item_DJS_Confirm_Title:SetProperty("Image","set:Menpaishuxing image:DunJiaShu_Title_Monster") --遁甲奇书
        else
            Item_DJS_Confirm_Title:SetText("#{UIGZ_130816_1}") --遁甲奇书
        end
		local itemIdx = tonumber(arg0)
		local szSceneName = tostring(arg1);
		local iSceneId = tonumber(arg2);
		local iPosX = tonumber(arg3);
		local iPosZ = tonumber(arg4);
		local iSelIdx = tonumber(arg5);

		Item_DJS_Confirm_CancelLastOp(FrameInfoList.DJQS_CONFIRM_CHUANSONG);
		g_FrameInfo = FrameInfoList.DJQS_CONFIRM_CHUANSONG;

		Client_ItemIndex = itemIdx
		DJS_SelIndex = iSelIdx

		local str;
		local iIsLeader = Player:IsLeader()
		if (1 == iIsLeader) then
			str= "#{DJTS_110509_27}"..szSceneName.."（"..iPosX.."，"..iPosZ.."）"
		else
			str= "#{DJTS_110509_14}".."\n"..szSceneName.."（"..iPosX.."，"..iPosZ.."）"
		end

		if (szSceneName ~= "") then
			Item_DJS_Confirm_Info:SetText(str)
			Item_DJS_Confirm_UpdateRect();
			this:Show();
			return
		else
		   PushDebugMessage("#{DJTS_110509_31}")
		   this:Hide()
		   return

		end
	end
	
	if(event == "CONFIRM_CHUANSONG_DJVIP") then
        if SystemSetup:IsClassic() == 1 then
		    Item_DJS_Confirm_Title:SetProperty("Image","set:Menpaishuxing image:DunJiaShu_Title_VIP") --遁甲书VIP
        else
            Item_DJS_Confirm_Title:SetText("#{UIGZ_130816_3}") --遁甲书VIP
        end
		local itemIdx = tonumber(arg0)
		local szSceneName = tostring(arg1);
		local iSceneId = tonumber(arg2);
		local iPosX = tonumber(arg3);
		local iPosZ = tonumber(arg4);
		local iSelIdx = tonumber(arg5);
		
		Item_DJS_Confirm_CancelLastOp(FrameInfoList.DJVIP_CONFIRM_CHUANSONG);
		g_FrameInfo = FrameInfoList.DJVIP_CONFIRM_CHUANSONG;
		
		Client_ItemIndex = itemIdx
		DJS_SelIndex = iSelIdx
		
		local str;
		local iIsLeader = Player:IsLeader()
		if (1 == iIsLeader) then
			str= "#{DJTS_110509_27}"..szSceneName.."（"..iPosX.."，"..iPosZ.."）"
		else
			str= "#{DJTS_110509_14}".."\n"..szSceneName.."（"..iPosX.."，"..iPosZ.."）"
		end
		
		if (szSceneName ~= "") then
			Item_DJS_Confirm_Info:SetText(str)
			Item_DJS_Confirm_UpdateRect();
			this:Show();
			return
		else
		   PushDebugMessage("#{DJTS_110509_31}")
		   this:Hide()
		   return
		end
	end

	if(event == "CONFIRM_BUCHONG_DJTS") then
        if SystemSetup:IsClassic() == 1 then
            Item_DJS_Confirm_Title:SetProperty("Image","set:Menpaishuxing image:DunJiaShu_Title_Index")--遁甲天书
        else
            Item_DJS_Confirm_Title:SetText("#{UIGZ_130816_2}") --遁甲奇书
        end
		local itemIdx = tonumber(arg0)
		local iNum = tonumber(arg1);
    		Client_ItemIndex = itemIdx

		Item_DJS_Confirm_CancelLastOp(FrameInfoList.DJTS_CONFIRM_BUCHONG);
		g_FrameInfo = FrameInfoList.DJTS_CONFIRM_BUCHONG;

		local str;
		if (iNum>40) then
			str= "#{DJTS_110509_11}"
		else
			--str= "#{DJTS_110509_10}"
			Clear_XSCRIPT();
				Set_XSCRIPT_Function_Name("AddFuZhou");
				Set_XSCRIPT_ScriptID(330059);
				Set_XSCRIPT_Parameter(0, Client_ItemIndex)
				Set_XSCRIPT_Parameter(1, 1)
				Set_XSCRIPT_ParamCount(2);
			Send_XSCRIPT();
			return
		end

		Item_DJS_Confirm_Info:SetText(str)
		Item_DJS_Confirm_UpdateRect();
		this:Show()
		return
	end

	if(event == "CONFIRM_BUCHONG_DJQS") then
        if SystemSetup:IsClassic() == 1 then
		    Item_DJS_Confirm_Title:SetProperty("Image","set:Menpaishuxing image:DunJiaShu_Title_Monster") --遁甲奇书
        else
            Item_DJS_Confirm_Title:SetText("#{UIGZ_130816_1}") --遁甲奇书
        end
		local itemIdx = tonumber(arg0)
		local iNum = tonumber(arg1);
    		Client_ItemIndex = itemIdx

		Item_DJS_Confirm_CancelLastOp(FrameInfoList.DJQS_CONFIRM_BUCHONG);
		g_FrameInfo = FrameInfoList.DJQS_CONFIRM_BUCHONG;

		local str;
		if (iNum>10) then
			str= "#{DJTS_110509_11}"
		else
			str= "#{DJTS_110509_10}"
		end

		Item_DJS_Confirm_Info:SetText(str)
		Item_DJS_Confirm_UpdateRect()
		this:Show()
		return
	end

	-- 游戏窗口尺寸发生了变化
	if (event == "ADJEST_UI_POS" or event == "VIEW_RESOLUTION_CHANGED") then
		Item_DJS_Confirm_Frame_On_ResetPos()
		return
	end


	if event == "HIDE_ON_SCENE_TRANSED"  then
		
			this:Hide()

	end
	
	if ( event == "UI_COMMAND" ) then
		if tonumber(arg0) == 20141106 then
			 if SystemSetup:IsClassic() == 1 then
	            Item_DJS_Confirm_Title:SetProperty("Image","set:Menpaishuxing image:DunJiaShu_Title_Index")--遁甲天书
	        else
	            Item_DJS_Confirm_Title:SetText("#{UIGZ_130816_2}") --遁甲奇书
	        end

			local str
			g_msgFrameVar[1] = Get_XParam_INT(0)
			Client_ItemIndex = Get_XParam_INT(1)
			if g_msgFrameVar[1] == 1 then
				Item_DJS_Confirm_CancelLastOp(FrameInfoList.DJTS_CONFIRM_BUCHONG_YUANBAO_BIND)
				g_FrameInfo = FrameInfoList.DJTS_CONFIRM_BUCHONG_YUANBAO_BIND
				str = "#{WPKC_141107_06}"
			elseif g_msgFrameVar[1] == 2 then
				Item_DJS_Confirm_CancelLastOp(FrameInfoList.DJTS_CONFIRM_BUCHONG_YUANBAO)
				g_FrameInfo = FrameInfoList.DJTS_CONFIRM_BUCHONG_YUANBAO
				g_msgFrameVar[2] = Get_XParam_INT(2)
				g_msgFrameVar[3] = Get_XParam_INT(3)
				str = ScriptGlobal_Format("#{WPKC_141107_08}", g_msgFrameVar[2], g_msgFrameVar[3])
			elseif g_msgFrameVar[1] == 3 then
				Item_DJS_Confirm_CancelLastOp(FrameInfoList.DJTS_CONFIRM_BUCHONG_ITEM_BIND)
				g_FrameInfo = FrameInfoList.DJTS_CONFIRM_BUCHONG_ITEM_BIND
				str = "#{CDFL_20220718_01}"
			end
			Item_DJS_Confirm_Info:SetText(str)
			Item_DJS_Confirm_UpdateRect();
			this:Show()
			return
		end
	end
	
end

--===============================================
-- 点击确定（IDOK）
--===============================================
function Item_DJS_Confirm_Queding_Clicked()

	if (g_FrameInfo == FrameInfoList.DJTS_CONFIRM_SETPOS) then
		Clear_XSCRIPT();
			Set_XSCRIPT_Function_Name("SetPosition");
			Set_XSCRIPT_ScriptID(330059);
			Set_XSCRIPT_Parameter(0, Client_ItemIndex)
			Set_XSCRIPT_Parameter(1, DJS_SelIndex)
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT();
	end

	if (g_FrameInfo == FrameInfoList.DJQS_CONFIRM_SETPOS) then
		Clear_XSCRIPT();
			Set_XSCRIPT_Function_Name("SetPosition");
			Set_XSCRIPT_ScriptID(330060);
			Set_XSCRIPT_Parameter(0, Client_ItemIndex)
			Set_XSCRIPT_Parameter(1, DJS_SelIndex)
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT();
	end
	
	if (g_FrameInfo == FrameInfoList.DJVIP_CONFIRM_SETPOS) then
		Clear_XSCRIPT();
			Set_XSCRIPT_Function_Name("SetPosition");
			Set_XSCRIPT_ScriptID(330061);
			Set_XSCRIPT_Parameter(0, Client_ItemIndex)
			Set_XSCRIPT_Parameter(1, DJS_SelIndex)
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT();
	end


	if (g_FrameInfo == FrameInfoList.DJTS_CONFIRM_CHUANSONG) then

		Clear_XSCRIPT();
			Set_XSCRIPT_Function_Name("SetUISelIdx");
			Set_XSCRIPT_ScriptID(330059);
			Set_XSCRIPT_Parameter(0, Client_ItemIndex)
			Set_XSCRIPT_Parameter(1, DJS_SelIndex)
			Set_XSCRIPT_ParamCount(2);
		Send_XSCRIPT();

		PlayerPackage:UseItem(Client_ItemIndex)	--遁甲天书的默认使用逻辑为传送....

	end

	if (g_FrameInfo == FrameInfoList.DJQS_CONFIRM_CHUANSONG) then
		Clear_XSCRIPT();
			Set_XSCRIPT_Function_Name("SetUISelIdx");
			Set_XSCRIPT_ScriptID(330060);
			Set_XSCRIPT_Parameter(0, Client_ItemIndex)
			Set_XSCRIPT_Parameter(1, DJS_SelIndex)
			Set_XSCRIPT_ParamCount(2);
		Send_XSCRIPT();
		PlayerPackage:UseItem(Client_ItemIndex)	--遁甲奇书的默认使用逻辑为传送....
	end

	if (g_FrameInfo == FrameInfoList.DJVIP_CONFIRM_CHUANSONG) then
		Clear_XSCRIPT();
			Set_XSCRIPT_Function_Name("SetUISelIdx");
			Set_XSCRIPT_ScriptID(330061);
			Set_XSCRIPT_Parameter(0, Client_ItemIndex)
			Set_XSCRIPT_Parameter(1, DJS_SelIndex)
			Set_XSCRIPT_ParamCount(2);
		Send_XSCRIPT();
		PlayerPackage:UseItem(Client_ItemIndex)	--瞬影符箓的默认使用逻辑为传送....
	end
	
	if (g_FrameInfo == FrameInfoList.DJTS_CONFIRM_BUCHONG) then
		Clear_XSCRIPT();
			Set_XSCRIPT_Function_Name("AddFuZhou");
			Set_XSCRIPT_ScriptID(330059);
			Set_XSCRIPT_Parameter(0, Client_ItemIndex)
			Set_XSCRIPT_Parameter(1, 1)
			Set_XSCRIPT_ParamCount(2);
		Send_XSCRIPT();
	end

	if (g_FrameInfo == FrameInfoList.DJQS_CONFIRM_BUCHONG) then
		Clear_XSCRIPT();
			Set_XSCRIPT_Function_Name("AddFuZhou");
			Set_XSCRIPT_ScriptID(330060);
			Set_XSCRIPT_Parameter(0, Client_ItemIndex)
			Set_XSCRIPT_ParamCount(1);
		Send_XSCRIPT();
	end
	
	if (g_FrameInfo == FrameInfoList.DJTS_CONFIRM_BUCHONG_ITEM_BIND) then
		Clear_XSCRIPT();
			Set_XSCRIPT_Function_Name("AddFuZhou");
			Set_XSCRIPT_ScriptID(330059);
			Set_XSCRIPT_Parameter(0, Client_ItemIndex)
			Set_XSCRIPT_Parameter(1, 0)
			Set_XSCRIPT_ParamCount(2);
		Send_XSCRIPT();
	end
	
	if (g_FrameInfo == FrameInfoList.DJTS_CONFIRM_BUCHONG_YUANBAO_BIND) then
		Clear_XSCRIPT();
			Set_XSCRIPT_Function_Name("YuanbaoBind_AddFuZhou");
			Set_XSCRIPT_ScriptID(330059);
			Set_XSCRIPT_Parameter(0,Client_ItemIndex);
			Set_XSCRIPT_ParamCount(1);
		Send_XSCRIPT();
	end

	if (g_FrameInfo == FrameInfoList.DJTS_CONFIRM_BUCHONG_YUANBAO) then
		Clear_XSCRIPT();
			Set_XSCRIPT_Function_Name("Yuanbao_AddFuZhou");
			Set_XSCRIPT_ScriptID(330059);
			Set_XSCRIPT_Parameter(0,Client_ItemIndex);
			Set_XSCRIPT_ParamCount(1);
		Send_XSCRIPT();
	end

	this:Hide();
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function Item_DJS_Confirm_Frame_On_ResetPos()
  Item_DJS_Confirm_Frame:SetProperty("UnifiedPosition", g_Item_DJS_Confirm_Frame_UnifiedPosition);
end
