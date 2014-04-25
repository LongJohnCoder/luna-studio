---------------------------------------------------------------------------
-- Copyright (C) Flowbox, Inc - All Rights Reserved
-- Unauthorized copying of this file, via any medium is strictly prohibited
-- Proprietary and confidential
-- Flowbox Team <contact@flowbox.io>, 2014
---------------------------------------------------------------------------
module Flowbox.RepoManager.Data.Package.Flag where

import Flowbox.Prelude

data Flag = Flag { name        :: String
                 , description :: String
                 , isSet       :: Bool
                 } deriving Show