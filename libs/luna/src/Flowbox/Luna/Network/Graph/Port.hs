---------------------------------------------------------------------------
-- Copyright (C) Flowbox, Inc - All Rights Reserved
-- Unauthorized copying of this file, via any medium is strictly prohibited
-- Proprietary and confidential
-- Flowbox Team <contact@flowbox.io>, 2013
---------------------------------------------------------------------------

module Flowbox.Luna.Network.Graph.Port(
    Port(..),
) where

import           Flowbox.Prelude   

data Port = Number Int
          | All
          deriving (Show, Read, Ord, Eq)