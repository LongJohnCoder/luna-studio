module Reactive.Commands.Graph where


import           Utils.PreludePlus
import           Utils.Vector
import           Utils.Angle
import qualified Utils.MockTC as MockTC
import qualified Utils.Nodes  as NodeUtils

import           Data.IntMap.Lazy (IntMap(..))
import qualified Data.IntMap.Lazy as IntMap
import           Data.Map (Map)
import qualified Data.Map as Map
import           Object.Object
import           Object.Node
import           Object.Port
import           Object.UITypes
import           Object.Widget
import qualified Object.Widget.Node       as Model
import qualified Object.Widget.Connection as ConnectionModel
import qualified Object.Widget.Port       as PortModel

import qualified JS.NodeGraph   as UI


import           Reactive.State.Graph
import qualified Reactive.State.Connect        as Connect
import qualified Reactive.State.Graph          as Graph
import qualified Reactive.State.UIRegistry     as UIRegistry
import qualified Reactive.State.Camera         as Camera
import qualified Reactive.State.Global         as Global
import           Reactive.Commands.Command     (Command, command, pureCommand, ioCommand)
import qualified Reactive.Commands.UIRegistry  as UICmd
import           Reactive.State.UIRegistry     (sceneGraphId)

import           Control.Monad.State

import qualified BatchConnector.Commands                           as BatchCmd

import qualified UI.Widget.Node as UINode
import qualified UI.Widget.Port as UIPort
import qualified UI.Widget.Connection as UIConnection
import qualified UI.Generic as UIGeneric
import           Reactive.State.Camera (Camera, screenToWorkspace)

updateConnNodes :: [NodeId] -> Command Global.State ()
updateConnNodes nodeIds = pureCommand $ \state -> let
    noConns nid   = not $ hasConnections nid (state ^. Global.graph)
    changeFun     = nodeIds & filter noConns
                            & map   (IntMap.adjust MockTC.revertNode)
                            & foldl (.) id
    nodesMap      = changeFun . Graph.getNodesMap . view Global.graph $ state
    newState      = state &  Global.graph %~ Graph.updateNodes nodesMap
    in newState

lookupAllConnections :: Command (UIRegistry.State b) [WidgetFile b ConnectionModel.Connection]
lookupAllConnections = gets UIRegistry.lookupAll

updateConnections :: Command Global.State ()
updateConnections = do
    allConnections <- zoom Global.uiRegistry lookupAllConnections
    nodePositions  <- zoom Global.uiRegistry nodePositionMap
    portAngles     <- zoom Global.uiRegistry portRefToAngleMap
    portTypes      <- portTypes
    connectionsMap <- uses Global.graph getConnectionsMap

    let updateSingleConnection widgetFile = do
        let connectionId   = widgetFile ^. widget . ConnectionModel.connectionId
            connection     = IntMap.lookup connectionId connectionsMap
            connectionLine = (\conn -> getConnectionLine nodePositions portAngles portTypes (conn ^. source) (conn ^. destination)) <$> connection
        forM_ connectionLine $ \(posFrom, posTo, visible, color) -> do
            zoom Global.uiRegistry $ do
                UICmd.update (widgetFile ^. objectId) $ (ConnectionModel.from    .~ posFrom)
                                                      . (ConnectionModel.to      .~ posTo)
                                                      . (ConnectionModel.visible .~ visible)
                                                      . (ConnectionModel.color   .~ color)

    mapM_ updateSingleConnection allConnections

