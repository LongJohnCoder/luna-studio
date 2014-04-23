---------------------------------------------------------------------------
-- Copyright (C) Flowbox, Inc - All Rights Reserved
-- Unauthorized copying of this file, via any medium is strictly prohibited
-- Proprietary and confidential
-- Flowbox Team <contact@flowbox.io>, 2014
---------------------------------------------------------------------------
module Flowbox.RepoManager.Data.Dependency where

import           Flowbox.Prelude
import qualified Flowbox.RepoManager.Data.Version as Version

data Dependency = Dependency { depName     :: String
                             , constraints :: [Version.Constraint]
                             } deriving (Show)
