module Test.Kore.Step.Simplification.Next (
    test_nextSimplification,
) where

import Kore.Internal.OrPattern (
    OrPattern,
 )
import qualified Kore.Internal.OrPattern as OrPattern
import Kore.Internal.Pattern as Pattern
import Kore.Internal.Predicate (
    makeEqualsPredicate,
    makeTruePredicate,
 )
import Kore.Internal.TermLike
import Kore.Rewriting.RewritingVariable (
    RewritingVariableName,
 )
import Kore.Step.Simplification.Next (
    simplify,
 )
import Prelude.Kore
import qualified Test.Kore.Step.MockSymbols as Mock
import Test.Tasty
import Test.Tasty.HUnit.Ext

test_nextSimplification :: [TestTree]
test_nextSimplification =
    [ testCase
        "Next evaluates to Next"
        ( assertEqual
            ""
            ( OrPattern.fromPatterns
                [ Conditional
                    { term = mkNext Mock.a
                    , predicate = makeTruePredicate
                    , substitution = mempty
                    }
                ]
            )
            ( evaluate
                ( makeNext
                    [ Conditional
                        { term = Mock.a
                        , predicate = makeTruePredicate
                        , substitution = mempty
                        }
                    ]
                )
            )
        )
    , testCase
        "Next collapses or"
        ( assertEqual
            ""
            ( OrPattern.fromPatterns
                [ Conditional
                    { term =
                        mkNext
                            ( mkOr
                                Mock.a
                                (mkAnd Mock.b (mkEquals_ Mock.a Mock.b))
                            )
                    , predicate = makeTruePredicate
                    , substitution = mempty
                    }
                ]
            )
            ( evaluate
                ( makeNext
                    [ Conditional
                        { term = Mock.a
                        , predicate = makeTruePredicate
                        , substitution = mempty
                        }
                    , Conditional
                        { term = Mock.b
                        , predicate = makeEqualsPredicate Mock.a Mock.b
                        , substitution = mempty
                        }
                    ]
                )
            )
        )
    ]

findSort :: [Pattern RewritingVariableName] -> Sort
findSort [] = Mock.testSort
findSort (Conditional{term} : _) = termLikeSort term

evaluate ::
    Next Sort (OrPattern RewritingVariableName) ->
    OrPattern RewritingVariableName
evaluate = simplify

makeNext ::
    [Pattern RewritingVariableName] ->
    Next Sort (OrPattern RewritingVariableName)
makeNext child =
    Next
        { nextSort = findSort child
        , nextChild = OrPattern.fromPatterns child
        }
