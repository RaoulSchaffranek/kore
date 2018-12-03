{-|
Module      : Kore.MetaML.BuildersImpl
Description : Helper functions for "Data.Kore.MetaML.Builder"
Copyright   : (c) Runtime Verification, 2018
License     : NCSA
Maintainer  : virgil.serbanuta@runtimeverification.com
Stability   : experimental
Portability : POSIX
-}
module Kore.AST.BuildersImpl where

import           Control.Comonad.Trans.Cofree
                 ( CofreeF (..) )
import qualified Data.Functor.Foldable as Recursive
import           Data.Proxy

import Kore.AST.Pure


newtype ChildSort level = ChildSort (Sort level)
newtype ResultSort level = ResultSort (Sort level)

{-|'fillCheckSorts' matches a list of sorts to a list of 'PurePatternStub's,
checking that the sorts are identical where possible, creating a pattern with
the provided sort otherwise.
-}
fillCheckSorts
    ::  ( Functor domain
        , Show level
        , Show (variable level)
        , Show (Pattern level domain variable child)
        , child ~ PurePattern level domain variable ()
        )
    => [Sort level]
    -> [PurePatternStub level domain variable ()]
    -> [PurePattern level domain variable ()]
fillCheckSorts [] []         = []
fillCheckSorts [] _          = error "Not enough sorts!"
fillCheckSorts _ []          = error "Not enough patterns!"
fillCheckSorts (s:ss) (p:ps) = fillCheckSort s p : fillCheckSorts ss ps

{-|'fillCheckSorts' matches a sort to a 'PurePatternStub', checking
that the pattern's sorts is identical if possible, creating a pattern with the
provided sort otherwise.
-}
fillCheckSort
    ::  ( Functor domain
        , Show level
        , Show (variable level)
        , Show (Pattern level domain variable child)
        , child ~ PurePattern level domain variable ()
        )
    => Sort level
    -> PurePatternStub level domain variable ()
    -> PurePattern level domain variable ()
fillCheckSort
    desiredSort
    ( SortedPatternStub SortedPattern
        { sortedPatternPattern = p, sortedPatternSort = actualSort }
    )
  | desiredSort == actualSort =
    Recursive.embed $ () :< p
  | otherwise =
    (error . unlines)
        [ "Unmatched sorts, expected:"
        , show desiredSort
        , "but got:"
        , show actualSort
        , "for pattern"
        , show p ++ "."
        ]
fillCheckSort desiredSort (UnsortedPatternStub p) =
    Recursive.embed $ () :< p desiredSort

{-|'fillCheckPairSorts' takes two 'PurePatternStub' objects, assumes that
they must have the same sort, and tries to build 'CommonKorePattern's from them
if possible, otherwise it returns functions that can build 'CommonKorePattern's.
-}
fillCheckPairSorts
    :: Functor domain
    => PurePatternStub level domain variable ()
    -> PurePatternStub level domain variable ()
    -> Either
        ( Sort level -> PurePattern level domain variable ()
        , Sort level -> PurePattern level domain variable ()
        )
        ( Sort level
        , PurePattern level domain variable ()
        , PurePattern level domain variable ()
        )
fillCheckPairSorts (UnsortedPatternStub first) (UnsortedPatternStub second) =
    Left
        ( Recursive.embed . (:<) () . first
        , Recursive.embed . (:<) () . second
        )
fillCheckPairSorts
    (UnsortedPatternStub first)
    ( SortedPatternStub SortedPattern
        { sortedPatternPattern = second, sortedPatternSort = s }
    )
  =
    Right
        ( s
        , Recursive.embed (() :< first s)
        , Recursive.embed (() :< second)
        )
fillCheckPairSorts
    ( SortedPatternStub SortedPattern
        { sortedPatternPattern = first, sortedPatternSort = s }
    )
    (UnsortedPatternStub second)
  =
    Right
        ( s
        , Recursive.embed (() :< first)
        , Recursive.embed (() :< second s)
        )
