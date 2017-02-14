{-|
Module         : Piccolo.Output
Description    : Utilities to display Piccolo internals
Stability      : experimental

Some options of the Piccolo compiler may involve internals printing.
This module helps printing those data.
-}
module Piccolo.Output
  (printEnvSizes
  )
where

import Piccolo.AST

import Control.Monad

printEnvSizes :: Modul -> IO ()
printEnvSizes modul = do
  putStrLn $ "Env sizes for module " ++ modName modul ++ ":"
  forM_ (modDefs modul) $ \def -> do
    putStr $ "Process '" ++ defName def ++ "' has env size of "
    putStrLn . show $ defEnvSize def

