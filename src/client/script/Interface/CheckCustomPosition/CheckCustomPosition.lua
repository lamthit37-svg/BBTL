-------------------------------------------------------
--"查看自定义帮会职位"界面脚本
--create by xindefeng
-------------------------------------------------------

local g_CustomPosition = nil	--需要用到的控件表
local g_CustomPosition_bp = nil --BanPao = 1
--标准帮会职位名称
local g_StdPositionName = {
	"帮主",			--9
	"副帮主",		--8
	"内务使",		--7
	"工务使",		--6
	"弘化使",		--5
	"商人",			--4
	"精英",			--3
	"帮众"			--2
}
--标准帮会职位名称
local g_StdPositionName_bp = {
	"帮主",			--9
	"副帮主",		--8
	"内务使",		--7
	"工务使",		--6
	"弘化使",		--5
	--"商人",			--4
	"精英",			--3
	"帮众"			--2
}
local g_NameToPosition_bp = {9,8,7,6,5,3,2} --删除“商人”职位

--事件注册
function CheckCustomPosition_PreLoad()
	this:RegisterEvent("GUILD_CHECK_CUSTOMPOSITION",true)
	this:RegisterEvent("GUILD_FORCE_CLOSE",false)	
end

function CheckCustomPosition_OnLoad()	
end

--事件响应
function CheckCustomPosition_OnEvent(event)	
	if( event == "GUILD_CHECK_CUSTOMPOSITION" ) then
		CheckCustomPosition_SetCtls()	--设置控件
				
		CheckCustomPosition_Update()
		CheckCustomPosition_Show()
	elseif( event == "GUILD_FORCE_CLOSE" ) then	
		CheckCustomPosition_Ok()
	end
end

--设置控件表
function CheckCustomPosition_SetCtls()
	g_CustomPosition = {
												CheckCustomPosition_CurPos1,
												CheckCustomPosition_CurPos2,
												CheckCustomPosition_CurPos3,
												CheckCustomPosition_CurPos4,
												CheckCustomPosition_CurPos5,
												CheckCustomPosition_CurPos6,
												CheckCustomPosition_CurPos7,
												CheckCustomPosition_CurPos8							
										}
	g_CustomPosition_bp = {
												CheckCustomPosition2_CurPos1,
												CheckCustomPosition2_CurPos2,
												CheckCustomPosition2_CurPos3,
												CheckCustomPosition2_CurPos4,
												CheckCustomPosition2_CurPos5,
												CheckCustomPosition2_CurPos6,
												CheckCustomPosition2_CurPos7,
										}
end


--刷新界面显示的数据
function CheckCustomPosition_Update()
	local szMsg = nil
	
	CheckCustomPosition_Title:SetText("#gFF0FA0自定义职位名称")
	
	if DataPool:Lua_IsPaoShangSvr() == 1 then
		--开放跑商
		CheckCustomPosition_Client:Show()
		CheckCustomPosition_Client2:Hide()
		
		--显示当前"自定义职位名称"
		for i=1,8 do
			szMsg = Guild:GetCurCustomPositionName(10-i)
			if((szMsg == "") or (szMsg == g_StdPositionName[i]))then
				szMsg = g_StdPositionName[i]			
			else
				szMsg = szMsg.."("..g_StdPositionName[i]..")"			
			end
			
			--设置当前自定义职位名称
			g_CustomPosition[i]:SetText(szMsg)
		end
	else
		--关停跑商
		CheckCustomPosition_Client:Hide()
		CheckCustomPosition_Client2:Show()
		
		--显示当前"自定义职位名称"
		for i=1,7 do
			szMsg = Guild:GetCurCustomPositionName(g_NameToPosition_bp[i])
			if((szMsg == "") or (szMsg == g_StdPositionName_bp[i]))then
				szMsg = g_StdPositionName_bp[i]			
			else
				szMsg = szMsg.."("..g_StdPositionName_bp[i]..")"			
			end
			
			--设置当前自定义职位名称
			g_CustomPosition_bp[i]:SetText(szMsg)
			
		end
	end
	
end

--打开界面
function CheckCustomPosition_Show()	
	this:Show()
end

--确定
function CheckCustomPosition_Ok()	
	--关闭窗口
	this:Hide()	
end

--Add By YuanPeiLong
function CheckCustomPosition_Cancel_Clicked()
    this:Hide();
end
