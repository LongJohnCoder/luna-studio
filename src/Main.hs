{-# LANGUAGE ConstraintKinds #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeSynonymInstances #-}


module Main where


import            Luna.Data.Namespace                       (Namespace (Namespace))
import            Luna.Data.Source                          (Medium (Text), Source (Source))

import qualified  Luna.Pass                                 as Pass
import qualified  Luna.Pass2.Analysis.Struct                as P2SA
--import qualified  Luna.Pass2.Target.HS.HASTGen              as P2HASTGen
--import qualified  Luna.Pass2.Target.HS.HSC                  as P2HSC
import qualified  Luna.Pass2.Transform.Desugar.ImplicitSelf as P2ImplSelf
import qualified  Luna.Pass2.Transform.Hash                 as P2Hash
import qualified  Luna.Pass2.Transform.Parse.Stage1         as P2Stage1
import qualified  Luna.Pass2.Transform.Parse.Stage2         as P2Stage2
import qualified  Luna.Pass2.Transform.SSA                  as P2SSA

import            Control.Monad                             (forM_)
import            Control.Monad.IO.Class                    (MonadIO, liftIO)
import            Control.Monad.Trans.Either
import            Data.List                                 (intercalate)
import            Data.Text.Lazy                            (pack)

import            System.Environment                        (getArgs)
import            Text.Show.Pretty                          (ppShow)


import            Inference                                 as FooInfer


main :: IO ()
main =  getArgs >>= \case
          []      -> [Red, Bold] `colouredPrint` "no file given, sorry"
          (x:y:_) -> [Red, Bold] `colouredPrint` "too many args given - requires one (path to *.luna file). Sorry"
          [file]  -> do
            [Bold,Green]  `colouredPrint` file
            [Cyan]        `colouredPrint` "…reading `" ++ file ++ "`"
            file_contents <- do tmp <- readFile file
                                tmp `seq` return tmp
            [Cyan] `colouredPrint` "…passes"
            let src = Source (pack file) (Text $ pack file_contents)

            result <- runEitherT $ do
              (ast1, astinfo1) <- Pass.run1_ P2Stage1.pass src
              sa1              <- Pass.run1_ P2SA.pass ast1
              (ast2, astinfo2) <- Pass.run3_ P2Stage2.pass (Namespace [] sa1) astinfo1 ast1
              (ast3, astinfo3) <- Pass.run2_ P2ImplSelf.pass astinfo2 ast2
              sa2              <- Pass.run1_ P2SA.pass ast3
              constraints      <- Pass.run2_ FooInfer.tcpass ast3 sa2
              ast4             <- Pass.run1_ P2Hash.pass ast3
              ast5             <- Pass.run1_ P2SSA.pass ast4
              --hast             <- Pass.run1_ P2HASTGen.pass ast5
              --hsc              <- Pass.run1_ P2HSC.pass hast
              writeAST " 1.1. Transform.Parse.Stage1         : ast1"        $ ppShow ast1
              writeAST " 1.2. Transform.Parse.Stage1         : astinfo1"    $ ppShow astinfo1
              writeAST " 2.   Analysis.Struct                : sa1"         $ ppShow sa1
              writeAST " 3.1. Transform.Parse.Stage2         : ast2"        $ ppShow ast2
              writeAST " 3.2. Transform.Parse.Stage2         : astinfo2"    $ ppShow astinfo2
              writeAST " 4.1. Transform.Desugar.ImplicitSelf : ast3"        $ ppShow ast3
              writeAST " 4.2. Transform.Desugar.ImplicitSelf : astinfo3"    $ ppShow astinfo3
              writeAST " 5.   Pass2.Analysis.Struct          : sa2"         $ ppShow sa2
              writeAST " 6.   Typechecker                    : constraints" $ ppShow constraints
              writeAST " 7.   Transform.Hash                 : ast4"        $ ppShow ast4
              writeAST " 8.   Transform.SSA                  : ast5"        $ ppShow ast5
              -- writeAST " 9.   Target.HS.HASTGen              : hast"        $ ppShow $ hast
              -- writeAST "10.   Target.HS.HSC                  : hsc"         $ unpack $ hsc
              return  ()

            case result of
              Left _   -> [Red, Bold] `colouredPrint` "some error, sorry"
              Right () -> return ()

writeAST :: (MonadIO m) => FilePath -> String -> m ()
writeAST path str = liftIO $ do
    writeFile filepath str
    [Cyan] `colouredPrint` "…writing " ++ show filepath
  where filepath = "tmp/" ++ path

printer :: (Show a) => String -> a -> IO ()
printer x y = printer_aux x (show y)

printer_aux :: String -> String -> IO ()
printer_aux x y = do  [Bold,White] `colouredPrint` "\n-----------------------------------------------------------------------------"
                      putStr "> "
                      [Yellow] `colouredPrint` x
                      [Bold,White] `colouredPrint` "-----------------------------------------------------------------------------\n"
                      putStrLn y

section :: IO () -> IO ()
section sec = do  sec
                  [Bold, White] `colouredPrint` "\n\n#############################################################################\n\n"

infix 4 `colouredPrint`
colouredPrint :: [PrintAttrs] -> String -> IO ()
colouredPrint fs x = do
    putStr $ "\x1b[" ++ fmt ++ "m"
    putStr x
    putStrLn "\x1b[0m"
  where fmt = intercalate ";" (fmap (show.attrtonum) fs)

data PrintAttrs = Black
                | Red
                | Green
                | Yellow
                | Blue
                | Magenta
                | Cyan
                | White
                | Bold

attrtonum :: PrintAttrs -> Int
attrtonum Black   = 30
attrtonum Red     = 31
attrtonum Green   = 32
attrtonum Yellow  = 33
attrtonum Blue    = 34
attrtonum Magenta = 35
attrtonum Cyan    = 36
attrtonum White   = 37
attrtonum Bold    = 1
