local _, Addon = ...;

Addon.MAP = CreateFrame( 'Frame' );
Addon.MAP:RegisterEvent( 'ADDON_LOADED' );
Addon.MAP:SetScript( 'OnEvent',function( self,Event,AddonName )
    if( AddonName == 'jPvPMap' ) then

        --
        --  Get module defaults
        --
        --  @return table
        Addon.MAP.GetDefaults = function( self )
            return {
                Point = 'TOPLEFT',
                RelativeTo = 'UIParent',
                RelativePoint = nil,
                XPos = 15.480,
                YPos = -48.181,
                MapScale = 0.866,

                Alpha = 0.2,
                PinScale = 2,
                PinAnimDuration = 90,
                ZoneUpdate = true,
                SkullMyAss = true,
                AlwaysShow = true,
                PanelColapsed = true,
            };
        end

        --
        --  Set value
        --
        --  @param  string  Index
        --  @param  mixed   Value
        --  @return void
        Addon.MAP.SetValue = function( self,Index,Value )
            if( self.persistence[ Index ] ~= nil ) then
                self.persistence[ Index ] = Value;
            end
        end

        --
        --  Get value
        --
        --  @return mixed
        Addon.MAP.GetValue = function( self,Index )
            if( self.persistence[ Index ] ~= nil ) then
                return self.persistence[ Index ];
            end
        end

        --
        --  Get module settings
        --
        --  @return table
        Addon.MAP.GetSettings = function( self )
            return {
                type = 'group',
                get = function( Info )
                    if( self.persistence[ Info.arg ] ~= nil ) then
                        return self.persistence[ Info.arg ];
                    end
                end,
                set = function( Info,Value )
                    if( self.persistence[ Info.arg ] ~= nil ) then
                        self.persistence[ Info.arg ] = Value;
                    end
                end,
                type = 'group',
                name = AddonName..' Settings',
                args = {
                    Alpha = {
                        order = 2,
                        type = 'range',
                        name = 'Map Alpha',
                        desc = 'Main map alpha',
                        min = 0.1, max = 1, step = 0.1,
                        arg = 'Alpha',
                    },
                    AlwaysShow = {
                        order = 3,
                        type = 'toggle',
                        name = 'Always Show Map',
                        desc = 'Whether or not the map should open if you move and it is not already open',
                        arg = 'AlwaysShow',
                    },
                    SkullMyAss = {
                        order = 5,
                        type = 'toggle',
                        name = 'Skull Your Position',
                        desc = 'Whether or not to display your position on the map as a skull',
                        arg = 'SkullMyAss',
                    },
                    PinScale = {
                        order = 6,
                        type = 'range',
                        name = 'Your Position\'s Scale',
                        desc = 'Main map player location scale',
                        min = 1, max = 2, step = 1,
                        arg = 'PinScale',
                        set = function( Info,Value )
                            self:SetValue( 'PinScale',Value );
                            self:GetUnitPin():SetPlayerPingScale( self:GetValue( 'PinScale' ) );
                        end,
                    },
                    PinAnimDuration = {
                        order = 7,
                        type = 'range',
                        name = 'Animation Duration',
                        desc = 'Main map player location animation duration',
                        min = 10, max = 120, step = 10,
                        arg = 'PinAnimDuration',
                        set = function( Info,Value )
                            self:SetValue( 'PinAnimDuration',Value );
                            self:GetUnitPin():StartPlayerPing( 1,self:GetValue( 'PinAnimDuration' ) );
                        end,
                    },
                    ZoneUpdate = {
                        order = 8,
                        type = 'toggle',
                        name = 'Always Move to Zone',
                        desc = 'Whether or not the map should update when you enter a new zone',
                        arg = 'ZoneUpdate',
                    },
                    PanelColapsed = {
                        order = 9,
                        type = 'toggle',
                        name = 'Quest Panel Closed',
                        desc = 'Whether or not the retail version of the map should expand the quest list',
                        arg = 'PanelColapsed',
                    },
                }
            };
            -- /Interface/FrameXML/UnitPositionFrameTemplates.lua
        end;

        --
        --  Map stop moving
        --
        --  @return void
        Addon.MAP.WorldMapFrameStopMoving = function( self )
            WorldMapFrame:StopMovingOrSizing();
            if not WorldMapFrame:IsMaximized() then
                local Point,RelativeTo,RelativePoint,XPos,YPos = WorldMapFrame:GetPoint();
                if( XPos ~= nil and YPos ~= nil ) then
                    Addon.MAP:SetValue( 'Point',Point );
                    Addon.MAP:SetValue( 'RelativeTo',RelativeTo or 'UIParent' );
                    Addon.MAP:SetValue( 'RelativePoint',RelativePoint );
                    Addon.MAP:SetValue( 'XPos',XPos );
                    Addon.MAP:SetValue( 'YPos',YPos );
                    --[[
                    Addon:Dump( {
                        Action = 'Saving',
                        Point = Addon.MAP:GetValue( 'Point' ),
                        RelativeTo = Addon.MAP:GetValue( 'RelativeTo' ), 
                        RelativePoint = Addon.MAP:GetValue( 'RelativePoint' ), 
                        XPos = Addon.MAP:GetValue( 'XPos' ), 
                        YPos = Addon.MAP:GetValue( 'YPos' ), 
                    } );
                    ]]
                end
            end
        end

        --
        --  Map start moving
        --
        --  @return void
        Addon.MAP.WorldMapFrameStartMoving = function( self )
            if not WorldMapFrame:IsMaximized() then
                WorldMapFrame:StartMoving()
            end
        end

        --
        --  Map save position
        --
        --  @return void
        Addon.MAP.SetPosition = function( self )
            local Point,RelativeTo,RelativePoint,XPos,YPos;
            if( not WorldMapFrame:IsMaximized() ) then
                Point,RelativeTo,RelativePoint,XPos,YPos = self:GetValue( 'Point' ),self:GetValue( 'RelativeTo' ),self:GetValue( 'RelativePoint' ),self:GetValue( 'XPos' ),self:GetValue( 'YPos' );
                if( XPos ~= nil and YPos ~= nil ) then
                    --[[
                    Addon:Dump( {
                        Action = 'Loading',
                        Point = self:GetValue( 'Point' ),
                        RelativeTo = self:GetValue( 'RelativeTo' ), 
                        RelativePoint = self:GetValue( 'RelativePoint' ), 
                        XPos = self:GetValue( 'XPos' ), 
                        YPos = self:GetValue( 'YPos' ), 
                    } );
                    ]]
                    WorldMapFrame:ClearAllPoints();
                    WorldMapFrame:SetPoint( Point,RelativeTo,RelativePoint,XPos,YPos );
                    WorldMapFrame:SetScale( self:GetValue( 'MapScale' ) );
                end
            end
        end

        --
        --  Create module config frames
        --
        --  @return void
        Addon.MAP.CreateFrames = function( self )
            -- Verify
            local WorldMapUnitPin = self:GetUnitPin();
            if( not WorldMapUnitPin ) then
                return;
            end

            -- Register
            self.Config = LibStub( 'AceConfigDialog-3.0' ):AddToBlizOptions( string.upper( AddonName ),AddonName );
            self.Config.okay = function( self )
            	self:Refresh();
                RestartGx();
            end
            self.Config.default = function( self )
                self.db:ResetDB();
            end
            LibStub( 'AceConfigRegistry-3.0' ):RegisterOptionsTable( string.upper( AddonName ),self:GetSettings() );

            -- Events
            self.Events = CreateFrame( 'Frame' );

            -- Movement
            self.Events:RegisterEvent( 'PLAYER_STARTED_MOVING' );
            self.Events:RegisterEvent( 'PLAYER_STARTED_LOOKING' );
            self.Events:RegisterEvent( 'PLAYER_STARTED_TURNING' );
            self.Events:SetScript( 'OnEvent',function( self,Event,... )
                if( WorldMapFrame:IsShown() ) then
                    Addon.MAP:UpdatePin();
                end

                if( not WorldMapFrame:IsShown() and Addon.MAP:GetValue( 'AlwaysShow' ) ) then
                    WorldMapFrame:Show();
                end
            end );
            
            -- Pin
            LibStub( 'AceHook-3.0' ):SecureHook( WorldMapUnitPin,'OnMapChanged',function()
                self:UpdatePin();
            end );
            LibStub( 'AceHook-3.0' ):SecureHook( WorldMapUnitPin,'SynchronizePinSizes',function() 
                WorldMapUnitPin:SetPlayerPingScale( self:GetValue( 'PinScale' ) );
            end );

            -- Scale
            WorldMapFrame.Resize = CreateFrame( 'Button','resize',WorldMapFrame );
            WorldMapFrame.Resize:SetSize( 16,16 );
            WorldMapFrame.Resize:SetPoint( 'bottomright' );
            WorldMapFrame.Resize:SetNormalTexture( 'Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up' );
            WorldMapFrame.Resize:SetHighlightTexture( 'Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight' );
            WorldMapFrame.Resize:SetPushedTexture( 'Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down' );
            WorldMapFrame.Resize:SetScript( 'OnMouseDown',function( self,Button )
                if( Button == 'LeftButton' ) then
                    Addon.MAP.Scaling = true;
                end
            end );
            WorldMapFrame.Resize:SetScript( 'OnUpdate',function( self,Button )
                if( Addon.MAP.Scaling == true ) then

                    local p,rt,rp,x,y = WorldMapFrame:GetPoint();

                    local cx, cy = GetCursorPosition();
                    cx = cx / self:GetEffectiveScale() - self:GetParent():GetLeft();
                    cy = self:GetParent( ):GetHeight() - ( cy / self:GetEffectiveScale() - self:GetParent():GetBottom() );

                    local s = cx / self:GetParent():GetWidth();

                    self:GetParent():ClearAllPoints();
                    self:GetParent():SetScale( self:GetParent():GetScale() * s );
                    self:GetParent():SetPoint( p,rt,rp,x,y );
                    self:GetParent().x,self:GetParent().y = x,y;
                end
            end );
            WorldMapFrame.Resize:SetScript( 'OnMouseUp',function( self,Button )
                if( Button == 'LeftButton' ) then
                    Addon.MAP.Scaling = false;
                    Addon.MAP:SetValue( 'MapScale',WorldMapFrame:GetScale() );
                end
            end );

            -- Show
            LibStub( 'AceHook-3.0' ):SecureHookScript( WorldMapFrame,'OnShow',function( Map )
                local PreviousZone = C_Map.GetBestMapForUnit( 'player' );
                if( PreviousZone ) then
                    self.PreviousZone = PreviousZone;
                end
                self:Refresh();
            end );

            -- Update
            LibStub( 'AceHook-3.0' ):SecureHookScript( WorldMapFrame,'OnUpdate',function( Map )
                -- Focus
                if( self.Scaling == true ) then
                    WorldMapFrame:SetAlpha( 1 );
                else
                    if( not Map:IsMouseOver() ) then
                        WorldMapFrame:SetAlpha( self:GetValue( 'Alpha' ) );
                    -- Unfocus
                    else
                        WorldMapFrame:SetAlpha( 1 );
                    end
                end
                -- Zone change
                local CurrentZone = C_Map.GetBestMapForUnit( 'player' );
                if( ( CurrentZone and self.PreviousZone ) and CurrentZone ~= self.PreviousZone ) then
                    if( self:GetValue( 'ZoneUpdate' ) ) then
                        self.PreviousZone = CurrentZone;
                        Addon.MAP.UpdateMap();
                    end
                end
            end );

            -- Position
            WorldMapFrame:SetMovable( true );
            WorldMapFrame:RegisterForDrag( 'LeftButton' );
            WorldMapFrame:SetScript( 'OnDragStart',self.WorldMapFrameStartMoving );
            WorldMapFrame:SetScript( 'OnDragStop',self.WorldMapFrameStopMoving );
            
            --WorldMapFrame:EnableMouse( false );
        end

        --
        -- Map Unit Pin
        --
        -- @return  mixed
        Addon.MAP.GetUnitPin = function( self )
            local WorldMapUnitPin;
            for pin in WorldMapFrame:EnumeratePinsByTemplate( 'GroupMembersPinTemplate' ) do
                WorldMapUnitPin = pin
                break;
            end
            if( not WorldMapUnitPin ) then
                return;
            end
            return WorldMapUnitPin;
        end

        --
        -- Map Unit Update
        --
        -- @return  void
        Addon.MAP.UpdatePin = function( self )
            local WorldMapUnitPin = self:GetUnitPin();
            if( not WorldMapUnitPin ) then
                return;
            end
            local animation_scale   = self:GetValue( 'PinScale' );
            local animation_seconds = self:GetValue( 'PinAnimDuration' );
            if( self:GetValue( 'SkullMyAss' ) ) then
                WorldMapUnitPin:SetPinTexture( 'player','Interface\\WorldMap\\Skull_64Purple' );
            end
            WorldMapUnitPin:SetPlayerPingScale( animation_scale );
            WorldMapUnitPin:StartPlayerPing( 1,animation_seconds );
        end

        --
        -- Map Zone Update
        --
        -- @return  void
        Addon.MAP.UpdateMap = function( self )
            local CurrentZone = C_Map.GetBestMapForUnit( 'player' );
            if CurrentZone then
                WorldMapFrame:SetMapID( CurrentZone );
            end
        end

        --
        --  Module refresh
        --
        --  @return void
        Addon.MAP.Refresh = function( self )
            -- Verify
            if( not self.db ) then
                return;
            end
            self.persistence = self.db.profile;
            if( not self.persistence ) then
                return;
            end
            if( not WorldMapFrame ) then
                return;
            end

            -- Passback
            local Point,RelativeTo,RelativePoint,x,y = WorldMapFrame:GetPoint();
            WorldMapFrame.x,WorldMapFrame.y = x,y;

            -- Settings
            WorldMapFrame:SetAlpha( self:GetValue( 'Alpha' ) );
            WorldMapFrame:SetFrameStrata( 'LOW' );
            self:SetPosition();
            self:UpdatePin();
        end

        --
        --  Module init
        --
        --  @return void
        Addon.MAP.Init = function( self )
            -- Verify
            self.db = LibStub( 'AceDB-3.0' ):New( AddonName,{ profile = self:GetDefaults() },true );
            if( not self.db ) then
                return;
            end
            self.persistence = self.db.profile;
            if( not self.persistence ) then
                return;
            end
            if( not WorldMapFrame ) then
                return;
            end
            --self.db:ResetDB();
        end

        --
        --  Module run
        --
        --  @return void
        Addon.MAP.Run = function( self )
            -- Verify
            if( not self.db ) then
                return;
            end
            self.persistence = self.db.profile;
            if( not self.persistence ) then
                return;
            end
            if( not WorldMapFrame ) then
                return;
            end
            
            -- Cvars
            SetCVar('questLogOpen',not self:GetValue( 'PanelColapsed' ) );
            --SetCVar( 'mapFade',0 );

            C_Timer.After( 2, function()
               self:Refresh();
            end );

            --Addon:Dump( self.persistence )
        end

        self:Init();
        self:CreateFrames();
        self:Run();
        self:UnregisterEvent( 'ADDON_LOADED' );
    end
end );