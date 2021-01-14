{- |
Copyright   : (c) Runtime Verification, 2018
License     : NCSA
-}

{-# LANGUAGE Strict #-}

module Kore.Step.Simplification.Condition
    ( create
    , simplify
    , simplifyPredicate
    , simplifyCondition
    ) where

import Prelude.Kore

import qualified Control.Lens as Lens
import Control.Monad.State.Strict
    ( StateT
    , evalStateT
    )
import qualified Control.Monad.State.Strict as State
import qualified Data.Functor.Foldable as Recursive
import Data.Generics.Product
    ( field
    )
import Data.HashMap.Strict
    ( HashMap
    )
import qualified Data.HashMap.Strict as HashMap
import Data.List
    ( sortOn
    )
import qualified GHC.Generics as GHC

import Changed
import Kore.Attribute.Synthetic
    ( synthesize
    )
import qualified Kore.Internal.Condition as Condition
import qualified Kore.Internal.Conditional as Conditional
import Kore.Internal.MultiAnd
    ( MultiAnd
    )
import qualified Kore.Internal.MultiAnd as MultiAnd
import qualified Kore.Internal.OrPattern as OrPattern
import Kore.Internal.Pattern
    ( Condition
    , Conditional (..)
    )
import qualified Kore.Internal.Pattern as Pattern
import Kore.Internal.Predicate
    ( Predicate
    , pattern PredicateEquals
    , pattern PredicateExists
    , pattern PredicateForall
    , pattern PredicateNot
    , makeFalsePredicate
    , makeTruePredicate
    )
import qualified Kore.Internal.Predicate as Predicate
import Kore.Internal.SideCondition
    ( SideCondition
    )
import qualified Kore.Internal.Substitution as Substitution
import Kore.Internal.Symbol
    ( isConstructor
    , isFunction
    )
import Kore.Internal.TermLike
    ( pattern App_
    , pattern Equals_
    , pattern Exists_
    , pattern Forall_
    , pattern Inj_
    , pattern InternalBool_
    , pattern InternalBool_
    , pattern InternalBytes_
    , pattern InternalInt_
    , pattern InternalList_
    , pattern InternalMap_
    , pattern InternalSet_
    , pattern InternalString_
    , pattern InternalString_
    , pattern Mu_
    , pattern Nu_
    , TermLike
    , Variable (..)
    , mkEquals_
    )
import qualified Kore.Internal.TermLike as TermLike
import Kore.Step.Simplification.Simplify
import Kore.Step.Simplification.SubstitutionSimplifier
    ( SubstitutionSimplifier (..)
    )
import qualified Kore.TopBottom as TopBottom
import Kore.Unparser
import Logic
import Pair
import qualified Pretty

{- | Create a 'ConditionSimplifier' using 'simplify'.
-}
create
    :: MonadSimplify simplifier
    => SubstitutionSimplifier simplifier
    -> ConditionSimplifier simplifier
create substitutionSimplifier =
    ConditionSimplifier $ simplify substitutionSimplifier

{- | Simplify a 'Condition'.

@simplify@ applies the substitution to the predicate and simplifies the
result. The result is re-simplified until it stabilizes.

The 'term' of 'Conditional' may be any type; it passes through @simplify@
unmodified.
-}
simplify
    ::  forall simplifier variable any
    .   ( HasCallStack
        , InternalVariable variable
        , MonadSimplify simplifier
        )
    =>  SubstitutionSimplifier simplifier
    ->  SideCondition variable
    ->  Conditional variable any
    ->  LogicT simplifier (Conditional variable any)
simplify SubstitutionSimplifier { simplifySubstitution } sideCondition =
    normalize >=> worker
  where
    worker Conditional { term, predicate, substitution } = do
        let substitution' = Substitution.toMap substitution
            predicate' = Predicate.substitute substitution' predicate
        simplified <- simplifyPredicate sideCondition predicate'
        TopBottom.guardAgainstBottom simplified
        let merged = simplified <> Condition.fromSubstitution substitution
        normalized <- normalize merged
        -- Check for full simplification *after* normalization. Simplification
        -- may have produced irrelevant substitutions that become relevant after
        -- normalization.
        let simplifiedPattern =
                Lens.traverseOf
                    (field @"predicate")
                    simplifyConjunctions
                    normalized { term }
        if fullySimplified simplifiedPattern
            then return (extract simplifiedPattern)
            else worker (extract simplifiedPattern)

    -- TODO(Ana): this should also check if the predicate is simplified
    fullySimplified (Unchanged Conditional { predicate, substitution }) =
        Predicate.isFreeOf predicate variables
      where
        variables = Substitution.variables substitution
    fullySimplified (Changed _) = False

    normalize
        ::  forall any'
        .   Conditional variable any'
        ->  LogicT simplifier (Conditional variable any')
    normalize conditional@Conditional { substitution } = do
        let conditional' = conditional { substitution = mempty }
        predicates' <- lift $
            simplifySubstitution sideCondition substitution
        predicate' <- scatter predicates'
        return $ Conditional.andCondition conditional' predicate'

{- | Simplify the 'Predicate' once.

@simplifyPredicate@ does not attempt to apply the resulting substitution and
re-simplify the result.

See also: 'simplify'

-}
simplifyPredicate
    ::  ( HasCallStack
        , InternalVariable variable
        , MonadSimplify simplifier
        )
    =>  SideCondition variable
    ->  Predicate variable
    ->  LogicT simplifier (Condition variable)
simplifyPredicate sideCondition predicate = do
    patternOr <-
        lift
        $ simplifyTermLike sideCondition
        $ Predicate.fromPredicate_ predicate
    -- Despite using lift above, we do not need to
    -- explicitly check for \bottom because patternOr is an OrPattern.
    scatter (OrPattern.map eraseTerm patternOr)
  where
    eraseTerm conditional
      | TopBottom.isTop (Pattern.term conditional)
      = Conditional.withoutTerm conditional
      | otherwise =
        (error . show . Pretty.vsep)
            [ "Expecting a \\top term, but found:"
            , unparse conditional
            ]

simplifyConjunctions
    :: InternalVariable variable
    => Predicate variable
    -> Changed (Predicate variable)
simplifyConjunctions original@(MultiAnd.fromPredicate -> predicates) =
    case simplifyConjunctionByAssumption predicates of
        Unchanged _ -> Unchanged original
        Changed changed ->
            Changed (MultiAnd.toPredicate changed)

data DoubleMap variable = DoubleMap
    { termLikeMap :: HashMap (TermLike variable) (TermLike variable)
    , predMap :: HashMap (Predicate variable) (Predicate variable)
    }
    deriving (Eq, GHC.Generic, Show)

{- | Simplify the conjunction of 'Predicate' clauses by assuming each is true.
The conjunction is simplified by the identity:
@
A ∧ P(A) = A ∧ P(⊤)
@
 -}
simplifyConjunctionByAssumption
    :: forall variable
    .  InternalVariable variable
    => MultiAnd (Predicate variable)
    -> Changed (MultiAnd (Predicate variable))
simplifyConjunctionByAssumption (toList -> andPredicates) =
    fmap MultiAnd.make
    $ flip evalStateT (DoubleMap HashMap.empty HashMap.empty)
    $ for (sortBySize andPredicates)
    $ \original -> do
        result <- applyAssumptions original
        assume result
        return result
  where
    -- Sorting by size ensures that every clause is considered before any clause
    -- which could contain it, because the containing clause is necessarily
    -- larger.
    sortBySize :: [Predicate variable] -> [Predicate variable]
    sortBySize = sortOn predSize

    size :: TermLike variable -> Int
    size =
        Recursive.fold $ \(_ :< termLikeF) ->
            case termLikeF of
                TermLike.EvaluatedF evaluated -> TermLike.getEvaluated evaluated
                TermLike.DefinedF defined -> TermLike.getDefined defined
                _ -> 1 + sum termLikeF

    predSize :: Predicate variable -> Int
    predSize =
        Recursive.fold $ \(_ :< predF) ->
            case predF of
                Predicate.CeilF ceil_ -> 1 + sum (size <$> ceil_)
                Predicate.EqualsF equals_ -> 1 + sum (size <$> equals_)
                Predicate.FloorF floor_ -> 1 + sum (size <$> floor_)
                Predicate.InF in_ -> 1 + sum (size <$> in_)
                _ -> 1 + sum predF

    assume
        :: Predicate variable ->
        StateT (DoubleMap variable) Changed ()
    assume predicate =
        State.modify' (assumeEqualTerms . assumePredicate)
      where
        assumePredicate =
            case predicate of
                PredicateNot notChild ->
                    -- Infer that the predicate is \bottom.
                    Lens.over (field @"predMap") $
                        HashMap.insert notChild makeFalsePredicate
                _ ->
                    -- Infer that the predicate is \top.
                    Lens.over (field @"predMap") $
                        HashMap.insert predicate makeTruePredicate
        assumeEqualTerms =
            case predicate of
                PredicateEquals t1 t2 ->
                    case retractLocalFunction (mkEquals_ t1 t2) of
                        Just (Pair t1' t2') ->
                            Lens.over (field @"termLikeMap") $
                                HashMap.insert t1' t2'
                        _ -> id
                _ -> id

    applyAssumptions
        ::  Predicate variable
        ->  StateT (DoubleMap variable) Changed (Predicate variable)
    applyAssumptions replaceIn = do
        assumptions <- State.get
        lift (applyAssumptionsWorker assumptions replaceIn)

    applyAssumptionsWorker
        :: DoubleMap variable
        -> Predicate variable
        -> Changed (Predicate variable)
    applyAssumptionsWorker assumptions original
      | Just result <- HashMap.lookup original (predMap assumptions) = Changed result

      | HashMap.null (termLikeMap assumptions') &&
        HashMap.null (predMap assumptions') = Unchanged original

      | otherwise = (case replaceIn of
          Predicate.CeilF ceil_ -> Predicate.CeilF <$> traverse
            (applyAssumptionsWorkerTerm (termLikeMap assumptions')) ceil_
          Predicate.FloorF floor_ -> Predicate.FloorF <$> traverse
            (applyAssumptionsWorkerTerm (termLikeMap assumptions')) floor_
          Predicate.EqualsF equals_ -> Predicate.EqualsF <$> traverse
            (applyAssumptionsWorkerTerm (termLikeMap assumptions')) equals_
          Predicate.InF in_ -> Predicate.InF <$> traverse
            (applyAssumptionsWorkerTerm (termLikeMap assumptions')) in_
          _ -> traverse (applyAssumptionsWorker assumptions') replaceIn
        )
        & getChanged
        -- The next line ensures that if the result is Unchanged, any allocation
        -- performed while computing that result is collected.
        & maybe (Unchanged original) (Changed . synthesize)

      where
        _ :< replaceIn = Recursive.project original

        assumptions'
          | PredicateExists var _ <- original = restrictAssumptions (inject var)
          | PredicateForall var _ <- original = restrictAssumptions (inject var)
          | otherwise = assumptions

        restrictAssumptions Variable { variableName } =
            Lens.over (field @"termLikeMap")
            (HashMap.filterWithKey (\term _ -> wouldNotCaptureTerm term))
            $
            Lens.over (field @"predMap")
            (HashMap.filterWithKey (\predicate _ -> wouldNotCapture predicate))
            assumptions
          where
            wouldNotCapture = not . Predicate.hasFreeVariable variableName
            wouldNotCaptureTerm = not . TermLike.hasFreeVariable variableName

    applyAssumptionsWorkerTerm
        :: HashMap (TermLike variable) (TermLike variable)
        -> TermLike variable
        -> Changed (TermLike variable)
    applyAssumptionsWorkerTerm assumptions original
      | Just result <- HashMap.lookup original assumptions = Changed result

      | HashMap.null assumptions' = Unchanged original

      | otherwise =
        traverse (applyAssumptionsWorkerTerm assumptions') replaceIn
        & getChanged
        -- The next line ensures that if the result is Unchanged, any allocation
        -- performed while computing that result is collected.
        & maybe (Unchanged original) (Changed . synthesize)

      where
        _ :< replaceIn = Recursive.project original

        assumptions'
          | Exists_ _ var _ <- original = restrictAssumptions (inject var)
          | Forall_ _ var _ <- original = restrictAssumptions (inject var)
          | Mu_       var _ <- original = restrictAssumptions (inject var)
          | Nu_       var _ <- original = restrictAssumptions (inject var)
          | otherwise = assumptions

        restrictAssumptions Variable { variableName } =
            HashMap.filterWithKey
                (\termLike _ -> wouldNotCapture termLike)
                assumptions
          where
            wouldNotCapture = not . TermLike.hasFreeVariable variableName

{- | Get a local function definition from a 'TermLike'.
A local function definition is a predicate that we can use to evaluate a
function locally (based on the side conditions) when none of the functions
global definitions (axioms) apply. We are looking for a 'TermLike' of the form
@
\equals(f(...), C(...))
@
where @f@ is a function and @C@ is a constructor, sort injection or builtin.
@retractLocalFunction@ will match an @\equals@ predicate with its arguments
in either order, but the function pattern is always returned first in the
'Pair'.
 -}
retractLocalFunction
    :: TermLike variable
    -> Maybe (Pair (TermLike variable))
retractLocalFunction =
    \case
        Equals_ _ _ term1 term2 -> go term1 term2 <|> go term2 term1
        _ -> Nothing
  where
    go term1@(App_ symbol1 _) term2
      | isFunction symbol1 =
        -- TODO (thomas.tuegel): Add tests.
        case term2 of
            App_ symbol2 _
              | isConstructor symbol2 -> Just (Pair term1 term2)
            Inj_ _     -> Just (Pair term1 term2)
            InternalInt_ _ -> Just (Pair term1 term2)
            InternalBytes_ _ _ -> Just (Pair term1 term2)
            InternalString_ _ -> Just (Pair term1 term2)
            InternalBool_ _ -> Just (Pair term1 term2)
            InternalList_ _ -> Just (Pair term1 term2)
            InternalMap_ _ -> Just (Pair term1 term2)
            InternalSet_ _ -> Just (Pair term1 term2)
            _          -> Nothing
    go _ _ = Nothing
