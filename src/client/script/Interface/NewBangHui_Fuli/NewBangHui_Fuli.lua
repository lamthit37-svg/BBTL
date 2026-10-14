
local g_NewBangHui_Fuli_Frame_UnifiedPosition = nil
local g_NewBangHui_Fuli_ListItemCtrl={}
local g_NewBangHui_Fuli_ListItem_Image={}
local g_NewBangHui_Fuli_ListItem_Text={}
local g_NewBangHui_Fuli_ListItem_Button={}

local g_NewBangHui_Fuli_MAX_COUNT=5

local g_NewBangHui_FuliType_GSHKiller = 2
local g_NewBangHui_FuliType_Fuben = 3

local g_NewBangHui_npcObjId = -1;
local g_NewBangHui_objCared = -1;

local g_NewBangHui_Fuli_listConfig = {
	[0] = { -- 双倍经验
		--image="set:JiuJiuXiaoHanTu_Summer01 image:JiuJiuXiaoHanTu_Summer01_1",
		fTips=nil,
		fStatusText=nil,
		fButtonText=nil,
		fButtonTips=nil,
		}
}

function NewBangHui_Fuli_PreLoad()

	this:RegisterEvent("UI_COMMAND",true);
	this:RegisterEvent("GUILD_UPDATE_FULIPOINT",true)
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	this:RegisterEvent("OBJECT_CARED_EVENT",false);

end

