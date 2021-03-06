module LunaStudio.API.Library.ListLibraries where

import           Data.Aeson.Types        (ToJSON)
import           Data.Binary             (Binary)
import qualified LunaStudio.API.Request  as R
import qualified LunaStudio.API.Response as Response
import qualified LunaStudio.API.Topic    as T
import           LunaStudio.Data.Library (Library, LibraryId)
import           LunaStudio.Data.Project (ProjectId)
import           Prologue


data Request = Request
    { _projectId :: ProjectId
    } deriving (Eq, Generic, Show)

data Result  = Result
    { _libraries :: [(LibraryId, Library)]
    } deriving (Eq, Generic, Show)

makeLenses ''Request
makeLenses ''Result

instance Binary Request
instance NFData Request
instance ToJSON Request
instance Binary Result
instance NFData Result
instance ToJSON Result


type Response = Response.Response Request () Result
instance Response.ResponseResult Request () Result

topicPrefix :: T.Topic
topicPrefix = "empire.library.list"
instance T.MessageTopic (R.Request Request) where
    topic _ = topicPrefix <> T.request
instance T.MessageTopic Response            where
    topic _ = topicPrefix <> T.response
