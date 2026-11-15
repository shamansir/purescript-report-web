module Test.Main where

import Prelude

import Data.Maybe (Maybe(..))

import Effect (Effect)
import Effect.Aff (runAff_)

import Test.Spec.Runner.Node (runSpecAndExitProcess)
import Test.Spec.Reporter.Console (consoleReporter)

import Test.ReportImpl as ReportImpl
import Test.MusicApi as MusicApi


main :: Effect Unit
main = do
    -- runAff_ (const $ pure unit) $ MusicApi.fetchArtist Nothing "Queen"

    runSpecAndExitProcess [consoleReporter] do
        ReportImpl.spec
        -- MusicApi.spec
