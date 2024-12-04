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
        --  @return bool
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
                    Addon.APP:Ping();
                    if( not WorldMapFrame:IsShown() and Addon.APP:GetValue( 'AlwaysShow' ) ) then
                        WorldMapFrame:Show();
                    end
                end
                Addon.APP:UpdateZone();
            end );

            -- Display
            LibStub( 'AceHook-3.0' ):SecureHook( WorldMapFrame,'SynchronizeDisplayState',function()
                if( not( WorldMapFrame:IsMaximized() ) ) then
                    self:SetPosition();
                    --self:UpdateZone();
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
                if( Addon.APP:GetValue( 'MapFade' ) ) then
                    return;
                end
                if( not WorldMapFrame:IsMouseOver() ) then
                    WorldMapFrame:SetAlpha( Addon.APP:GetValue( 'MapAlpha' ) );
                else
                    WorldMapFrame:SetAlpha( 1 );
                end
            end );

            -- Zooming/Scaling
            local SliderData = {
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
            local RangeSlider = Addon.FRAMES:AddRange( SliderData,WorldMapFrame,{
                -- AddRange initialization calls this
                Get = function( Index )
                    return self:GetValue( 'MapScale' );
                end,
                -- AddRange:OnValueChanged calls this
                Set = function( Index,Value )
                    print( 'Set',Index,Value)
                    --return self:SetValue( 'MapScale',Value );
                end,
            } );
            -- Cause map zooming to control the slider
            WorldMapFrame.ScrollContainer:HookScript( 'OnMouseWheel',function( self,Value )
                if( not Addon.APP:GetValue( 'ScrollScale' ) ) then
                    return;
                end
                local CurrentValue = Addon.APP:GetValue( SliderData.Name );
                local ScrollDirection;
                if Value > 0 then
                    ScrollDirection = 'up';
                else
                    ScrollDirection = 'down';
                end

                local MaxValue;
                local MinValue;
                local NewValue;

                if ScrollDirection == 'up' then
                    MaxValue = SliderData.KeyPairs.High.Value;
                    NewValue = CurrentValue + SliderData.Step;
                    if NewValue > MaxValue then
                        return;
                    end
                elseif ScrollDirection == 'down' then
                    MinValue = SliderData.KeyPairs.Low.Value;
                    NewValue = CurrentValue - SliderData.Step;
                    if NewValue < MinValue then
                        return;
                    end
                end

                if( NewValue ~= nil ) then
                    RangeSlider.EditBox:SetText( NewValue );
                    Addon.APP:SetValue( SliderData.Name,NewValue );
                    Addon.APP:SetScale();
                end
                local WorldMapUnitPin = Addon.APP:GetUnitPin();
                if( not WorldMapUnitPin ) then
                    return;
                end
                WorldMapUnitPin:SynchronizePinSizes();
            end );

            WorldMapUnitPin:SetFrameStrata( 'TOOLTIP' );
            
            -- Interface/AddOns/Blizzard_SharedMapDataProviders/GroupMembersDataProvider.lua
            LibStub( 'AceHook-3.0' ):SecureHook( WorldMapUnitPin,'SynchronizePinSizes',function( self )
                local scale = self:GetMap():GetCanvasScale();
                for unit, size in self.dataProvider:EnumerateUnitPinSizes() do
                    if( Addon:IsClassic() and unit == 'player' ) then
                        size = size+10;
                        self:SetFrameStrata( 'TOOLTIP' );
                    end
                    if self.dataProvider:ShouldShowUnit(unit) then
                        self:SetPinSize(unit, size / scale);
                    end
                end
                self:SetPlayerPingScale( Addon.APP:GetValue( 'PinAnimScale' ) / scale);
            end );
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
            SetCVar('questLogOpen',Addon:BoolToInt( not self:GetValue( 'PanelColapsed' ) ) );

            SetCVar( 'mapFade',Addon:BoolToInt( self:GetValue( 'MapFade' ) ) );

            SetCVar( 'rotateMinimap',Addon:BoolToInt( self:GetValue( 'MiniRotate' ) ) );
        end

        --
        --  Map save scale
        --
        --  @return void
        Addon.APP.SetScale = function( self )
            WorldMapFrame:SetScale( self:GetValue( 'MapScale' ) );
        end

        --
        -- Get Map Unit Pin
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
        -- Update Map Unit Pin Colors
        --
        -- @return  mixed
        Addon.APP.UpdatePinColors = function( self )
            local WorldMapUnitPin = Addon.APP:GetUnitPin();
            if( not WorldMapUnitPin ) then
                return;
            end
            if( Addon.APP:GetValue( 'Debug' ) ) then
                Addon.FRAMES:Debug( 'UpdatePinColors call' );
            end

            local PinColor = Addon.APP:GetValue( 'SkullMyAss' );
            if( PinColor == 'Pink' ) then
                WorldMapUnitPin:SetPinTexture( 'player','Interface\\WorldMap\\Skull_64Purple' );
            elseif( PinColor == 'Blue' ) then
                WorldMapUnitPin:SetPinTexture( 'player','Interface\\WorldMap\\Skull_64Blue' );
            elseif( PinColor == 'Yellow' ) then
                WorldMapUnitPin:SetPinTexture( 'player','Interface\\WorldMap\\skull_64' );
            elseif( PinColor == 'Green' ) then
                WorldMapUnitPin:SetPinTexture( 'player','Interface\\WorldMap\\Skull_64Green' );
            elseif( PinColor == 'Grey' ) then
                WorldMapUnitPin:SetPinTexture( 'player','Interface\\WorldMap\\skull_64grey' );
            elseif( PinColor == 'Red' ) then
                WorldMapUnitPin:SetPinTexture( 'player','Interface\\WorldMap\\Skull_64Red' );
            elseif( PinColor == 'Normal' ) then
                WorldMapUnitPin:SetPinTexture( 'player','Interface\\WorldMap\\WorldMapArrow' );
            end
            local PingWidth,PingHeight = 75,75;

            if( Enum and Enum.PingTextureType and Enum.PingTextureType.Rotation ) then
                WorldMapUnitPin:SetPlayerPingTexture( Enum.PingTextureType.Rotation,'Interface\\minimap\\UI-Minimap-Ping-Rotate',PingWidth,PingHeight );
            end

            --WorldMapUnitPin:SetPinTexture( 'party','Interface\\WorldMap\\Skull_64Grey' );
            --WorldMapUnitPin:SetPinTexture( 'raid','Interface\\WorldMap\\Skull_64Red' );
            --WorldMapUnitPin:SetPinTexture( 'party','Interface\\WorldMap\\Skull_64Green' );
            --WorldMapUnitPin:SetPinTexture( 'party','Interface\\WorldMap\\Skull_64Blue' );

            if( Addon.APP:GetValue( 'ClassColors' ) ) then
                WorldMapUnitPin:SetUseClassColor( 'party',true );
                WorldMapUnitPin:SetUseClassColor( 'raid',true );
            else
                WorldMapUnitPin:SetUseClassColor( 'party',false );
                WorldMapUnitPin:SetUseClassColor( 'raid',false );
            end
        end

        --
        -- Animate Map Unit Pin
        --
        -- @return  void
        Addon.APP.Ping = function( self )
            if( InCombatLockdown() ) then
                return;
            end
            local WorldMapUnitPin = self:GetUnitPin();
            if( not WorldMapUnitPin ) then
                return;
            end
            if( Addon.APP:GetValue( 'PinPing' ) ) then
                WorldMapUnitPin:StartPlayerPing( 1,self:GetValue( 'PinAnimDuration' ) );
            else
                WorldMapUnitPin:StartPlayerPing( 1,0 );
                WorldMapUnitPin:StopPlayerPing();
            end
        end

        --
        -- Map Zone Update
        --
        -- @return  void
        Addon.APP.UpdateZone = function( self )
            if( not Addon.APP:GetValue( 'UpdateZone' ) ) then
                return;
            end
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

            -- Map Strata
            local DefaultStrata = WorldMapFrame:GetFrameStrata();
            if( Addon.APP:GetValue( 'SitBehind' ) and DefaultStrata ~= 'MEDIUM' ) then
                WorldMapFrame:SetFrameStrata( 'MEDIUM' );
            else
                WorldMapFrame:SetFrameStrata( DefaultStrata );
            end

            -- Map Show
            if( not WorldMapFrame:IsShown() and self:GetValue( 'AlwaysShow' ) ) then
                WorldMapFrame:Show();
            end

            -- Map Zone
            self:UpdateZone();

            -- Pin Color
            self:UpdatePinColors();

            -- CVars
            self:SetCVars();

            -- Pin Size
            local WorldMapUnitPin = self:GetUnitPin();
            if( not WorldMapUnitPin ) then
                return;
            end
            WorldMapUnitPin:SynchronizePinSizes();
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

            -- SetPassThroughButtons
            --[[
            hooksecurefunc( WorldMapFrame,'AcquirePin',function( PinTemplate,... )
                if( not WorldMapFrame.pinPools[ PinTemplate ] ) then
                    local pinTemplateType = WorldMapFrame.pinTemplateTypes[ PinTemplate ] or 'FRAME';
                    WorldMapFrame.pinPools[ PinTemplate ] = CreateFramePool( pinTemplateType,WorldMapFrame:GetCanvas(),PinTemplate,OnPinReleased );
                end

                local pin,newPin = WorldMapFrame.pinPools[ PinTemplate ]:Acquire();
                if( pin.SetPassThroughButtons ) then
                    pin.SetPassThroughButtons = nil;
                end
            end );
            ]]
            
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

            C_Timer.After( 2, function()
               self:Refresh();
               self:Ping();
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