getConnectionLine :: IntMap (Vector2 Double) -> Map PortRef Double -> Map PortRef ValueType -> PortRef  -> PortRef -> (Vector2 Double, Vector2 Double, Bool, Int)
getConnectionLine nodePos portAngles portTypes srcPortRef dstPortRef = (srcWs, dstWs, visible, color) where
    srcNWs@(Vector2 xSrcN ySrcN) = nodePos IntMap.! (srcPortRef ^. refPortNodeId)
    dstNWs@(Vector2 xDstN yDstN) = nodePos IntMap.! (dstPortRef ^. refPortNodeId)
    outerPos                     = portOuterBorder + distFromPort
    angleSrc                     = Map.findWithDefault missingPortPos srcPortRef portAngles
    angleDst                     = Map.findWithDefault missingPortPos dstPortRef portAngles
    srcWs                        = Vector2 (xSrcN + outerPos * cos angleSrc) (ySrcN + outerPos * sin angleSrc)
    dstWs                        = Vector2 (xDstN + outerPos * cos angleDst) (yDstN + outerPos * sin angleDst)
    delta                        = dstNWs - srcNWs
    visible                      = lengthSquared delta > 4 * portOuterBorderSquared
    color                        = fromMaybe missingPortColor $ colorVT <$> portTypes ^? ix srcPortRef
    missingPortPos               = -pi / 2.0
    missingPortColor             = 13

connectNodes :: PortRef -> PortRef -> Command Global.State ()
connectNodes src dst = do
    batchConnectNodes src dst
    localConnectNodes src dst

batchConnectNodes :: PortRef -> PortRef -> Command Global.State ()
batchConnectNodes src dst = ioCommand $ \state -> let
    workspace = state ^. Global.workspace
    in BatchCmd.connectNodes workspace src dst


-- localConnectNodes :: PortRef -> PortRef -> Command Global.State ()
-- localConnectNodes src dst = command $ \state -> let
--     oldGraph                     = state ^. Global.graph
--     oldRegistry                  = state ^. Global.uiRegistry
--     newState                     = state  & Global.graph      .~ newGraph
--                                           & Global.uiRegistry .~ newRegistry
--     valueType                    = view portValueType $ getPort oldGraph src
--     uiUpdate                     = forM_ file $ \f -> createConnectionWidget (f ^. objectId) (f ^. widget) color
--     validConnection              = (isJust $ NodeUtils.getPortByRef src oldNodesMap) && (isJust $ NodeUtils.getPortByRef dst oldNodesMap)
--     color                        = if validConnection then (colorVT valueType) else colorError
--
--     newNodesMap                  = oldNodesMap
--     oldNodesMap                  = Graph.getNodesMap oldGraph
--     updSourceGraph               = Graph.updateNodes newNodesMap oldGraph
--     (connId, newGraph)           = Graph.addConnection src dst updSourceGraph
--     (file, newRegistry)          = case connId of
--         Just connId             -> (Just widget, newRegistry) where
--             (widget, newRegistry)= UIRegistry.register UIRegistry.sceneGraphId uiConnection def oldRegistry
--             uiConnection         = getConnectionLine newNodesMap $ Graph.Connection connId src dst
--         Nothing                 -> (Nothing, oldRegistry)
--     in (uiUpdate, newState)

addConnectionM :: PortRef -> PortRef -> Command Global.State (Maybe ConnectionId)
addConnectionM src dst = do
    graph          <- use Global.graph
    let (connId, newGraph) = Graph.addConnection src dst graph
    Global.graph .= newGraph
    return connId

localConnectNodes :: PortRef -> PortRef -> Command Global.State ()
localConnectNodes src dst = do
    connectionId <- addConnectionM src dst
    forM_ connectionId $ \connectionId -> do
        nodePositions  <- zoom Global.uiRegistry nodePositionMap
        portAngles     <- zoom Global.uiRegistry portRefToAngleMap
        color <- return 5
        zoom Global.uiRegistry $ UICmd.register sceneGraphId (ConnectionModel.Connection connectionId False def def color) def
        return ()
    updatePortAngles
    updateConnections

sortAndGroup assocs = Map.fromListWith (++) [(k, [v]) | (k, v) <- assocs]

