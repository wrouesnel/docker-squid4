#!/usr/bin/env stack
{- stack --resolver lts-12.10 --install-ghc runghc
    --package aeson
    --package binary
    --package getopt-generics
    --package lens
    --package string-conversions
    --package text
    --package uri-bytestring
-}

{-# LANGUAGE AllowAmbiguousTypes #-}
{-# LANGUAGE BangPatterns #-}
{-# LANGUAGE ConstraintKinds #-}
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE DefaultSignatures #-}
{-# LANGUAGE DeriveFunctor #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DeriveLift #-}
{-# LANGUAGE DeriveTraversable #-}
{-# LANGUAGE DerivingStrategies #-}
{-# LANGUAGE EmptyCase #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE FunctionalDependencies #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE InstanceSigs #-}
{-# LANGUAGE KindSignatures #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE MultiWayIf #-}
{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE PackageImports #-}
{-# LANGUAGE PatternSynonyms #-}
{-# LANGUAGE PolyKinds #-}
{-# LANGUAGE QuasiQuotes #-}
{-# LANGUAGE RankNTypes #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE StandaloneDeriving #-}
{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE TupleSections #-}
{-# LANGUAGE TypeApplications #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE TypeFamilyDependencies #-}
{-# LANGUAGE TypeOperators #-}
{-# LANGUAGE UndecidableInstances #-}
{-# LANGUAGE ViewPatterns #-}

module Main where

import Control.Lens
import Data.Aeson
import Data.Binary.Builder (toLazyByteString)
import Data.List (nub, sort)
import Data.Maybe
import Data.String.Conversions (cs)
import Data.Text
import GHC.Generics (Generic)
import URI.ByteString
import WithCli


-- * data

data Command
  = Urls
  | Domains
  | WarmupScript
  | ZoneFile
  deriving (Eq, Show, Bounded, Enum, Generic)

data File = File FilePath
  deriving (Eq, Show, Typeable, Generic)

data Entry = Entry
  { _entrySize :: Int
  , _entryVerb :: Text
  , _entryURI  :: URI
  }
  deriving (Eq, Show, Generic)

makeLenses ''Entry


instance HasArguments Command where
  argumentsParser = atomicArgumentsParser

instance Argument Command where
  argumentType Proxy = show @[Command] [minBound..]
  parseArgument x = case [ x' | x' <- [minBound..], show x' == x ] of
    [x'] -> Just x'

instance HasArguments File where
  argumentsParser = atomicArgumentsParser

instance Argument File where
  argumentType Proxy = "file"
  parseArgument f = Just (File f)

instance FromJSON Entry where
  parseJSON = withObject "Entry" $ \o -> Entry
    <$> o .: "size"
    <*> o .: "verb"
    <*> o .: "uri"

instance FromJSON URI where
  parseJSON = withText "URI" $ \s ->
    either (fail . show . (, s)) pure . parseURI laxURIParserOptions . cs . fixSquidLogs $ s
    where
      -- the access logs we are parsing here sometimes have an IP address as a domain and no
      -- scheme.  this is invalid according to uri-bytestring, so we add default scheme http
      -- if none is set.
      fixSquidLogs :: Text -> Text
      fixSquidLogs s = case splitOn "://" s of
        [_, _] -> s
        [_]    -> "http://" <> s
        bad    -> error $ "instance FromJSON URI: " <> show (s, bad)


-- * main

main :: IO ()
main = withCli run

run :: Command -> File -> IO ()
run cmd (File input) = do
  entries :: [Entry]
    <- either (error . show) pure . eitherDecode . cs
       =<< readFile input

  putStrLn . cs $ case cmd of
    Urls         -> cmdUrls entries
    Domains      -> cmdDomains entries
    WarmupScript -> cmdWarmupScript entries
    ZoneFile     -> cmdZoneFile entries


-- * commands

cmdUrls :: [Entry] -> Text
cmdUrls
  = intercalate "\n"
  . nub . sort
  . fmap (cs . toLazyByteString . serializeURIRef . view entryURI)


cmdDomains :: [Entry] -> Text
cmdDomains
  = intercalate "\n"
  . nub . sort
  . fmap (cs . hostBS)
  . catMaybes
  . fmap (^? entryURI . authorityL . _Just . authorityHostL)


cmdWarmupScript :: [Entry] -> Text
cmdWarmupScript = intercalate "\n" . ("#!/bin/bash\nset -xe" :) . nub . sort . fmap mkcurl
  where
    mkcurl entry = "curl -s " <>
      (cs . toLazyByteString . serializeURIRef $ entry ^. entryURI) <>
      " >/dev/null"


cmdZoneFile :: [Entry] -> Text
cmdZoneFile = undefined
