---------------------------------------------------------------------------
-- Copyright (C) Flowbox, Inc - All Rights Reserved
-- Unauthorized copying of this file, via any medium is strictly prohibited
-- Proprietary and confidential
-- Flowbox Team <contact@flowbox.io>, 2014
---------------------------------------------------------------------------
{-# LANGUAGE ConstraintKinds  #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE Rank2Types       #-}
{-# LANGUAGE TemplateHaskell  #-}

module Luna.DEP.Pass.Transform.AST.DepSort.DepSort where

import           Flowbox.Prelude           hiding (error, id, mod)
import           Flowbox.System.Log.Logger hiding (info)
import qualified Luna.DEP.AST.AST          as AST
import qualified Luna.DEP.AST.Expr         as Expr
import           Luna.DEP.AST.Module       (Module)
import qualified Luna.DEP.AST.Module       as Module
import           Luna.DEP.Data.AliasInfo   (AliasInfo)
import qualified Luna.DEP.Data.AliasInfo   as AliasInfo
import           Luna.DEP.Data.CallGraph   (CallGraph)
import qualified Luna.DEP.Data.CallGraph   as CallGraph
import           Luna.DEP.Pass.Pass        (Pass)
import qualified Luna.DEP.Pass.Pass        as Pass
--import           Luna.Pass.Transform.AST.Desugar.General.State (DesugarState)
--import qualified Luna.Pass.Transform.AST.Desugar.General.State as DS



logger :: LoggerIO
logger = getLoggerIO $(moduleName)


type DepSortPass result = Pass Pass.NoState result


run :: CallGraph -> AliasInfo -> Module -> Pass.Result Module
run = (Pass.run_ (Pass.Info "Transform.DepSort") Pass.NoState) .:. depSort


depSort :: CallGraph -> AliasInfo -> Module -> DepSortPass Module
depSort cg info mod = do
    let sGraph = reverse $ CallGraph.sort cg
        mAst   = sequence $ map (\id -> info ^. AliasInfo.ast ^. at id) sGraph
    case mAst of
        Nothing      -> Pass.fail "Cannot make dependency sorting!"
        Just methods -> return $ (mod & Module.methods .~ (map AST.fromExpr methods))


dsMod :: Module -> DepSortPass Module
dsMod mod = Module.traverseM dsMod dsExpr pure pure pure pure mod


dsExpr :: Expr.Expr -> DepSortPass Expr.Expr
dsExpr ast = case ast of
--    Expr.Con      {}                           -> Expr.App <$> DS.genID <*> continue <*> pure []
--    Expr.App      id src args                  -> Expr.App id <$> omitNextExpr src <*> mapM dsExpr args
--    Expr.Accessor id name dst                  -> Expr.App <$> DS.genID <*> continue <*> pure []
--    Expr.Import   {}                           -> omitAll
    _                                          -> continue
    where continue  = Expr.traverseM dsExpr pure pure pure pure ast
--          omitNext  = Expr.traverseM omitNextExpr pure desugarPat pure ast
--          omitAll   = Expr.traverseM omitAllExpr pure desugarPat pure ast

