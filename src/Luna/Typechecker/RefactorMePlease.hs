module Luna.Typechecker.RefactorMePlease (
    mkTyID
  ) where

import Luna.Typechecker.IDs
import Luna.Typechecker.TIMonad
import Luna.Typechecker.Type.Type

import Control.Applicative
import Control.Monad.Trans


mkTyID :: TILogger Type
mkTyID = (TVar . Tyvar . TyID . show) <$> lift getNextID