portRefToWidgetMap :: Command (UIRegistry.State a) (Map PortRef WidgetId)
portRefToWidgetMap = do
    ports <- allPorts
    return $ Map.fromList $ (\file -> (file ^. widget . PortModel.portRef, file ^. objectId)) <$> ports

portRefToAngleMap :: Command (UIRegistry.State a) (Map PortRef Double)
portRefToAngleMap = do
    ports <- allPorts
    return $ Map.fromList $ (\file -> (file ^. widget . PortModel.portRef, file ^. widget . PortModel.angle)) <$> ports

nodePositionMap :: Command (UIRegistry.State a) (IntMap (Vector2 Double))
nodePositionMap = do
    nodes <- allNodes
    return $ IntMap.fromList $ (\file -> (file ^. widget . Model.nodeId, file ^. widget . widgetPosition)) <$> nodes

connectionVector :: IntMap (Vector2 Double) -> PortRef -> PortRef -> Vector2 Double
connectionVector map src dst = explode (dstPos - srcPos) where
    srcPos = map IntMap.! (src ^. refPortNodeId)
    dstPos = map IntMap.! (dst ^. refPortNodeId)

defaultAngles :: Command Global.State (Map PortRef Double)
defaultAngles = do
    nodes <- use $ Global.graph . Graph.nodes

    let inputAngles = concat $ calculateInputAngles <$> nodes where
            calculateInputAngles node = portAngle <$> node ^. ports . inputPorts where
                inputPortNum = length $ node ^. ports . inputPorts
                portAngle port = (portRef, portDefaultAngle InputPort inputPortNum $ port ^. portId) where
                    portRef = PortRef (node ^. nodeId) InputPort (port ^. portId)

    let outputAngles = concat $ calculateOutputAngles <$> nodes where
            calculateOutputAngles node = portAngle <$> node ^. ports . outputPorts where
                outputPortNum = length $ node ^. ports . outputPorts
                portAngle port = (portRef, portDefaultAngle OutputPort outputPortNum $ port ^. portId) where
                    portRef = PortRef (node ^. nodeId) OutputPort (port ^. portId)

    return $ Map.fromList $ inputAngles ++ outputAngles

portTypes :: Command Global.State (Map PortRef ValueType)
portTypes = do
    nodes <- use $ Global.graph . Graph.nodes

    return $ Map.fromList $ concat $ getPorts <$> nodes where
            getPorts node = ins ++ outs where
                ins   = (getPort InputPort)  <$> node ^. ports . inputPorts
                outs  = (getPort OutputPort) <$> node ^. ports . outputPorts
                getPort tpe port = (portRef, port ^. portValueType) where
                    portRef = PortRef (node ^. nodeId) tpe (port ^. portId)

updatePortAngles :: Command Global.State ()
updatePortAngles = do
    connectionsMap <- use $ Global.graph . Graph.connectionsMap
    nodePositions  <- zoom Global.uiRegistry nodePositionMap

    let connectionTuples conn          = [ (conn ^. source,      conn ^. destination)
                                         , (conn ^. destination, conn ^. source     ) ]
        connections                    = sortAndGroup . concat $ connectionTuples <$> connectionsMap

    let calculateAngle portRef targets = toAngle . sum $ connectionVector nodePositions portRef <$> targets
        connectedAngles                = Map.mapWithKey calculateAngle connections

    defAngles <- defaultAngles

    let angles = Map.union connectedAngles defAngles
    portWidgets <- zoom Global.uiRegistry portRefToWidgetMap

    forM_ (Map.toList angles) $ \(portRef, angle) -> do
        let widgetId = portWidgets ^? ix portRef
        forM_ widgetId $ \widgetId -> zoom Global.uiRegistry $ UICmd.update widgetId (PortModel.angle .~ angle)


