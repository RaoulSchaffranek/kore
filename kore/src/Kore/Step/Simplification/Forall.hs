{-|
Module      : Kore.Step.Simplification.Forall
Description : Tools for Forall pattern simplification.
Copyright   : (c) Runtime Verification, 2018
License     : NCSA
Maintainer  : virgil.serbanuta@runtimeverification.com
Stability   : experimental
Portability : portable
-}
module Kore.Step.Simplification.Forall
    ( simplify
    , makeEvaluate
    ) where

import           Kore.AST.Common
                 ( Forall (..) )
import           Kore.AST.Valid
import           Kore.Predicate.Predicate
                 ( makeTruePredicate )
import           Kore.Step.OrPattern
                 ( OrPattern )
import qualified Kore.Step.OrPattern as OrPattern
import           Kore.Step.Pattern as Pattern
import qualified Kore.Step.Representation.MultiOr as MultiOr
                 ( fmapWithPairs )
import           Kore.Step.Simplification.Data
                 ( SimplificationProof (..) )
import           Kore.Unparser

-- TODO: Move Forall up in the other simplifiers or something similar. Note
-- that it messes up top/bottom testing so moving it up must be done
-- immediately after evaluating the children.
{-|'simplify' simplifies an 'Forall' pattern with an 'OrPattern'
child.

Right now this has special cases only for top and bottom children.

Note that while forall x . phi(x) and [x=alpha] can be simplified
(it's bottom if x's sort is multivalued and alpha is not the 'x' pattern or
the identity function applied to the pattern x, or phi(alpha) otherwise),
we only expect forall usage for symbolic variables, so we won't attempt to
simplify it this way.

For this reason, we don't even try to see if the variable actually occurs in
the pattern except for the top/bottom cases.
-}
simplify
    ::  ( SortedVariable variable
        , Ord variable
        , Show variable
        , Unparse variable
        )
    => Forall Object variable (OrPattern Object variable)
    ->  ( OrPattern Object variable
        , SimplificationProof Object
        )
simplify
    Forall { forallVariable = variable, forallChild = child }
  =
    simplifyEvaluated variable child

{- TODO (virgil): Preserve pattern sorts under simplification.

One way to preserve the required sort annotations is to make 'simplifyEvaluated'
take an argument of type

> CofreeF (Forall Object) (Valid Object) (OrPattern Object variable)

instead of a 'variable' and an 'OrPattern' argument. The type of
'makeEvaluate' may be changed analogously. The 'Valid' annotation will
eventually cache information besides the pattern sort, which will make it even
more useful to carry around.

-}
simplifyEvaluated
    ::  ( SortedVariable variable
        , Ord variable
        , Show variable
        , Unparse variable
        )
    => variable
    -> OrPattern Object variable
    -> (OrPattern Object variable, SimplificationProof Object)
simplifyEvaluated variable simplified
  | OrPattern.isTrue simplified = (simplified, SimplificationProof)
  | OrPattern.isFalse simplified = (simplified, SimplificationProof)
  | otherwise =
    let
        (patt, _proofs) =
            MultiOr.fmapWithPairs (makeEvaluate variable) simplified
      in
        ( patt
        , SimplificationProof
        )

{-| evaluates an 'Forall' given its two 'Pattern' children.

See 'simplify' for detailed documentation.
-}
makeEvaluate
    ::  ( SortedVariable variable
        , Ord variable
        , Show variable
        , Unparse variable
        )
    => variable
    -> Pattern Object variable
    -> (Pattern Object variable, SimplificationProof Object)
makeEvaluate variable patt
  | Pattern.isTop patt =
    (Pattern.top, SimplificationProof)
  | Pattern.isBottom patt =
    ( Pattern.bottom
    , SimplificationProof
    )
  | otherwise =
    ( Conditional
        { term = mkForall
            variable
            (Pattern.toMLPattern patt)
        , predicate = makeTruePredicate
        , substitution = mempty
        }
    , SimplificationProof
    )
