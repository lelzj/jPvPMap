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
                MapPoint = 'TOPLEFT',
                MapRelativeTo = 'UIParent',
                MapRelativePoint = nil,
                MapXPos = 15.480,
                MapYPos = -48.181,
                MapScale = 0.866,
                MapAlpha = 0.2,

                PinAnimDuration = 90,
                ZoneUpdate = true,
                SkullMyAss = true,
                MatchWorldScale = true,
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
                        self:Refresh();
                    end
                end,
                type = 'group',
                name = 'jMap Settings',
                args = {
                    MapAlpha = {
                        order = 2,
                        type = 'range',
                        name = 'Map Alpha',
                        desc = 'Map transparency/how well you can see behind the map while open',
                        min = 0.1, max = 1, step = 0.1,
                        arg = 'MapAlpha',
                    },
                    AlwaysShow = {
                        order = 3,
                        type = 'toggle',
                        name = 'Always Show Map',
                        desc = 'Whether or not the map should remain open at all times',
                        arg = 'AlwaysShow',
                    },
                    SkullMyAss = {
                        order = 5,
                        type = 'toggle',
                        name = 'Skull Your Pin',
                        desc = 'Whether or not to display your position on the map as a skull',
                        arg = 'SkullMyAss',
                    },
                    MatchWorldScale = {
                        order = 6,
                        type = 'toggle',
                        name = 'Pin Scale to World Scale',
                        desc = 'Attempt to match your map position scale to the scale of the world map. Seems to be just a retail thing...where maps are excessively large and player pin winds up being especially tiny by default',
                        arg = 'MatchWorldScale',
                    },
                    PinAnimDuration = {
                        order = 7,
                        type = 'range',
                        name = 'Animation Duration',
                        desc = 'Map player location animation duration',
                        min = 10, max = 120, step = 10,
                        arg = 'PinAnimDuration',
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
            self.Config = LibStub( 'AceConfigDialog-3.0' ):AddToBlizOptions( 'jMap','jMap' );
            self.Config.okay = function( self )
                self:Refresh();
                RestartGx();
            end
            self.Config.default = function( self )
                self.db:ResetDB();
            end
            LibStub( 'AceConfigRegistry-3.0' ):RegisterOptionsTable( 'jMap',self:GetSettings() );

            -- Events
            self.Events = CreateFrame( 'Frame' );

            -- Movement
            self.Events:RegisterEvent( 'PLAYER_STARTED_MOVING' );
            self.Events:RegisterEvent( 'PLAYER_STARTED_LOOKING' );
            self.Events:RegisterEvent( 'PLAYER_STARTED_TURNING' );
            self.Events:SetScript( 'OnEvent',function( self,Event,... )
                Addon.MAP:UpdatePin();
                if( not WorldMapFrame:IsShown() and Addon.MAP:GetValue( 'AlwaysShow' ) ) then
                    WorldMapFrame:Show();
                end
                Addon.MAP.UpdateZone();
            end );
            
            -- Pin
            LibStub( 'AceHook-3.0' ):SecureHook( WorldMapUnitPin,'SynchronizePinSizes',function() 
                self:UpdatePin();
            end );

            -- Scale
            WorldMapFrame.Resize = CreateFrame( 'Button','resize',WorldMapFrame );
            WorldMapFrame.Resize:SetSize( 32,32 );
            WorldMapFrame.Resize:SetPoint( 'bottomright',15,-15 );
            WorldMapFrame.Resize:SetNormalTexture( 'Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up' );
            WorldMapFrame.Resize:SetHighlightTexture( 'Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight' );
            WorldMapFrame.Resize:SetPushedTexture( 'Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down' );

            local BGTheme = Addon.Theme.Gold;
            local r,g,b,a = BGTheme.r,BGTheme.g,BGTheme.b,1;

            WorldMapFrame.Resize.Texture = WorldMapFrame.Resize:CreateTexture();
            WorldMapFrame.Resize.Texture:SetAllPoints( WorldMapFrame.Resize );
            WorldMapFrame.Resize.Texture:SetColorTexture( r,g,b,a );

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
                if( InCombatLockdown() ) then
                    return;
                end
                -- Scaling
                if( self.Scaling == true ) then
                    WorldMapFrame:SetAlpha( 1 );
                    return;
                end
                -- Focus
                if( not Map:IsMouseOver() ) then
                    WorldMapFrame:SetAlpha( self:GetValue( 'MapAlpha' ) );
                -- Unfocus
                else
                    WorldMapFrame:SetAlpha( 1 );
                end

                -- Zone change
                local CurrentZone = C_Map.GetBestMapForUnit( 'player' );
                if( ( CurrentZone and self.PreviousZone ) and CurrentZone ~= self.PreviousZone ) then
                    if( self:GetValue( 'ZoneUpdate' ) ) then
                        self.PreviousZone = CurrentZone;
                        Addon.MAP.UpdateZone();
                    end
                end
            end );
        end

        --
        --  Map stop moving
        --
        --  @return void
        Addon.MAP.WorldMapFrameStopMoving = function( self )
            WorldMapFrame:StopMovingOrSizing();
            if not WorldMapFrame:IsMaximized() then
                local MapPoint,MapRelativeTo,MapRelativePoint,MapXPos,MapYPos = WorldMapFrame:GetPoint();
                if( MapXPos ~= nil and MapYPos ~= nil ) then
                    Addon.MAP:SetValue( 'MapPoint',MapPoint );
                    Addon.MAP:SetValue( 'MapRelativeTo',MapRelativeTo or 'UIParent' );
                    Addon.MAP:SetValue( 'MapRelativePoint',MapRelativePoint );
                    Addon.MAP:SetValue( 'MapXPos',MapXPos );
                    Addon.MAP:SetValue( 'MapYPos',MapYPos );
                    --[[
                    Addon:Dump( {
                        Action = 'Saving',
                        MapPoint = Addon.MAP:GetValue( 'MapPoint' ),
                        MapRelativeTo = Addon.MAP:GetValue( 'MapRelativeTo' ), 
                        MapRelativePoint = Addon.MAP:GetValue( 'MapRelativePoint' ), 
                        MapXPos = Addon.MAP:GetValue( 'MapXPos' ), 
                        MapYPos = Addon.MAP:GetValue( 'MapYPos' ), 
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
            local MapPoint,MapRelativeTo,MapRelativePoint,MapXPos,MapYPos;
            if( not WorldMapFrame:IsMaximized() ) then
                Point,MapRelativeTo,MapRelativePoint,MapXPos,MapYPos = self:GetValue( 'MapPoint' ),self:GetValue( 'MapRelativeTo' ),self:GetValue( 'MapRelativePoint' ),self:GetValue( 'MapXPos' ),self:GetValue( 'MapYPos' );
                if( MapXPos ~= nil and MapYPos ~= nil ) then
                    --[[
                    Addon:Dump( {
                        Action = 'Loading',
                        MapPoint = self:GetValue( 'MapPoint' ),
                        MapRelativeTo = self:GetValue( 'MapRelativeTo' ), 
                        MapRelativePoint = self:GetValue( 'MapRelativePoint' ), 
                        MapXPos = self:GetValue( 'MapXPos' ), 
                        MapYPos = self:GetValue( 'MapYPos' ), 
                    } );
                    ]]
                    WorldMapFrame:ClearAllPoints();
                    WorldMapFrame:SetPoint( Point,MapRelativeTo,MapRelativePoint,MapXPos,MapYPos );
                    WorldMapFrame:SetScale( self:GetValue( 'MapScale' ) );
                end
            end
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
            if( InCombatLockdown() ) then
                return;
            end
            if( not WorldMapFrame.ScrollContainer.Child ) then
                return;
            end
            local WorldMapUnitPin = self:GetUnitPin();
            if( not WorldMapUnitPin ) then
                return;
            end
            WorldMapUnitPin:SetPinSize( 'player',64 );
            --WorldMapUnitPin:SetPinSize( 'party',64 );
            --WorldMapUnitPin:SetPinSize( 'raid',64 );
            WorldMapUnitPin:SetPlayerPingScale( 3 );

            if( self:GetValue( 'MatchWorldScale' ) ) then
                if( WorldMapUnitPin:GetEffectiveScale() <= .3 ) then
                    WorldMapUnitPin:SetPlayerPingScale( 2 * 5 );
                    WorldMapUnitPin:SetPinSize( 'player',192 );
                end
            end

            if( self:GetValue( 'SkullMyAss' ) ) then
                WorldMapUnitPin:SetPinTexture( 'player','Interface\\WorldMap\\Skull_64Purple' );
                --WorldMapUnitPin:SetPinTexture( 'party','Interface\\WorldMap\\Skull_64Grey' );
                --WorldMapUnitPin:SetPinTexture( 'raid','Interface\\WorldMap\\Skull_64Red' );
                --WorldMapUnitPin:SetPinTexture( 'party','Interface\\WorldMap\\Skull_64Green' );
                --WorldMapUnitPin:SetPinTexture( 'party','Interface\\WorldMap\\Skull_64Blue' );
            else
                WorldMapUnitPin:SetPinTexture( 'player','Interface\\WorldMap\\WorldMapArrow' );
            end
            --WorldMapUnitPin:SetUseClassColor( 'party',true );
            --WorldMapUnitPin:SetUseClassColor( 'raid',true );
            WorldMapUnitPin:SetFrameStrata( 'TOOLTIP' );

            WorldMapUnitPin:StartPlayerPing( 1,self:GetValue( 'PinAnimDuration' ) );
        end

        --
        -- Map Zone Update
        --
        -- @return  void
        Addon.MAP.UpdateZone = function( self )
            if( InCombatLockdown() ) then
                return;
            end
            -- Verify
            if( not WorldMapFrame ) then
                return;
            end
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

            -- Position
            WorldMapFrame:SetMovable( true );
            WorldMapFrame:RegisterForDrag( 'LeftButton' );
            WorldMapFrame:SetScript( 'OnDragStart',self.WorldMapFrameStartMoving );
            WorldMapFrame:SetScript( 'OnDragStop',self.WorldMapFrameStopMoving );

            -- Opacity
            WorldMapFrame:SetAlpha( self:GetValue( 'MapAlpha' ) );

            -- Sit behind
            WorldMapFrame:SetFrameStrata( 'LOW' );
            
            --WorldMapFrame:EnableMouse( false );

            -- Passback
            local _,_,_,X,Y = WorldMapFrame:GetPoint();
            WorldMapFrame.x,WorldMapFrame.y = X,Y;

            -- Settings
            self:SetPosition();
            self:UpdatePin();

            -- Ping map
            self:GetUnitPin():StartPlayerPing( 1,self:GetValue( 'PinAnimDuration' ) );

            -- Show map
            if( not WorldMapFrame:IsShown() and self:GetValue( 'AlwaysShow' ) ) then
                WorldMapFrame:Show();
            end
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
            SetCVar( 'mapFade',0 );

            -- Reaply
            C_Timer.After( 2, function()
               self:Refresh();
            end );
        end

        self:Init();
        self:CreateFrames();
        self:Run();
        self:UnregisterEvent( 'ADDON_LOADED' );
    end
end );