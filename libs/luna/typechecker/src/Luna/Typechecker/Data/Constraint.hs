module Luna.Typechecker.Data.Constraint where


import            Flowbox.Prelude

import qualified  Data.IntConvertibleSet as S

import            Luna.Typechecker.AlphaEquiv
import            Luna.Typechecker.Data.TVar
import            Luna.Typechecker.Data.Predicate



data Constraint = C [Predicate]
                | Proj [TVar] [Predicate]
                deriving (Show)


instance Monoid Constraint where
    mempty = C [TRUE]
    mappend (C p1) (C p2)               = C (p1 ++ p2)
    mappend (C p1) (Proj tvr p2)        = Proj tvr (p1 ++ p2)
    mappend (Proj tvr p1) (C p2)        = Proj tvr (p1 ++ p2)
    mappend (Proj tv1 p1) (Proj tv2 p2) = Proj (tv1 ++ tv2) (p1 ++ p2)


true_cons :: Constraint
true_cons = C [TRUE]


instance AlphaEquiv Constraint where
    equiv p@(C preds1) q@(C preds2)
      | S.size free1 /= S.size free2 = notAlphaEquivalent
      | otherwise                    = nonDeterministicEquiv (S.toList free1) (S.toList free2)
      where
        free1 = freevars $ filter (not.isTrivial) preds1
        free2 = freevars $ filter (not.isTrivial) preds2

    equiv (C p) b = equiv (Proj [] p) b
    equiv a (C p) = equiv a (Proj [] p)

    equiv p@(Proj tvs1 ps1) q@(Proj tvs2 ps2)
      | S.size free1  /= S.size free2  = notAlphaEquivalent
      | S.size quant1 /= S.size quant2 = notAlphaEquivalent
      | otherwise = do
        nonDeterministicEquiv (S.toList free1)  (S.toList free2)
        nonDeterministicEquiv (S.toList quant1) (S.toList quant2)
      where tvars_tvs1 = S.fromList tvs1
            free1      = freevars ps1C `S.difference`   tvars_tvs1
            quant1     = freevars ps1C `S.intersection` tvars_tvs1

            tvars_tvs2 = S.fromList tvs2
            free2      = freevars ps2C `S.difference`   tvars_tvs2
            quant2     = freevars ps2C `S.intersection` tvars_tvs2

            ps1C = filter (not.isTrivial) ps1
            ps2C = filter (not.isTrivial) ps2

    translateBtoA (C        ps) = C    <$>                     mapM translateBtoA ps
    translateBtoA (Proj tvs ps) = Proj <$> mapM ttBtoA tvs <*> mapM translateBtoA ps

    freevars (C ps) = freevars ps
    freevars (Proj tvs ps) = mconcat (freevars <$> ps) `S.difference` S.fromList tvs
