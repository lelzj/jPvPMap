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
                        desc = 'Whether or not to display your pin as a skull',
                        arg = 'skullMyAss',
                    },
                    zoneUpdate = {
                        order = 6,
                        type = 'toggle',
                        name = 'zoneUpdate',
                        desc = 'Whether or not the map should update when entering a new zone',
                        arg = 'zoneUpdate',
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
            --[[
            local x,y  = 0,0;
            local pos  = C_Map.GetPlayerMapPosition( WorldMapFrame:GetMapID(),'player' );
            if pos then
                x,y = pos:GetXY();
            end
            ]]
            local mapID = C_Map.GetBestMapForUnit( 'player' );
            --local mapInfo = C_Map.GetMapInfoAtPosition( WorldMapFrame:GetMapID(),x,y );
            if mapID then
                WorldMapFrame:SetMapID( mapID );
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
            self.Events = CreateFrame( 'Frame' );
        end

        --
        --  Module run
        --
        --  @return void
        Addon.MAP.Run = function( self )
            -- Unit moving
            local WorldMapUnitPin = self:GetUnitPin();
            LibStub( 'AceHook-3.0' ):SecureHook( WorldMapUnitPin, 'OnMapChanged', function()
                self:UpdatePin();
            end );
            self.Events:RegisterEvent( 'PLAYER_STARTED_MOVING' );
            self.Events:RegisterEvent( 'PLAYER_STARTED_LOOKING' );
            self.Events:RegisterEvent( 'PLAYER_STARTED_TURNING' );
            if( self:GetValue( 'zoneUpdate' ) ) then
                self.Events:RegisterEvent( 'ZONE_CHANGED_NEW_AREA' );
            end
            self.Events:SetScript( 'OnEvent',function( self,Event,... ) 
                if( Event == 'PLAYER_STARTED_MOVING' 
                    or Event == 'PLAYER_STARTED_LOOKING' 
                    or Event == 'PLAYER_STARTED_TURNING' ) then
                    if( WorldMapFrame:IsShown() ) then
                        Addon.MAP:UpdatePin();
                    end
                elseif( Event == 'ZONE_CHANGED_NEW_AREA' ) then
                    Addon.MAP.UpdateMap();
                end
            end );

            -- Unit pin scale
            if( WorldMapUnitPin ) then
                LibStub( 'AceHook-3.0' ):SecureHook( WorldMapUnitPin, 'SynchronizePinSizes', function() 
                    WorldMapUnitPin:SetPlayerPingScale( self:GetValue( 'pinScale' ) );
                end );
            end
            -- Map mouseover
            LibStub( 'AceHook-3.0' ):SecureHookScript( WorldMapFrame.ScrollContainer,'OnEnter',function()
                WorldMapFrame:SetAlpha( 1 );
            end );
            -- Map mouseaway
            LibStub( 'AceHook-3.0' ):SecureHookScript( WorldMapFrame.ScrollContainer,'OnLeave',function()
                WorldMapFrame:SetAlpha( self:GetValue( 'mapAlpha' ) );
            end );
            -- Map show
            SetCVar( 'mapFade',0 );
            LibStub( 'AceHook-3.0' ):SecureHookScript( WorldMapFrame, 'OnShow', function() 
                WorldMapFrame:SetAlpha( self:GetValue( 'mapAlpha' ) );
                self:UpdatePin();
            end );
        end

        self:Init();
        self:CreateFrames();
        self:Refresh();
        self:Run();
        self:UnregisterEvent( 'ADDON_LOADED' );
    end
end );