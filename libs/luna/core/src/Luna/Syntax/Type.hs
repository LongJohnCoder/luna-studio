---------------------------------------------------------------------------
-- Copyright (C) Flowbox, Inc - All Rights Reserved
-- Unauthorized copying of this file, via any medium is strictly prohibited
-- Proprietary and confidential
-- Flowbox Team <contact@flowbox.io>, 2014
---------------------------------------------------------------------------
{-# LANGUAGE UndecidableInstances #-}

module Luna.Syntax.Type where

import Flowbox.Prelude

import Luna.Syntax.Label     (Label)
import Luna.Syntax.Name.Path (NamePath)
import Luna.Syntax.Name      (VNameP, TNameP)


data Type a
    = Function { _inputs   :: [LType a]  , _output  :: LType a   }
    | App      { _src      :: LType a    , _args    :: [LType a] }
    | Var      { _vname    :: VNameP                             }
    | Tuple    { _items    :: [LType a]                          }
    | List     { _item     :: LType a                            }
    | Con      { _segments :: [TNameP]                           }
    | Meta     (LMeta a)
    | Wildcard 
    deriving (Show, Generic, Eq, Read)


type LType a = Label a (Type a)

data Meta = MetaCons TNameP
          | MetaVar  VNameP
          | MetaRoot
          deriving (Show, Generic, Eq, Read)

type LMeta a = Label a Meta