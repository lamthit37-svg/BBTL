local TBL_TextFrame = {}
local TBL_NotChat_Button = {}
local TBL_Chat_Button = {}

local AcceArryEx = 10   --自定义快捷键数组中前11个元素不允许玩家自定义

local ControlMaxNum = 64

local PageStart = 0
local PageEnd = 0

local AcceSeting = 0   --快捷键设置中
--===============================================
-- OnLoad()
--===============================================
function AcceSetup_PreLoad()

	this:RegisterEvent("TOGLE_INPUTSETUP",true);

	this:RegisterEvent("TOGLE_SYSTEMFRAME",false);
	this:RegisterEvent("TOGLE_SOUNDSETUP",false);
	this:RegisterEvent("TOGLE_VIEWSETUP",false);
	this:RegisterEvent("TOGLE_GAMESETUP",false);

	this:RegisterEvent("CHANGE_ACCE_SETUP",false);
	this:RegisterEvent("CLOSE_SETUP_WINDOW",false);
end

function AcceSetup_OnLoad()
--	GameSetup_ChatBkg_Slider:SetProperty( "DocumentSize","1" );
--	GameSetup_ChatBkg_Slider:SetProperty( "PageSize","0.1" );
--	GameSetup_ChatBkg_Slider:SetProperty( "StepSize","0.1" );

--初始化图片表
TBL_TextFrame[1] = AcceSetup_List_Name1;
TBL_TextFrame[2] = AcceSetup_List_Name2;
TBL_TextFrame[3] = AcceSetup_List_Name3;
TBL_TextFrame[4] = AcceSetup_List_Name4;
TBL_TextFrame[5] = AcceSetup_List_Name5;
TBL_TextFrame[6] = AcceSetup_List_Name6;
TBL_TextFrame[7] = AcceSetup_List_Name7;
TBL_TextFrame[8] = AcceSetup_List_Name8;
TBL_TextFrame[9] = AcceSetup_List_Name9;
TBL_TextFrame[10] = AcceSetup_List_Name10;
TBL_TextFrame[11] = AcceSetup_List_Name11;
TBL_TextFrame[12] = AcceSetup_List_Name12;
TBL_TextFrame[13] = AcceSetup_List_Name13;
TBL_TextFrame[14] = AcceSetup_List_Name14;
TBL_TextFrame[15] = AcceSetup_List_Name15;
TBL_TextFrame[16] = AcceSetup_List_Name16;
TBL_TextFrame[17] = AcceSetup_List_Name17;
TBL_TextFrame[18] = AcceSetup_List_Name18;
TBL_TextFrame[19] = AcceSetup_List_Name19;
TBL_TextFrame[20] = AcceSetup_List_Name20;
TBL_TextFrame[21] = AcceSetup_List_Name55;			--上方快捷栏
TBL_TextFrame[22] = AcceSetup_List_Name56;
TBL_TextFrame[23] = AcceSetup_List_Name57;
TBL_TextFrame[24] = AcceSetup_List_Name58;
TBL_TextFrame[25] = AcceSetup_List_Name59;
TBL_TextFrame[26] = AcceSetup_List_Name60;
TBL_TextFrame[27] = AcceSetup_List_Name61;
TBL_TextFrame[28] = AcceSetup_List_Name62;
TBL_TextFrame[29] = AcceSetup_List_Name63;
TBL_TextFrame[30] = AcceSetup_List_Name64;
TBL_TextFrame[31] = AcceSetup_List_Name21;
TBL_TextFrame[32] = AcceSetup_List_Name22;
TBL_TextFrame[33] = AcceSetup_List_Name23;
TBL_TextFrame[34] = AcceSetup_List_Name24;
TBL_TextFrame[35] = AcceSetup_List_Name25;
TBL_TextFrame[36] = AcceSetup_List_Name26;
TBL_TextFrame[37] = AcceSetup_List_Name27;
TBL_TextFrame[38] = AcceSetup_List_Name28;
TBL_TextFrame[39] = AcceSetup_List_Name29;
TBL_TextFrame[40] = AcceSetup_List_Name30;
TBL_TextFrame[41] = AcceSetup_List_Name31;
TBL_TextFrame[42] = AcceSetup_List_Name32;
TBL_TextFrame[43] = AcceSetup_List_Name33;
TBL_TextFrame[44] = AcceSetup_List_Name34;
TBL_TextFrame[45] = AcceSetup_List_Name35;
TBL_TextFrame[46] = AcceSetup_List_Name36;
TBL_TextFrame[47] = nil--AcceSetup_List_Name37;
TBL_TextFrame[48] = AcceSetup_List_Name38;
TBL_TextFrame[49] = AcceSetup_List_Name39;
TBL_TextFrame[50] = AcceSetup_List_Name40;
TBL_TextFrame[51] = AcceSetup_List_Name41;
TBL_TextFrame[52] = AcceSetup_List_Name42;
TBL_TextFrame[53] = AcceSetup_List_Name43;
TBL_TextFrame[54] = AcceSetup_List_Name44;
TBL_TextFrame[55] = nil--AcceSetup_List_Name45;
TBL_TextFrame[56] = nil--AcceSetup_List_Name46;
TBL_TextFrame[57] = AcceSetup_List_Name47;
TBL_TextFrame[58] = AcceSetup_List_Name48;
TBL_TextFrame[59] = AcceSetup_List_Name49;
TBL_TextFrame[60] = AcceSetup_List_Name50;
TBL_TextFrame[61] = AcceSetup_List_Name51;
TBL_TextFrame[62] = AcceSetup_List_Name52;
TBL_TextFrame[63] = AcceSetup_List_Name53;
TBL_TextFrame[64] = nil;

