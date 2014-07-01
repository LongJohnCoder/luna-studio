---------------------------------------------------------------------------
-- Copyright (C) Flowbox, Inc - All Rights Reserved
-- Unauthorized copying of this file, via any medium is strictly prohibited
-- Proprietary and confidential
-- Flowbox Team <contact@flowbox.io>, 2014
---------------------------------------------------------------------------

module Flowbox.Graphics.Composition.Generators.Constant where

import Flowbox.Prelude                                    (Double)
import Flowbox.Graphics.Composition.Generators.Structures (Generator)
import Flowbox.Math.Matrix                                (Exp)



constant :: Exp Double -> Generator
constant value _ _ = value