function NewBangHui_Fuli_OnLoad()
	
	g_NewBangHui_Fuli_Frame_UnifiedPosition = NewBangHui_Fuli_Frame:GetProperty("UnifiedPosition")
	
	g_NewBangHui_Fuli_ListItemCtrl[0] = NewBangHui_Fuli_Item1
	g_NewBangHui_Fuli_ListItemCtrl[1] = NewBangHui_Fuli_Item2
	g_NewBangHui_Fuli_ListItemCtrl[2] = NewBangHui_Fuli_Item3
	g_NewBangHui_Fuli_ListItemCtrl[3] = NewBangHui_Fuli_Item4
	g_NewBangHui_Fuli_ListItemCtrl[4] = NewBangHui_Fuli_Item5
	g_NewBangHui_Fuli_ListItemCtrl[5] = NewBangHui_Fuli_Item6
	
	g_NewBangHui_Fuli_ListItem_Image[0] = NewBangHui_Fuli_Item1_Image
	g_NewBangHui_Fuli_ListItem_Image[1] = NewBangHui_Fuli_Item2_Image
	g_NewBangHui_Fuli_ListItem_Image[2] = NewBangHui_Fuli_Item3_Image
	g_NewBangHui_Fuli_ListItem_Image[3] = NewBangHui_Fuli_Item4_Image
	g_NewBangHui_Fuli_ListItem_Image[4] = NewBangHui_Fuli_Item5_Image
	g_NewBangHui_Fuli_ListItem_Image[5] = NewBangHui_Fuli_Item6_Image
	
	g_NewBangHui_Fuli_ListItem_Text[0] = NewBangHui_Fuli_Item1_Text
	g_NewBangHui_Fuli_ListItem_Text[1] = NewBangHui_Fuli_Item2_Text
	g_NewBangHui_Fuli_ListItem_Text[2] = NewBangHui_Fuli_Item3_Text
	g_NewBangHui_Fuli_ListItem_Text[3] = NewBangHui_Fuli_Item4_Text
	g_NewBangHui_Fuli_ListItem_Text[4] = NewBangHui_Fuli_Item5_Text
	g_NewBangHui_Fuli_ListItem_Text[5] = NewBangHui_Fuli_Item6_Text
	
	g_NewBangHui_Fuli_ListItem_Button[0] = NewBangHui_Fuli_Item1_Submit
	g_NewBangHui_Fuli_ListItem_Button[1] = NewBangHui_Fuli_Item2_Submit
	g_NewBangHui_Fuli_ListItem_Button[2] = NewBangHui_Fuli_Item3_Submit
	g_NewBangHui_Fuli_ListItem_Button[3] = NewBangHui_Fuli_Item4_Submit
	g_NewBangHui_Fuli_ListItem_Button[4] = NewBangHui_Fuli_Item5_Submit
	g_NewBangHui_Fuli_ListItem_Button[5] = NewBangHui_Fuli_Item6_Submit
	
	-- 双倍经验
	g_NewBangHui_Fuli_listConfig[0] = {};
	g_NewBangHui_Fuli_listConfig[0].fTips = NewBangHui_Fuli_DE_GetIamgeTips;
	g_NewBangHui_Fuli_listConfig[0].fStatusText = NewBangHui_Fuli_DE_GetStatusText;
	g_NewBangHui_Fuli_listConfig[0].fButtonText = NewBangHui_Fuli_General_GetButtonText;
	g_NewBangHui_Fuli_listConfig[0].fButtonTips = NewBangHui_Fuli_DE_GetButtonTips;

	-- 双倍内息
	g_NewBangHui_Fuli_listConfig[1] = {};
	g_NewBangHui_Fuli_listConfig[1].fTips = NewBangHui_Fuli_DoubleNeixi_GetIamgeTips;
	g_NewBangHui_Fuli_listConfig[1].fStatusText = NewBangHui_Fuli_DoubleNeixi_GetStatusText;
	g_NewBangHui_Fuli_listConfig[1].fButtonText = NewBangHui_Fuli_General_GetButtonText;
	g_NewBangHui_Fuli_listConfig[1].fButtonTips = NewBangHui_Fuli_DoubleNeixi_GetButtonTips;
	
	-- 观山海杀手
	g_NewBangHui_Fuli_listConfig[2] = {};
	g_NewBangHui_Fuli_listConfig[2].fTips = NewBangHui_Fuli_GSHKiller_GetIamgeTips;
	g_NewBangHui_Fuli_listConfig[2].fStatusText = NewBangHui_Fuli_GSHKiller_GetStatusText;
	g_NewBangHui_Fuli_listConfig[2].fButtonText = NewBangHui_Fuli_General_GetButtonText;
	g_NewBangHui_Fuli_listConfig[2].fButtonTips = NewBangHui_Fuli_GSHKiller_GetButtonTips;
	
	-- 帮会副本
	g_NewBangHui_Fuli_listConfig[3] = {};
	g_NewBangHui_Fuli_listConfig[3].fTips = NewBangHui_Fuli_GuildFuben_GetIamgeTips;
	g_NewBangHui_Fuli_listConfig[3].fStatusText = NewBangHui_Fuli_GuildFuben_GetStatusText;
	g_NewBangHui_Fuli_listConfig[3].fButtonText = NewBangHui_Fuli_GuildFuben_GetButtonText;
	g_NewBangHui_Fuli_listConfig[3].fButtonTips = NewBangHui_Fuli_GuildFuben_GetButtonTips;
	
	-- 天外boss礼盒
	g_NewBangHui_Fuli_listConfig[4] = {};
	g_NewBangHui_Fuli_listConfig[4].fTips = NewBangHui_Fuli_Gift_GetIamgeTips;
	g_NewBangHui_Fuli_listConfig[4].fStatusText = NewBangHui_Fuli_Gift_GetStatusText;
	g_NewBangHui_Fuli_listConfig[4].fButtonText = NewBangHui_Fuli_Gift_GetButtonText;
	g_NewBangHui_Fuli_listConfig[4].fButtonTips = NewBangHui_Fuli_Gift_GetButtonTips;	
	
end

