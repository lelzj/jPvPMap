local _, Addon = ...;

Addon.APP = CreateFrame( 'Frame' );
Addon.APP:RegisterEvent( 'ADDON_LOADED' );
Addon.APP:SetScript( 'OnEvent',function( self,Event,AddonName )
    if( AddonName == 'jPvPMap' ) then

        --
        --  Get module defaults
        --
        --  @return table
        Addon.APP.GetDefaults = function( self )
            return {
                MapPoint = 'TOPLEFT',
                MapRelativeTo = 'UIParent',
                MapRelativePoint = nil,
                MapXPos = 15.480,
                MapYPos = -48.181,
                MapScale = 0.866,
                MapAlpha = 0.2,

                PinAnimDuration = 90,
                SkullMyAss = 'Pink',
                MatchWorldScale = true,
                ClassColors = false,
                AlwaysShow = true,
                PanelColapsed = true,
                StopReading = true,
                SitBehind = false,
                UpdateZone = true,
                Debug = false,
            };
        end

        --
        --  Set value
        --
        --  @param  string  Index
        --  @param  mixed   Value
        --  @return void
        Addon.APP.SetValue = function( self,Index,Value )
            return Addon.DB:SetValue( Index,Value );
        end

        --
        --  Get value
        --
        --  @return mixed
        Addon.APP.GetValue = function( self,Index )
            return Addon.DB:GetValue( Index );
        end

        --
        --  Get module settings
        --
        --  @return table
        Addon.APP.GetSettings = function( self )

            local GetGeneral = function()
                local Order = 1;
                local Settings = {
                    General = {
                        type = 'header',
                        order = Order,
                        name = 'General',
                    },
                };
                Order = Order+1;
                Settings.AlwaysShow = {
                    order = Order,
                    type = 'toggle',
                    name = 'Always Show Map',
                    desc = 'Whether or not the map should remain open at all times',
                    arg = 'AlwaysShow',
                };
                Order = Order+1;
                Settings.MapAlpha = {
                    order = Order,
                    type = 'range',
                    name = 'Map Alpha',
                    desc = 'Map transparency/how well you can see behind the map while open',
                    min = 0.1, max = 1, step = 0.1,
                    arg = 'MapAlpha',
                };
                Order = Order+1;
                Settings.SitBehind = {
                    order = Order,
                    type = 'toggle',
                    name = 'Sit Behind Windows',
                    desc = 'If the map should sit behind other windows',
                    arg = 'SitBehind',
                };
                Order = Order+1;
                Settings.UpdateZone = {
                    order = Order,
                    type = 'toggle',
                    name = 'Auto Update Zone',
                    desc = 'Attempt to transition map to new zone automatically. Retail has known issues with this, as it seems to cause some errors',
                    arg = 'UpdateZone',
                };
                Order = Order+1;
                Settings.PanelColapsed = {
                    order = Order,
                    type = 'toggle',
                    name = 'Quest Panel Closed',
                    desc = 'Whether or not the retail version of the map should expand the quest list',
                    arg = 'PanelColapsed',
                };
                Order = Order+1;
                Settings.StopReading = {
                    order = Order,
                    type = 'toggle',
                    name = 'Stop Reading Emote',
                    desc = 'If your character should /read while the map is open',
                    arg = 'StopReading',
                };
                Order = Order+1;
                Settings.Debug = {
                    order = Order,
                    type = 'toggle',
                    name = 'Debug',
                    desc = 'Development debugging',
                    arg = 'Debug',
                };
                return Settings;
            end
            local GetPins = function()
                local Order = 1;
                local Settings = {
                    General = {
                        type = 'header',
                        order = Order,
                        name = 'Pins',
                    },
                };
                Order = Order+1;
                Settings.SkullMyAss = {
                    order = Order,
                    type = 'select',
                    name = 'Pin',
                    desc = 'Your player icon on the map',
                    values = {
                        Pink = 'Pink',
                        Blue = 'Blue',
                        Yellow = 'Yellow',
                        Green = 'Green',
                        Grey = 'Grey',
                        Red = 'Red',
                        Normal = 'Normal', 
                    },
                    arg = 'SkullMyAss',
                };
                Order = Order+1;
                Settings.PinAnimDuration = {
                    order = Order,
                    type = 'range',
                    name = 'Animation Duration',
                    desc = 'Pin location animation duration',
                    min = 10, max = 120, step = 10,
                    arg = 'PinAnimDuration',
                };
                Order = Order+1;
                Settings.ClassColors = {
                    order = Order,
                    type = 'toggle',
                    name = 'Class Colors',
                    desc = 'If group members should show on the map with their respective class colors',
                    arg = 'ClassColors',
                };
                Order = Order+1;
                Settings.MatchWorldScale = {
                    order = Order,
                    type = 'toggle',
                    name = 'Pin Scale',
                    desc = 'Attempt to match your map position scale to the scale of the world map. Seems to be just a retail thing...where maps are excessively large and player pin winds up being especially tiny by default',
                    arg = 'MatchWorldScale',
                };
                -- /Interface/FrameXML/UnitPositionFrameTemplates.lua
                return Settings;
            end

            local Settings = {
                type = 'group',
                get = function( Info )
                    if( Addon.DB:GetPersistence()[ Info.arg ] ~= nil ) then
                        return Addon.DB:GetPersistence()[ Info.arg ];
                    end
                end,
                set = function( Info,Value )
                    if( Addon.DB:GetPersistence()[ Info.arg ] ~= nil ) then
                        Addon.DB:GetPersistence()[ Info.arg ] = Value;
                        self:Refresh();
                    end
                end,
                name = 'jMap Settings',
                childGroups = 'tab',
                args = {},
            };

            -- General
            local Order = 0;
            Settings.args[ 'tab'..Order ] = {
                type = 'group',
                name = 'General',
                width = 'full',
                order = Order,
                args = GetGeneral(),
            };

            -- General
            Order = Order+1;
            Settings.args[ 'tab'..Order ] = {
                type = 'group',
                name = 'Pins',
                width = 'full',
                order = Order,
                args = GetPins(),
            };

            Settings.args.profiles = LibStub( 'AceDBOptions-3.0' ):GetOptionsTable( Addon.DB.db );

            return Settings;
        end;

        --
        --  Create module config frames
        --
        --  @return void
        Addon.APP.CreateFrames = function( self )
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

            self.Events:RegisterEvent( 'ZONE_CHANGED_NEW_AREA' );
            self.Events:RegisterEvent( 'ZONE_CHANGED' );
            self.Events:RegisterEvent( 'ZONE_CHANGED_INDOORS' );
            self.Events:SetScript( 'OnEvent',function( self,Event,... )
                if( InCombatLockdown() ) then
                    return;
                end
                if( Event == 'PLAYER_STARTED_MOVING' or Event == 'PLAYER_STARTED_LOOKING' or Event == 'PLAYER_STARTED_TURNING' ) then
                    Addon.APP:UpdatePin();
                    if( not WorldMapFrame:IsShown() and Addon.APP:GetValue( 'AlwaysShow' ) ) then
                        WorldMapFrame:Show();
                    end
                end
                if( Addon.APP:GetValue( 'UpdateZone' ) ) then
                    Addon.APP:UpdateZone();
                end
            end );
            
            -- Pin
            LibStub( 'AceHook-3.0' ):SecureHook( WorldMapUnitPin,'SynchronizePinSizes',function() 
                self:UpdatePin();
            end );

            -- Display
            LibStub( 'AceHook-3.0' ):SecureHook( WorldMapFrame,'SynchronizeDisplayState',function()
                if( not( WorldMapFrame:IsMaximized() ) ) then
                    self:SetPosition();
                    self:UpdateZone();
                end
                if( self:GetValue( 'Debug' ) ) then
                    Addon.FRAMES:Debug( 'WorldMapFrame','SynchronizeDisplayState' );
                end
            end );

            -- Scale
            WorldMapFrame.Resize = CreateFrame( 'Button','resize',WorldMapFrame );
            WorldMapFrame.Resize:SetSize( 32,32 );
            WorldMapFrame.Resize:SetPoint( 'bottomright',15,-15 );
            WorldMapFrame.Resize:SetNormalTexture( 'Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up' );
            WorldMapFrame.Resize:SetHighlightTexture( 'Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight' );
            WorldMapFrame.Resize:SetPushedTexture( 'Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down' );

            WorldMapFrame.Resize:SetScript( 'OnMouseDown',function( self,Button )
                if( Button == 'LeftButton' ) then
                    Addon.APP.Scaling = true;
                end
            end );
            WorldMapFrame.Resize:SetScript( 'OnUpdate',function( self,Button )
                if( Addon.APP.Scaling == true ) then

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
                Addon.APP.Scaling = false;
                if( Button == 'LeftButton' ) then
                    Addon.APP.Scaling = false;
                    Addon.APP:SetValue( 'MapScale',WorldMapFrame:GetScale() );
                end
            end );

            -- Show
            LibStub( 'AceHook-3.0' ):SecureHookScript( WorldMapFrame,'OnShow',function( Map )
                local PreviousZone = C_Map.GetBestMapForUnit( 'player' );
                if( PreviousZone ) then
                    self.PreviousZone = PreviousZone;
                end
                self:SetPosition();
                self:UpdateZone();
            end );

            -- MouseOver Map Frame
            WorldMapFrame:HookScript( 'OnUpdate',function( self )
                if( Addon.APP.Scaling ) then
                    self:SetAlpha( 1 );
                    return;
                end
                if( not self:IsMouseOver() ) then
                    self:SetAlpha( Addon.APP:GetValue( 'MapAlpha' ) );
                else
                    self:SetAlpha( 1 );
                end
            end );

            --[[
            if( not WorldMapFrame.NavBar ) then
                WorldMapFrame.Nav = CreateFrame( 'Frame',AddonName..'Nav',WorldMapFrame.ScrollContainer.Child );
                WorldMapFrame.Nav:SetSize( WorldMapFrame.ScrollContainer.Child:GetWidth(),60 );
                WorldMapFrame.Nav:SetPoint( 'topleft',WorldMapFrame.ScrollContainer.Child,'topleft',0,0 );

                local BGTheme = Addon.Theme.Background;
                local r,g,b,a = BGTheme.r,BGTheme.g,BGTheme.b,0.9;

                WorldMapFrame.Nav.Texture = WorldMapFrame.Nav:CreateTexture();
                WorldMapFrame.Nav.Texture:SetAllPoints( WorldMapFrame.Nav );
                WorldMapFrame.Nav.Texture:SetColorTexture( r,g,b,a );
            end
            ]]
        end

        --
        --  Map stop moving
        --
        --  @return void
        Addon.APP.WorldMapFrameStopMoving = function( self )
            WorldMapFrame:StopMovingOrSizing();
            if( not( WorldMapFrame:IsMaximized() ) ) then
                local MapPoint,MapRelativeTo,MapRelativePoint,MapXPos,MapYPos = WorldMapFrame:GetPoint();
                if( MapXPos ~= nil and MapYPos ~= nil ) then
                    Addon.APP:SetValue( 'MapPoint',MapPoint );
                    Addon.APP:SetValue( 'MapRelativeTo',MapRelativeTo );
                    Addon.APP:SetValue( 'MapRelativePoint',MapRelativePoint );
                    Addon.APP:SetValue( 'MapXPos',MapXPos );
                    Addon.APP:SetValue( 'MapYPos',MapYPos );

                    if( Addon.APP:GetValue( 'Debug' ) ) then
                        Addon:Dump( {
                            Action = 'Saving',
                            MapPoint = Addon.APP:GetValue( 'MapPoint' ),
                            MapRelativeTo = Addon.APP:GetValue( 'MapRelativeTo' ), 
                            MapRelativePoint = Addon.APP:GetValue( 'MapRelativePoint' ), 
                            MapXPos = Addon.APP:GetValue( 'MapXPos' ), 
                            MapYPos = Addon.APP:GetValue( 'MapYPos' ), 
                        } );

                        Addon.FRAMES:Debug( 'Addon.APP','WorldMapFrameStopMoving' );
                    end
                end
            end
            WorldMapFrame:SetUserPlaced( true );
        end

        --
        --  Map start moving
        --
        --  @return void
        Addon.APP.WorldMapFrameStartMoving = function( self )
            if not WorldMapFrame:IsMaximized() then
                WorldMapFrame:StartMoving()
            end
        end

        --
        --  Map save position
        --
        --  @return void
        Addon.APP.SetPosition = function( self )
            if( not( WorldMapFrame:IsMaximized() ) ) then
                local MapPoint,MapXPos,MapYPos = self:GetValue( 'MapPoint' ),self:GetValue( 'MapXPos' ),self:GetValue( 'MapYPos' );
                if( MapXPos ~= nil and MapYPos ~= nil ) then

                    if( Addon.APP:GetValue( 'Debug' ) ) then
                        Addon:Dump( {
                            Action = 'Loading',
                            MapPoint = MapPoint,
                            MapRelativeTo = MapRelativeTo, 
                            MapRelativePoint = MapRelativePoint, 
                            MapXPos = MapXPos, 
                            MapYPos = MapYPos, 
                        } );

                        Addon.FRAMES:Debug( 'Addon.APP','SetPosition' );
                    end
                    
                    WorldMapFrame:ClearAllPoints();
                    WorldMapFrame:SetPoint( MapPoint,MapXPos,MapYPos );
                    WorldMapFrame:SetScale( self:GetValue( 'MapScale' ) );
                end
            end
        end

        --
        -- Map Unit Pin
        --
        -- @return  mixed
        Addon.APP.GetUnitPin = function( self )
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
        Addon.APP.UpdatePin = function( self )
            if( InCombatLockdown() ) then
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

            if( self:GetValue( 'SkullMyAss' ) == 'Pink' ) then
                WorldMapUnitPin:SetPinTexture( 'player','Interface\\WorldMap\\Skull_64Purple' );
            end
            if( self:GetValue( 'SkullMyAss' ) == 'Blue' ) then
                WorldMapUnitPin:SetPinTexture( 'player','Interface\\WorldMap\\Skull_64Blue' );
            end
            if( self:GetValue( 'SkullMyAss' ) == 'Yellow' ) then
                WorldMapUnitPin:SetPinTexture( 'player','Interface\\WorldMap\\skull_64' );
            end
            if( self:GetValue( 'SkullMyAss' ) == 'Green' ) then
                WorldMapUnitPin:SetPinTexture( 'player','Interface\\WorldMap\\Skull_64Green' );
            end
            if( self:GetValue( 'SkullMyAss' ) == 'Grey' ) then
                WorldMapUnitPin:SetPinTexture( 'player','Interface\\WorldMap\\skull_64grey' );
            end
            if( self:GetValue( 'SkullMyAss' ) == 'Red' ) then
                WorldMapUnitPin:SetPinTexture( 'player','Interface\\WorldMap\\Skull_64Red' );
            end
            if( self:GetValue( 'SkullMyAss' ) == 'Normal' ) then
                WorldMapUnitPin:SetPinTexture( 'player','Interface\\WorldMap\\WorldMapArrow' );
            end

            --WorldMapUnitPin:SetPinTexture( 'party','Interface\\WorldMap\\Skull_64Grey' );
            --WorldMapUnitPin:SetPinTexture( 'raid','Interface\\WorldMap\\Skull_64Red' );
            --WorldMapUnitPin:SetPinTexture( 'party','Interface\\WorldMap\\Skull_64Green' );
            --WorldMapUnitPin:SetPinTexture( 'party','Interface\\WorldMap\\Skull_64Blue' );

            if( self:GetValue( 'ClassColors' ) ) then
                WorldMapUnitPin:SetUseClassColor( 'party',true );
                WorldMapUnitPin:SetUseClassColor( 'raid',true );
            else
                WorldMapUnitPin:SetUseClassColor( 'party',false );
                WorldMapUnitPin:SetUseClassColor( 'raid',false );
            end

            WorldMapUnitPin:SetFrameStrata( 'TOOLTIP' );

            WorldMapUnitPin:StartPlayerPing( 1,self:GetValue( 'PinAnimDuration' ) );
        end

        --
        -- Map Zone Update
        --
        -- @return  void
        Addon.APP.UpdateZone = function( self )
            if( InCombatLockdown() ) then
                return;
            end
            -- Verify
            if( not WorldMapFrame ) then
                return;
            end
            local NewPosition = WorldMapFrame.mapID;
            local CurrentZone = C_Map.GetBestMapForUnit( 'player' );

            if( CurrentZone ) then
                WorldMapFrame:SetMapID( CurrentZone );
            end

            --WorldMapFrame:ResetZoom();
        end

        --
        --  Module refresh
        --
        --  @return void
        Addon.APP.Refresh = function( self )
            if( not WorldMapFrame ) then
                return;
            end

            -- Map Opacity
            WorldMapFrame:SetAlpha( self:GetValue( 'MapAlpha' ) );

            -- Sit behind
            local DefaultStrata = WorldMapFrame:GetFrameStrata();
            if( Addon.APP:GetValue( 'SitBehind' ) and DefaultStrata ~= 'MEDIUM' ) then
                WorldMapFrame:SetFrameStrata( 'MEDIUM' );
            else
                WorldMapFrame:SetFrameStrata( DefaultStrata );
            end
            
            -- Player icon
            self:UpdatePin();
            
            -- Cvars
            SetCVar('questLogOpen',not self:GetValue( 'PanelColapsed' ) );
            SetCVar( 'mapFade',0 );

            -- Position
            self:SetPosition();
            
            -- I really love a cock in my ass
            --WorldMapFrame:EnableMouse( false );
        end

        --
        --  Module init
        --
        --  @return void
        Addon.APP.Init = function( self )
            if( not WorldMapFrame ) then
                return;
            end

            -- Position
            WorldMapFrame:SetMovable( true );
            WorldMapFrame:RegisterForDrag( 'LeftButton' );
            WorldMapFrame:SetScript( 'OnDragStart',self.WorldMapFrameStartMoving );
            WorldMapFrame:SetScript( 'OnDragStop',self.WorldMapFrameStopMoving );

            -- Emotes
            hooksecurefunc( 'DoEmote',function( Emote )
                if( Emote == 'READ' and WorldMapFrame:IsShown() ) then
                    if( Addon.APP:GetValue( 'StopReading' ) ) then
                        CancelEmote();
                    end
                end
            end );

            -- Slash command
            SLASH_JMAP1, SLASH_JMAP2 = '/jm', '/jpm';
            SlashCmdList['JMAP'] = function( Msg,EditBox )
                Settings.OpenToCategory( 'jMap' );
            end
        end

        --
        --  Module run
        --
        --  @return void
        Addon.APP.Run = function( self )
            if( not WorldMapFrame ) then
                return;
            end

            -- Reaply
            C_Timer.After( 2, function()
               self:Refresh();

                -- Ping map
                self:GetUnitPin():StartPlayerPing( 1,self:GetValue( 'PinAnimDuration' ) );

                -- Show map
                if( not WorldMapFrame:IsShown() and self:GetValue( 'AlwaysShow' ) ) then
                    WorldMapFrame:Show();
                end

                -- Position
                self:SetPosition();

                -- Zone
                self:UpdateZone();
            end );
        end

        Addon.DB:Init();
        self:Init();
        self:CreateFrames();
        self:Run();
        self:UnregisterEvent( 'ADDON_LOADED' );
    end
end );