--初始NotChat_Button表
TBL_NotChat_Button[1] = AcceSetup_NotChat_Button1;
TBL_NotChat_Button[2] = AcceSetup_NotChat_Button2;
TBL_NotChat_Button[3] = AcceSetup_NotChat_Button3;
TBL_NotChat_Button[4] = AcceSetup_NotChat_Button4;
TBL_NotChat_Button[5] = AcceSetup_NotChat_Button5;
TBL_NotChat_Button[6] = AcceSetup_NotChat_Button6;
TBL_NotChat_Button[7] = AcceSetup_NotChat_Button7;
TBL_NotChat_Button[8] = AcceSetup_NotChat_Button8;
TBL_NotChat_Button[9] = AcceSetup_NotChat_Button9;
TBL_NotChat_Button[10] = AcceSetup_NotChat_Button10;
TBL_NotChat_Button[11] = AcceSetup_NotChat_Button11;
TBL_NotChat_Button[12] = AcceSetup_NotChat_Button12;
TBL_NotChat_Button[13] = AcceSetup_NotChat_Button13;
TBL_NotChat_Button[14] = AcceSetup_NotChat_Button14;
TBL_NotChat_Button[15] = AcceSetup_NotChat_Button15;
TBL_NotChat_Button[16] = AcceSetup_NotChat_Button16;
TBL_NotChat_Button[17] = AcceSetup_NotChat_Button17;
TBL_NotChat_Button[18] = AcceSetup_NotChat_Button18;
TBL_NotChat_Button[19] = AcceSetup_NotChat_Button19;
TBL_NotChat_Button[20] = AcceSetup_NotChat_Button20;
TBL_NotChat_Button[21] = AcceSetup_NotChat_Button55;			--上方快捷栏
TBL_NotChat_Button[22] = AcceSetup_NotChat_Button56;
TBL_NotChat_Button[23] = AcceSetup_NotChat_Button57;
TBL_NotChat_Button[24] = AcceSetup_NotChat_Button58;
TBL_NotChat_Button[25] = AcceSetup_NotChat_Button59;
TBL_NotChat_Button[26] = AcceSetup_NotChat_Button60;
TBL_NotChat_Button[27] = AcceSetup_NotChat_Button61;
TBL_NotChat_Button[28] = AcceSetup_NotChat_Button62;
TBL_NotChat_Button[29] = AcceSetup_NotChat_Button63;
TBL_NotChat_Button[30] = AcceSetup_NotChat_Button64;
TBL_NotChat_Button[31] = AcceSetup_NotChat_Button21;
TBL_NotChat_Button[32] = AcceSetup_NotChat_Button22;
TBL_NotChat_Button[33] = AcceSetup_NotChat_Button23;
TBL_NotChat_Button[34] = AcceSetup_NotChat_Button24;
TBL_NotChat_Button[35] = AcceSetup_NotChat_Button25;
TBL_NotChat_Button[36] = AcceSetup_NotChat_Button26;
TBL_NotChat_Button[37] = AcceSetup_NotChat_Button27;
TBL_NotChat_Button[38] = AcceSetup_NotChat_Button28;
TBL_NotChat_Button[39] = AcceSetup_NotChat_Button29;
TBL_NotChat_Button[40] = AcceSetup_NotChat_Button30;
TBL_NotChat_Button[41] = AcceSetup_NotChat_Button31;
TBL_NotChat_Button[42] = AcceSetup_NotChat_Button32;
TBL_NotChat_Button[43] = AcceSetup_NotChat_Button33;
TBL_NotChat_Button[44] = AcceSetup_NotChat_Button34;
TBL_NotChat_Button[45] = AcceSetup_NotChat_Button35;
TBL_NotChat_Button[46] = AcceSetup_NotChat_Button36;
TBL_NotChat_Button[47] = nil;--AcceSetup_NotChat_Button37;原H快捷键用以打开帮助窗口
TBL_NotChat_Button[48] = AcceSetup_NotChat_Button38;
TBL_NotChat_Button[49] = AcceSetup_NotChat_Button39;
TBL_NotChat_Button[50] = AcceSetup_NotChat_Button40;
TBL_NotChat_Button[51] = AcceSetup_NotChat_Button41;
TBL_NotChat_Button[52] = AcceSetup_NotChat_Button42;
TBL_NotChat_Button[53] = AcceSetup_NotChat_Button43;
TBL_NotChat_Button[54] = AcceSetup_NotChat_Button44;
TBL_NotChat_Button[55] = nil--AcceSetup_NotChat_Button45;
TBL_NotChat_Button[56] = nil--AcceSetup_NotChat_Button46;
TBL_NotChat_Button[57] = AcceSetup_NotChat_Button47;
TBL_NotChat_Button[58] = AcceSetup_NotChat_Button48;
TBL_NotChat_Button[59] = AcceSetup_NotChat_Button49;
TBL_NotChat_Button[60] = AcceSetup_NotChat_Button50;
TBL_NotChat_Button[61] = AcceSetup_NotChat_Button51;
TBL_NotChat_Button[62] = AcceSetup_NotChat_Button52;
TBL_NotChat_Button[63] = AcceSetup_NotChat_Button53;
TBL_NotChat_Button[64] = nil;


