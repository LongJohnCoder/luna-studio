module ThreeJS.PlaneGeometry where

import           Utils.PreludePlus

import           GHCJS.Foreign
import           GHCJS.Types      ( JSRef, JSString )
import           ThreeJS.Types
import           ThreeJS.Geometry

data PlaneGeometry

instance Geometry PlaneGeometry


foreign import javascript unsafe "new THREE.PlaneBufferGeometry($1, $2)"
    buildPlaneGeometry :: Double -> Double -> IO (JSRef PlaneGeometry)

buildNormalizedPlaneGeometry :: IO (JSRef PlaneGeometry)
buildNormalizedPlaneGeometry = do
    geom  <- buildPlaneGeometry 1.0 1.0
    translate geom 0.5 0.5 0.0
    return geom
