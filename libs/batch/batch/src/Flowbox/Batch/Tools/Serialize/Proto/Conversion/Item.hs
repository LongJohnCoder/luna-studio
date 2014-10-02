---------------------------------------------------------------------------
-- Copyright (C) Flowbox, Inc - All Rights Reserved
-- Unauthorized copying of this file, via any medium is strictly prohibited
-- Proprietary and confidential
-- Flowbox Team <contact@flowbox.io>, 2014
---------------------------------------------------------------------------

{-# OPTIONS_GHC -fno-warn-orphans #-}
{-# LANGUAGE FlexibleInstances     #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE TypeSynonymInstances  #-}

module Flowbox.Batch.Tools.Serialize.Proto.Conversion.Item where

import           Flowbox.Batch.FileSystem.Item                  (Item (..))
import qualified Flowbox.Batch.FileSystem.Item                  as Item
import           Flowbox.Control.Error
import           Flowbox.Prelude
import           Flowbox.Tools.Serialize.Proto.Conversion.Basic
import qualified Generated.Proto.Filesystem.Item                as Gen
import qualified Generated.Proto.Filesystem.Item.Type           as Gen



instance Convert Item Gen.Item where
    encode item = Gen.Item titemType tpath tsize where
        titemType = Just $ case item of
            Directory {} -> Gen.Directory
            File      {} -> Gen.File
            Other     {} -> Gen.Other
        tpath = encodePJ $ item ^. Item.path
        tsize = encodePJ $ item ^. Item.size
    decode (Gen.Item mtitemType mtpath mtsize) = do
        titemType <- mtitemType <?> "Failed to decode Item: 'itemType' field is missing"
        tpath     <- mtpath     <?> "Failed to decode Item: 'path' field is missing"
        tsize     <- mtsize     <?> "Failed to decode Item: 'size' field is missing"
        let apath = decodeP tpath
            asize = decodeP tsize
        case titemType of
            Gen.Directory -> return $ Directory apath asize
            Gen.File      -> return $ File      apath asize
            Gen.Other     -> return $ Other     apath asize
