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
                mapAlpha = 0.2,
                pinScale = 1,
                pinAnimDuration = 90,
            };
        end

        Addon.MAP.SetValue = function( self,Index,Value )
            if( Addon.MAP.persistence[ Index ] ~= nil ) then
                Addon.MAP.persistence[ Index ] = Value;
            end
        end

        Addon.MAP.GetValue = function( self,Index )
            if( Addon.MAP.persistence[ Index ] ~= nil ) then
                return Addon.MAP.persistence[ Index ];
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
                    if( Addon.MAP.persistence[ Info.arg ] ~= nil ) then
                        return Addon.MAP.persistence[ Info.arg ];
                    end
                end,
                set = function( Info,Value )
                    if( Addon.MAP.persistence[ Info.arg ] ~= nil ) then
                        Addon.MAP.persistence[ Info.arg ] = Value;
                    end
                end,
                type = 'group',
                name = AddonName..' Settings',
                args = {
                    intro = {
                        order = 1,
                        type = 'description',
                        name = 'You\'ll need to run /script SetCVar( \'mapFade\',0 ); for the fading to work correctly',
                    },
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
                }
            };
            -- /Interface/FrameXML/UnitPositionFrameTemplates.lua
        end;

        --
        --  Create module config frames
        --
        --  @return void
        Addon.MAP.CreateFrames = function( self )
            Addon.MAP.Config = LibStub( 'AceConfigDialog-3.0' ):AddToBlizOptions( string.upper( AddonName ),AddonName );
            Addon.MAP.Config.okay = function( self )
            	Addon.MAP:Refresh();
                RestartGx();
            end
            Addon.MAP.Config.default = function( self )
                Addon.MAP.db:ResetDB();
            end
            LibStub( 'AceConfigRegistry-3.0' ):RegisterOptionsTable( string.upper( AddonName ),Addon.MAP:GetSettings() );
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
            local WorldMapUnitPin = Addon.MAP:GetUnitPin();
            if( not WorldMapUnitPin ) then
                return;
            end
            local animation_scale   = Addon.MAP:GetValue( 'pinScale' );
            local animation_seconds = Addon.MAP:GetValue( 'pinAnimDuration' );
            --WorldMapUnitPin:SetPinTexture( 'player', 'Interface\\WorldMap\\Skull_64Purple' );
            WorldMapUnitPin:SetPlayerPingScale( animation_scale );
            WorldMapUnitPin:StartPlayerPing( 1, animation_seconds );
        end

        --
        -- Map Zone Update
        --
        -- @return  void
        Addon.MAP.UpdateMap = function( self )
            local x, y  = 0,0;
            local pos   = C_Map.GetPlayerMapPosition( WorldMapFrame:GetMapID(), 'player' );
            if pos then
                x, y = pos:GetXY();
            end
            local mapInfo = C_Map.GetMapInfoAtPosition( WorldMapFrame:GetMapID(), x, y);
            if mapInfo then
                WorldMapFrame:SetMapID( mapInfo.mapID );
            end
        end

        --
        --  Module refresh
        --
        --  @return void
        Addon.MAP.Refresh = function( self )
            if( not Addon.MAP.persistence ) then
                return;
            end
        end

        --
        --  Module init
        --
        --  @return void
        Addon.MAP.Init = function( self )
            -- Database
            Addon.MAP.db = LibStub( 'AceDB-3.0' ):New( AddonName,{ char = Addon.MAP:GetDefaults() },true );
            if( not Addon.MAP.db ) then
                return;
            end
            Addon.MAP.persistence = Addon.MAP.db.char;
            if( not Addon.MAP.persistence ) then
                return;
            end
        end

        --
        --  Module run
        --
        --  @return void
        Addon.MAP.Run = function( self )
            -- Unit moving
            local WorldMapUnitPin = Addon.MAP:GetUnitPin();
            LibStub( 'AceHook-3.0' ):SecureHook( WorldMapUnitPin, 'OnMapChanged', function()
                Addon.MAP:UpdatePin();
            end );
            --[[Addon.MAP.Events:RegisterEvent( 'PLAYER_STARTED_MOVING' );
            Addon.MAP.Events:RegisterEvent( 'PLAYER_STARTED_LOOKING' );
            Addon.MAP.Events:RegisterEvent( 'PLAYER_STARTED_TURNING' );
            Addon.MAP.Events:SetScript( 'OnEvent',function( self,Event,... ) 
                if( Event == 'PLAYER_STARTED_MOVING' 
                    or Event == 'PLAYER_STARTED_LOOKING' 
                    or Event == 'PLAYER_STARTED_TURNING' ) then
                    if( WorldMapFrame:IsShown() ) then
                        Addon.MAP:UpdatePin();
                    end
                end
            end );]]
            -- Unit pin scale
            if( WorldMapUnitPin ) then
                LibStub( 'AceHook-3.0' ):SecureHook( WorldMapUnitPin, 'SynchronizePinSizes', function() 
                    WorldMapUnitPin:SetPlayerPingScale( Addon.MAP:GetValue( 'pinScale' ) );
                end );
            end
            -- Map mouseover
            LibStub( 'AceHook-3.0' ):SecureHookScript( WorldMapFrame.ScrollContainer,'OnEnter',function()
                WorldMapFrame:SetAlpha( 1 );
            end );
            -- Map mouseaway
            LibStub( 'AceHook-3.0' ):SecureHookScript( WorldMapFrame.ScrollContainer,'OnLeave',function()
                WorldMapFrame:SetAlpha( Addon.MAP:GetValue( 'mapAlpha' ) );
            end );
            -- Map show
            LibStub( 'AceHook-3.0' ):SecureHookScript( WorldMapFrame, 'OnShow', function() 
                WorldMapFrame:SetAlpha( Addon.MAP:GetValue( 'mapAlpha' ) );
                Addon.MAP:UpdatePin();
            end );
        end

        Addon.MAP:Init();
        Addon.MAP:CreateFrames();
        Addon.MAP:Refresh();
        Addon.MAP:Run();
        Addon.MAP:UnregisterEvent( 'ADDON_LOADED' );
    end
end );