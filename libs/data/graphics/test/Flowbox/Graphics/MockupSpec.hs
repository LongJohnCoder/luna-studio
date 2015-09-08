module Flowbox.Graphics.MockupSpec where

import Test.Hspec
import Test.QuickCheck
import Flowbox.Graphics.Mockup.Basic as M
import Flowbox.Graphics.Mockup.Filter as M
import Flowbox.Graphics.Composition.EdgeBlur as EB
import qualified Flowbox.Math.Matrix as M



import Flowbox.Prelude as P

import TestHelpers


spec :: Spec
spec = do
    let specPath = "./test/Flowbox/Graphics/"
        in do 
          let testName = "edgeBlur"
              testPath = specPath++testName
                in describe testName $ do 
                    it "waits for tests"
                      pending
                  