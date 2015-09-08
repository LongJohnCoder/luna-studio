---------------------------------------------------------------------------
-- Copyright (C) Flowbox, Inc - All Rights Reserved
-- Unauthorized copying of this file, via any medium is strictly prohibited
-- Proprietary and confidential
-- Flowbox Team <contact@flowbox.io>, 2014
---------------------------------------------------------------------------
{-# LANGUAGE TemplateHaskell #-}

module Luna.DEP.Graph.Node where

import           Flowbox.Prelude
import           Luna.DEP.Graph.Node.Expr       (NodeExpr)
import qualified Luna.DEP.Graph.Node.Expr       as NodeExpr
import           Luna.DEP.Graph.Node.Position   (Position)
import qualified Luna.DEP.Graph.Node.StringExpr as StringExpr



data Node = Expr     { _expr :: NodeExpr, _outputName :: String, _pos :: Position }
          | Inputs   {                                           _pos :: Position }
          | Outputs  {                                           _pos :: Position }
          deriving (Show, Eq)


makeLenses ''Node


type ID = Int



position' :: (ID, Node) -> (Float, Float)
position' = view pos . snd


isInputs :: Node -> Bool
isInputs (Inputs {}) = True
isInputs _           = False


isOutputs :: Node -> Bool
isOutputs (Outputs {}) = True
isOutputs _            = False


isExpr :: Node -> Bool
isExpr (Expr {}) = True
isExpr _         = False


exprStr :: Node -> Maybe String
exprStr (Expr (NodeExpr.StringExpr strExpr)  _ _) = Just $ StringExpr.toString strExpr
exprStr _                                         = Nothing