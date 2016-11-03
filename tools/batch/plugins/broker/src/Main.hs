---------------------------------------------------------------------------
-- Copyright (C) Flowbox, Inc - All Rights Reserved
-- Unauthorized copying of this file, via any medium is strictly prohibited
-- Proprietary and confidential
-- Flowbox Team <contact@flowbox.io>, 2014
---------------------------------------------------------------------------
{-# LANGUAGE TemplateHaskell #-}

module Main where

import qualified Control.Concurrent                  as Concurrent

import           ZMQ.Bus.Broker.Cmd                  (Cmd)
import qualified ZMQ.Bus.Broker.Cmd                  as Cmd
import qualified ZMQ.Bus.Broker.Proxy                as Proxy
import qualified ZMQ.Bus.Broker.Version              as Version
import qualified ZMQ.Bus.Control.BusCtx          as BusCtx
import qualified ZMQ.Bus.Control.Handler.Handler as Handler
import qualified ZMQ.Bus.EndPoint                as EP
import qualified ZMQ.Bus.Config               as Config
import           Flowbox.Options.Applicative         hiding (info)
import qualified Flowbox.Options.Applicative         as Opt
import           Flowbox.Prelude                     hiding (error, switch)
import           Flowbox.System.Log.Logger
import qualified ZMQ.RPC.Server.Server       as RPC


rootLogger :: Logger
rootLogger = getLogger ""


logger :: LoggerIO
logger = getLoggerIO $moduleName


parser :: Parser Cmd
parser = Opt.flag' Cmd.Version (long "version" <> hidden)
       <|> Cmd.Serve
           <$> optIntFlag (Just "verbose") 'v' 2 3          "Verbose level (level range is 0-5, default level is 3)"
           <*> switch    ( long "no-color"          <> help "Disable color output" )


opts :: ParserInfo Cmd
opts = Opt.info (helper <*> parser)
                (Opt.fullDesc <> Opt.header (Version.full False))


main :: IO ()
main = execParser opts >>= run


run :: Cmd -> IO ()
run cmd = case cmd of
    Cmd.Version  -> putStrLn (Version.full False) -- TODO [PM] hardcoded numeric = False
    Cmd.Serve {} -> do
        rootLogger setIntLevel $ Cmd.verbose cmd
        endPoints <- EP.serverFromConfig <$> Config.load
        logger info "Starting proxy service"
        _ <- Concurrent.forkIO $ Proxy.run (EP.pullEndPoint endPoints) (EP.pubEndPoint endPoints)
        logger info "Starting control service"
        ctx <- BusCtx.empty
        RPC.run 16 (EP.controlEndPoint endPoints) (Handler.handler ctx) -- TODO [PM] hardcoded number of workers