function NewBangHui_Fuli_OnEvent(event)
	if(event == "GUILD_UPDATE_FULIPOINT" ) then
		local nOpenUI = tonumber(arg0);
		
		if nOpenUI == 0 and not this:IsVisible() then
			return
		end		
				
		NewBangHui_Fuli_ShowUI();
		
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 61002001 ) then
		g_NewBangHui_npcObjId = Get_XParam_INT(0)
		g_NewBangHui_objCared = DataPool : GetNPCIDByServerID(g_NewBangHui_npcObjId)
		if g_NewBangHui_objCared == -1 then
			NewBangHui_Fuli_OnClose()
			return
		end
		this : CareObject( g_NewBangHui_objCared, 1, "NewBangHui_Fuli" )
	
	elseif (event == "ADJEST_UI_POS") then
		NewBangHui_Fuli_ResetPos()
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		NewBangHui_Fuli_ResetPos()
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		NewBangHui_Fuli_OnClose()
	elseif (event == "OBJECT_CARED_EVENT") then
		if(tonumber(arg0) ~= g_NewBangHui_objCared) then
			return;
		end
		--如果和NPC的距离大于一定距离或者被删除，自动关闭
		if(arg1 == "distance" and tonumber(arg2)>MAX_OBJ_DISTANCE or arg1=="destroy") then
			NewBangHui_Fuli_OnClose()	
		end
	end
end

function NewBangHui_Fuli_ShowUI()
	-- 当前帮会福利点
	local nFuliPoint, nLeiJiPoint = Guild:GetGuildFuliPoint();
	NewBangHui_Fuli_Currency1:SetText( ScriptGlobal_Format("#{BHFLGTMB_210714_10}", nFuliPoint) );
	
	-- 
	for i = 0, 5 do
		if g_NewBangHui_Fuli_listConfig[i] ~= nil then
			local nOpenTime, nCount, nParam, nGetTime, nRemainTime = Guild:GetGuildFuliPointInfo( i );
						
			local szText = g_NewBangHui_Fuli_listConfig[i].fTips( nOpenTime, nCount, nGetTime, nRemainTime );
			g_NewBangHui_Fuli_ListItem_Image[i]:SetToolTip( szText );
			
			local szStatusText = g_NewBangHui_Fuli_listConfig[i].fStatusText( nOpenTime, nCount, nParam, nGetTime, nRemainTime );			
			g_NewBangHui_Fuli_ListItem_Text[i]:SetText( szStatusText );
			
			-- 开启按钮
			local szBtnText, bEnable = g_NewBangHui_Fuli_listConfig[i].fButtonText( nOpenTime, nCount, nGetTime, nRemainTime );
			g_NewBangHui_Fuli_ListItem_Button[i]:SetText( szBtnText );
			
			if bEnable == 1 then
				local szBtnTips = g_NewBangHui_Fuli_listConfig[i].fButtonTips( nOpenTime, nCount, nGetTime, nRemainTime );
				g_NewBangHui_Fuli_ListItem_Button[i]:SetToolTip( szBtnTips );
				g_NewBangHui_Fuli_ListItem_Button[i]:Enable();
			else
				g_NewBangHui_Fuli_ListItem_Button[i]:Disable();
			end
				
			g_NewBangHui_Fuli_ListItemCtrl[i]:Show();
		else
			g_NewBangHui_Fuli_ListItemCtrl[i]:Hide();
		end
		
	end
	
	if Player:GetData("Is2606S") == 1 then
		NewBangHui_Fuli_Item2:Hide()
		NewBangHui_Fuli_Item3:Hide()
		NewBangHui_Fuli_Item4:Hide()
		NewBangHui_Fuli_Item5:Hide()
	else		
		NewBangHui_Fuli_Item2:Show()
		NewBangHui_Fuli_Item3:Show()
		NewBangHui_Fuli_Item4:Show()
		NewBangHui_Fuli_Item5:Show()
	end
	this:Show()
end

