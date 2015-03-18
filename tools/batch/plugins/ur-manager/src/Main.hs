---------------------------------------------------------------------------
-- Copyright (C) Flowbox, Inc - All Rights Reserved
-- Unauthorized copying of this file, via any medium is strictly prohibited
-- Proprietary and confidential
-- Flowbox Team <contact@flowbox.io>, 2014
---------------------------------------------------------------------------
{-# LANGUAGE TemplateHaskell #-}

module Main where

import qualified Flowbox.Bus.EndPoint        as EP
import qualified Flowbox.Bus.RPC.Server.Server              as Server
import           Flowbox.UR.Manager.Cmd      (Cmd)
import qualified Flowbox.UR.Manager.Cmd      as Cmd
import qualified Flowbox.UR.Manager.Context  as Context
import qualified Flowbox.UR.Manager.RPC.Handler.Handler as Handler
import qualified Flowbox.UR.Manager.Version  as Version
import qualified Flowbox.Config.Config       as Config
import           Flowbox.Control.Error
import           Flowbox.Options.Applicative hiding (info)
import qualified Flowbox.Options.Applicative as Opt
import           Flowbox.Prelude
import           Flowbox.System.Log.Logger

rootLogger :: Logger
rootLogger = getLogger ""

logger :: LoggerIO
logger = getLoggerIO $(moduleName)

parser :: Parser Cmd
parser = Opt.flag' Cmd.Version (long "version" <> hidden)
       <|> Cmd.Run
           <$> optIntFlag (Just "verbose") 'v' 2 3          "Verbose level (level range is 0-5, default level is 3)"
           <*> switch    ( long "no-color"          <> help "Disable color output" )


opts :: ParserInfo Cmd
opts = Opt.info (helper <*> parser)
                (Opt.fullDesc <> Opt.header (Version.full False))

main :: IO ()
main = execParser opts >>= run

run :: Cmd -> IO ()
run cmd = case cmd of
    Cmd.Version -> putStrLn (Version.full False) -- TODO [PM] hardcoded numeric = False
    Cmd.Run {}  -> do
        rootLogger setIntLevel $ Cmd.verbose cmd
        cfg <- Config.load
        let ctx = Context.mk
        eitherStringToM' $ Server.run (EP.clientFromConfig cfg) ctx Handler.handlerMap