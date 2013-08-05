---------------------------------------------------------------------------
-- Copyright (C) Flowbox, Inc - All Rights Reserved
-- Unauthorized copying of this file, via any medium is strictly prohibited
-- Proprietary and confidential
-- Flowbox Team <contact@flowbox.io>, 2013
---------------------------------------------------------------------------

module Luna.Codegen.Hs.ModGenerator(
    generateDefinition,
    generateModule
) where

import Debug.Trace


import           Data.List                         (zip4)

import qualified Luna.Network.Def.DefManager     as DefManager
import           Luna.Network.Def.DefManager       (DefManager)
import qualified Luna.Network.Path.Path          as Path
import qualified Luna.Network.Def.NodeDef        as NodeDef
import qualified Luna.Type.Type                  as Type
import qualified Luna.Codegen.Hs.Import          as Import
import qualified Luna.Data.Graph                 as Graph

import qualified Luna.Codegen.Hs.AST.Module      as Module
import           Luna.Codegen.Hs.AST.Module        (Module)
import qualified Luna.Codegen.Hs.FuncGenerator   as FG
import qualified Luna.Codegen.Hs.ClassGenerator  as CG
import qualified Luna.Codegen.Hs.Path            as Path
import qualified Luna.Codegen.Hs.AST.Function    as Function
import qualified Luna.Codegen.Hs.AST.Extension   as Extension
import qualified Luna.Codegen.Hs.AST.DataType    as DataType
import qualified Luna.Codegen.Hs.AST.Expr        as Expr

import           Luna.Data.List


--import Control.Monad.State

--generateDefinition manager vtx = runState

generateDefinition :: DefManager -> Graph.Vertex -> Module
generateDefinition manager vtx = nmod where
    def = Graph.lab manager vtx
    cls = NodeDef.cls def
    nmod = case cls of
        Type.Module   {} -> m where
            basemod  = generateModule manager vtx
            submods  = Module.submodules basemod
            subpaths = map Module.path submods
            subimps  = map Import.simple subpaths 
            m        = Module.addImports subimps basemod

        Type.Function {} -> m where
            basemod  = generateModule manager vtx
            submods  = Module.submodules basemod
            subpaths = map Module.path submods
            subimps  = map Import.qualified subpaths
            subnames = map Path.last subpaths
            subsrcs  = map (Path.toString . Path.toModulePath) subpaths
            aliases  = [(name, src ++ "." ++ name) | (name, src) <- zip subnames subsrcs]
            (basefunc, basemod2) = FG.generateFunction def basemod
            func     = foldr Function.addAlias basefunc aliases
            m        = Module.addFunction func
                     $ Module.addImports subimps
                     $ basemod2

        Type.Class {} -> m where
            basemod   = generateModule manager vtx
            submods   = Module.submodules basemod
            subpaths  = map Module.path submods
            subimps   = map Import.qualified subpaths
            subnames  = map Path.last subpaths
            subnamesM = map Path.mkMonadName subnames
            commimps  = map Import.common subnames

            csubnames   = map Path.mkClassName subnames
            modsubpaths = map Path.toModulePath subpaths
            impfuncs  = map Path.toString $ zipWith Path.append subnames  modsubpaths
            impfuncsM = map Path.toString $ zipWith Path.append subnamesM modsubpaths

            --test     = Function.empty { Function.name      = "ala"
            --                          , Function.signature = [Expr.At Path.inputs (Expr.Tuple ((Expr.Cons "dupa" []):(replicate 3 Expr.Any)))]
            --                          }


            (basedt, basemod2) = CG.generateClass def basemod
            modproto = Module.addImports subimps 
                     $ Module.addImports commimps 
                     $ Module.addExt Extension.TemplateHaskell
                     $ Module.addExt Extension.FlexibleInstances
                     $ Module.addExt Extension.MultiParamTypeClasses
                     $ Module.addExt Extension.UndecidableInstances       --FIXME[wd]: Czy mozna sie tego pozbyc?
                     $ basemod2

            instargs = zip4 csubnames impfuncs impfuncsM subnames


            m        = --trace(show $ length (Expr.fields basedt)) $
            --foldri Module.addAlias aliases 
                     foldri Module.mkInst instargs 
                     $ modproto

            --mkInstIO ''F_len 'len_ 'len_IO 'len

        _            -> error "Not known type conversion."



generateModule :: DefManager -> Graph.Vertex -> Module
generateModule manager vtx  = m where
    path        = Path.fromList $ DefManager.pathNames manager vtx 
    outnodes    = DefManager.suc manager vtx
    modules     = map (generateDefinition manager) outnodes
    m           = Module.base { Module.path       = path
                              , Module.submodules = modules
                              }

    --outnames    = fmap (Type.name . NodeDef.cls) outnodes
    --outpaths    = fmap ((Path.add path) . Path.single) outnames
    --imports     = zipWith Import.single outpaths outnames
    --importstxt  = join "\n" $ fmap Import.genCode imports
    --header      = "module " ++ Path.toModulePath path
    --out         = header ++ generateModuleReturn ++ importstxt ++ "\n\n"