--初始TBL_Chat_Button表
TBL_Chat_Button[1] = AcceSetup_Chat_Button1;
TBL_Chat_Button[2] = AcceSetup_Chat_Button2;
TBL_Chat_Button[3] = AcceSetup_Chat_Button3;
TBL_Chat_Button[4] = AcceSetup_Chat_Button4;
TBL_Chat_Button[5] = AcceSetup_Chat_Button5;
TBL_Chat_Button[6] = AcceSetup_Chat_Button6;
TBL_Chat_Button[7] = AcceSetup_Chat_Button7;
TBL_Chat_Button[8] = AcceSetup_Chat_Button8;
TBL_Chat_Button[9] = AcceSetup_Chat_Button9;
TBL_Chat_Button[10] = AcceSetup_Chat_Button10;
TBL_Chat_Button[11] = AcceSetup_Chat_Button11;
TBL_Chat_Button[12] = AcceSetup_Chat_Button12;
TBL_Chat_Button[13] = AcceSetup_Chat_Button13;
TBL_Chat_Button[14] = AcceSetup_Chat_Button14;
TBL_Chat_Button[15] = AcceSetup_Chat_Button15;
TBL_Chat_Button[16] = AcceSetup_Chat_Button16;
TBL_Chat_Button[17] = AcceSetup_Chat_Button17;
TBL_Chat_Button[18] = AcceSetup_Chat_Button18;
TBL_Chat_Button[19] = AcceSetup_Chat_Button19;
TBL_Chat_Button[20] = AcceSetup_Chat_Button20;
TBL_Chat_Button[21] = AcceSetup_Chat_Button55;		--上方快捷栏
TBL_Chat_Button[22] = AcceSetup_Chat_Button56;
TBL_Chat_Button[23] = AcceSetup_Chat_Button57;
TBL_Chat_Button[24] = AcceSetup_Chat_Button58;
TBL_Chat_Button[25] = AcceSetup_Chat_Button59;
TBL_Chat_Button[26] = AcceSetup_Chat_Button60;
TBL_Chat_Button[27] = AcceSetup_Chat_Button61;
TBL_Chat_Button[28] = AcceSetup_Chat_Button62;
TBL_Chat_Button[29] = AcceSetup_Chat_Button63;
TBL_Chat_Button[30] = AcceSetup_Chat_Button64;