-- displayDragLine :: NodesMap -> Angle -> Vector2 Double -> Connect.Connecting -> IO ()
-- displayDragLine nodesMap angle ptWs@(Vector2 cx cy) connecting = putStrLn "Graph.hs: displayDragLine" -- do
--     let portRef              = connecting ^. Connect.sourcePortRef
--         port                 = connecting ^. Connect.sourcePort
--         color                = colorVT $ port ^. portValueType
--         ndWs@(Vector2 nx ny) = NodeUtils.getNodePos nodesMap $ portRef ^. refPortNodeId
--         outerPos             = portOuterBorder + distFromPort
--         sy                   = ny + outerPos * sin angle
--         sx                   = nx + outerPos * cos angle
--         (Vector2 vx vy)      = ptWs - ndWs
--         draw                 = vx * vx + vy * vy > portOuterBorderSquared
--     setAnglePortRef angle portRef
--     if draw then UI.displayCurrentConnection color sx sy cx cy
--             else UI.removeCurrentConnection


-- displayDragLine :: NodesMap -> PortRef -> Vector2 Double -> IO ()
-- displayDragLine nodesMap portRef ptWs@(Vector2 cx cy) = do
--     let angle = calcAngle ptWs ndWs
--     -- let portRef              = connecting ^. Connect.sourcePort
--         ndWs@(Vector2 nx ny) = NodeUtils.getNodePos nodesMap $ portRef ^. refPortNodeId
--         outerPos             = portOuterBorder + distFromPort
--         sy                   = ny + outerPos * sin angle
--         sx                   = nx + outerPos * cos angle
--         (Vector2 vx vy)      = ptWs - ndWs
--         draw                 = vx * vx + vy * vy > portOuterBorderSquared
--     setAnglePortRef angle portRef
--     if draw then UI.displayCurrentConnection sx sy cx cy
--             else UI.removeCurrentConnection

-- setAnglePortRef :: Angle -> PortRef -> IO ()
-- setAnglePortRef refAngle portRef = setAngle (portRef ^. refPortType)
--                                             (portRef ^. refPortNodeId)
--                                             (portRef ^. refPortId)
--                                             refAngle
--
-- setAngle :: PortType -> NodeId -> PortId -> Angle -> IO ()
-- setAngle  InputPort = UI.setInputPortAngle
-- setAngle OutputPort = UI.setOutputPortAngle

allNodes :: Command (UIRegistry.State a) [WidgetFile a Model.Node]
allNodes = UIRegistry.lookupAllM

allPorts :: Command (UIRegistry.State a) [WidgetFile a PortModel.Port]
allPorts = UIRegistry.lookupAllM

nodeIdToWidgetId :: NodeId -> Command (UIRegistry.State a) (Maybe WidgetId)
nodeIdToWidgetId nodeId = do
    files <- allNodes
    let matching = find (\file -> (file ^. widget . Model.nodeId) == nodeId) files
    return (view objectId <$> matching)

unselectAllNodes :: Command (UIRegistry.State a) ()
unselectAllNodes = do
    widgets <- allNodes
    forM_ widgets UINode.unselectNode



-- TODO: Clever algorithm taking radius into account
getNodesInRect :: Vector2 Int -> Vector2 Int -> Command Global.State [WidgetId]
getNodesInRect (Vector2 x1 y1) (Vector2 x2 y2) = do
    widgets <- zoom Global.uiRegistry allNodes
    camera  <- use $ Global.camera . Camera.camera
    let leftBottom = screenToWorkspace camera (Vector2 (min x1 x2) (min y1 y2)) - Vector2 radiusShadow radiusShadow
        rightTop   = screenToWorkspace camera (Vector2 (max x1 x2) (max y1 y2)) + Vector2 radiusShadow radiusShadow
        isNodeInBounds file = let pos = file ^. widget . widgetPosition in
                              leftBottom ^. x <= pos ^. x && pos ^. x <= rightTop ^. x &&
                              leftBottom ^. y <= pos ^. y && pos ^. y <= rightTop ^. y
        nodesInBounds = filter isNodeInBounds widgets
    return $ (view objectId) <$> nodesInBounds

