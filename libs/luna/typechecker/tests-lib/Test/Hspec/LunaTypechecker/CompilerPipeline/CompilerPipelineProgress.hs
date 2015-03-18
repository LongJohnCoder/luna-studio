{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE RecordWildCards #-}

module Test.Hspec.LunaTypechecker.CompilerPipeline.CompilerPipelineProgress where


import            Flowbox.Prelude

import qualified  Luna.Data.ASTInfo                           as ASTInfo
import qualified  Luna.Data.StructInfo                        as StructInfo

import qualified  Luna.Pass.Target.HS.HASTGen                 as HASTGen
import qualified  Luna.Syntax.Enum                            as Enum

import qualified  Luna.Syntax.Expr                            as Expr
import qualified  Luna.Syntax.Module                          as Module
import qualified  Luna.Syntax.Unit                            as Unit

import qualified  Luna.Typechecker.StageTypecheckerState      as Typechecker



data CompilerPipelineProgress 
    = CompilerPipelineProgress  { _a_parsestage1_ast                :: Maybe (Unit.Unit (Module.LModule Enum.IDTag String))
                                , _a_parsestage1_astinfo            :: Maybe ASTInfo.ASTInfo
                                , _b_analysisstruct                 :: Maybe StructInfo.StructInfo
                                , _c_parsestage2_ast                :: Maybe (Unit.Unit (Module.LModule Enum.IDTag (Expr.LExpr Enum.IDTag ())))
                                , _c_parsestage2_astinfo            :: Maybe ASTInfo.ASTInfo
                                , _d_desugarimplicitself_ast        :: Maybe (Unit.Unit (Module.LModule Enum.IDTag (Expr.LExpr Enum.IDTag ())))
                                , _d_desugarimplicitself_astinfo    :: Maybe ASTInfo.ASTInfo
                                , _e_analysisstruct                 :: Maybe StructInfo.StructInfo
                                , _f_typecheckerinference_ast       :: Maybe (Unit.Unit (Module.LModule Enum.IDTag (Expr.LExpr Enum.IDTag ())))
                                , _f_typecheckerinference_tcstate   :: Maybe Typechecker.StageTypecheckerState
                                , _g_desugarimplicitscopes_ast      :: Maybe (Unit.Unit (Module.LModule Enum.IDTag (Expr.LExpr Enum.IDTag ())))
                                , _g_desugarimplicitscopes_astinfo  :: Maybe ASTInfo.ASTInfo
                                , _h_desugarimplicitcalls_ast       :: Maybe (Unit.Unit (Module.LModule Enum.IDTag (Expr.LExpr Enum.IDTag ())))
                                , _h_desugarimplicitcalls_astinfo   :: Maybe ASTInfo.ASTInfo
                                , _i_ssa                            :: Maybe (Unit.Unit (Module.LModule Enum.IDTag (Expr.LExpr Enum.IDTag ())))
                                , _j_hshastgen                      :: Maybe HASTGen.HE
                                , _k_hshsc                          :: Maybe Text
                                }
                                deriving (Show)

makeLenses ''CompilerPipelineProgress


instance Default CompilerPipelineProgress where
    def = CompilerPipelineProgress  { _a_parsestage1_ast                = Nothing
                                    , _a_parsestage1_astinfo            = Nothing
                                    , _b_analysisstruct                 = Nothing
                                    , _c_parsestage2_ast                = Nothing
                                    , _c_parsestage2_astinfo            = Nothing
                                    , _d_desugarimplicitself_ast        = Nothing
                                    , _d_desugarimplicitself_astinfo    = Nothing
                                    , _e_analysisstruct                 = Nothing
                                    , _f_typecheckerinference_ast       = Nothing
                                    , _f_typecheckerinference_tcstate   = Nothing
                                    , _g_desugarimplicitscopes_ast      = Nothing
                                    , _g_desugarimplicitscopes_astinfo  = Nothing
                                    , _h_desugarimplicitcalls_ast       = Nothing
                                    , _h_desugarimplicitcalls_astinfo   = Nothing
                                    , _i_ssa                            = Nothing
                                    , _j_hshastgen                      = Nothing
                                    , _k_hshsc                          = Nothing
                                    }