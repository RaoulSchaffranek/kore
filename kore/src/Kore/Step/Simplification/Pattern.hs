{- |
Copyright   : (c) Runtime Verification, 2018
License     : NCSA
-}
module Kore.Step.Simplification.Pattern (
    simplifyTopConfiguration,
    simplifyTopConfigurationDefined,
    simplify,
    makeEvaluate,
) where

import Control.Monad (
    (>=>),
 )
import qualified Kore.Internal.Condition as Condition
import qualified Kore.Internal.Conditional as Conditional
import Kore.Internal.OrPattern (
    OrPattern,
 )
import qualified Kore.Internal.OrPattern as OrPattern
import Kore.Internal.Pattern (
    Conditional (..),
    Pattern,
 )
import Kore.Internal.SideCondition (
    SideCondition,
 )
import qualified Kore.Internal.SideCondition as SideCondition (
    andCondition,
    assumeDefined,
    top,
 )
import Kore.Internal.Substitution (
    toMap,
 )
import Kore.Internal.TermLike (
    TermLike,
    pattern Exists_,
 )
import Kore.Rewriting.RewritingVariable (
    RewritingVariableName,
 )
import Kore.Step.Simplification.Simplify (
    MonadSimplify,
    simplifyCondition,
    simplifyConditionalTerm,
 )
import Kore.Substitute (
    substitute,
 )
import Prelude.Kore

-- | Simplifies the 'Pattern' and removes the exists quantifiers at the top.
simplifyTopConfiguration ::
    forall simplifier.
    MonadSimplify simplifier =>
    Pattern RewritingVariableName ->
    simplifier (OrPattern RewritingVariableName)
simplifyTopConfiguration =
    simplify >=> return . removeTopExists

{- | Simplifies the 'Pattern' with the assumption that the 'TermLike' is defined
and removes the exists quantifiers at the top.
-}
simplifyTopConfigurationDefined ::
    MonadSimplify simplifier =>
    Pattern RewritingVariableName ->
    TermLike RewritingVariableName ->
    simplifier (OrPattern RewritingVariableName)
simplifyTopConfigurationDefined patt defined =
    makeEvaluate sideCondition patt
        >>= return . removeTopExists
  where
    sideCondition = SideCondition.assumeDefined defined

-- | Removes all existential quantifiers at the top of every 'Pattern''s 'term'.
removeTopExists ::
    OrPattern RewritingVariableName ->
    OrPattern RewritingVariableName
removeTopExists = OrPattern.map removeTopExistsWorker
  where
    removeTopExistsWorker ::
        Pattern RewritingVariableName ->
        Pattern RewritingVariableName
    removeTopExistsWorker p@Conditional{term = Exists_ _ _ quantified} =
        removeTopExistsWorker p{term = quantified}
    removeTopExistsWorker p = p

-- | Simplifies an 'Pattern', returning an 'OrPattern'.
simplify ::
    MonadSimplify simplifier =>
    Pattern RewritingVariableName ->
    simplifier (OrPattern RewritingVariableName)
simplify = makeEvaluate SideCondition.top

{- | Simplifies a 'Pattern' with a custom 'SideCondition'.
This should only be used when it's certain that the
'SideCondition' was not created from the 'Condition' of
the 'Pattern'.
-}
makeEvaluate ::
    MonadSimplify simplifier =>
    SideCondition RewritingVariableName ->
    Pattern RewritingVariableName ->
    simplifier (OrPattern RewritingVariableName)
makeEvaluate sideCondition pattern' =
    OrPattern.observeAllT $ do
        withSimplifiedCondition <- simplifyCondition sideCondition pattern'
        let (term, simplifiedCondition) =
                Conditional.splitTerm withSimplifiedCondition
            term' = substitute (toMap $ substitution simplifiedCondition) term
            simplifiedCondition' =
                -- Combine the predicate and the substitution. The substitution
                -- has already been applied to the term being simplified. This
                -- is only to make SideCondition.andCondition happy, below,
                -- because there might be substitution variables in
                -- sideCondition. That's allowed because we are only going to
                -- send the side condition to the solver, but we should probably
                -- fix SideCondition.andCondition instead.
                simplifiedCondition
                    & Condition.toPredicate
                    & Condition.fromPredicate
            termSideCondition =
                sideCondition `SideCondition.andCondition` simplifiedCondition'
        simplifiedTerm <- simplifyConditionalTerm termSideCondition term'
        let simplifiedPattern =
                Conditional.andCondition simplifiedTerm simplifiedCondition
        simplifyCondition sideCondition simplifiedPattern