TBL_Chat_Button[31] = AcceSetup_Chat_Button21;
TBL_Chat_Button[32] = AcceSetup_Chat_Button22;
TBL_Chat_Button[33] = AcceSetup_Chat_Button23;
TBL_Chat_Button[34] = AcceSetup_Chat_Button24;
TBL_Chat_Button[35] = AcceSetup_Chat_Button25;
TBL_Chat_Button[36] = AcceSetup_Chat_Button26;
TBL_Chat_Button[37] = AcceSetup_Chat_Button27;
TBL_Chat_Button[38] = AcceSetup_Chat_Button28;
TBL_Chat_Button[39] = AcceSetup_Chat_Button29;
TBL_Chat_Button[40] = AcceSetup_Chat_Button30;
TBL_Chat_Button[41] = AcceSetup_Chat_Button31;
TBL_Chat_Button[42] = AcceSetup_Chat_Button32;
TBL_Chat_Button[43] = AcceSetup_Chat_Button33;
TBL_Chat_Button[44] = AcceSetup_Chat_Button34;
TBL_Chat_Button[45] = AcceSetup_Chat_Button35;
TBL_Chat_Button[46] = AcceSetup_Chat_Button36;
TBL_Chat_Button[47] = nil;--AcceSetup_Chat_Button37;原H快捷键用以打开帮助窗口
TBL_Chat_Button[48] = AcceSetup_Chat_Button38;
TBL_Chat_Button[49] = AcceSetup_Chat_Button39;
TBL_Chat_Button[50] = AcceSetup_Chat_Button40;
TBL_Chat_Button[51] = AcceSetup_Chat_Button41;
TBL_Chat_Button[52] = AcceSetup_Chat_Button42;
TBL_Chat_Button[53] = AcceSetup_Chat_Button43;
TBL_Chat_Button[54] = AcceSetup_Chat_Button44;
TBL_Chat_Button[55] = nil--AcceSetup_Chat_Button45;
TBL_Chat_Button[56] = nil--AcceSetup_Chat_Button46;
TBL_Chat_Button[57] = AcceSetup_Chat_Button47;
TBL_Chat_Button[58] = AcceSetup_Chat_Button48;
TBL_Chat_Button[59] = AcceSetup_Chat_Button49;
TBL_Chat_Button[60] = AcceSetup_Chat_Button50;
TBL_Chat_Button[61] = AcceSetup_Chat_Button51;
TBL_Chat_Button[62] = AcceSetup_Chat_Button52;
TBL_Chat_Button[63] = AcceSetup_Chat_Button53;
TBL_Chat_Button[64] = nil;


--隐藏不需要的部分
for i = 11,ControlMaxNum do
  if(TBL_TextFrame[i] ~= nil and TBL_NotChat_Button[i] ~= nil and TBL_Chat_Button[i] ~= nil) then
    TBL_TextFrame[i]:Hide()
    TBL_NotChat_Button[i]:Hide()
    TBL_Chat_Button[i]:Hide()
  end
end

PageStart = 1;
PageEnd = PageStart + 10
end

