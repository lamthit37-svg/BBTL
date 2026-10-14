--20150701-七夕交互任务-by yuanpeilong

local g_Frame_UnifiedXPosition_Tanabata;
local g_Frame_UnifiedYPosition_Tanabata;

--此2个参数，在大小界面切换时，用作记录界面类型和性别用
local Param0 = 0 --模拟：Int0：记录界面类型
local Param2 = 0 --模拟：Int2：记录性别
local MsgStr = ""

function Tanabata_PreLoad()
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("2015QIXI_JH_SMALL")
	this:RegisterEvent("2015QIXI_JH_BIG")
end

function Tanabata_OnLoad()
	Tanabata_Client:Hide()
	Tanabata_Frame1:Hide()
	Tanabata_Frame2:Hide()
	Tanabata_Frame3:Hide()
	Tanabata_Frame1_Info:SetText("")
	Tanabata_Frame2_Info:SetText("")
	Tanabata_Frame3_Info:SetText("")
	g_Frame_UnifiedXPosition_Tanabata	= Tanabata_Frame:GetProperty("UnifiedXPosition");
	g_Frame_UnifiedYPosition_Tanabata	= Tanabata_Frame:GetProperty("UnifiedYPosition");		
end

function Tanabata_OnEvent(event)

	if(event == "UI_COMMAND") then
		
		local comefrom = tonumber(arg0)
		if comefrom == 891335 or comefrom == 891336 or comefrom == 891337 or comefrom == 891338 or comefrom == 891339 
			 or comefrom == 891367  or comefrom == 891368 or comefrom == 891340 or comefrom == 891357 then
		
			local JieMina = Get_XParam_INT(0)
			
			if JieMina == 0 or JieMina == 1 or JieMina == 2 or JieMina == 3 or JieMina == 4 or JieMina == 5 or JieMina == 6 then
			
				Tanabata_Clear()
				
				local Int0 = Get_XParam_INT(0)
				local Int1 = Get_XParam_INT(1)
				local Int2 = Get_XParam_INT(2)

				Param0 = Int0
				Param2 = Int2
				
				if Int1 == 0 then
					--关闭界面
					Tanabata_Frame_Mini_Close()
					this:Hide()
				elseif Int1 == 1 then
					MsgStr = Get_XParam_STR(0)
					if Int0 == 0 then
						--采花罗盘
						if Int2 == 0 then
							--图
							Tanabata_Frame1_Image:SetProperty("Image", "set:Tanabata image:Tanabata_0");
							--文字提示界面
							Tanabata_Frame1_Info:SetText(MsgStr)
						elseif Int2 == 1 then
							--图
							Tanabata_Frame1_Image:SetProperty("Image", "set:Tanabata image:Tanabata_0");
							--文字提示界面
							Tanabata_Frame1_Info:SetText(MsgStr)
						end
						Tanabata_Frame1:Show()
						Tanabata_Client:Show()
					elseif Int0 == 1 then
						--采花
						if Int2 == 1 then
							--技能提示界面
							Tanabata_Frame2_Icon:SetProperty("Image", "set:FBSkill_2 image:FBSkill_2_5");
							--文字提示界面
							Tanabata_Frame2_Info:SetText(MsgStr)
							Tanabata_Frame2:Show()
						elseif Int2 == 0 then
							--文字提示界面
							Tanabata_Frame3_Info:SetText(MsgStr)
							Tanabata_Frame3:Show()					
						end
						Tanabata_Client:Show()
					elseif Int0 == 2 then
						--解控
						if Int2 == 0 then
							--技能提示界面
							Tanabata_Frame2_Icon:SetProperty("Image", "set:FBSkill_2 image:FBSkill_2_4");
							--文字提示界面
							Tanabata_Frame2_Info:SetText(MsgStr)
							Tanabata_Frame2:Show()
						elseif Int2 == 1 then
							--文字提示界面
							Tanabata_Frame3_Info:SetText(MsgStr)
							Tanabata_Frame3:Show()					
						end
						Tanabata_Client:Show()			
					elseif Int0 == 3 then
						--嘲讽
						if Int2 == 0 then
							--文字提示界面
							Tanabata_Frame3_Info:SetText(MsgStr)
							Tanabata_Frame3:Show()	
						elseif Int2 == 1 then
							--技能提示界面
							Tanabata_Frame2_Icon:SetProperty("Image", "set:FBSkill_2 image:FBSkill_2_1");
							--文字提示界面
							Tanabata_Frame2_Info:SetText(MsgStr)
							Tanabata_Frame2:Show()				
						end
						Tanabata_Client:Show()				
					elseif Int0 == 4 then
						--反手一击
						if Int2 == 0 then
							--文字提示界面
							Tanabata_Frame3_Info:SetText(MsgStr)
							Tanabata_Frame3:Show()					
						elseif Int2 == 1 then
							--技能提示界面
							Tanabata_Frame2_Icon:SetProperty("Image", "set:FBSkill_1 image:FBSkill_1_16");
							--文字提示界面
							Tanabata_Frame2_Info:SetText(MsgStr)
							Tanabata_Frame2:Show()					
						end
						Tanabata_Client:Show()						
					elseif Int0 == 5 then
						--套索
						if Int2 == 0 then
							--技能提示界面
							Tanabata_Frame2_Icon:SetProperty("Image", "set:FBSkill_2 image:FBSkill_2_2");
							--文字提示界面
							Tanabata_Frame2_Info:SetText(MsgStr)
							Tanabata_Frame2:Show()					
						elseif Int2 == 1 then
							--文字提示界面
							Tanabata_Frame3_Info:SetText(MsgStr)
							Tanabata_Frame3:Show()					
						end
						Tanabata_Client:Show()
					elseif Int0 == 6 then
						--玫瑰罗盘技能
						if(Int2 == 0) then
							--技能提示界面
							Tanabata_Frame2_Icon:SetProperty("Image", "set:FBSkill_2 image:FBSkill_2_3");
							--文字提示界面
							Tanabata_Frame2_Info:SetText(MsgStr)
							Tanabata_Frame2:Show()	
						elseif Int2 == 1 then
							--文字提示界面
							Tanabata_Frame3_Info:SetText(MsgStr)
							Tanabata_Frame3:Show()	
						end
						Tanabata_Client:Show()
					end
					
					this:Show()
				end
			end
		end
		
	elseif(event == "2015QIXI_JH_BIG") then

		Tanabata_Clear()
		Tanabata_Frame_Mini_Close()
		local Int0 = tonumber( arg0 )
		local Int2 = tonumber( arg1 )

		MsgStr = tostring( arg2 )
		
		if Int0 == 0 then
			--采花罗盘
			if Int2 == 0 then
				--图
				Tanabata_Frame1_Image:SetProperty("Image", "set:Tanabata image:Tanabata_0");
				--文字提示界面
				Tanabata_Frame1_Info:SetText(MsgStr)
			elseif Int2 == 1 then
				--图
				Tanabata_Frame1_Image:SetProperty("Image", "set:Tanabata image:Tanabata_0");
				--文字提示界面
				Tanabata_Frame1_Info:SetText(MsgStr)
			end
			Tanabata_Frame1:Show()
			Tanabata_Client:Show()
		elseif Int0 == 1 then
			--采花
			if Int2 == 1 then
				--技能提示界面
				Tanabata_Frame2_Icon:SetProperty("Image", "set:FBSkill_2 image:FBSkill_2_5");
				--文字提示界面
				Tanabata_Frame2_Info:SetText(MsgStr)
				Tanabata_Frame2:Show()
			elseif Int2 == 0 then
				--文字提示界面
				Tanabata_Frame3_Info:SetText(MsgStr)
				Tanabata_Frame3:Show()					
			end
			Tanabata_Client:Show()
		elseif Int0 == 2 then
			--解控
			if Int2 == 0 then
				--技能提示界面
				Tanabata_Frame2_Icon:SetProperty("Image", "set:FBSkill_2 image:FBSkill_2_4");
				--文字提示界面
				Tanabata_Frame2_Info:SetText(MsgStr)
				Tanabata_Frame2:Show()
			elseif Int2 == 1 then
				--文字提示界面
				Tanabata_Frame3_Info:SetText(MsgStr)
				Tanabata_Frame3:Show()					
			end
			Tanabata_Client:Show()			
		elseif Int0 == 3 then
			--嘲讽
			if Int2 == 0 then
				--文字提示界面
				Tanabata_Frame3_Info:SetText(MsgStr)
				Tanabata_Frame3:Show()	
			elseif Int2 == 1 then
				--技能提示界面
				Tanabata_Frame2_Icon:SetProperty("Image", "set:FBSkill_2 image:FBSkill_2_1");
				--文字提示界面
				Tanabata_Frame2_Info:SetText(MsgStr)
				Tanabata_Frame2:Show()				
			end
			Tanabata_Client:Show()				
		elseif Int0 == 4 then
			--反手一击
			if Int2 == 0 then
				--文字提示界面
				Tanabata_Frame3_Info:SetText(MsgStr)
				Tanabata_Frame3:Show()					
			elseif Int2 == 1 then
				--技能提示界面
				Tanabata_Frame2_Icon:SetProperty("Image", "set:FBSkill_1 image:FBSkill_1_16");
				--文字提示界面
				Tanabata_Frame2_Info:SetText(MsgStr)
				Tanabata_Frame2:Show()					
			end
			Tanabata_Client:Show()			
		elseif Int0 == 5 then
			--套索
			if Int2 == 0 then
				--技能提示界面
				Tanabata_Frame2_Icon:SetProperty("Image", "set:FBSkill_2 image:FBSkill_2_2");
				--文字提示界面
				Tanabata_Frame2_Info:SetText(MsgStr)
				Tanabata_Frame2:Show()					
			elseif Int2 == 1 then
				--文字提示界面
				Tanabata_Frame3_Info:SetText(MsgStr)
				Tanabata_Frame3:Show()					
			end
			Tanabata_Client:Show()
		elseif Int0 == 6 then
			--玫瑰罗盘技能
			if(Int2 == 0) then
				--技能提示界面
				Tanabata_Frame2_Icon:SetProperty("Image", "set:FBSkill_2 image:FBSkill_2_3");
				--文字提示界面
				Tanabata_Frame2_Info:SetText(MsgStr)
				Tanabata_Frame2:Show()	
			elseif Int2 == 1 then
				--文字提示界面
				Tanabata_Frame3_Info:SetText(MsgStr)
				Tanabata_Frame3:Show()	
			end
			Tanabata_Client:Show()
		end
		
		this:Show()
	
	end
	
end

function Tanabata_ResetPos()
	Tanabata_Frame:SetProperty("UnifiedXPosition", g_Frame_UnifiedXPosition_Tanabata);
	Tanabata_Frame:SetProperty("UnifiedYPosition", g_Frame_UnifiedYPosition_Tanabata);
end

function Tanabata_Frame_Mini_Cliecked()
	this:Hide()
	PushEvent( "2015QIXI_JH_SMALL", Param0, Param2, MsgStr )
end

function Tanabata_Frame_Mini_Close()
	this:Hide()
	PushEvent( "2015QIXI_JH_SMALL", 1234567, Param2, MsgStr )
end

function Tanabata_Clear()

	Tanabata_Client:Hide()
	Tanabata_Frame1:Hide()
	Tanabata_Frame2:Hide()
	Tanabata_Frame3:Hide()
	Tanabata_Frame1_Info:SetText("")
	Tanabata_Frame2_Info:SetText("")
	Tanabata_Frame3_Info:SetText("")
	
	this:Hide()
	
end