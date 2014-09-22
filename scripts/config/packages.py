###########################################################################
## Copyright (C) Flowbox, Inc / All Rights Reserved
## Unauthorized copying of this file, via any medium is strictly prohibited
## Proprietary and confidential
## Flowbox Team <contact@flowbox.io>, 2014
###########################################################################

import os
from subprocess import call, Popen, PIPE
from utils.colors import print_error
from utils.errors import fatal
from utils.system import system, systems
import sys



rootPath = os.path.dirname(os.path.dirname(os.path.dirname(os.path.realpath(__file__))))

def handle_error(e):
    if e:
        print_error(e)
        fatal()


class Flag(object):
    def __init__(self, content, systems=None):
        self.content   = content
        self.systems = systems

class Flags(object):
    def __init__(self, flags=None):
        if flags     == None: flags = []
        self.flags   = flags

    def get(self):
        fs = []
        for flag in self.flags:
            if flag.systems == None or system in flag.systems:
                fs.append(flag.content)
        return fs



class Project(object):
    def __init__(self, name='', path='', binpath='', deps=None, flags=None):
        if deps  == None: deps = []
        if flags == None: flags = Flags()
        self.name    = name
        self.path    = path
        self.binpath = binpath
        self.sbox    = os.path.join(rootPath, 'dist', self.path)
        self.deps    = set(deps)
        self.flags   = flags

    def install(self):   pass

    def uninstall(self): pass

    def targets(self):
        return [self]

    def target_binpaths(self):
        paths = []
        for target in self.targets():
            paths.append(target.binpath)
        return paths

    def target_names(self):
        names = []
        for target in self.targets():
            names.append(target.name)
        return names


class HProject(Project):
    def install(self):
        cmd = 'cabal sandbox add-source %s' % os.path.join(rootPath, self.path)
        (out, err) = Popen(cmd, stdout=PIPE, stderr=PIPE, shell=True).communicate()
        handle_error(err)
        return out

    def uninstall(self):
        cmd = 'cabal sandbox hc-pkg unregister %s' % self.name
        (out, err) = Popen(cmd, stdout=PIPE, stderr=PIPE, shell=True).communicate()
        if err:
            err = err.replace('.exe', '')
            if not err.startswith('ghc-pkg: cannot find package'):
                handle_error(err)
        return out


class AllProject(Project):
    def targets(self):
        # It is needed to omit non-project entries with no path (like @all)
        return [project for project in pkgDb.values() if project.path]  

