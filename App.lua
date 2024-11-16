local _, Addon = ...;

Addon.APP = CreateFrame( 'Frame' );
Addon.APP:RegisterEvent( 'ADDON_LOADED' );
Addon.APP:SetScript( 'OnEvent',function( self,Event,AddonName )
    if( AddonName == 'jPvPMap' ) then

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
        --  Create module config frames
        --
        --  @return void
        Addon.APP.CreateFrames = function( self )
            -- Verify
            local WorldMapUnitPin = self:GetUnitPin();
            if( not WorldMapUnitPin ) then
                return;
            end

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
                    WorldMapFrame:SetAlpha( Addon.APP:GetValue( 'MapAlpha' ) );
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

            -- Show
            LibStub( 'AceHook-3.0' ):SecureHookScript( WorldMapFrame,'OnShow',function( Map )
                local PreviousZone = C_Map.GetBestMapForUnit( 'player' );
                if( PreviousZone ) then
                    self.PreviousZone = PreviousZone;
                end
                self:SetPosition();
                self:UpdateZone();
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

            -- Fading
            -- /Blizzard_FrameXMLBase/PlayerMovementFrameFader.lua
            PlayerMovementFrameFader.RemoveFrame( WorldMapFrame );

            local FrameFaderDriver = CreateFrame( 'Frame',nil,WorldMapFrame );
            FrameFaderDriver:SetScript( 'OnUpdate',function( self,Elapsed )
                if( not WorldMapFrame:IsMouseOver() ) then
                    WorldMapFrame:SetAlpha( Addon.APP:GetValue( 'MapAlpha' ) );
                else
                    WorldMapFrame:SetAlpha( 1 );
                end
            end );

            local VarData = {
                Name = 'MapScale',
                Step = .1,
                KeyPairs = {
                    Low = {
                        Value = .5,
                        Description = 'Low',
                    },
                    High = {
                        Value = 2,
                        Description = 'High',
                    },
                },
            };

            local Values = {
                .1,
                .2,
                .3,
                .4,
                .5,
                .6,
                .7,
                .8,
                .9,
                1,
                1.1,
                1.2,
                1.3,
                1.4,
                1.5,
                1.6,
                1.7,
                1.8,
                1.9,
                2,
            };

            local Key = VarData.Name;
            local RangeSlider = CreateFrame( 'Slider',Key..'Range',WorldMapFrame,'OptionsSliderTemplate' );
            RangeSlider:Hide();

            RangeSlider:SetMinMaxValues( VarData.KeyPairs.Low.Value,VarData.KeyPairs.High.Value );
            RangeSlider:SetValueStep( VarData.Step );

            RangeSlider.minValue,RangeSlider.maxValue = RangeSlider:GetMinMaxValues();

            RangeSlider.Low:SetText( VarData.KeyPairs.Low.Value );
            RangeSlider.High:SetText( VarData.KeyPairs.High.Value );

            local Point,RelativeFrame,RelativePoint,X,Y = RangeSlider.Low:GetPoint();
            RangeSlider.Low:SetPoint( Point,RelativeFrame,RelativePoint,X+5,Y-5 );

            local Point,RelativeFrame,RelativePoint,X,Y = RangeSlider.High:GetPoint();
            RangeSlider.High:SetPoint( Point,RelativeFrame,RelativePoint,X-5,Y-5 );

            local TreatAsMouseEvent = true;
            local Value = Addon.APP:GetValue( Key );
            
            RangeSlider:SetValue( Addon.APP:GetValue( Key ),TreatAsMouseEvent );
            RangeSlider.keyValue = Key;
            RangeSlider.EditBox = CreateFrame( 'EditBox',Key..'SliderEditBox',Frame,'InputBoxTemplate' --[[and BackdropTemplate]] );
            WorldMapFrame.ScrollContainer:HookScript( 'OnMouseWheel',function( self,Value )
                if( not Addon.APP:GetValue( 'ScrollScale' ) ) then
                    return;
                end
                local CurrentValue = Addon.APP:GetValue( VarData.Name );
                local Direction;
                if Value > 0 then
                    Direction = 'up';
                else
                    Direction = 'down';
                end

                local MaxValue;
                local MinValue;
                local NewValue;

                if Direction == 'up' then
                    MaxValue = VarData.KeyPairs.High.Value;
                    NewValue = CurrentValue + VarData.Step;
                    if NewValue > MaxValue then
                        return;
                    end
                elseif Direction == 'down' then
                    MinValue = VarData.KeyPairs.Low.Value;
                    NewValue = CurrentValue - VarData.Step;
                    if NewValue < MinValue then
                        return;
                    end
                end

                if( NewValue ~= nil ) then
                    RangeSlider.EditBox:SetText( NewValue );
                    Addon.APP:SetValue( VarData.Name,NewValue );
                    Addon.APP:SetScale();
                end
            end );
            RangeSlider.EditBox:Disable();
            RangeSlider:SetHeight( 15 );

            RangeSlider:SetPoint( 'topleft',WorldMapFrame,'topright' );
            RangeSlider:SetOrientation( 'VERTICAL' );
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

        Addon.APP.SetCVars = function( self )
            SetCVar('questLogOpen',not self:GetValue( 'PanelColapsed' ) );
            SetCVar( 'mapFade',0 );
        end

        --
        --  Map save scale
        --
        --  @return void
        Addon.APP.SetScale = function( self )
            WorldMapFrame:SetScale( self:GetValue( 'MapScale' ) );
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

            -- Map Scale
            self:SetScale();

            -- Sit behind
            local DefaultStrata = WorldMapFrame:GetFrameStrata();
            if( Addon.APP:GetValue( 'SitBehind' ) and DefaultStrata ~= 'MEDIUM' ) then
                WorldMapFrame:SetFrameStrata( 'MEDIUM' );
            else
                WorldMapFrame:SetFrameStrata( DefaultStrata );
            end
            
            -- Player icon
            self:UpdatePin();
            
            -- Player position
            self:UpdateZone();
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

                -- CVars
                self:SetCVars();
            end );
        end

        Addon.DB:Init();
        Addon.CONFIG:Init( self );

        self:Init();
        self:CreateFrames();
        self:Run();
        self:UnregisterEvent( 'ADDON_LOADED' );
    end
end );