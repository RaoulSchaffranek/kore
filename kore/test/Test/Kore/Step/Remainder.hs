module Test.Kore.Step.Remainder where

import Test.Tasty

import           Kore.AST.Valid
import           Kore.Predicate.Predicate
                 ( Predicate )
import qualified Kore.Predicate.Predicate as Predicate
import qualified Kore.Step.Remainder as Remainder
import           Kore.Syntax.Variable
                 ( Variable )
import           Kore.Variables.Target
                 ( Target (..) )

import           Test.Kore.Comparators ()
import qualified Test.Kore.Step.MockSymbols as Mock
import           Test.Terse

test_existentiallyQuantifyTarget :: [TestTree]
test_existentiallyQuantifyTarget =
    [ target `becomes` quantified $  "quantifies target variables"
    ]
  where
    becomes original expect =
        equals (Remainder.existentiallyQuantifyTarget original) expect

target :: Predicate (Target Variable)
target =
    Predicate.makeEqualsPredicate
        (mkVar $ NonTarget Mock.x)
        (Mock.sigma
            (mkVar $ Target Mock.y)
            (mkVar $ Target Mock.z)
        )

quantified :: Predicate Variable
quantified =
    Predicate.makeMultipleExists [Mock.y, Mock.z]
    $ Predicate.makeEqualsPredicate
        (mkVar Mock.x)
        (Mock.sigma (mkVar Mock.y) (mkVar Mock.z))