--===============================================
-- OnEvent()
--===============================================
function AcceSetup_OnEvent(event)

	if ( event == "TOGLE_INPUTSETUP" ) then
		if(arg0 == "show") then -- 打开消息
			local setupUnionPos = Variable:GetVariable("SetupUnionPos");
			if(setupUnionPos ~= nil) then
				AcceSetup_Frame:SetProperty("UnifiedPosition", setupUnionPos);
			end

            --- 每次打开该界面，都先对当前快捷键设置进行一下备份
	        SystemSetup:SaveCurAcceCustom()

			AcceSetup_MenuButtons_Reset()
			this:Show();		
			AcceSetup_UpdateFrame();
            
            --- 设置没有修改任何数据
            AcceSetup_Set_Setup_UnChanged()
		else -- 字符消息
			--计算控件位置。。。
			local  index = 0
			if(tonumber(arg2) <= 20 ) then
				index = tonumber(arg2)
			elseif(tonumber(arg2) >= 21 and tonumber(arg2) <= 54 ) then
				index = tonumber(arg2) + 10
			elseif(tonumber(arg2) >= 105 and tonumber(arg2) <= 114) then
				index = tonumber(arg2) - 84
			else
				return
			end
			if (tostring( arg0 ) == "") then
				TBL_NotChat_Button[index]:SetProperty("Text", "无");
			else
				TBL_NotChat_Button[index]:SetProperty("Text", tostring( arg0 ));
			end
	    
			if (tostring( arg1 ) == "") then
				TBL_Chat_Button[index]:SetProperty("Text", "无");
			else
				TBL_Chat_Button[index]:SetProperty("Text", tostring( arg1 ));
			end
			AcceSeting = 0;
            AcceSetup_Set_Setup_Changed()
		--SystemSetup:InputSetup_OnOff(false,false,0);
		end
	elseif(event == "TOGLE_GAMESETUP" ) then
		this:Hide();
	elseif(event == "TOGLE_SYSTEMFRAME" ) then
		this:Hide();
	elseif(event == "TOGLE_SOUNDSETUP" ) then
		this:Hide();
	elseif(event == "TOGLE_VIEWSETUP" ) then
		this:Hide();
    elseif event == "CHANGE_ACCE_SETUP" then
        if ( tonumber(arg0) == 0 ) then
            AcceSetup_YingYong_Clicked()
        else
            AcceSetup_Retrieve_Setup()
        end
    elseif event == "CLOSE_SETUP_WINDOW" then
        this:Hide()
	end

end


--===============================================
-- UpdateFrame()
--===============================================
function AcceSetup_UpdateFrame()

   local key1,key2

   for i = 1,ControlMaxNum do
     if(TBL_TextFrame[i] ~= nil and TBL_NotChat_Button[i] ~= nil and TBL_Chat_Button[i] ~= nil) then
		if( i >= 21 and i <= 30) then
			key1,key2 = SystemSetup:GetInputSetup(i + AcceArryEx + 41);
		elseif( i >= 31) then
			key1,key2 = SystemSetup:GetInputSetup(i + AcceArryEx - 10);
		else
			key1,key2 = SystemSetup:GetInputSetup(i + AcceArryEx);
		end
        if(key1 == "") then
          TBL_NotChat_Button[i]:SetProperty("Text", "无");
        else
          TBL_NotChat_Button[i]:SetProperty("Text", key1);
        end
      
        if(key2 == "") then
          TBL_Chat_Button[i]:SetProperty("Text", "无");
        else
          TBL_Chat_Button[i]:SetProperty("Text", key2);   
        end
      end
   end
end

--===============================================
-- IDOK()
--===============================================
function AcceSetup_Accept_Clicked()
    if 1 == SystemSetup:GetIsConfigChanged( ) then
        PushDebugMessage( "#{XTSZYH_111220_10}" )
    end

  if(AcceSeting == 1) then
     PushDebugMessage("操作失败，请先完成当前激活快捷键的定义后再进行其他操作");
     return;
  end
  --应用新的快捷键设置
	SystemSetup:UseAcceCustomKey();
	this:Hide();
end

--===============================================
-- IDCONCLE
--===============================================
function AcceSetup_Cancel_Clicked()
    SystemSetup:InputSetupSwitch(false)
	AcceSeting = 0;
    if 1 == SystemSetup:GetIsConfigChanged() then
        PushEvent( "CONFIRM_SAVE_GAME_SETUP", 3, -1, "#{XTSZYH_111220_06}" )
    else
    	this:Hide();
    end
end

function AcceSetup_Cancel_Clicked2()
    SystemSetup:InputSetupSwitch(false)
	AcceSeting = 0;
   	this:Hide();
end


function AcceSetup_shangyiye_Clicked()
    if(AcceSeting == 1) then
     PushDebugMessage("操作失败，请先完成当前激活快捷键的定义后再进行其他操作");
     return;
    end
    
    PageChange(0)
