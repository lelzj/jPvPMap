local _, Addon = ...;

Addon.DB = CreateFrame( 'Frame' );
Addon.DB:RegisterEvent( 'ADDON_LOADED' );
Addon.DB:SetScript( 'OnEvent',function( self,Event,AddonName )
    if( AddonName == 'jPvPMap' ) then

        --
        --  Get module defaults
        --
        --  @return table
        Addon.DB.GetDefaults = function( self )
            return {
                MapPoint = 'TOPLEFT',
                MapRelativeTo = 'UIParent',
                MapRelativePoint = nil,
                MapXPos = 15.480,
                MapYPos = -48.181,
                MapScale = 0.866,
                MapAlpha = 0.2,
                MapFade = false,

                MiniRotate = true,

                PinAnimDuration = 90,
                PinAnimScale = 3,
                PinPing = true,
                SkullMyAss = 'Pink',
                MatchWorldScale = true,
                ClassColors = false,
                AlwaysShow = true,
                PanelColapsed = true,
                StopReading = true,
                SitBehind = false,
                UpdateZone = true,
                ScrollScale = true,
                Debug = false,
            };
        end

        Addon.DB.Reset = function( self )
            if( not self.db ) then
                return;
            end
            self.db:ResetDB();
        end

        --
        --  Get module persistence
        --
        --  @return table
        Addon.DB.GetPersistence = function( self )
            if( not self.db ) then
                return;
            end
            local Player = UnitName( 'player' );
            local Realm = GetRealmName();
            local PlayerRealm = Player..'-'..Realm;

            self.persistence = self.db.global;
            if( not self.persistence ) then
                return;
            end
            return self.persistence;
        end

        --
        -- Set DB value
        --
        -- @return void
        Addon.DB.SetValue = function( self,Index,Value )
            if( self:GetPersistence()[ Index ] ~= nil ) then
                self:GetPersistence()[ Index ] = Value;
            end
        end

        --
        -- Get DB value
        --
        -- @return mixed
        Addon.DB.GetValue = function( self,Index )
            if( self:GetPersistence()[ Index ] ~= nil ) then
                return self:GetPersistence()[ Index ];
            end
        end

        --
        --  Module init
        --
        --  @return void
        Addon.DB.Init = function( self )
            self.db = LibStub( 'AceDB-3.0' ):New( AddonName,{ global = self:GetDefaults() },true );
            if( not self.db ) then
                return;
            end

            if( not self:GetPersistence() ) then
                return;
            end
        end
        
        Addon.DB:UnregisterEvent( 'ADDON_LOADED' );
    end
end );