{- |
Copyright   : (c) Runtime Verification, 2019
License     : NCSA
-}
module Kore.Builtin.External (
    externalize,
) where

import Data.Functor.Const (
    Const (..),
 )
import qualified Data.Functor.Foldable as Recursive
import qualified Kore.Attribute.Null as Attribute
import Kore.Attribute.Synthetic (
    synthesize,
 )
import qualified Kore.Builtin.Bool.Bool as Bool
import qualified Kore.Builtin.Endianness.Endianness as Endianness
import qualified Kore.Builtin.Int.Int as Int
import qualified Kore.Builtin.InternalBytes.InternalBytes as InternalBytes
import qualified Kore.Builtin.List.List as List
import qualified Kore.Builtin.Map.Map as Map
import qualified Kore.Builtin.Set.Set as Set
import qualified Kore.Builtin.Signedness.Signedness as Signedness
import qualified Kore.Builtin.String.String as String
import qualified Kore.Internal.Alias as Alias
import qualified Kore.Internal.Inj as Inj
import qualified Kore.Internal.Symbol as Symbol
import Kore.Internal.TermLike
import qualified Kore.Syntax.Pattern as Syntax
import Prelude.Kore

{- | Externalize the 'TermLike' into a 'Syntax.Pattern'.

All builtins will be rendered using their concrete Kore syntax.

See also: 'asPattern'
-}
externalize ::
    forall variable.
    InternalVariable variable =>
    TermLike variable ->
    Syntax.Pattern variable Attribute.Null
externalize =
    Recursive.unfold worker
  where
    worker ::
        TermLike variable ->
        Recursive.Base
            (Syntax.Pattern variable Attribute.Null)
            (TermLike variable)
    worker termLike =
        -- TODO (thomas.tuegel): Make all these cases into classes.
        case termLikeF of
            InternalBoolF (Const internalBool) ->
                (toPatternF . Recursive.project) (Bool.asTermLike internalBool)
            InternalIntF (Const internalInt) ->
                (toPatternF . Recursive.project) (Int.asTermLike internalInt)
            InternalBytesF (Const internalBytes) ->
                (toPatternF . Recursive.project)
                    (InternalBytes.asTermLike internalBytes)
            InternalStringF (Const internalString) ->
                (toPatternF . Recursive.project)
                    (String.asTermLike internalString)
            InternalListF internalList ->
                (toPatternF . Recursive.project)
                    (List.asTermLike internalList)
            InternalMapF internalMap ->
                (toPatternF . Recursive.project)
                    (Map.asTermLike internalMap)
            InternalSetF internalSet ->
                (toPatternF . Recursive.project)
                    (Set.asTermLike internalSet)
            InjF inj ->
                (toPatternF . Recursive.project . synthesize . ApplySymbolF)
                    (Inj.toApplication inj)
            _ -> toPatternF termLikeBase
      where
        termLikeBase@(_ :< termLikeF) = Recursive.project termLike

    toPatternF ::
        HasCallStack =>
        Recursive.Base (TermLike variable) (TermLike variable) ->
        Recursive.Base
            (Syntax.Pattern variable Attribute.Null)
            (TermLike variable)
    toPatternF (_ :< termLikeF) =
        (Attribute.Null :<) $
            case termLikeF of
                AndF andF -> Syntax.AndF andF
                ApplyAliasF applyAliasF ->
                    Syntax.ApplicationF $
                        mapHead Alias.toSymbolOrAlias applyAliasF
                ApplySymbolF applySymbolF ->
                    Syntax.ApplicationF $
                        mapHead Symbol.toSymbolOrAlias applySymbolF
                BottomF bottomF -> Syntax.BottomF bottomF
                CeilF ceilF -> Syntax.CeilF ceilF
                DomainValueF domainValueF -> Syntax.DomainValueF domainValueF
                EqualsF equalsF -> Syntax.EqualsF equalsF
                ExistsF existsF -> Syntax.ExistsF existsF
                FloorF floorF -> Syntax.FloorF floorF
                ForallF forallF -> Syntax.ForallF forallF
                IffF iffF -> Syntax.IffF iffF
                ImpliesF impliesF -> Syntax.ImpliesF impliesF
                InF inF -> Syntax.InF inF
                MuF muF -> Syntax.MuF muF
                NextF nextF -> Syntax.NextF nextF
                NotF notF -> Syntax.NotF notF
                NuF nuF -> Syntax.NuF nuF
                OrF orF -> Syntax.OrF orF
                RewritesF rewritesF -> Syntax.RewritesF rewritesF
                StringLiteralF stringLiteralF ->
                    Syntax.StringLiteralF stringLiteralF
                TopF topF -> Syntax.TopF topF
                VariableF variableF -> Syntax.VariableF variableF
                InhabitantF inhabitantF -> Syntax.InhabitantF inhabitantF
                EndiannessF endiannessF ->
                    Syntax.ApplicationF $
                        mapHead Symbol.toSymbolOrAlias $
                            Endianness.toApplication $
                                getConst endiannessF
                SignednessF signednessF ->
                    Syntax.ApplicationF $
                        mapHead Symbol.toSymbolOrAlias $
                            Signedness.toApplication $
                                getConst signednessF
                InjF _ -> error "Unexpected sort injection"
                InternalBoolF _ -> error "Unexpected internal builtin"
                InternalBytesF _ -> error "Unexpected internal builtin"
                InternalIntF _ -> error "Unexpected internal builtin"
                InternalStringF _ -> error "Unexpected internal builtin"
                InternalListF _ -> error "Unexpected internal builtin"
                InternalMapF _ -> error "Unexpected internal builtin"
                InternalSetF _ -> error "Unexpected internal builtin"