end

function AcceSetup_xiayiye_Clicked()
    if(AcceSeting == 1) then
     PushDebugMessage("操作失败，请先完成当前激活快捷键的定义后再进行其他操作");
     return;
    end
    
    PageChange(1)
end

--=====================================================================================
--修改快捷键自定义设置中翻页相关的逻辑时要十分的小心，翻页的逻辑以10项为一页
--但是，在实际页面布局的ＸＭＬ代码中，去掉了好几项曾经使用的快捷键(控件索引分别为37、45、46）
--这就导致了两个页面的控件索引不是连续的10个，相应的保存控件名数组项也不是连续的10个，
--而是大于10个，这就是在翻页处理函数PageChange()中为什么有一些很奇怪的判断和处理的原因。废弃的
--控件为什么不删除，而只是在页面中设置为不可见而且还在保存数组中占位的原因是，快捷键的定义
--是通过C++代码在客户端读取的，读取的时候根据的是快捷键在表中注册的位置索引，如果不占位，那么
--需要修改整张的快捷键注册表格，否则会导致读取时错位。而且，这界面上的控件索引顺序和页面顺序
--也是不一致的
--Add By Wang Jian 2013.08.07
--===========================================================================================
function PageChange(type)

    if(type == 0) then  --上一页 
      if((PageStart - 10) < 1) then--检验是否越界
         return
      elseif((PageStart - 10) < 11) then
         AcceSetup_shangyiye:SetProperty("Disabled", "True");
      end
      PageStart = PageStart - 10;  
      --恢复下一页按钮的可用性 
      AcceSetup_xiayiye:SetProperty("Disabled", "False");
    elseif(type == 1) then  --下一页
      if((PageStart + 10) > 63) then--检验是否越界
         return
      elseif((PageStart + 10) > 50) then
         AcceSetup_xiayiye:SetProperty("Disabled", "True");
      end
      PageStart = PageStart + 10; 
      --恢复上一页按钮的可用性 
      AcceSetup_shangyiye:SetProperty("Disabled", "False");     
    end
    
    PageEnd = PageStart + 10
    
	local RealPageStart = PageStart
	local RealPageEnd = PageEnd

	if ( PageEnd >= 50 and PageEnd < 60 ) then
		RealPageEnd = PageEnd + 1
	end

	if( PageStart >= 50 and PageStart < 60 ) then
		RealPageStart = PageStart + 1
	end



	if PageStart >= 60 then
		RealPageStart = PageStart + 3
	end

	if PageEnd >= 60 then
    	RealPageEnd = PageEnd + 3
    end
    
    for i = 1,ControlMaxNum do
      if(i >= RealPageStart and i < RealPageEnd) then   --在该页范围内的控件显示否则隐藏
         if(TBL_TextFrame[i] ~= nil and TBL_NotChat_Button[i] ~= nil and TBL_Chat_Button[i] ~= nil) then
          TBL_TextFrame[i]:Show()
          TBL_NotChat_Button[i]:Show()
          TBL_Chat_Button[i]:Show()
         end
      else
          if(TBL_TextFrame[i] ~= nil and TBL_NotChat_Button[i] ~= nil and TBL_Chat_Button[i] ~= nil) then
            TBL_TextFrame[i]:Hide()
            TBL_NotChat_Button[i]:Hide()
            TBL_Chat_Button[i]:Hide()
          end
      end
    end
end

function Chat_Button_Clicked(ButtonId)
    if(AcceSeting == 1) then
     PushDebugMessage("操作失败，请先完成当前激活快捷键的定义后再进行其他操作");
     return;
    end

	--进入设置快捷键状态
   if(ButtonId >= 55) then
		SystemSetup:InputSetup_OnOff(true,true,ButtonId + 50);
		TBL_Chat_Button[ButtonId - 34]:SetText("#G请输入");
	elseif( ButtonId >= 21 and ButtonId <= 54 ) then
		SystemSetup:InputSetup_OnOff(true,true,ButtonId);
		TBL_Chat_Button[ButtonId + 10]:SetText("#G请输入");
	else
		SystemSetup:InputSetup_OnOff(true,true,ButtonId);
		TBL_Chat_Button[ButtonId]:SetText("#G请输入");
	end
	
    AcceSeting = 1;
end

function NoChat_Button_Clicked(ButtonId)

   if(AcceSeting == 1) then
     PushDebugMessage("操作失败，请先完成当前激活快捷键的定义后再进行其他操作");
     return;
   end
   
   --进入设置快捷键状态
   if(ButtonId >= 55) then
		SystemSetup:InputSetup_OnOff(true,false,ButtonId + 50);
		TBL_NotChat_Button[ButtonId - 34]:SetText("#G请输入");
	elseif( ButtonId >= 21 and ButtonId <= 54 ) then
		SystemSetup:InputSetup_OnOff(true,false,ButtonId);
		TBL_NotChat_Button[ButtonId + 10]:SetText("#G请输入");
	else
		SystemSetup:InputSetup_OnOff(true,false,ButtonId);
		TBL_NotChat_Button[ButtonId]:SetText("#G请输入");
	end
	
   AcceSeting = 1;
end

--恢复快捷键默认设置
function AcceSetup_Default_Clicked()

   if(AcceSeting == 1) then
     PushDebugMessage("操作失败，请先完成当前激活快捷键的定义后再进行其他操作");
     return;
   end
   --进入设置快捷键状态
   SystemSetup:ComeBackAcce();
   AcceSetup_UpdateFrame();
   
   PushDebugMessage("恢复成功！您的键位已经恢复为默认设置。");
   	
    AcceSetup_Set_Setup_Changed()
end


function AcceSetup_ViewSetup_Clicked()
	Variable:SetVariable("SetupUnionPos", AcceSetup_Frame:GetProperty("UnifiedPosition"), 1);
    if 1 == SystemSetup:GetIsConfigChanged() then
        PushEvent( "CONFIRM_SAVE_GAME_SETUP", 3, 0, "#{XTSZYH_111220_06}" )
    else
        SystemSetup:ViewSetup();
    end
end

function AcceSetup_SoundSetup_Clicked()
	Variable:SetVariable("SetupUnionPos", AcceSetup_Frame:GetProperty("UnifiedPosition"), 1);
    if 1 == SystemSetup:GetIsConfigChanged() then
        PushEvent( "CONFIRM_SAVE_GAME_SETUP", 3, 1, "#{XTSZYH_111220_06}" )
    else
        SystemSetup:SoundSetup()
    end
end

function AcceSetup_GameSetup_Clicked()
	Variable:SetVariable("SetupUnionPos", AcceSetup_Frame:GetProperty("UnifiedPosition"), 1);
    if 1 == SystemSetup:GetIsConfigChanged() then
        PushEvent( "CONFIRM_SAVE_GAME_SETUP", 3, 2, "#{XTSZYH_111220_06}" )
    else
	    SystemSetup:GameSetup()
    end
end

function AcceSetup_AcceSetup_Clicked()
	
end

function AcceSetup_MenuButtons_Reset()
	AcceSetup_MenuBox_ViewSetup	:SetCheck(0)
	AcceSetup_MenuBox_SoundSetup:SetCheck(0)
	AcceSetup_MenuBox_GameSetup	:SetCheck(0)
	AcceSetup_MenuBox_AcceSetup	:SetCheck(1)
end

--- 应用按钮走和确定按钮一样的逻辑就好了。
function AcceSetup_YingYong_Clicked()
	if(AcceSeting == 1) then
	     PushDebugMessage("操作失败，请先完成当前激活快捷键的定义后再进行其他操作");
    	 return;
	  end
	--应用新的快捷键设置
	SystemSetup:UseAcceCustomKey();

    --- 标记对设置进行了修改
    AcceSetup_YingYong:Disable()
    SystemSetup:SetIsConfigChanged( 0 )
    PushDebugMessage( "#{XTSZYH_111220_10}" )
end

function AcceSetup_Set_Setup_UnChanged()
    --- 设置当前没有任何修改
    SystemSetup:SetIsConfigChanged( 0 )
    --- 灰化掉应用按钮
    AcceSetup_YingYong:Disable()
end

function AcceSetup_Retrieve_Setup()
    SystemSetup : RevertAcceCustom()
end

function AcceSetup_Set_Setup_Changed()
    SystemSetup:SetIsConfigChanged( 1 )
	AcceSetup_YingYong:Enable()
end

