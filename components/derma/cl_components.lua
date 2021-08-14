local PLUGIN = PLUGIN;
local matGradient = Material("gui/gradient_up")
local sw, sh = ScrW(), ScrH();
local math = math;
local appr = math.Approach;

local PANEL = {}

function PANEL:Init()	
		timer.Simple(0, function()
			self:Populate()
		end)
end

function PANEL:Populate()
		self.btnLeft.Paint = function(s, w, h) 
				surface.SetDrawColor(Color(255, 255, 255))
				surface.DrawLine( w - 8, 3.5, 2.5, h/2 )
				surface.DrawLine( w - 8, h - 3.5, 2.5, h/2 )
		end
		self.btnRight.Paint = function(s, w, h) 
				surface.SetDrawColor(Color(255, 255, 255))
				surface.DrawLine( 2.5, 3.5, w - 8, h/2 )
				surface.DrawLine( 2.5, h - 3.5, w - 8, h/2 )
		end
end;

vgui.Register( "CompHorScroll", PANEL, "DHorizontalScroller" )


local PANEL = {}

function PANEL:Init()
    local ConVas, ScrollBar = self:GetCanvas(), self:GetVBar()
    ScrollBar:SetWidth(5)
    ScrollBar:DockMargin(5, 5, 5, 5)
		ScrollBar:SetHideButtons( true )
		function ScrollBar:Paint(w, h) draw.RoundedBox(0, 0, 0, w, h, Color(50, 50, 50, 50)) end
		function ScrollBar.btnGrip:Paint(w, h) draw.RoundedBox(0, 0, 0, w, h, Color(60, 60, 60, 100)) end
end
vgui.Register( "CompScroll", PANEL, "DScrollPanel" )

local PANEL = {}

function PANEL:Init()
    self:Dock(TOP)
    self:SizeToContents()
		self:SetMouseInputEnabled( true )
    self:SetContentAlignment(5)
    self:SetCursor("hand")

		self:SetFont("JobBtns")

		self.clrPaintTo = Color(255, 185, 138)
end

function PANEL:Paint( w, h )
    if self.disabled then
        self:SetColor(Color(100, 100, 100));
        return;
    end
    if self:IsHovered() then
	    if !self.soundPlayed then
			surface.PlaySound("helix/ui/rollover.wav")
			self:ColorTo(self.clrPaintTo, .2, 0, function() self:SetColor(self.clrPaintTo) end);
			self.soundPlayed = true;
		end;
	elseif !self:IsHovered() then
		self:SetColor(color_white)
		self.soundPlayed = false;
	end
end;

vgui.Register( "CompButton", PANEL, "DLabel" )

local PANEL = {}

function PANEL:Init()
		self:SetMouseInputEnabled( true )
		timer.Simple(0, function()
				self:Populate()
		end)
end

function PANEL:SetWorkData(data)
		self.work = data or {}
end;

function PANEL:Populate()
		if !self.work then self:Remove() return end;
		local minAmount, lineAmount, min, max;
    local REPUTATION = LocalPlayer():GetVendorRep()

		local workDesc = self.work.description

		self.job = self:Add("DPanel")
    self.job:Dock(TOP)
		self.job:SetMouseInputEnabled( true )
    self.job.Paint = function(s, w, h) end;
		self.job.OnMousePressed = function()
				self:OnMousePressed()
		end;

		self.title = self.job:Add("DLabel")
    self.title:Dock(TOP)
    self.title:SetText(self.work.title or "Unknown")
    self.title:SetFont("JobHighlight")
    self.title:SetContentAlignment(5)

		if workDesc != "" && workDesc:len() > 0 then
				local x, y = surface.GetTextSize(workDesc)
				minAmount = y
				lineAmount = math.ceil(workDesc:len() / minAmount);
				for i = 1, lineAmount do
						min = (i-1) * minAmount;
						max = i * minAmount

						local stringLine = self.job:Add("DLabel")
						stringLine:SetFont("JobDescription")
						stringLine:Dock(TOP)
						stringLine:SetText( workDesc:sub(min, max-1) )
						stringLine:SetContentAlignment(5)
						stringLine:DockMargin(sw * 0.005, sh * 0.005, sw * 0.002, i == lineAmount && sh * 0.005 || 0)
				end
		end

		self.job:DockMargin(0, sh * 0.15 - (lineAmount or 1 * 5), 0, 0)

		self.price = self.job:Add("DLabel")
		self.price:Dock(TOP)
		self.price:SetText("Price: ".. nut.currency.get(self.work.price or 0))
		self.price:SetContentAlignment(5)
		self.price:SetFont("JobHighlight")

		if REPUTATION > 0 then
			local bonus = 
			(REPUTATION * (JOBREP.repMutli / 100)) 
			+ 
			(self.work.price * (JOBREP.priceMulti / 100));
			bonus = math.Round(bonus, 2)
			self.bonus = self.job:Add("DLabel")
			self.bonus:Dock(TOP)
			self.bonus:SetText("Bonus: +".. nut.currency.get(bonus or 0))
			self.bonus:SetContentAlignment(5)
			self.bonus:SetFont("JobHighlight")
			self.bonus:SetTextColor(Color(100, 200, 100))
		end;

		self.choose = self.job:Add("DLabel")
		self.choose:Dock(TOP)
		self.choose:SetText(!self.notChoose && "Click to choose this work" || "You can't choose this work now")
		self.choose:SetContentAlignment(5)
		self.choose:SetFont("JobDescription")
		self.choose:SetTextColor( Color(150, 150, 150) )
		self.choose:SetAlpha(0)
		self.choose:DockMargin(0, sh * 0.15, 0, 0)

		self.dColor = Color(0, 0, 0, 0);
		self.dCopy = self.dColor
		
		self.job:InvalidateLayout(true)
		self.job:SizeToChildren(true, true)