pkgDb = \
       { '@all'                                : AllProject ('@all', deps = [])
       , 'libs/aws'                            : HProject   ('flowbox-aws'                  , os.path.join ('libs' , 'aws')                                 , 'libs'    , ['libs/utils', 'libs/rpc', 'third-party/hs-certificate/x509', 'third-party/hs-crypto-random', 'third-party/hs-tls/core'])
       , 'libs/batch/batch'                    : HProject   ('flowbox-batch'                , os.path.join ('libs' , 'batch', 'batch')                      , 'libs'    , ['libs/utils', 'libs/config', 'libs/luna/core', 'libs/luna/distribution', 'libs/luna/initializer', 'libs/luna/interpreter-old', 'libs/luna/pass', 'libs/luna/protobuf'])
       , 'libs/batch/plugins/project-manager'  : HProject   ('batch-lib-project-manager'    , os.path.join ('libs' , 'batch', 'plugins', 'project-manager') , 'libs'    , ['libs/utils', 'libs/config', 'libs/rpc', 'libs/bus', 'libs/luna/core', 'libs/batch/batch'])
       , 'libs/bus'                            : HProject   ('flowbox-bus'                  , os.path.join ('libs' , 'bus')                                 , 'libs'    , ['libs/utils', 'libs/config', 'libs/rpc'])
       , 'libs/cabal-install'                  : HProject   ('cabal-install'                , os.path.join ('libs' , 'cabal-install')                       , 'libs'    , [])
       , 'libs/data/codec/exr'                 : HProject   ('openexr'                      , os.path.join ('libs' , 'codec', 'exr')                        , 'libs'    , [], flags=Flags([Flag('--with-gcc=g++')]))
       , 'libs/config'                         : HProject   ('flowbox-config'               , os.path.join ('libs' , 'config')                              , 'libs'    , ['libs/utils'])
       , 'libs/data/dynamics/particles'        : HProject   ('particle'                     , os.path.join ('libs' , 'dynamics', 'particles')               , 'libs'    , [])
       , 'libs/data/graphics/graphics'         : HProject   ('flowbox-graphics'             , os.path.join ('libs' , 'graphics', 'graphics')                , 'libs'    , ['libs/luna/target/ghchs', 'libs/utils', 'libs/num-conversion', 'libs/codec/exr', 'libs/graphics/hopencv'], flags=Flags([Flag("--with-gcc=gcc-4.9", [systems.DARWIN])]))
       , 'libs/data/graphics/hopencv'          : HProject   ('HOpenCV'                      , os.path.join ('libs' , 'graphics', 'hopencv')                 , 'libs'    , [])
       , 'libs/luna/core'                      : HProject   ('luna-core'                    , os.path.join ('libs' , 'luna', 'core')                        , 'libs'    , ['libs/utils'])
       , 'libs/luna/parser'                    : HProject   ('luna-parser'                  , os.path.join ('libs' , 'luna', 'parser')                      , 'libs'    , ['libs/utils', 'libs/luna/core'])
       , 'libs/luna/parser2'                   : HProject   ('luna-parser'                  , os.path.join ('libs' , 'luna', 'parser2')                     , 'libs'    , ['libs/utils', 'libs/luna/core'])
       , 'libs/luna/distribution'              : HProject   ('luna-distribution'            , os.path.join ('libs' , 'luna', 'distribution')                , 'libs'    , ['libs/utils', 'libs/config', 'libs/luna/core', 'libs/luna/protobuf'])
       , 'libs/luna/pass'                      : HProject   ('luna-pass'                    , os.path.join ('libs' , 'luna', 'pass')                        , 'libs'    , ['libs/utils', 'libs/luna/core', 'libs/luna/distribution', 'libs/config', 'libs/luna/target/ghchs', 'libs/luna/parser'])
       , 'libs/luna/protobuf'                  : HProject   ('luna-protobuf'                , os.path.join ('libs' , 'luna', 'protobuf')                    , 'libs'    , ['libs/utils', 'libs/luna/core', 'libs/config'])
       , 'libs/luna/interpreter'               : HProject   ('luna-interpreter'             , os.path.join ('libs' , 'luna', 'interpreter')                 , 'libs'    , ['libs/utils', 'libs/luna/core', 'libs/luna/pass', 'libs/batch/batch'], flags=Flags([Flag('--force-reinstalls')])) # FIXME [PM] force reinstalls-flag  resolves problem with HTTP and network
       , 'libs/luna/interpreter-old'           : HProject   ('luna-interpreter-old'         , os.path.join ('libs' , 'luna', 'interpreter-old')             , 'libs'    , ['libs/utils', 'libs/config', 'libs/luna/core', 'libs/luna/pass'], flags=Flags([Flag('--force-reinstalls')])) # FIXME [PM] force reinstalls-flag  resolves problem with HTTP and network
       , 'libs/luna/initializer'               : HProject   ('luna-initializer'             , os.path.join ('libs' , 'luna', 'initializer')                 , 'libs'    , ['libs/utils', 'libs/config'], flags=Flags([Flag('--force-reinstalls')])) # FIXME [PM] force reinstalls-flag  resolves problem with HTTP and network
       , 'libs/doc/markup'                     : HProject   ('doc-markup'                   , os.path.join ('libs' , 'doc', 'markup')                       , 'libs'    , [])
       , 'libs/num-conversion'                 : HProject   ('num-conversion'               , os.path.join ('libs' , 'num-conversion')                      , 'libs'    , [])
       , 'libs/repo-manager'                   : HProject   ('flowbox-repo-manager'         , os.path.join ('libs' , 'repo-manager')                        , 'libs'    , ['libs/utils', 'libs/config', 'libs/rpc', 'libs/bus'])
       , 'libs/rpc'                            : HProject   ('flowbox-rpc'                  , os.path.join ('libs' , 'rpc')                                 , 'libs'    , ['libs/utils'])
       , 'libs/luna/target/ghchs'              : HProject   ('luna-target-ghchs'            , os.path.join ('libs' , 'luna', 'target', 'ghchs')             , 'libs'    , ['libs/utils'])
       , 'libs/utils'                          : HProject   ('flowbox-utils'                , os.path.join ('libs' , 'utils')                               , 'libs'    , ['third-party/protocol-buffers', "third-party/fgl"])
       , 'tools/aws/account-manager'           : HProject   ('flowbox-account-manager'      , os.path.join ('tools', 'aws', 'account-manager')              , 'tools'   , ['libs/utils', 'libs/rpc'   , 'libs/aws'], flags=Flags([Flag('--force-reinstalls')])) # FIXME [PM] force reinstalls flag resolves problem with HTTP and network
       , 'tools/aws/account-manager-mock'      : HProject   ('flowbox-account-manager-mock' , os.path.join ('tools', 'aws', 'account-manager-mock')         , 'tools'   , ['libs/utils', 'libs/rpc'   , 'libs/aws'], flags=Flags([Flag('--force-reinstalls')])) # FIXME [PM] force reinstalls flag resolves problem with HTTP and network
       , 'tools/aws/instance-manager'          : HProject   ('flowbox-instance-manager'     , os.path.join ('tools', 'aws', 'instance-manager')             , 'tools'   , ['libs/utils', 'libs/aws'], flags=Flags([Flag('--force-reinstalls')])) # FIXME [PM] force reinstalls-flag  resolves problem with HTTP and network
       , 'tools/batch/plugins/broker'          : HProject   ('batch-plugin-broker'          , os.path.join ('tools', 'batch', 'plugins', 'broker')          , 'tools'   , ['libs/utils', 'libs/config', 'libs/rpc', 'libs/bus'])
       , 'tools/batch/plugins/bus-logger'      : HProject   ('batch-plugin-bus-logger'      , os.path.join ('tools', 'batch', 'plugins', 'bus-logger')      , 'tools'   , ['libs/utils', 'libs/config', 'libs/rpc', 'libs/bus'])
       , 'tools/batch/plugins/interpreter'     : HProject   ('batch-plugin-interpreter'     , os.path.join ('tools', 'batch', 'plugins', 'interpreter')     , 'tools'   , ['libs/utils', 'libs/config', 'libs/rpc', 'libs/bus', 'libs/luna/interpreter', 'libs/batch/batch', 'libs/batch/plugins/project-manager'])
       , 'tools/batch/plugins/file-manager'    : HProject   ('batch-plugin-file-manager'    , os.path.join ('tools', 'batch', 'plugins', 'file-manager')    , 'tools'   , ['libs/utils', 'libs/config', 'libs/rpc', 'libs/bus'])
       , 'tools/batch/plugins/parser'          : HProject   ('batch-plugin-parser'          , os.path.join ('tools', 'batch', 'plugins', 'parser')          , 'tools'   , ['libs/utils', 'libs/config', 'libs/rpc', 'libs/bus', 'libs/luna/core', 'libs/batch/batch'])
       , 'tools/batch/plugins/plugin-manager'  : HProject   ('batch-plugin-plugin-manager'  , os.path.join ('tools', 'batch', 'plugins', 'plugin-manager')  , 'tools'   , ['libs/utils', 'libs/config', 'libs/rpc', 'libs/bus'])
       , 'tools/batch/plugins/project-manager' : HProject   ('batch-plugin-project-manager' , os.path.join ('tools', 'batch', 'plugins', 'project-manager') , 'tools'   , ['libs/utils', 'libs/config', 'libs/rpc', 'libs/bus', 'libs/luna/core', 'libs/batch/batch', 'libs/batch/plugins/project-manager'])
       , 'tools/batch/plugins/s3-file-manager' : HProject   ('batch-plugin-s3-file-manager' , os.path.join ('tools', 'batch', 'plugins', 's3-file-manager') , 'tools'   , ['libs/utils', 'libs/config', 'libs/rpc', 'libs/bus', 'libs/luna/core', 'libs/batch/batch', 'libs/aws'], flags=Flags([Flag('--force-reinstalls')])) # FIXME [PM] force reinstalls flag resolves problem with HTTP and network
       , 'tools/initializer'                   : HProject   ('flowbox-initializer-cli'      , os.path.join ('tools', 'initializer')                         , 'tools'   , ['libs/utils', 'libs/config', 'libs/luna/initializer'], flags=Flags([Flag('--force-reinstalls')])) # FIXME [PM] force reinstalls flag resolves problem with HTTP and network
       , 'tools/lunac'                         : HProject   ('luna-compiler'                , os.path.join ('tools', 'lunac')                               , 'tools'   , ['libs/utils', 'libs/config', 'libs/luna/core', 'libs/luna/pass', 'libs/luna/distribution', 'libs/luna/initializer'], flags=Flags([Flag('--force-reinstalls')])) # FIXME [PM] force reinstalls flag resolves problem with HTTP and network
       , 'tools/wrappers'                      : HProject   ('flowbox-wrappers'             , os.path.join ('tools', 'wrappers')                            , 'wrappers', ['libs/config'])
       , 'third-party/fgl'                     : HProject   ('fgl'                          , os.path.join ('third-party', 'fgl')                           , 'third-party', []) # [PM] temporary fix until fgl is fixed
       , 'third-party/hs-certificate/x509'     : HProject   ('x509'                         , os.path.join ('third-party', 'hs-certificate', 'x509')        , 'third-party', []) # [PM] temporary fix until x509 is fixed ( https://github.com/vincenthz/hs-certificate/pull/33 )
       , 'third-party/hs-crypto-random'        : HProject   ('crypto-random'                , os.path.join ('third-party', 'hs-crypto-random')              , 'third-party', []) # [PM] temporary fix until crypto-random is fixed ( https://github.com/vincenthz/hs-crypto-random/pull/8 )
       , 'third-party/hs-tls/core'             : HProject   ('tls'                          , os.path.join ('third-party', 'hs-tls', 'core')                , 'third-party', []) # [PM] temporary fix until tls is fixed ( https://github.com/vincenthz/hs-tls/pull/75 )
       , 'third-party/protocol-buffers'        : HProject   ('protocol-buffers'             , os.path.join ('third-party', 'protocol-buffers')              , 'third-party', []) # [PM] temporary fix until protocol-buffers is fixed
       }



