---------------------------------------------------------------------------
-- Copyright (C) Flowbox, Inc - All Rights Reserved
-- Unauthorized copying of this file, via any medium is strictly prohibited
-- Proprietary and confidential
-- Flowbox Team <contact@flowbox.io>, 2014
---------------------------------------------------------------------------

module Luna.Interpreter.RPC.Handler.Lift where

import           Flowbox.Bus.RPC.RPC              (RPC)
import           Flowbox.Control.Error
import           Flowbox.Prelude                  hiding (Context)
import           Flowbox.ProjectManager.Context   (Context)
import qualified Luna.Interpreter.Session.Error   as Error
import           Luna.Interpreter.Session.Session (Session, SessionST)



liftSession :: Session mm a -> RPC Context (SessionST mm) a
liftSession a = hoistEither . fmapL Error.format =<< lift2 (runEitherT a)


liftSession' :: (MonadTrans t, Monad m)
             => EitherT e m a -> t m (Either e a)
liftSession' a = lift (runEitherT a)