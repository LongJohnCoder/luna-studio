{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE TemplateHaskell #-}

module Luna.Typechecker.StageTypecheckerState.Class where


import Flowbox.Prelude

import Text.PrettyPrint

import Luna.Data.StructInfo              (StructInfo)
import Luna.Typechecker.Data             (Constraint, Subst, TVar(..), Typo, TypeMap, TypeSchemeMap, init_typo)
import Luna.Typechecker.Debug.PrettyData (prettyConstr, prettyNullable, prettySubst, prettyTypo, prettyTypeMap, prettyTVar)



data StageTypecheckerState = StageTypecheckerState  { _debugLog      :: [Text]
                                                    , _typo          :: [Typo]
                                                    , _nextTVar      :: TVar
                                                    , _subst         :: Subst
                                                    , _constr        :: Constraint
                                                    , _sa            :: StructInfo
                                                    -- TODO [llachowski]
                                                    -- 30.01 2015: typeMap
                                                    -- and typeScheme
                                                    -- should be local for
                                                    -- each expression,
                                                    -- similar to environment
                                                    , _typeMap       :: TypeMap
                                                    , _typeSchemeMap :: TypeSchemeMap
                                                    }

makeLenses ''StageTypecheckerState


instance Default StageTypecheckerState where
    def = StageTypecheckerState { _debugLog      = []
                                , _typo          = init_typo
                                , _nextTVar      = TVar 0
                                , _subst         = def
                                , _constr        = mempty
                                , _sa            = mempty
                                , _typeMap       = mempty
                                , _typeSchemeMap = mempty
                                }


instance Show StageTypecheckerState where
    show = render . prettyState


prettyState :: StageTypecheckerState -> Doc
prettyState StageTypecheckerState{..} = str_field
                                    $+$ constr_field
                                    $+$ typo_field
                                    $+$ subst_field
                                    $+$ nextTVar_field
                                    $+$ typeMap_field
      where
        str_field      = text "Debug       :" <+> prettyNullable (map (text.fromText) $ reverse _debugLog)
        constr_field   = text "Constraints :" <+> prettyConstr   _constr
        nextTVar_field = text "TVars used  :" <+> prettyTVar     _nextTVar
        typo_field     = text "Type env    :" <+> prettyNullable (map (parens . prettyTypo) _typo)
        subst_field    = text "Substs      :" <+> prettySubst    _subst
        typeMap_field  = text "Type map    :" <+> prettyTypeMap  _typeMap