function NewBangHui_Fuli_ItemClicked( index )

	if index > g_NewBangHui_Fuli_MAX_COUNT then
		return
	end
	
	local nOpenTime, nCount, nParam, nGetTime, nRemainTime = Guild:GetGuildFuliPointInfo( index-1 );
	if nOpenTime == nil or nGetTime == nil then
		return
	end
	if nOpenTime <= 0 then		-- 开启
		if index-1 == g_NewBangHui_FuliType_Fuben then	-- 额外副本
			PushEvent("GUILD_FUBENSEL_OPENUI", index-1);
			
		else
			Clear_XSCRIPT()
				Set_XSCRIPT_Function_Name( "OnOpenFuli" )
				Set_XSCRIPT_ScriptID( 610020 )
				Set_XSCRIPT_Parameter(0, index-1)
				Set_XSCRIPT_Parameter(1, 0)
				Set_XSCRIPT_Parameter(2, 0)
				Set_XSCRIPT_ParamCount(3)
			Send_XSCRIPT()
		end 		
	else
		if nOpenTime > nGetTime then		-- 领取
			if index-1 == g_NewBangHui_FuliType_GSHKiller then	-- 观山海杀手
				PushEvent("GUILD_BONUSSEL_OPENUI", index-1);
			else
				Clear_XSCRIPT()
					Set_XSCRIPT_Function_Name( "OnGetFuli" )
					Set_XSCRIPT_ScriptID( 610020 )
					Set_XSCRIPT_Parameter(0, index-1)
					Set_XSCRIPT_Parameter(1, 0)
					Set_XSCRIPT_ParamCount(2)
				Send_XSCRIPT()
			end
		end
	end
end

function NewBangHui_Fuli_OnClose()
	this:Hide();
end

function NewBangHui_Fuli_OnHiden()
	--取消关心
	this:CareObject(g_NewBangHui_objCared, 0, "NewBangHui_Fuli");	
	g_NewBangHui_objCared = -1
	
	if IsWindowShow("NewBangHui_Fuben") then
		CloseWindow("NewBangHui_Fuben", true)
	end
		
	if IsWindowShow("NewBangHui_Guanshanhai") then
		CloseWindow("NewBangHui_Guanshanhai", true)
	end
	
end

function NewBangHui_Fuli_ResetPos()
	NewBangHui_Fuli_Frame:SetProperty("UnifiedPosition",g_NewBangHui_Fuli_Frame_UnifiedPosition)
end

-- 双倍经验
function NewBangHui_Fuli_DE_GetIamgeTips( nOpenTime, nCount, nGetTime, nRemainTime )
	local szText = "#{BHFLGTMB_210714_12}";
	if nOpenTime == nil or nOpenTime <= 0 then
		szText = szText.."#r".."#{BHFLGTMB_210714_14}";
	else
		if nRemainTime ~= nil and nRemainTime > 0 then
			if nRemainTime < 3600 then
				szText = szText.."#r"..ScriptGlobal_Format("#{BHFLGTMB_210714_13}", math.floor(tonumber(nRemainTime)/60));
			else
				szText = szText.."#r"..ScriptGlobal_Format("#{BHFLGTMB_210714_133}", math.floor(tonumber(nRemainTime)/3600));
			end
		end
	end 
	
	return szText
end

function NewBangHui_Fuli_DE_GetStatusText( nOpenTime, nCount, nParam, nGetTime, nRemainTime )

	local szText = ""
	if nOpenTime == nil or nOpenTime <= 0 then
		szText = "#{BHFLGTMB_210714_33}";
	else
		if nRemainTime ~= nil and nRemainTime > 0 then
			if nRemainTime < 3600 then
				szText = ScriptGlobal_Format("#{BHFLGTMB_210714_134}", math.floor(tonumber(nRemainTime)/60));
			else
				szText = ScriptGlobal_Format("#{BHFLGTMB_210714_135}", math.floor(tonumber(nRemainTime)/3600));
			end
		end
	end 
	
	return szText;
end

