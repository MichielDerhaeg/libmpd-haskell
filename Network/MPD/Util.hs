-- | Module    : Network.MPD.Util
-- Copyright   : (c) Ben Sinclair 2005-2009, Joachim Fasting 2010
-- License     : LGPL (see LICENSE)
-- Maintainer  : Joachim Fasting <joachim.fasting@gmail.com>
-- Stability   : alpha
--
-- Utilities.

module Network.MPD.Util (
    parseDate, parseIso8601, formatIso8601, parseNum, parseFrac,
    parseBool, showBool, breakChar, parseTriple,
    toAssoc, toAssocList, splitGroups, maybeRead
    ) where

import           Data.Char (isDigit)
import           Data.Maybe (listToMaybe)
import           Data.Time.Format (ParseTime, parseTime, FormatTime, formatTime)
import           System.Locale (defaultTimeLocale)

-- Break a string by character, removing the separator.
breakChar :: Char -> String -> (String, String)
breakChar c s = let (x, y) = break (== c) s in (x, drop 1 y)

-- XXX: need a more robust date parser.
-- Parse a date value.
-- > parseDate "2008" = Just 2008
-- > parseDate "2008-03-01" = Just 2008
parseDate :: String -> Maybe Int
parseDate = parseNum . takeWhile isDigit

-- Parse date in iso 8601 format
parseIso8601 :: (ParseTime t) => String -> Maybe t
parseIso8601 = parseTime defaultTimeLocale iso8601Format

formatIso8601 :: FormatTime t => t -> String
formatIso8601 = formatTime defaultTimeLocale iso8601Format

iso8601Format :: String
iso8601Format = "%FT%TZ"

-- Parse a positive or negative integer value, returning 'Nothing' on failure.
parseNum :: (Read a, Integral a) => String -> Maybe a
parseNum s = do
    [(x, "")] <- return (reads s)
    return x

-- Parse C style floating point value, returning 'Nothing' on failure.
parseFrac :: (Fractional a, Read a) => String -> Maybe a
parseFrac s =
    case s of
        "nan"  -> return $ read "NaN"
        "inf"  -> return $ read "Infinity"
        "-inf" -> return $ read "-Infinity"
        _      -> do [(x, "")] <- return $ reads s
                     return x

-- Inverts 'parseBool'.
showBool :: Bool -> String
showBool x = if x then "1" else "0"

-- Parse a boolean response value.
parseBool :: String -> Maybe Bool
parseBool s = case take 1 s of
                  "1" -> Just True
                  "0" -> Just False
                  _   -> Nothing

-- Break a string into triple.
parseTriple :: Char -> (String -> Maybe a) -> String -> Maybe (a, a, a)
parseTriple c f s = let (u, u') = breakChar c s
                        (v, w)  = breakChar c u' in
    case (f u, f v, f w) of
        (Just a, Just b, Just c') -> Just (a, b, c')
        _                        -> Nothing

-- Break a string into an key-value pair, separating at the first ':'.
toAssoc :: String -> (String, String)
toAssoc x = (k, dropWhile (== ' ') $ drop 1 v)
    where
        (k,v) = break (== ':') x

toAssocList :: [String] -> [(String, String)]
toAssocList = map toAssoc

-- Takes an association list with recurring keys and groups each cycle of keys
-- with their values together.  There can be several keys that begin cycles,
-- (the elements of the first parameter).
splitGroups :: [String] -> [(String, String)] -> [[(String, String)]]
splitGroups groupHeads = go
  where
    go []     = []
    go (x:xs) =
      let
        (ys, zs) = break isGroupHead xs
      in
        (x:ys) : go zs

    isGroupHead = (`elem` groupHeads) . fst

maybeRead :: Read a => String -> Maybe a
maybeRead = fmap fst . listToMaybe . reads
