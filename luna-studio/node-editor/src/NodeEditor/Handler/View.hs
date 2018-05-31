module NodeEditor.Handler.View where

import           Common.Prelude

import           Common.Action.Command   (Command)
import           NodeEditor.Event.Event  (Event (View))
import           NodeEditor.State.Global (State)


handle :: Event -> Maybe (Command State ())
handle _ = Nothing
-- handle (View v) = Just $ print v