function NewBangHui_Fuli_General_GetButtonText( nOpenTime, nCount, nGetTime, nRemainTime )

	local szText = ""
	local bEnable = 1
	if nOpenTime == nil or nOpenTime <= 0 then
		szText = "#{BHFLGTMB_210714_15}"		-- 开启
	else
		if nOpenTime > nGetTime then
			szText = "#{BHFLGTMB_210714_17}"		-- 领取
		else
			szText = "#{BHFLGTMB_210714_20}"		-- 已领取
			bEnable = 0
		end
	end
	
	return szText, bEnable;
end

function NewBangHui_Fuli_DE_GetButtonTips( nOpenTime, nCount, nGetTime, nRemainTime )
	local szText = ""
	if nOpenTime == nil or nOpenTime <= 0 then
		szText = "#{BHFLGTMB_210714_16}"
	else
		if nOpenTime > nGetTime then
			szText = "#{BHFLGTMB_210714_19}"
		end
	end
	
	return szText;
end

-- 双倍内息
function NewBangHui_Fuli_DoubleNeixi_GetIamgeTips( nOpenTime, nCount, nGetTime, nRemainTime )
	local szText = "#{BHFLGTMB_210714_21}";
	if nOpenTime == nil or nOpenTime <= 0 then
		szText = szText.."#r".."#{BHFLGTMB_210714_23}";
	else
		if nRemainTime ~= nil and nRemainTime > 0 then
			if nRemainTime < 3600 then
				szText = szText.."#r"..ScriptGlobal_Format("#{BHFLGTMB_210714_13}", math.floor(tonumber(nRemainTime)/60));
			else
				szText = szText.."#r"..ScriptGlobal_Format("#{BHFLGTMB_210714_133}", math.floor(tonumber(nRemainTime)/3600));
			end
		end
	end 
	return szText
end

function NewBangHui_Fuli_DoubleNeixi_GetStatusText( nOpenTime, nCount, nParam, nGetTime, nRemainTime )

	local szText = ""
	if nOpenTime == nil or nOpenTime <= 0 then
		szText = "#{BHFLGTMB_210714_33}";
	else
		if nRemainTime ~= nil and nRemainTime > 0 then
			if nRemainTime < 3600 then
				szText = ScriptGlobal_Format("#{BHFLGTMB_210714_134}", math.floor(tonumber(nRemainTime)/60));
			else
				szText = ScriptGlobal_Format("#{BHFLGTMB_210714_135}", math.floor(tonumber(nRemainTime)/3600));
			end
		end
	end
	
	return szText;
end

function NewBangHui_Fuli_DoubleNeixi_GetButtonTips( nOpenTime, nCount, nGetTime, nRemainTime )
	local szText = ""
	if nOpenTime == nil or nOpenTime <= 0 then
		szText = "#{BHFLGTMB_210714_24}"
	else
		if nOpenTime > nGetTime then
			szText = "#{BHFLGTMB_210714_25}"
		end
	end
		
	return szText;
end

-- 观山海杀手
function NewBangHui_Fuli_GSHKiller_GetIamgeTips( nOpenTime, nCount, nGetTime, nRemainTime )
	local szText = "#{BHFLGTMB_210714_26}";
	if nOpenTime == nil or nOpenTime <= 0 then
		szText = szText.."#r".."#{BHFLGTMB_210714_28}";
	else
		if nRemainTime ~= nil and nRemainTime > 0 then
			if nRemainTime < 3600 then
				szText = szText.."#r"..ScriptGlobal_Format("#{BHFLGTMB_210714_13}", math.floor(tonumber(nRemainTime)/60));
			else
				szText = szText.."#r"..ScriptGlobal_Format("#{BHFLGTMB_210714_133}", math.floor(tonumber(nRemainTime)/3600));
			end
		end
	end 
	return szText
end