end;

function PANEL:OnMousePressed()
		if LocalPlayer():GetJobID() != 0 || self.notChoose then
				return
		end
		Derma_Query("Do you want to pick up this work?", self.work.title or "Unknown", 
		"Yes", 
		function() 
				if LocalPlayer():GetJobID() == 0 then
						netstream.Start('jobVendor::pickWork', self.work.uniqueID)
						
						local uniqueID = "WorkTime: " .. LocalPlayer():getChar():getID()
						timer.Simple(0, function()
								if VENDOR_INTERFACE then
										VENDOR_INTERFACE:CheckWorks()
								end;
						end)
						timer.Create(uniqueID, 1, self.work.timeForRepair, function()
								if !timer.Exists(uniqueID) || !LocalPlayer():IsValid() then timer.Remove(uniqueID) return; end;
								
								if timer.RepsLeft(uniqueID) <= 0 then
									timer.Simple(0, function()
										if VENDOR_INTERFACE then
											VENDOR_INTERFACE:CheckWorks()
										end;
									end);
								end
						end);
				end
		end,
		"No")
end;

function PANEL:Paint( w, h )
		if !self.dColor then return end;
		
		local incTo = !self.notChoose && Color(139, 23, 155, 150) || Color(177, 60, 80, 150)
		local cCopy = self.dCopy 
		local hov = self:IsHovered() || self:IsChildHovered()
		local red, green, blue, alpha = self.dColor.r, self.dColor.g, self.dColor.b, self.dColor.a
		self.dColor = {
				r = appr(red, hov && incTo.r || cCopy.r, FrameTime() * 700),
				g = appr(green, hov && incTo.g || cCopy.g, FrameTime() * 700),
				b = appr(blue, hov && incTo.b || cCopy.b, FrameTime() * 700),
				a = appr(alpha, hov && incTo.a || cCopy.a, FrameTime() * 700)
		}
		surface.SetDrawColor( self.dColor )
		surface.SetMaterial( matGradient )
		surface.DrawTexturedRect( 0, 0, w, h )

		if self:IsHovered() || self:IsChildHovered() then
				if self.choose && self.choose:GetAlpha() == 0 then
						self.choose:AlphaTo(255, .3, 0, function() end)
				end
		elseif self.choose && self.choose:GetAlpha() >= 255 then
				self.choose:AlphaTo(0, .3, 0, function() end)
		end;
end;

vgui.Register( "JobSlice", PANEL, "DPanel" )

local PANEL = {}

function PANEL:Init() 
		self:DockMargin(sw * 0.01, sh * 0.01, sw * 0.01, sh * 0.01)
end

function PANEL:Paint( w, h )
		surface.SetDrawColor(Color(60, 60, 60, 150))
    surface.DrawRect(0, 0, w, h)
    surface.SetDrawColor(Color(25, 25, 25, 255))
    surface.DrawOutlinedRect( 0, 0, w, h, 1 )	
end;

