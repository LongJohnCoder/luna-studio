module LunaStudio.API.Graph.Undo where

import           Data.Aeson.Types        (ToJSON)
import           Data.Binary             (Binary)
import qualified LunaStudio.API.Request  as R
import qualified LunaStudio.API.Response as Response
import qualified LunaStudio.API.Topic    as T
import           Prologue


data UndoRequest = UndoRequest deriving (Eq, Generic, Show)

data Request = Request { _request :: UndoRequest } deriving (Eq, Generic, Show)

makeLenses ''UndoRequest
makeLenses ''Request
instance Binary UndoRequest
instance NFData UndoRequest
instance ToJSON UndoRequest
instance Binary Request
instance NFData Request
instance ToJSON Request


type Response = Response.Response Request () ()
instance Response.ResponseResult Request () ()

topicPrefix :: T.Topic
topicPrefix = "empire.undo"
instance T.MessageTopic (R.Request Request) where
    topic _ = topicPrefix <> T.request
instance T.MessageTopic Response            where
    topic _ = topicPrefix <> T.response
