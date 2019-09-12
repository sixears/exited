{-# LANGUAGE LambdaCase        #-}
{-# LANGUAGE NoImplicitPrelude #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE UnicodeSyntax     #-}

module Exited
  ( ToExitCode( toExitCode )

  , die, dieUsage, doMain

  , exitCodeSuccess , exitSuccess
  , exitCodeAbnormal, exitAbnormal
  , exitCodeUsage   , exitUsage
  , exitCodeInternal, exitInternal
  , exitCodeFail    , exitFail

  , exitWith, exitWith'
  )
where

import Prelude  ( fromIntegral )

-- base --------------------------------

import qualified  System.Exit

import Control.Exception       ( Exception, handle, throwIO )
import Control.Monad           ( (>>), return )
import Control.Monad.IO.Class  ( MonadIO, liftIO )
import Data.Either             ( Either( Left, Right ) )
import Data.Function           ( ($), id )
import Data.Word               ( Word8 )
import System.Environment      ( getProgName )
import System.Exit             ( ExitCode( ExitFailure, ExitSuccess ) )
import System.IO               ( IO, hPutStrLn, print, stderr )

-- base-unicode-symbols ----------------

import Data.Eq.Unicode  ( (≡) )

-- data-textual ------------------------

import Data.Textual  ( Printable, toString )

-- mtl ---------------------------------

import Control.Monad.Except  ( ExceptT )

------------------------------------------------------------
--                     local imports                      --
------------------------------------------------------------

import MonadError  ( ѥ )

--------------------------------------------------------------------------------

{- | Marker that we have exited (cf. `()`, which doesn't tell you anything). -}

data Exited = Exited

exited ∷ Exited
exited = Exited

----------------------------------------

{- | Things that may be treated as an ExitCode; specifically, to allow for use
     of a `Word8`. -}
class ToExitCode ξ where
  toExitCode ∷ ξ → ExitCode

instance ToExitCode ExitCode where
  toExitCode = id

instance ToExitCode Word8 where
  toExitCode 0 = ExitSuccess
  toExitCode i = ExitFailure $ fromIntegral i

------------------------------------------------------------

{- | Like `System.Exit.exitWith`, but allows for `Word8`; lifts to `MonadIO`,
     and returns `Exited` -}
exitWith ∷ (MonadIO m, ToExitCode ξ) ⇒ ξ → m Exited
exitWith x = liftIO $ do
  _ ← System.Exit.exitWith (toExitCode x)
  return exited

exitWith' ∷ MonadIO μ ⇒ Word8 → μ Exited
exitWith' = exitWith

----------------------------------------

{- | Issue a dying wail, and exit with a given code -}

die ∷ (MonadIO μ, ToExitCode δ, Printable ρ) ⇒ δ → ρ → μ Exited
die ex msg = liftIO $ hPutStrLn stderr (toString msg) >> exitWith ex

{- | Issue an explanation before exiting, signalling a usage error. -}

dieUsage ∷ (MonadIO μ, Printable ρ) ⇒ ρ → μ Exited
dieUsage = die exitCodeUsage

----------------------------------------

{- | Run a "main" function, which returns an exit code but may throw an
     `Exception`.  Any Exception is caught, displayed, and causes a general
     failure exit code.  Care is taken to not exit ghci if we are running there.
 -}
doMain ∷ (Printable ε, Exception ε, ToExitCode σ) ⇒ ExceptT ε IO σ → IO ()
doMain f = do
  m ← ѥ f
  p ← getProgName
  let handler = if p ≡ "<interactive>"
                -- in ghci, always rethrow an exception (thus, we get an
                -- 'ExitSuccess' exception); ExitFailure 0 can never match
                then \ case ExitFailure 0 → return Exited; e → throwIO e
                -- in normal running, an ExitSuccess should just be a return
                else \ case ExitSuccess   → return Exited; e → throwIO e
  Exited ← handle handler $
    case m of
      Left  e → print (toString e) >> exitFail
      Right x → exitWith x
  return ()

------------------------------------------------------------

{- | Exit code for successful termination. -}
exitCodeSuccess  ∷ Word8
exitCodeSuccess  = 0

{- | Exit after successful run. -}
exitSuccess ∷ MonadIO μ ⇒ μ Exited
exitSuccess = exitWith exitCodeSuccess

--------------------

{- | Exit code for abnormal termination (e.g., grep; everything worked, but
     nothing was found). -}
exitCodeAbnormal ∷ Word8
exitCodeAbnormal = 1

{- | Exit after successful but abnormal run (e.g., grep ran successfully, but
     found nothing). -}
exitAbnormal ∷ MonadIO μ ⇒ μ Exited
exitAbnormal = exitWith exitCodeAbnormal

--------------------

{- | Exit code for usage error (and calling @--help@). -}
exitCodeUsage    ∷ Word8
exitCodeUsage    = 2

{- | Exit after usage error (and calling @--help@). -}
exitUsage ∷ MonadIO μ ⇒ μ Exited
exitUsage = exitWith exitCodeUsage

--------------------

{- | Exit code for internal issue (e.g., irrefutable pattern was refuted). -}
exitCodeInternal ∷ Word8
exitCodeInternal = 255

{- | Exit after internal issue (e.g., irrefutable pattern was refuted). -}
exitInternal ∷ MonadIO μ ⇒ μ Exited
exitInternal = exitWith exitCodeInternal

--------------------

{- | Exit code for any failure not otherwise covered. -}
exitCodeFail     ∷ Word8
exitCodeFail     = 255

{- | Exit after any failure not otherwise covered. -}
exitFail ∷ MonadIO μ ⇒ μ Exited
exitFail = exitWith exitCodeFail

-- that's all, folks! ----------------------------------------------------------