fillCheckPairSorts
    ( SortedPatternStub SortedPattern
        { sortedPatternPattern = p1, sortedPatternSort = actualSort1 }
    )
    ( SortedPatternStub SortedPattern
        { sortedPatternPattern = p2, sortedPatternSort = actualSort2 }
    )
  | actualSort1 == actualSort2 =
    Right
        ( actualSort1
        , Recursive.embed (() :< p1)
        , Recursive.embed (() :< p2)
        )
  | otherwise =
    (error . unwords)
        [ "Unmatched sorts:"
        , show actualSort1
        , "and"
        , show actualSort2 ++ "."
        ]

{-|'unaryPattern' is a helper for building 'PurePatternStub's for unary
operators, like @\not@.
-}
unaryPattern
    :: Functor domain
    => (Sort level
        -> PurePattern level domain variable ()
        -> Pattern level domain variable (PurePattern level domain variable ())
       )
    -> PurePatternStub level domain variable ()
    -> PurePatternStub level domain variable ()
unaryPattern
    constructor
    ( SortedPatternStub SortedPattern
        { sortedPatternPattern = p, sortedPatternSort = s }
    )
  =
    SortedPatternStub SortedPattern
        { sortedPatternPattern =
            constructor s (Recursive.embed (() :< p))
        , sortedPatternSort    = s
        }
unaryPattern constructor (UnsortedPatternStub p) =
    UnsortedPatternStub
        (\sortS -> constructor sortS (Recursive.embed (() :< p sortS)))

{-|'unarySortedPattern' is a helper for building 'PurePatternStub's for unary
operators where the result sort is different from the operand sort, like \ceil.
-}
unarySortedPattern
    ::  ( Functor domain
        , MetaOrObject level
        , child ~ PurePattern level domain variable ()
        , Show child
        , Show (Pattern level domain variable child)
        )
    =>  (  ResultSort level
        -> ChildSort level
        -> child
        -> Pattern level domain variable child
        )
    -> Maybe (ChildSort level)
    -> PurePatternStub level domain variable ()
    -> PurePatternStub level domain variable ()
unarySortedPattern constructor maybeSort patternStub =
    UnsortedPatternStub
        (\sortS ->
            constructor
                (ResultSort sortS)
                (ChildSort childSort)
                (Recursive.embed $ () :< sortedPatternPattern sortedPat)
        )
  where
    (childSort, SortedPatternStub sortedPat) = case (maybeSort, patternStub) of
        (Just (ChildSort sort), _) -> (sort, withSort sort patternStub)
        (Nothing, SortedPatternStub sp) -> (sortedPatternSort sp, patternStub)
        (_, UnsortedPatternStub usp) -> error
            (  "Could not find a sort for child pattern: "
            ++ show (usp (dummySort childSort))
            )

{-|'binaryPattern' is a helper for building 'PurePatternStub's for binary
operators, like @\and@.
-}
binaryPattern
    :: Functor domain
    =>  (  Sort level
        -> PurePattern level domain variable ()
        -> PurePattern level domain variable ()
        -> Pattern level domain variable (PurePattern level domain variable ())
        )
    -> PurePatternStub level domain variable ()
    -> PurePatternStub level domain variable ()
    -> PurePatternStub level domain variable ()
binaryPattern constructor first second =
    case fillCheckPairSorts first second of
        Left (firstPattern, secondPattern) ->
            UnsortedPatternStub
                (\sortS ->
                    constructor sortS (firstPattern sortS) (secondPattern sortS)
                )
        Right (commonSort, firstPattern, secondPattern) ->
            SortedPatternStub SortedPattern
                { sortedPatternPattern =
                    constructor commonSort firstPattern secondPattern
                , sortedPatternSort    = commonSort
                }

{-|'binarySortedPattern' is a helper for building 'PurePatternStub's for binary
operators where the result sort is different from the operand sort,
like \equals.
-}
binarySortedPattern
    ::  ( Functor domain
        , MetaOrObject level
        , child ~ PurePattern level domain variable ()
        , Show child
        )
    =>  (  ResultSort level
        -> ChildSort level
        -> child
        -> child
        -> Pattern level domain variable child
        )
    -> Maybe (ChildSort level)
    -> PurePatternStub level domain variable ()
    -> PurePatternStub level domain variable ()
    -> PurePatternStub level domain variable ()
