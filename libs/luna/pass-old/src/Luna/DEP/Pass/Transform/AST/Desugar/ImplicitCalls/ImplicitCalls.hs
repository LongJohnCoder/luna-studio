---------------------------------------------------------------------------
-- Copyright (C) Flowbox, Inc - All Rights Reserved
-- Unauthorized copying of this file, via any medium is strictly prohibited
-- Proprietary and confidential
-- Flowbox Team <contact@flowbox.io>, 2014
---------------------------------------------------------------------------
{-# LANGUAGE ConstraintKinds           #-}
{-# LANGUAGE FlexibleContexts          #-}
{-# LANGUAGE NoMonomorphismRestriction #-}
{-# LANGUAGE Rank2Types                #-}
{-# LANGUAGE TemplateHaskell           #-}

module Luna.DEP.Pass.Transform.AST.Desugar.ImplicitCalls.ImplicitCalls where

import           Flowbox.Prelude                                   hiding (error, id, mod)
import           Flowbox.System.Log.Logger
import qualified Luna.DEP.AST.Arg                                  as Arg
import qualified Luna.DEP.AST.Expr                                 as Expr
import           Luna.DEP.AST.Module                               (Module)
import qualified Luna.DEP.AST.Module                               as Module
import           Luna.DEP.AST.Pat                                  (Pat)
import qualified Luna.DEP.AST.Pat                                  as Pat
import           Luna.DEP.Data.ASTInfo                             (ASTInfo)
import           Luna.DEP.Pass.Pass                                (Pass)
import qualified Luna.DEP.Pass.Pass                                as Pass
import           Luna.DEP.Pass.Transform.AST.Desugar.General.State (DesugarState)
import qualified Luna.DEP.Pass.Transform.AST.Desugar.General.State as DS


logger :: LoggerIO
logger = getLoggerIO $(moduleName)


type DesugarPass result = Pass DesugarState result


run :: ASTInfo -> Module -> Pass.Result (Module, ASTInfo)
run inf = (Pass.run_ (Pass.Info "Desugar.ImplicitCalls") $ DS.mk inf) . desugar


desugar :: Module -> DesugarPass (Module, ASTInfo)
desugar mod = (,) <$> desugarModule mod <*> DS.getInfo


desugarModule :: Module -> DesugarPass Module
desugarModule mod = Module.traverseM desugarModule desugarExpr pure desugarPat pure pure mod

--TODO[wd]: convert to traverses!
desugarArg :: Arg.Arg Expr.Expr -> DesugarPass (Arg.Arg Expr.Expr)
desugarArg a = case a of
    Arg.Unnamed id      arg -> fmap (Arg.Unnamed id)      $ desugarExpr arg
    Arg.Named   id name arg -> fmap (Arg.Named   id name) $ desugarExpr arg

desugarExpr :: Expr.Expr -> DesugarPass Expr.Expr
desugarExpr ast = case ast of
    Expr.Con      {}                           -> Expr.App <$> DS.genID <*> continue <*> pure []
    Expr.App      id src args                  -> Expr.App id <$> omitNextExpr src <*> mapM desugarArg args
    Expr.Accessor id name dst                  -> Expr.App <$> DS.genID <*> continue <*> pure []
    Expr.Import   {}                           -> omitAll
    _                                          -> continue
    where continue  = desugarExprGeneral ast
          omitNext  = Expr.traverseM omitNextExpr pure desugarPat pure pure ast
          omitAll   = Expr.traverseM omitAllExpr pure desugarPat pure pure ast


omitNextExpr :: Expr.Expr -> DesugarPass Expr.Expr
omitNextExpr ast = continue
    where continue = desugarExprGeneral ast

desugarExprGeneral :: Expr.Expr -> DesugarPass Expr.Expr
desugarExprGeneral ast = case ast of
    Expr.Ref      {}                           -> omitAll
    _                                          -> continue
    where continue  = Expr.traverseM desugarExpr pure desugarPat pure pure ast
          omitAll   = Expr.traverseM omitAllExpr pure desugarPat pure pure ast

omitAllExpr :: Expr.Expr -> DesugarPass Expr.Expr
omitAllExpr ast = continue
    where continue = Expr.traverseM omitAllExpr pure desugarPat pure pure ast


desugarPat :: Pat -> DesugarPass Pat
desugarPat pat = case pat of
    _              -> continue
    where continue = Pat.traverseM desugarPat pure pure pat