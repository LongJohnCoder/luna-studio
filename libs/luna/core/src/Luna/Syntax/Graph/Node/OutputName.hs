---------------------------------------------------------------------------
-- Copyright (C) Flowbox, Inc - All Rights Reserved
-- Unauthorized copying of this file, via any medium is strictly prohibited
-- Proprietary and confidential
-- Flowbox Team <contact@flowbox.io>, 2014
---------------------------------------------------------------------------

module Luna.Syntax.Graph.Node.OutputName (
    provide,
    fixEmpty,
    fixEmpty',
    generate,
) where

import qualified Data.Char as Char
import qualified Data.List as List

import           Flowbox.Prelude
import           Luna.Syntax.Graph.Node            (Node)
import qualified Luna.Syntax.Graph.Node            as Node
import           Luna.Syntax.Graph.Node.Expr       (NodeExpr)
import qualified Luna.Syntax.Graph.Node.Expr       as NodeExpr
import qualified Luna.Syntax.Graph.Node.StringExpr as StringExpr



generate :: NodeExpr a e -> Int -> String
generate nodeExpr num = mangle (exprStr ++ "Result") ++ show num where
    exprStr = case nodeExpr of
        NodeExpr.ASTExpr    {}      -> ""
        NodeExpr.StringExpr strExpr -> StringExpr.toString strExpr


fixEmpty :: Node a e -> Node.ID -> Node a e
fixEmpty node nodeID = case node ^. Node.outputName of
    "" -> provide node nodeID
    _  -> node


fixEmpty' :: (Node.ID, Node a e) -> (Node.ID, Node a e)
fixEmpty' (nodeID, node) =
    (nodeID, fixEmpty node nodeID)


provide :: Node a e -> Node.ID -> Node a e
provide node@(Node.Expr nodeExpr _ _) nodeID =
    node & Node.outputName .~ generate nodeExpr nodeID
provide node                   _      = node


mangle :: String -> String
mangle name = case List.takeWhile Char.isAlphaNum name of
    f:alphaNum -> if Char.isDigit f
                     then 'r' : f : alphaNum
                     else Char.toLower f : alphaNum
    []         -> "node"