binarySortedPattern constructor maybeSort first second =
    case fillCheckPairSorts first second of
        Left (firstPattern, secondPattern) ->
            case maybeSort of
                Nothing ->
                    error
                        (  "Could not find a sort for equals children: "
                        ++ show (firstPattern (dummySort (Proxy :: Proxy level)))
                        ++ " and "
                        ++ show (secondPattern (dummySort (Proxy :: Proxy level)))
                        ++ "."
                        )
                Just childSort@(ChildSort s) ->
                    patternFromChildSort
                        (firstPattern s) (secondPattern s) childSort
        Right (commonSort, firstPattern, secondPattern) ->
            case maybeSort of
                Nothing ->
                    patternFromChildSort
                        firstPattern secondPattern (ChildSort commonSort)
                Just (ChildSort s) ->
                    if s == commonSort
                        then
                            patternFromChildSort
                                firstPattern
                                secondPattern
                                (ChildSort commonSort)
                        else
                            error
                                (  "Incompatible sorts for equals children: "
                                ++ show s
                                ++ " and "
                                ++ show commonSort
                                ++ "."
                                )
  where
    patternFromChildSort firstPattern secondPattern childSort =
        UnsortedPatternStub
            (\sortS ->
                constructor
                    (ResultSort sortS)
                    childSort
                    firstPattern
                    secondPattern
            )

equalsM_
    ::  ( Functor domain
        , MetaOrObject level
        , Show (PurePattern level domain variable ())
        )
    => Maybe (Sort level)
    -> PurePatternStub level domain variable ()
    -> PurePatternStub level domain variable ()
    -> PurePatternStub level domain variable ()
equalsM_ s =
    binarySortedPattern
        (\(ResultSort resultSort)
            (ChildSort childSort)
            firstPattern
            secondPattern
          ->
            EqualsPattern Equals
                { equalsOperandSort = childSort
                , equalsResultSort  = resultSort
                , equalsFirst       = firstPattern
                , equalsSecond      = secondPattern
                }
        )
        (ChildSort <$> s)

inM_
    ::  ( Functor domain
        , MetaOrObject level
        , Show (variable level)
        , Show (PurePattern level domain variable ())
        )
    => Maybe (Sort level)
    -> PurePatternStub level domain variable ()
    -> PurePatternStub level domain variable ()
    -> PurePatternStub level domain variable ()
inM_ s =
    binarySortedPattern
        (\(ResultSort resultSort)
            (ChildSort childSort)
            firstPattern
            secondPattern
          ->
            InPattern In
                { inOperandSort     = childSort
                , inResultSort      = resultSort
                , inContainedChild  = firstPattern
                , inContainingChild = secondPattern
                }
        )
        (ChildSort <$> s)

ceilM_
    ::  ( Functor domain
        , MetaOrObject level
        , child ~ PurePattern level domain variable ()
        , Show child
        , Show (Pattern level domain variable child)
        )
    => Maybe (Sort level)
    -> PurePatternStub level domain variable ()
    -> PurePatternStub level domain variable ()
ceilM_ s =
    unarySortedPattern
        (\(ResultSort resultSort)
            (ChildSort childSort)
            childPattern
          ->
            CeilPattern Ceil
                { ceilOperandSort = childSort
                , ceilResultSort  = resultSort
                , ceilChild       = childPattern
                }
        )
        (ChildSort <$> s)

floorM_
    ::  ( Functor domain
        , MetaOrObject level
        , child ~ PurePattern level domain variable ()
        , Show child
        , Show (Pattern level domain variable child)
        )
    => Maybe (Sort level)
    -> PurePatternStub level domain variable ()
    -> PurePatternStub level domain variable ()
floorM_ s =
    unarySortedPattern
        (\(ResultSort resultSort)
            (ChildSort childSort)
            childPattern
          ->
            FloorPattern Floor
                { floorOperandSort = childSort
                , floorResultSort  = resultSort
                , floorChild       = childPattern
                }
        )
        (ChildSort <$> s)
