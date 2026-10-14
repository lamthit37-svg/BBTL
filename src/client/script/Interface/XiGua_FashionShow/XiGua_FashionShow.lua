
local g_XiGua_FashionShow_UnifiedPosition

local g_XiGua_FashionShow_CurItem = -1

local g_XiGua_FashionShow_ItemList ={
[1] = { id = 10126161, IsCan = 1,
		tips = {"风格1","风格2","风格3","风格4","风格5","风格6","风格7","风格8","风格9"},
		image = { 	"set:GuanShanHai17 image:EM", 
					"set:GuanShanHai17 image:GB", 
					"set:GuanShanHai18 image:GG", 
					"set:GuanShanHai18 image:MJ", 
					"set:GuanShanHai19 image:MR", 
					"set:GuanShanHai19 image:SL", 
					"set:GuanShanHai20 image:WD", 
					"set:GuanShanHai20 image:XX", 
					"set:GuanShanHai21 image:TM", 
					},
		},
[2] = { id = 10126162, IsCan = 0, 
		image = "set:GuanShanHai21 image:TS",
		},
[3] = { id = 10126163, IsCan = 0, 
		image = "set:GuanShanHai22 image:THD",
		},
[4] = { id = 10126164, IsCan = 0, 
		image = "set:GuanShanHai22 image:TL",
		},
}

local g_XiGua_FashionShow_ItemAction ={}

function XiGua_FashionShow_PreLoad()

	this:RegisterEvent("UI_COMMAND", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
	this:RegisterEvent("ADJEST_UI_POS",false)

end

function XiGua_FashionShow_OnLoad()
	
	g_XiGua_FashionShow_UnifiedPosition = XiGua_FashionShow_Frame_BK:GetProperty("UnifiedPosition")
	
	g_XiGua_FashionShow_ItemAction = { XiGua_FashionShow_Item1, XiGua_FashionShow_Item2, XiGua_FashionShow_Item3, XiGua_FashionShow_Item4 }

end

--=========
-- Event
--=========
function XiGua_FashionShow_OnEvent(event)

	if(event == "UI_COMMAND" and tonumber(arg0) == 88808204) then
		
		if this:IsVisible() then
			XiGua_FashionShow_Close()
			return
		end	

		g_XiGua_FashionShow_CurItem = -1
		
		XiGua_FashionShow_Open()
		this:Show()

	elseif event == "VIEW_RESOLUTION_CHANGED" then
	
		XiGua_FashionShow_On_ResetPos()

	elseif event == "HIDE_ON_SCENE_TRANSED" then

		XiGua_FashionShow_Close()

	elseif event == "ADJEST_UI_POS" then

		XiGua_FashionShow_On_ResetPos()
		
	end

end

--=========
-- 重置
--=========
function XiGua_FashionShow_On_ResetPos()

	XiGua_FashionShow_Frame_BK:SetProperty("UnifiedPosition", g_XiGua_FashionShow_UnifiedPosition)

end

--=========
-- 关闭
--=========
function XiGua_FashionShow_Close()

	for i = 1, table.getn(g_XiGua_FashionShow_ItemAction) do
		g_XiGua_FashionShow_ItemAction[i]:SetActionItem(-1)
	end
	
	XiGua_FashionShow_ScanChoose:ResetList()
	
	this:Hide()
end

--=========
-- 打开
--=========
function XiGua_FashionShow_Open()
	
	for i = 1, table.getn(g_XiGua_FashionShow_ItemList) do
		local theAction = DataPool:CreateActionItemForShow(g_XiGua_FashionShow_ItemList[i].id, 1)
		if theAction:GetID() ~= 0 then
			g_XiGua_FashionShow_ItemAction[i]:SetActionItem(theAction:GetID())
		end
	end
	
	-- 默认显示	
	XiGua_FashionShow_ItemClick( 1 )
	
end

--=========
-- 选择时装
--=========
function XiGua_FashionShow_ItemClick( btn )

	if g_XiGua_FashionShow_ItemList[btn] == nil then
		return
	end
	
	if g_XiGua_FashionShow_CurItem == btn then
		return
	end
	
	for i = 1, table.getn(g_XiGua_FashionShow_ItemAction) do
		if i == btn then
			g_XiGua_FashionShow_ItemAction[i]:SetPushed(1)
		else
			g_XiGua_FashionShow_ItemAction[i]:SetPushed(0)
		end
	end
	
	g_XiGua_FashionShow_CurItem = btn
	
	if g_XiGua_FashionShow_ItemList[btn].IsCan == 0 then
		XiGua_FashionShow_ScanChoose:Disable()
		XiGua_FashionShow_ScanChoose:SetText("#{MZXB_200609_101}")

		XiGua_FashionShow_Pic:SetProperty("Image", g_XiGua_FashionShow_ItemList[btn].image)
	
		XiGua_FashionShow_arrow:Show()
	else
		-- 填充
		XiGua_FashionShow_ScanChoose:Enable()
		XiGua_FashionShow_ScanChoose:ResetList()
		XiGua_FashionShow_ScanChoose:SetText("#{MZXB_200609_100}")
		for i = 1, table.getn(g_XiGua_FashionShow_ItemList[btn].image) do
			XiGua_FashionShow_ScanChoose:AddTextItem(g_XiGua_FashionShow_ItemList[btn].tips[i], i)
		end

		XiGua_FashionShow_Pic:SetProperty("Image", g_XiGua_FashionShow_ItemList[btn].image[1])
	
		XiGua_FashionShow_arrow:Hide()
	end
	
end

function XiGua_FashionShow_Changed()

	local _name, ComIdx = XiGua_FashionShow_ScanChoose:GetCurrentSelect()
	if g_XiGua_FashionShow_ItemList[g_XiGua_FashionShow_CurItem] ~= nil then
		if g_XiGua_FashionShow_ItemList[g_XiGua_FashionShow_CurItem].image[ComIdx] ~= nil then
			XiGua_FashionShow_Pic:SetProperty("Image", g_XiGua_FashionShow_ItemList[g_XiGua_FashionShow_CurItem].image[ComIdx])
		end
	end
	
end

function XiGua_FashionShow_HelpClick()

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("ShowHelpText")
		Set_XSCRIPT_ScriptID(888082)
		Set_XSCRIPT_Parameter(0, 1)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
		
end

