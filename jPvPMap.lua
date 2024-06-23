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
                x = 40,
                y = -40,
                point = 'TOPLEFT',
                scale = 1.06,
                
                MapAlpha = 0.2,
                PinScale = 1,
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
                    MapAlpha = {
                        order = 2,
                        type = 'range',
                        name = 'Map Alpha',
                        desc = 'Main map alpha',
                        min = 0.1, max = 1, step = 0.1,
                        arg = 'MapAlpha',
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
                Addon.MAP.Container.SavePosition( WorldMapFrame );
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
            if( not WorldMapFrame:IsMaximized() ) then
                Addon.MAP.Container.RestorePosition( WorldMapFrame );
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

            -- Container
            self.Container = LibStub( 'LibWindow-1.1' );
            self.Container.RegisterConfig( WorldMapFrame,self.persistence );

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
                    self:GetParent().x, self:GetParent().y = x, y;
                end
            end );
            WorldMapFrame.Resize:SetScript( 'OnMouseUp',function( self,Button )
                if( Button == 'LeftButton' ) then
                    Addon.MAP.Scaling = false;
                    Addon.MAP:SetValue( 'scale',WorldMapFrame:GetScale() );
                end
            end );

            --[[
            -- commented out bc currently overwriting whatever OnEnter hook already exists
            -- i'm not seeing an OnEnter attatched to QuestScrollFrame.DetailFrame.OnEnter however
            -- /wow-retail-source/Interface/FrameXML/QuestMapFrame.lua

            -- Quest mouseover
            LibStub( 'AceHook-3.0' ):SecureHookScript( QuestScrollFrame.DetailFrame,'OnEnter',function()
                WorldMapFrame:SetAlpha( 1 );
                QuestScrollFrame.DetailFrame:SetAlpha( 1 );
            end );
            -- Quest mouseaway
            LibStub( 'AceHook-3.0' ):SecureHookScript( QuestScrollFrame.DetailFrame,'OnLeave',function()
                WorldMapFrame:SetAlpha( self:GetValue( 'MapAlpha' ) );
                QuestScrollFrame.DetailFrame:SetAlpha( self:GetValue( 'MapAlpha' ) );
            end );
            ]]
            -- Show
            LibStub( 'AceHook-3.0' ):SecureHookScript( WorldMapFrame,'OnShow',function( Map )
                Map:SetAlpha( self:GetValue( 'MapAlpha' ) );
                self:SetPosition();
                self:UpdatePin();
                local PreviousZone = C_Map.GetBestMapForUnit( 'player' );
                if( PreviousZone ) then
                    self.PreviousZone = PreviousZone;
                end
            end );
            -- Update
            LibStub( 'AceHook-3.0' ):SecureHookScript( WorldMapFrame,'OnUpdate',function( Map )
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
                        Addon.MAP.UpdateMap();
                    end
                end
            end );
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
            if( not self.persistence ) then
                return;
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
        end

        --
        --  Module run
        --
        --  @return void
        Addon.MAP.Run = function( self )
            -- Verify
            if( not WorldMapFrame ) then
                return;
            end
            
            -- Cvars
            SetCVar('questLogOpen',not self:GetValue( 'PanelColapsed' ) );

            C_Timer.After( 2, function()
                -- Strata
                WorldMapFrame:SetFrameStrata( 'LOW' );

                -- Position
                WorldMapFrame:SetMovable( true );
                WorldMapFrame:RegisterForDrag( 'LeftButton' );
                WorldMapFrame:SetScript( 'OnDragStart',self.WorldMapFrameStartMoving );
                WorldMapFrame:SetScript( 'OnDragStop',self.WorldMapFrameStopMoving );
                self:SetPosition();

                -- Passback
                local _,_,_,x,y = WorldMapFrame:GetPoint();
                WorldMapFrame.x,WorldMapFrame.y = x,y;
                
                --WorldMapFrame:EnableMouse( false );
            end );
        end

        self:Init();
        self:CreateFrames();
        self:Refresh();
        self:Run();
        self:UnregisterEvent( 'ADDON_LOADED' );
    end
end );