vgui.Register( "JobSubPanel", PANEL, "DPanel" )

local PANEL = {}

function PANEL:Init()
		self:Dock(RIGHT)
		self:SetWide(sw * 0.02)
		self:DockMargin(sw * 0.0, sh * 0.005, sw * 0.005, sh * 0.01)
		self:SetCursor("hand")

		self:SetMouseInputEnabled(true)

		self.closeLbl = self:Add("DLabel")
		self.closeLbl:Dock(FILL)
		self.closeLbl:SetText("X")
		self.closeLbl:SetContentAlignment(5)

		self:InitHover(Color(50, 50, 50, 255), Color(70, 70, 70, 255), 0.2, Color(0,0,0,0))
end

function PANEL:Paint( w, h ) 
		self:HoverButton(w, h)
end;

function PANEL:OnMousePressed()
		if TAXI_INTERFACE && TAXI_INTERFACE:IsValid() then
				TAXI_INTERFACE:Close()
		end
end

vgui.Register( "TaxiCloseButton", PANEL, "EditablePanel" )

local PANEL = {}

function PANEL:Init() end

function PANEL:SetIndex(i)
		self.index = i;
end;

function PANEL:Populate()
		if !self.index then self:Remove() return end;
		if !TAXIJOB[self.index] then self:Remove() return end;

		local position = TAXIJOB[self.index].position;
		position = math.Round(LocalPlayer():GetPos():Distance( position ) / 28);
		local price = TAXIJOB[self.index].price;

		if TAXIJOB[self.index].take then
				self.label = self:Add("DLabel")
				self.label:Dock(FILL)
				self.label:SetText("TAKEN")
				self.label:SetContentAlignment(5)
				self.label:SetFont("TaxiBtnsLower")
				return;
		end;

		self.label = self:Add("DLabel")
		self.label:Dock(TOP)
		self.label:SetText("Position: ")
		self.label:SetContentAlignment(5)

		self.pos = self:Add("DLabel")
		self.pos:Dock(TOP)
		self.pos:SetText(position .. " meters")
		self.pos:SetContentAlignment(5)

		self.label = self:Add("DLabel")
		self.label:Dock(TOP)
		self.label:SetText("Price: ")
		self.label:SetContentAlignment(5)

		self.price = self:Add("DLabel")
		self.price:Dock(TOP)
		self.price:SetText(nut.currency.get( price ))
		self.price:SetContentAlignment(5)

		self.acceptBtn = self:Add("DButton")
		self.acceptBtn:Dock(TOP)
		self.acceptBtn:SetText("Accept")
		self.acceptBtn:DockMargin(sw * 0.01, sh * 0.005, sw * 0.01, 0)
		self.acceptBtn:SetTextColor(Color(255, 255, 255))

		self.acceptBtn.DoClick = function(btn)
				if !TAXIJOB[self.index].take then
						netstream.Start('taxi::TakeJob', self.index)
						surface.PlaySound("buttons/button17.wav")
				end
		end;

		local children = self:GetChildren();
		local i = #children;
		while (i > 0) do
				if children[i].SetFont then
					children[i]:SetFont("TaxiBtnsLower")
				end;
				i = i - 1;
		end
end;

function PANEL:Paint( w, h )
		surface.SetDrawColor(Color(199, 85, 180, 150))
    surface.DrawRect(0, 0, w, h)
end;

vgui.Register( "TaxiJob", PANEL, "EditablePanel" )

local PANEL = {}

function PANEL:Init()
		self:Dock(TOP)
		self:SetCursor("hand")
		self:DockMargin(sw * 0.05, sh * 0.02, sw * 0.05, sh * 0.01)

		self:SetMouseInputEnabled(true)

		self.text = self:Add("DLabel")
		self.text:Dock(FILL)
		self.text:SetText("")
		self.text:SetFont("TaxiBtnsLower")
		self.text:SetContentAlignment(5)

		self:InitHover(Color(50, 50, 50, 255), Color(70, 70, 70, 255), 0.2, nil)
end

function PANEL:SetText(text)
		self.text:SetText(text)
end;

function PANEL:Paint( w, h ) 
		self:HoverButton(w, h)
end;

function PANEL:SetDisabled( bool )
		self.Disable = bool;
end;

function PANEL:OnMousePressed()
		if self.Disable then
				return;
		end;

		self:DoClick(self)
end

vgui.Register( "TaxiUtilityButton", PANEL, "EditablePanel" )