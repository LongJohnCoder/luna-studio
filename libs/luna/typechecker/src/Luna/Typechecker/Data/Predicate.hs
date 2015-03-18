module Luna.Typechecker.Data.Predicate where


import            Flowbox.Prelude

import qualified  Data.IntConvertibleSet as S

import            Luna.Typechecker.AlphaEquiv
import            Luna.Typechecker.Data.Type



data Predicate  = TRUE
                | Type `Subsume` Type
                deriving (Show,Eq,Ord)


instance AlphaEquiv Predicate where
    equiv a b
      | isTrivial a && isTrivial b            = return ()
    equiv (p1 `Subsume` q1) (p2 `Subsume` q2) = equiv p1 p2 >> equiv q1 q2
    equiv _ _ = notAlphaEquivalent

    translateBtoA TRUE            = pure TRUE
    translateBtoA (p `Subsume` q) = Subsume <$> translateBtoA p <*> translateBtoA q

    freevars TRUE = S.empty
    freevars (p `Subsume` q) = freevars p <> freevars q


isTrivial :: Predicate -> Bool
isTrivial TRUE                     = True
isTrivial (x `Subsume` y) | x == y = True
isTrivial _                        = False