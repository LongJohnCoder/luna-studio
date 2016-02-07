{-# LANGUAGE NoMonomorphismRestriction #-}
{-# LANGUAGE FunctionalDependencies #-}
{-# LANGUAGE UndecidableInstances   #-}
{-# LANGUAGE RecursiveDo            #-}

{-# LANGUAGE PolyKinds            #-}

module Luna.Syntax.Model.Network.Builder.Term.Class where

import Prelude.Luna hiding (Num)

import           Data.Record                    (RecordOf, IsRecord, asRecord, SmartCons, Variant, MapTryingElemList_, withElement_, Props)
import qualified Data.Record                    as Record
import qualified Luna.Syntax.AST.Term           as Term
import           Luna.Syntax.AST.Term           hiding (Val, Lit, Thunk, Expr, Draft, Source)
import Luna.Syntax.Model.Graph
import Data.Prop
import           Control.Monad.Event
import           Luna.Runtime.Model                       as Runtime
import           Luna.Syntax.Model.Network.Builder.Layer
import qualified Luna.Syntax.Model.Graph.Builder as GraphBuilder
import qualified Luna.Syntax.Model.Network.Builder.Type as Type
import qualified Luna.Syntax.Model.Network.Builder.Self as Self
import           Luna.Syntax.Model.Network.Term
import           Luna.Syntax.Model.Layer
import           Luna.Syntax.AST.Arg
import           Data.Layer
import           Data.Layer.Cover
import           Data.Direction
import           Data.Tuple.Curry.Missing
import           Data.Tuple.OneTuple

import Type.Bool



-------------------------------------
-- === Term building utilities === --
-------------------------------------

-- === Utility Type Families === --

-- FIXME[WD]: Zmienic nazwe Layout na adekwatna
-- FIXME[WD]: Skoro Layout okresla jakie jest "wejscie" do nodu, to Input nie jest potrzebny, bo mozna go wyinferowac jako odwrotnosc Connection

type family BuildArgs (t :: k) n :: *
type family Expanded  (t :: k) n :: *


-- === ElemBuilder === --

class    ElemBuilder el m  a where buildElem :: el -> m a
instance {-# OVERLAPPABLE #-} ElemBuilder el IM a where buildElem = impossible

instance {-# OVERLAPPABLE #-}
         ( SmartCons el (Uncovered a)
         , CoverConstructor m a
         , Dispatcher ELEMENT a m
         , Self.MonadSelfBuilder s m
         , Castable a s
         ) => ElemBuilder el m a where
    -- TODO[WD]: change buildAbsMe to buildMe2
    --           and fire monad every time we construct an element, not once for the graph
    buildElem el = dispatch ELEMENT =<< Self.buildAbsMe (constructCover $ Record.cons el) where
    {-# INLINE buildElem #-}


-- === TermBuilder === --

class TermBuilder (t :: k) m a where buildTerm :: Proxy t -> BuildArgs t a -> m a
instance {-# OVERLAPPABLE #-} TermBuilder t IM a where buildTerm = impossible



-------------------------------
-- === Term constructors === --
-------------------------------

-- === Args === --

-- TODO[WD]: add named option
arg :: a -> Arg a
arg = Arg Nothing


-- === Lit === --

type instance BuildArgs Star n = ()
type instance BuildArgs Str  n = OneTuple String
type instance BuildArgs Num  n = OneTuple Int

instance ElemBuilder Star m a => TermBuilder Star m a where buildTerm p ()           = buildElem Star
instance ElemBuilder Str  m a => TermBuilder Str  m a where buildTerm p (OneTuple s) = buildElem $ Str s
instance ElemBuilder Num  m a => TermBuilder Num  m a where buildTerm p (OneTuple s) = buildElem $ Num s

star :: TermBuilder Star m a => m a
star = curryN $ buildTerm (Proxy :: Proxy Star)

str :: TermBuilder Str m a => String -> m a
str = curryN $ buildTerm (Proxy :: Proxy Str)

int :: TermBuilder Num m a => Int -> m a
int = curryN $ buildTerm (Proxy :: Proxy Num)


-- === Val === --

type instance BuildArgs Cons   n = OneTuple (NameInput n)

instance ( name ~ NameInput a
         , MonadFix m
         , ConnectibleName name a m
         , ElemBuilder (Cons (NameConnection name a)) m a
         ) => TermBuilder Cons m a where
    buildTerm p (OneTuple name) = mdo
        out   <- buildElem $ Cons cname
        cname <- nameConnection name out
        return out

cons :: TermBuilder Cons m a => NameInput a -> m a
cons = curryN $ buildTerm (Proxy :: Proxy Cons)

-- arr -- TODO (Maybe we should change the arr signature?)


-- === Thunk === --

type instance BuildArgs Acc n = (NameInput n, Input n)
type instance BuildArgs App n = (Input n, [Arg (Input n)])

instance {-# OVERLAPPABLE #-}
         ( src  ~ Input a
         , name ~ NameInput a
         , MonadFix m
         , Connectible     src  a m
         , ConnectibleName name a m
         , ElemBuilder (Acc (NameConnection name a) (Connection src a)) m a
         ) => TermBuilder Acc m a where
    buildTerm p (name, src) = mdo
        out   <- buildElem $ Acc cname csrc
        cname <- nameConnection name out
        csrc  <- connection     src  out
        return out

instance ( inp ~ Input a
         , MonadFix m
         , Connectible inp a m
         , ElemBuilder (App $ Connection inp a) m a
         ) => TermBuilder App m a where
    buildTerm p (src,args) = mdo
        out   <- buildElem $ App csrc cargs
        csrc  <- connection src out
        cargs <- (mapM ∘ mapM) (flip connection out) args
        return out

acc :: TermBuilder Acc m a => NameInput a -> Input a -> m a
acc = curryN $ buildTerm (Proxy :: Proxy Acc)

app :: TermBuilder App m a => Input a -> [Arg $ Input a] -> m a
app = curryN $ buildTerm (Proxy :: Proxy App)


-- === Expr === --


type instance BuildArgs Var   n = OneTuple (NameInput    n)
instance ( name ~ NameInput a
         , MonadFix m
         , ConnectibleName name a m
         , ElemBuilder (Var $ NameConnection name a) m a
         ) => TermBuilder Var m a where
    buildTerm p (OneTuple name) = mdo
        out   <- buildElem $ Var cname
        cname <- nameConnection name out
        return out

type instance BuildArgs Unify n = (Input n, Input n)
instance ( inp ~ Input a
         , MonadFix m
         , Connectible inp a m
         , ElemBuilder (Unify $ Connection inp a) m a
         ) => TermBuilder Unify m a where
    buildTerm p (a,b) = mdo
        out <- buildElem $ Unify ca cb
        ca  <- connection a out
        cb  <- connection b out
        return out

var :: TermBuilder Var m a => NameInput a -> m a
var = curryN $ buildTerm (Proxy :: Proxy Var)

unify :: TermBuilder Unify m a => Input a -> Input a -> m a
unify = curryN $ buildTerm (Proxy :: Proxy Unify)


-- === Draft === --

type instance BuildArgs   Blank n = ()
instance      ElemBuilder Blank m a => TermBuilder Blank m a where buildTerm p () = buildElem Blank

blank :: TermBuilder Blank m a => m a
blank = curryN $ buildTerm (Proxy :: Proxy Blank)












matchType :: Proxy t -> t -> t
matchType _ = id

matchTypeM :: Proxy t -> m t -> m t
matchTypeM _ = id

node :: n ~ Ref (Node $ ls :< term) => m n -> m n
node = id



acc4 :: ( MonadFix m
       , ElemBuilder (Acc (NameConnection n u) (Connection a u)) m u
       , Connectible a u m
       , ConnectibleName n u m
       ) => n -> a -> m u
acc4 name obj = mdo
    out   <- buildElem $ Acc cname cobj
    cname <- nameConnection name out
    cobj  <- connection obj out
    return out

------------------------------
-- === Network Building === --
------------------------------

type NetLayers = '[Type, Succs, Markable]
type NetNode   = NetLayers :< Draft Static

type NetGraph = Graph (NetLayers :< Raw) (Link (NetLayers :< Raw))

buildNetwork  = runIdentity ∘ buildNetworkM
buildNetworkM = rebuildNetworkM' (def :: NetGraph)

rebuildNetwork' = runIdentity .: rebuildNetworkM'
rebuildNetworkM' (net :: NetGraph) = flip Self.evalT (undefined ::        Ref $ Node NetNode)
                                   ∘ flip Type.evalT (Nothing   :: Maybe (Ref $ Node NetNode))
                                   ∘ constrainTypeM1 CONNECTION (Proxy :: Proxy $ Ref c)
                                   ∘ constrainTypeEq ELEMENT    (Proxy :: Proxy $ Ref $ Node NetNode)
                                   ∘ flip GraphBuilder.runT net
                                   ∘ registerSuccs   CONNECTION
{-# INLINE   buildNetworkM #-}
{-# INLINE rebuildNetworkM' #-}


class NetworkBuilderT net m n | m -> n, m -> net where runNetworkBuilderT :: net -> m a -> n (a, net)

instance {-# OVERLAPPABLE #-} NetworkBuilderT I IM IM where runNetworkBuilderT = impossible
instance {-# OVERLAPPABLE #-}
    ( m      ~ Listener CONNECTION SuccRegister m'
    , m'     ~ GraphBuilder.BuilderT n e m''
    , m''    ~ Listener ELEMENT (TypeConstraint Equality_Full (Ref $ Node NetNode)) m'''
    , m'''   ~ Listener CONNECTION (TypeConstraint Equality_M1 (Ref c)) m''''
    , m''''  ~ Type.TypeBuilderT (Ref $ Node NetNode) m'''''
    , m''''' ~ Self.SelfBuilderT (Ref $ Node NetNode) m''''''
    , Monad m'''''
    , Monad m''''''
    , net ~ Graph n e
    ) => NetworkBuilderT net m m'''''' where
    runNetworkBuilderT net = flip Self.evalT (undefined ::        Ref $ Node NetNode)
                           ∘ flip Type.evalT (Nothing   :: Maybe (Ref $ Node NetNode))
                           ∘ constrainTypeM1 CONNECTION (Proxy :: Proxy $ Ref c)
                           ∘ constrainTypeEq ELEMENT    (Proxy :: Proxy $ Ref $ Node NetNode)
                           ∘ flip GraphBuilder.runT net
                           ∘ registerSuccs   CONNECTION




-- FIXME[WD]: poprawic typ oraz `WithElement_` (!)
-- FIXME[WD]: inputs should be more general and should be refactored out
inputstmp :: forall layout term rt x.
      (MapTryingElemList_
                            (Elems term (ByRuntime rt Str x) x)
                            (TFoldable x)
                            (Term layout term rt), x ~ Layout layout term rt) => Term layout term rt -> [x]
inputstmp a = withElement_ (p :: P (TFoldable x)) (foldrT (:) []) a



type instance Prop Inputs (Term layout term rt) = [Layout layout term rt]
instance (MapTryingElemList_
                           (Elems
                              term
                              (ByRuntime rt Str (Layout layout term rt))
                              (Layout layout term rt))
                           (TFoldable (Layout layout term rt))
                           (Term layout term rt)) => Getter Inputs (Term layout term rt) where getter _ = inputstmp
