module Test.Kore.Builtin.Inj (
    test_patternVerifierHook,
) where

import Kore.ASTVerifier.PatternVerifier (
    verifyStandalonePattern,
    withBuiltinVerifiers,
 )
import Kore.ASTVerifier.PatternVerifier.PatternVerifier
import qualified Kore.Builtin as Builtin
import Kore.Builtin.Inj
import Kore.Builtin.Verifiers
import Kore.Error (
    assertRight,
 )
import Kore.Internal.TermLike
import Kore.Unparser (
    unparse,
 )
import Prelude.Kore
import qualified Pretty
import Test.Kore.Builtin.Builtin
import Test.Kore.Builtin.Definition
import qualified Test.Kore.Builtin.Int as Int
import Test.Tasty
import Test.Tasty.HUnit.Ext

test_patternVerifierHook :: [TestTree]
test_patternVerifierHook =
    [ testCase "patternVerifierHook" $ do
        let context = verifiedModuleContext verifiedModule
            actual =
                assertRight
                    . runPatternVerifier context
                    . runPatternVerifierHook patternVerifierHook
                    $ original
        assertEqual (message actual) expect actual
    , testCase "verifyStandalonePattern" $ do
        let context =
                verifiedModuleContext verifiedModule
                    & withBuiltinVerifiers Builtin.koreVerifiers
            actual =
                assertRight
                    . runPatternVerifier context
                    . verifyStandalonePattern (Just kItemSort)
                    $ Builtin.externalize original
        assertEqual (message actual) expect actual
    ]
  where
    Verifiers{patternVerifierHook} = verifiers
    original = mkApplySymbol (injSymbol intSort kItemSort) [Int.asInternal 0]
    expect = inj kItemSort (Int.asInternal 0)
    message actual =
        (show . Pretty.vsep)
            [ "Expected:"
            , (Pretty.indent 4 . unparse) expect
            , "but found:"
            , (Pretty.indent 4 . unparse) actual
            ]