function NewBangHui_Fuli_GSHKiller_GetStatusText( nOpenTime, nCount, nParam, nGetTime, nRemainTime )

	local szText = ""
	if nOpenTime == nil or nOpenTime <= 0 then
		szText = "#{BHFLGTMB_210714_33}";
	else
		if nRemainTime ~= nil and nRemainTime > 0 then
			if nRemainTime < 3600 then
				szText = ScriptGlobal_Format("#{BHFLGTMB_210714_134}", math.floor(tonumber(nRemainTime)/60));
			else
				szText = ScriptGlobal_Format("#{BHFLGTMB_210714_135}", math.floor(tonumber(nRemainTime)/3600));
			end
		end
	end
	
	return szText;
end

function NewBangHui_Fuli_GSHKiller_GetButtonTips( nOpenTime, nCount, nGetTime, nRemainTime )
	local szText = ""
	if nOpenTime == nil or nOpenTime <= 0 then
		szText = "#{BHFLGTMB_210714_29}"
	else
		if nOpenTime > nGetTime then
			szText = "#{BHFLGTMB_210714_30}"
		end
	end
		
	return szText;
end

-- 帮会副本
function NewBangHui_Fuli_GuildFuben_GetIamgeTips()
	local szText = "";
	szText = "#{BHFLGTMB_210714_116}";
	return szText
end

function NewBangHui_Fuli_GuildFuben_GetStatusText( nOpenTime, nCount, nParam, nGetTime, nRemainTime )

	local szText = ""
	if nOpenTime == nil or nOpenTime <= 0 then
		szText = "#{BHFLGTMB_210714_33}";
	else
		if nParam == 1 then
			szText = ScriptGlobal_Format("#{BHFLGTMB_210714_117}", "#{BHFLGTMB_210714_118}");
		elseif nParam == 2 then
			szText = ScriptGlobal_Format("#{BHFLGTMB_210714_117}", "#{BHFLGTMB_210714_119}");
		elseif nParam == 3 then
			szText = ScriptGlobal_Format("#{BHFLGTMB_210714_117}", "#{BHFLGTMB_210714_120}");
		end
	end
	
	return szText;
end

function NewBangHui_Fuli_GuildFuben_GetButtonText( nOpenTime, nCount, nGetTime, nRemainTime )
	local szText = ""
	local bEnable = 0
	if nOpenTime == nil or nOpenTime <= 0 then
		szText = "#{BHFLGTMB_210714_15}"		-- 开启
		bEnable = 1
	else
		szText = "#{BHFLGTMB_210714_18}"		-- 已开启
		bEnable = 0
	end
	
	return szText, bEnable;
end

function NewBangHui_Fuli_GuildFuben_GetButtonTips()
	local szText = ""
	szText = "#{BHFLGTMB_210714_121}"		-- 开启
	
	return szText;
end

-- 帮会礼包
function NewBangHui_Fuli_Gift_GetIamgeTips()
	local szText = "";
	szText = "#{BHFLGTMB_210714_125}";
	return szText
end

function NewBangHui_Fuli_Gift_GetStatusText( nOpenTime, nCount, nParam, nGetTime, nRemainTime )

	local szText = ""
	if nOpenTime == nil or nOpenTime <= 0 then
		szText = "#{BHFLGTMB_210714_33}";
	else
		szText = "#{BHFLGTMB_210714_18}";
	end
	
	return szText;
end

function NewBangHui_Fuli_Gift_GetButtonText( nOpenTime, nCount, nGetTime, nRemainTime )
	local szText = ""
	local bEnable = 0
	if nOpenTime == nil or nOpenTime <= 0 then
		szText = "#{BHFLGTMB_210714_15}"		-- 开启
		bEnable = 1
	else
		szText = "#{BHFLGTMB_210714_18}"		-- 已开启
		bEnable = 0
	end
	
	return szText, bEnable;
end

function NewBangHui_Fuli_Gift_GetButtonTips()
	local szText = ""
	szText = "#{BHFLGTMB_210714_126}"
		
	return szText;
end

