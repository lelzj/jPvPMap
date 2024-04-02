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
                mapAlpha = 0.1,
                pinScale = 1,
                pinAnimDuration = 90,
                zoneUpdate = false,
                skullMyAss = false,
                AlwaysShow = false,
                IsMovable = true,
            };
        end

        Addon.MAP.SetValue = function( self,Index,Value )
            if( self.persistence[ Index ] ~= nil ) then
                self.persistence[ Index ] = Value;
            end
        end

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
                    mapAlpha = {
                        order = 2,
                        type = 'range',
                        name = 'mapAlpha',
                        desc = 'Main map alpha',
                        min = 0.1, max = 1, step = 0.1,
                        arg = 'mapAlpha',
                    },
                    pinScale = {
                        order = 3,
                        type = 'range',
                        name = 'pinScale',
                        desc = 'Main map player pin scale',
                        min = 1, max = 2, step = 1,
                        arg = 'pinScale',
                    },
                    pinAnimDuration = {
                        order = 4,
                        type = 'range',
                        name = 'pinAnimDuration',
                        desc = 'Main map player pin animation duration',
                        min = 10, max = 120, step = 10,
                        arg = 'pinAnimDuration',
                    },
                    skullMyAss = {
                        order = 5,
                        type = 'toggle',
                        name = 'skullMyAss',
                        desc = 'Whether or not to display your position on the map as a skull',
                        arg = 'skullMyAss',
                    },
                    zoneUpdate = {
                        order = 6,
                        type = 'toggle',
                        name = 'zoneUpdate',
                        desc = 'Whether or not the map should update when you enter a new zone',
                        arg = 'zoneUpdate',
                    },
                    AlwaysShow = {
                        order = 7,
                        type = 'toggle',
                        name = 'AlwaysShow',
                        desc = 'Whether or not the map should open if you move and it is not already open',
                        arg = 'AlwaysShow',
                    },
                    IsMovable = {
                        order = 7,
                        type = 'toggle',
                        name = 'IsMovable',
                        desc = 'Whether or not the map should not be movable',
                        arg = 'IsMovable',
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
            self.Config = LibStub( 'AceConfigDialog-3.0' ):AddToBlizOptions( string.upper( AddonName ),AddonName );
            self.Config.okay = function( self )
            	self:Refresh();
                RestartGx();
            end
            self.Config.default = function( self )
                self.db:ResetDB();
            end
            LibStub( 'AceConfigRegistry-3.0' ):RegisterOptionsTable( string.upper( AddonName ),self:GetSettings() );
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
            local animation_scale   = self:GetValue( 'pinScale' );
            local animation_seconds = self:GetValue( 'pinAnimDuration' );
            if( self:GetValue( 'skullMyAss' ) ) then
                WorldMapUnitPin:SetPinTexture( 'player','Interface\\WorldMap\\Skull_64Purple' );
            end
            WorldMapUnitPin:SetPlayerPingScale( animation_scale );
            WorldMapUnitPin:StartPlayerPing( 1, animation_seconds );
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
            -- Database
            self.db = LibStub( 'AceDB-3.0' ):New( AddonName,{ char = self:GetDefaults() },true );
            if( not self.db ) then
                return;
            end
            self.persistence = self.db.char;
            if( not self.persistence ) then
                return;
            end
            -- Events
            self.Events = CreateFrame( 'Frame' );
        end

        --
        --  Module run
        --
        --  @return void
        Addon.MAP.Run = function( self )
            local WorldMapUnitPin = self:GetUnitPin();

            -- Map hooks
            if( WorldMapUnitPin ) then
                LibStub( 'AceHook-3.0' ):SecureHook( WorldMapUnitPin,'OnMapChanged',function()
                    self:UpdatePin();
                end );
            end
            self.Events:RegisterEvent( 'PLAYER_STARTED_MOVING' );
            self.Events:RegisterEvent( 'PLAYER_STARTED_LOOKING' );
            self.Events:RegisterEvent( 'PLAYER_STARTED_TURNING' );

            self.Events:SetScript( 'OnEvent',function( self,Event,... )
                -- Player movement
                if( Event == 'PLAYER_STARTED_MOVING' 
                    or Event == 'PLAYER_STARTED_LOOKING' 
                    or Event == 'PLAYER_STARTED_TURNING' ) then
                    if( WorldMapFrame:IsShown() ) then
                        Addon.MAP:UpdatePin();
                    end

                    if( not WorldMapFrame:IsShown() and Addon.MAP:GetValue( 'AlwaysShow' ) ) then
                        WorldMapFrame:Show();
                    end
                end
            end );

            -- Unit pin scale
            if( WorldMapUnitPin ) then
                LibStub( 'AceHook-3.0' ):SecureHook( WorldMapUnitPin,'SynchronizePinSizes',function() 
                    WorldMapUnitPin:SetPlayerPingScale( self:GetValue( 'pinScale' ) );
                end );
            end
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
                WorldMapFrame:SetAlpha( self:GetValue( 'mapAlpha' ) );
                QuestScrollFrame.DetailFrame:SetAlpha( self:GetValue( 'mapAlpha' ) );
            end );
            ]]
            -- Map show
            SetCVar( 'mapFade',0 );
            LibStub( 'AceHook-3.0' ):SecureHookScript( WorldMapFrame,'OnShow',function( Map ) 
                Map:SetAlpha( self:GetValue( 'mapAlpha' ) );
                self:UpdatePin();
                local PreviousZone = C_Map.GetBestMapForUnit( 'player' );
                if( PreviousZone ) then
                    self.PreviousZone = PreviousZone;
                end
            end );
            -- Map update
            LibStub( 'AceHook-3.0' ):SecureHookScript( WorldMapFrame,'OnUpdate',function( Map )
                -- Focus
                if( not Map:IsMouseOver() ) then
                    WorldMapFrame:SetAlpha( self:GetValue( 'mapAlpha' ) );
                -- Unfocus
                else
                    WorldMapFrame:SetAlpha( 1 );
                end
                -- Zone change
                local CurrentZone = C_Map.GetBestMapForUnit( 'player' );
                if( ( CurrentZone and self.PreviousZone ) and CurrentZone ~= self.PreviousZone ) then
                    if( self:GetValue( 'zoneUpdate' ) ) then
                        self.PreviousZone = CurrentZone;
                        Addon.MAP.UpdateMap();
                    end
                end
            end );
            C_Timer.After( 2, function()
                WorldMapFrame:SetFrameStrata( 'LOW' );

                -- Map move
                WorldMapFrame:SetMovable( Addon.MAP:GetValue( 'IsMovable' ) );
                LibStub( 'AceHook-3.0' ):SecureHookScript( WorldMapFrame,'OnDragStart',function( Map )
                    print( Map,'hooked' )
                    if( not Addon.MAP:GetValue( 'IsMovable' ) ) then
                        print( 'prevented' )
                        return false;
                    end
                end );
                
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