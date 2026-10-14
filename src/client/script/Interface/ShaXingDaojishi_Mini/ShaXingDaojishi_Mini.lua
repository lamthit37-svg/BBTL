--******************************************
--新杀星副本	玩家积分界面mini
--create by  limengyue 
--2022-07-29
--******************************************

local g_ShaXingDaojishi_SelectBossIdx = -1	--当前boss索引

--=========================================================
--PreLoad
--=========================================================
function ShaXingDaojishi_Mini_PreLoad()
	this:RegisterEvent("XINSHAXING_MINI");
	this:RegisterEvent("SCENE_TRANSED");
	this:RegisterEvent("PLAYER_LEAVE_WORLD");
end

--=========================================================
--OnLoad
--=========================================================
function ShaXingDaojishi_Mini_OnLoad()
end

--=========================================================
--事件
--=========================================================
function ShaXingDaojishi_Mini_OnEvent(event)
	if (event=="SCENE_TRANSED") then
		this:Hide()
	elseif (event=="PLAYER_LEAVE_WORLD") then
		if( this:IsVisible() ) then
			this:Hide()
		end
	elseif (event=="XINSHAXING_MINI") then
		
		if arg0=="0" then
			ShaXingDaojishi_Mini_Show(tonumber(arg1))
		else
			this:Hide()
		end
		
	end
end

--=========================================================
--事件
--=========================================================
function ShaXingDaojishi_Mini_Show(nSelectBossIdx)
	this:Show()
	g_ShaXingDaojishi_SelectBossIdx = nSelectBossIdx
	local MsgText = "一"
	if nSelectBossIdx == 2 then
		MsgText = "二"
	elseif nSelectBossIdx == 3 then
		MsgText = "三"
	elseif nSelectBossIdx == 4 then
		MsgText = "四"
	end
	ShaXingDaojishi_Mini_PageHeader:SetText( ScriptGlobal_Format("#{XSX_220705_111}", MsgText) )
end


--=========================================================
--事件
--=========================================================
function ShaXingDaojishi_Mini_Open()
	this:Hide()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "UpdateCurPageMyself" )
		Set_XSCRIPT_ScriptID( 893471)	
		Set_XSCRIPT_Parameter( 0 ,g_ShaXingDaojishi_SelectBossIdx)
		Set_XSCRIPT_ParamCount( 1 )
	Send_XSCRIPT()
end

