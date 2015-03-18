module Luna.Typechecker.Debug.ConsoleColours (
    PrintAttrs(..),
    colouredPrint, colouredFmt, writeFileM
  ) where


import Flowbox.Prelude



writeFileM :: (MonadIO m) => FilePath -> String -> m ()
writeFileM path str = liftIO $ do
    writeFile filepath str
    [Cyan] `colouredPrint` "…writing " ++ show filepath
  where filepath = "tmp/" ++ path


infix 4 `colouredPrint`
colouredPrint :: (MonadIO m) => [PrintAttrs] -> String -> m ()
colouredPrint fs = liftIO . putStrLn . colouredFmt fs

infix 4 `colouredFmt`
colouredFmt :: [PrintAttrs] -> String -> String
colouredFmt fs x = "\x1b[" ++ fmt ++ "m" ++ x ++ "\x1b[0m"
  where fmt = mjoin ";" $ fmap show fs


data PrintAttrs = Black
                | Red
                | Green
                | Yellow
                | Blue
                | Magenta
                | Cyan
                | White
                | Bold


instance Show PrintAttrs where
  show Black   = show (30 :: Int)
  show Red     = show (31 :: Int)
  show Green   = show (32 :: Int)
  show Yellow  = show (33 :: Int)
  show Blue    = show (34 :: Int)
  show Magenta = show (35 :: Int)
  show Cyan    = show (36 :: Int)
  show White   = show (37 :: Int)
  show Bold    = show (1  :: Int)
