
local g_EquipID2Str={--menpai加个标识 防止以后漏掉
{minID=10300423,maxID=10300431,str="#{JXSQ_170823_187}",image="set:SuperWeapon9_Show image:SuperWeapon9_Show01"},--{10300423,10300424,10300425,10300426,10300427,10300428,10300429,10300430,10300431},
{minID=10301444,maxID=10301452,str="#{JXSQ_170823_188}",image="set:SuperWeapon9_Show image:SuperWeapon9_Show02"},--{10301444,10301445,10301446,10301447,10301448,10301449,10301450,10301451,10301452},
{minID=10301453,maxID=10301461,str="#{JXSQ_170823_189}",image="set:SuperWeapon9_Show image:SuperWeapon9_Show03"},--{10301453,10301454,10301455,10301456,10301457,10301458,10301459,10301460,10301461},
{minID=10302449,maxID=10302457,str="#{JXSQ_170823_190}",image="set:SuperWeapon9_Show image:SuperWeapon9_Show04"},--{10302449,10302450,10302451,10302452,10302453,10302454,10302455,10302456,10302457},
{minID=10302458,maxID=10302466,str="#{JXSQ_170823_191}",image="set:SuperWeapon9_Show image:SuperWeapon9_Show05"},--{10302458,10302459,10302460,10302461,10302462,10302463,10302464,10302465,10302466},
{minID=10303440,maxID=10303448,str="#{JXSQ_170823_192}",image="set:SuperWeapon9_Show image:SuperWeapon9_Show06"},--{10303440,10303441,10303442,10303443,10303444,10303445,10303446,10303447,10303448},
{minID=10303449,maxID=10303457,str="#{JXSQ_170823_193}",image="set:SuperWeapon9_Show image:SuperWeapon9_Show07"},--{10303449,10303450,10303451,10303452,10303453,10303454,10303455,10303456,10303457},
{minID=10304427,maxID=10304435,str="#{JXSQ_170823_194}",image="set:SuperWeapon9_Show image:SuperWeapon9_Show08"},--{10304427,10304428,10304429,10304430,10304431,10304432,10304433,10304434,10304435},
{minID=10305445,maxID=10305453,str="#{JXSQ_170823_195}",image="set:SuperWeapon9_Show image:SuperWeapon9_Show09"},--{10305445,10305446,10305447,10305448,10305449,10305450,10305451,10305452,10305453},
{minID=10305454,maxID=10305462,str="#{JXSQ_170823_196}",image="set:SuperWeapon9_Show image:SuperWeapon9_Show10"},--{10305454,10305455,10305456,10305457,10305458,10305459,10305460,10305461,10305462},
{minID=10306043,maxID=10306051,str="#{JXSQ_170823_197}",image="set:SuperWeapon9_Show image:SuperWeapon9_Show11"},--{10306043,10306044,10306045,10306046,10306047,10306048,10306049,10306050,10306051},
{minID=10307043,maxID=10307051,str="#{JXSQ_170823_198}",image="set:SuperWeapon9_Show image:SuperWeapon9_Show12"},--{10307043,10307044,10307045,10307046,10307047,10307048,10307049,10307050,10307051}
{minID=10308043,maxID=10308051,str="#{THDJQ_190809_01}",image="set:SuperWeapon9_Show image:SuperWeapon9_Show13"},--{10307043,10307044,10307045,10307046,10307047,10307048,10307049,10307050,10307051}
{minID=10316043,maxID=10316051,str="#{CRJQ_210827_01}",image="set:SuperWeapon9_Show image:SuperWeapon9_Show14"},
{minID=10317043,maxID=10317051,str="#{CRJQ_210827_01}",image="set:SuperWeapon9_Show2 image:SuperWeapon9_Show15"},--mptodo 字典
}

local g_SuperWeapon9_Show_Fram_UnifiedPosition;
local g_weaponId = 0

function SuperWeapon9_Show_PreLoad()
	this:RegisterEvent("UI_COMMAND");
	this:RegisterEvent("ADJEST_UI_POS",false);		--	
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false);	--	窗口大小变换
	this:RegisterEvent("UPDATE_FAKE_OBJECT",false)
end

function SuperWeapon9_Show_OnLoad()
	g_SuperWeapon9_Show_Fram_UnifiedPosition = SuperWeapon9_Show_Frame:GetProperty("UnifiedPosition");
end

function SuperWeapon9_Show_OnEvent(event)
	if event == "UI_COMMAND" and tonumber(arg0) == 7020063 then
		local bOpenSX=Get_XParam_INT(0);
		if bOpenSX==1 then
			SuperWeapon9_Show_CancleEvent()
			return
		end
		g_weaponId=Get_XParam_INT(1);
		SuperWeapon9_Show_UpdateModel( g_weaponId )
		this:Show()
	end
	if event == "ADJEST_UI_POS" then
		SuperWeapon9_Show_ResetWindowPos();
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		SuperWeapon9_Show_ResetWindowPos()
	elseif event == "UPDATE_FAKE_OBJECT" and arg0 == "SuperWeapon9Show" then
		SuperWeapon9_Show_UpdateModel( g_weaponId )
	end
end

function SuperWeapon9_Show_UpdateModel( itemID )
	SuperWeapon9_Show_FakeObject:SetFakeObject("");	
	local szItemName = DataPool:Lua_GetItemNameByIndex(itemID)
	SuperWeapon9_Show_DragTitle:SetText("#gFF0FA0"..szItemName)
	LifeAbility:SetSuperWeapon9NewModel(itemID)
	SuperWeapon9_Show_FakeObject:SetFakeObject("SuperWeapon9Show");	
	SuperWeapon9_Show_SetImage(itemID)
end


function SuperWeapon9_Show_SetImage(itemID)
	local nCount=table.getn(g_EquipID2Str)
	for i=1,nCount do
		if itemID>=g_EquipID2Str[i].minID and itemID<=g_EquipID2Str[i].maxID then
			SuperWeapon9_Show_Explain2:SetProperty("Image" , g_EquipID2Str[i].image)
			return
		end
	end
end

function SuperWeapon9_Show_ResetWindowPos()
	SuperWeapon9_Show_Frame:SetProperty("UnifiedPosition", g_SuperWeapon9_Show_Fram_UnifiedPosition);
end

function SuperWeapon9_Show_CancleEvent()
	SuperWeapon9_Show_FakeObject:SetFakeObject("");	
	this:Hide();
end


function SuperWeapon9_Show_TurnLeft(start)
	local mouse_button = CEArg:GetValue("MouseButton");
	if(mouse_button == "LeftButton") then
		--向左旋转开始
		if(start == 1) then
			SuperWeapon9_Show_FakeObject:RotateBegin(-0.3);
		--向左旋转结束
		else
			SuperWeapon9_Show_FakeObject:RotateEnd();
		end
	end
end

function SuperWeapon9_Show_TurnRight(start)
	local mouse_button = CEArg:GetValue("MouseButton");
	if(mouse_button == "LeftButton") then
		--向右旋转开始
		if(start == 1) then
			SuperWeapon9_Show_FakeObject:RotateBegin(0.3);
		--向右旋转结束
		else
			SuperWeapon9_Show_FakeObject:RotateEnd();
		end
	end
end
