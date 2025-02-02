{ system
  , compiler
  , flags
  , pkgs
  , hsPkgs
  , pkgconfPkgs
  , errorHandler
  , config
  , ... }:
  {
    flags = { ghc-lib = false; };
    package = {
      specVersion = "1.20";
      identifier = { name = "ghcide"; version = "0.2.0"; };
      license = "Apache-2.0";
      copyright = "Digital Asset 2018-2020";
      maintainer = "Digital Asset";
      author = "Digital Asset";
      homepage = "https://github.com/digital-asset/ghcide#readme";
      url = "";
      synopsis = "The core of an IDE";
      description = "A library for building Haskell IDE's on top of the GHC API.";
      buildType = "Simple";
      isLocal = true;
      detailLevel = "FullDetails";
      licenseFiles = [ "LICENSE" ];
      dataDir = ".";
      dataFiles = [];
      extraSrcFiles = [
        "include/ghc-api-version.h"
        "README.md"
        "CHANGELOG.md"
        "test/data/hover/*.hs"
        "test/data/multi/cabal.project"
        "test/data/multi/hie.yaml"
        "test/data/multi/a/a.cabal"
        "test/data/multi/a/*.hs"
        "test/data/multi/b/b.cabal"
        "test/data/multi/b/*.hs"
        ];
      extraTmpFiles = [];
      extraDocFiles = [];
      };
    components = {
      "library" = {
        depends = ([
          (hsPkgs."aeson" or (errorHandler.buildDepError "aeson"))
          (hsPkgs."array" or (errorHandler.buildDepError "array"))
          (hsPkgs."async" or (errorHandler.buildDepError "async"))
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."binary" or (errorHandler.buildDepError "binary"))
          (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
          (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
          (hsPkgs."data-default" or (errorHandler.buildDepError "data-default"))
          (hsPkgs."deepseq" or (errorHandler.buildDepError "deepseq"))
          (hsPkgs."directory" or (errorHandler.buildDepError "directory"))
          (hsPkgs."extra" or (errorHandler.buildDepError "extra"))
          (hsPkgs."fuzzy" or (errorHandler.buildDepError "fuzzy"))
          (hsPkgs."filepath" or (errorHandler.buildDepError "filepath"))
          (hsPkgs."haddock-library" or (errorHandler.buildDepError "haddock-library"))
          (hsPkgs."hashable" or (errorHandler.buildDepError "hashable"))
          (hsPkgs."haskell-lsp-types" or (errorHandler.buildDepError "haskell-lsp-types"))
          (hsPkgs."haskell-lsp" or (errorHandler.buildDepError "haskell-lsp"))
          (hsPkgs."mtl" or (errorHandler.buildDepError "mtl"))
          (hsPkgs."network-uri" or (errorHandler.buildDepError "network-uri"))
          (hsPkgs."prettyprinter-ansi-terminal" or (errorHandler.buildDepError "prettyprinter-ansi-terminal"))
          (hsPkgs."prettyprinter-ansi-terminal" or (errorHandler.buildDepError "prettyprinter-ansi-terminal"))
          (hsPkgs."prettyprinter" or (errorHandler.buildDepError "prettyprinter"))
          (hsPkgs."regex-tdfa" or (errorHandler.buildDepError "regex-tdfa"))
          (hsPkgs."rope-utf16-splay" or (errorHandler.buildDepError "rope-utf16-splay"))
          (hsPkgs."safe-exceptions" or (errorHandler.buildDepError "safe-exceptions"))
          (hsPkgs."shake" or (errorHandler.buildDepError "shake"))
          (hsPkgs."sorted-list" or (errorHandler.buildDepError "sorted-list"))
          (hsPkgs."stm" or (errorHandler.buildDepError "stm"))
          (hsPkgs."syb" or (errorHandler.buildDepError "syb"))
          (hsPkgs."text" or (errorHandler.buildDepError "text"))
          (hsPkgs."time" or (errorHandler.buildDepError "time"))
          (hsPkgs."transformers" or (errorHandler.buildDepError "transformers"))
          (hsPkgs."unordered-containers" or (errorHandler.buildDepError "unordered-containers"))
          (hsPkgs."utf8-string" or (errorHandler.buildDepError "utf8-string"))
          (hsPkgs."hslogger" or (errorHandler.buildDepError "hslogger"))
          ] ++ (if flags.ghc-lib
          then [
            (hsPkgs."ghc-lib" or (errorHandler.buildDepError "ghc-lib"))
            (hsPkgs."ghc-lib-parser" or (errorHandler.buildDepError "ghc-lib-parser"))
            ]
          else [
            (hsPkgs."ghc-boot-th" or (errorHandler.buildDepError "ghc-boot-th"))
            (hsPkgs."ghc-boot" or (errorHandler.buildDepError "ghc-boot"))
            (hsPkgs."ghc" or (errorHandler.buildDepError "ghc"))
            ])) ++ (if system.isWindows
          then [ (hsPkgs."Win32" or (errorHandler.buildDepError "Win32")) ]
          else [ (hsPkgs."unix" or (errorHandler.buildDepError "unix")) ]);
        buildable = true;
        modules = (([
          "Development/IDE/Core/Compile"
          "Development/IDE/Core/Preprocessor"
          "Development/IDE/Core/FileExists"
          "Development/IDE/GHC/Compat"
          "Development/IDE/GHC/CPP"
          "Development/IDE/GHC/Orphans"
          "Development/IDE/GHC/Warnings"
          "Development/IDE/GHC/WithDynFlags"
          "Development/IDE/Import/FindImports"
          "Development/IDE/LSP/Notifications"
          "Development/IDE/Spans/AtPoint"
          "Development/IDE/Spans/Calculate"
          "Development/IDE/Spans/Documentation"
          "Development/IDE/Spans/Type"
          "Development/IDE/Plugin/CodeAction/PositionIndexed"
          "Development/IDE/Plugin/CodeAction/Rules"
          "Development/IDE/Plugin/CodeAction/RuleTypes"
          "Development/IDE/Plugin/Completions/Logic"
          "Development/IDE/Plugin/Completions/Types"
          "Development/IDE/Compat"
          "Development/IDE/Core/Debouncer"
          "Development/IDE/Core/FileStore"
          "Development/IDE/Core/IdeConfiguration"
          "Development/IDE/Core/OfInterest"
          "Development/IDE/Core/PositionMapping"
          "Development/IDE/Core/Rules"
          "Development/IDE/Core/RuleTypes"
          "Development/IDE/Core/Service"
          "Development/IDE/Core/Shake"
          "Development/IDE/GHC/Error"
          "Development/IDE/GHC/Util"
          "Development/IDE/Import/DependencyInformation"
          "Development/IDE/LSP/HoverDefinition"
          "Development/IDE/LSP/LanguageServer"
          "Development/IDE/LSP/Outline"
          "Development/IDE/LSP/Protocol"
          "Development/IDE/LSP/Server"
          "Development/IDE/Spans/Common"
          "Development/IDE/Types/Diagnostics"
          "Development/IDE/Types/Location"
          "Development/IDE/Types/Logger"
          "Development/IDE/Types/Options"
          "Development/IDE/Plugin"
          "Development/IDE/Plugin/Completions"
          "Development/IDE/Plugin/CodeAction"
          ] ++ (pkgs.lib).optionals (compiler.isGhc && (compiler.version).gt "8.5" && (compiler.isGhc && (compiler.version).lt "8.7") && !flags.ghc-lib) [
          "Development/IDE/GHC/HieAst"
          "Development/IDE/GHC/HieBin"
          "Development/IDE/GHC/HieTypes"
          "Development/IDE/GHC/HieDebug"
          "Development/IDE/GHC/HieUtils"
          ]) ++ (pkgs.lib).optionals (compiler.isGhc && (compiler.version).gt "8.7" && (compiler.isGhc && (compiler.version).lt "8.10") || flags.ghc-lib) [
          "Development/IDE/GHC/HieAst"
          "Development/IDE/GHC/HieBin"
          ]) ++ (pkgs.lib).optionals (compiler.isGhc && (compiler.version).gt "8.9") [
          "Development/IDE/GHC/HieAst"
          "Development/IDE/GHC/HieBin"
          ];
        cSources = (pkgs.lib).optional (!system.isWindows) "cbits/getmodtime.c";
        hsSourceDirs = (([
          "src"
          ] ++ (pkgs.lib).optional (compiler.isGhc && (compiler.version).gt "8.5" && (compiler.isGhc && (compiler.version).lt "8.7") && !flags.ghc-lib) "src-ghc86") ++ (pkgs.lib).optional (compiler.isGhc && (compiler.version).gt "8.7" && (compiler.isGhc && (compiler.version).lt "8.10") || flags.ghc-lib) "src-ghc88") ++ (pkgs.lib).optional (compiler.isGhc && (compiler.version).gt "8.9") "src-ghc810";
        includeDirs = [ "include" ];
        };
      exes = {
        "ghcide-test-preprocessor" = {
          depends = [ (hsPkgs."base" or (errorHandler.buildDepError "base")) ];
          buildable = true;
          hsSourceDirs = [ "test/preprocessor" ];
          mainPath = [ "Main.hs" ];
          };
        "ghcide" = {
          depends = [
            (hsPkgs."time" or (errorHandler.buildDepError "time"))
            (hsPkgs."async" or (errorHandler.buildDepError "async"))
            (hsPkgs."hslogger" or (errorHandler.buildDepError "hslogger"))
            (hsPkgs."aeson" or (errorHandler.buildDepError "aeson"))
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."binary" or (errorHandler.buildDepError "binary"))
            (hsPkgs."base16-bytestring" or (errorHandler.buildDepError "base16-bytestring"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
            (hsPkgs."cryptohash-sha1" or (errorHandler.buildDepError "cryptohash-sha1"))
            (hsPkgs."data-default" or (errorHandler.buildDepError "data-default"))
            (hsPkgs."deepseq" or (errorHandler.buildDepError "deepseq"))
            (hsPkgs."directory" or (errorHandler.buildDepError "directory"))
            (hsPkgs."extra" or (errorHandler.buildDepError "extra"))
            (hsPkgs."filepath" or (errorHandler.buildDepError "filepath"))
            (hsPkgs."ghc-check" or (errorHandler.buildDepError "ghc-check"))
            (hsPkgs."ghc-paths" or (errorHandler.buildDepError "ghc-paths"))
            (hsPkgs."ghc" or (errorHandler.buildDepError "ghc"))
            (hsPkgs."gitrev" or (errorHandler.buildDepError "gitrev"))
            (hsPkgs."hashable" or (errorHandler.buildDepError "hashable"))
            (hsPkgs."haskell-lsp" or (errorHandler.buildDepError "haskell-lsp"))
            (hsPkgs."haskell-lsp-types" or (errorHandler.buildDepError "haskell-lsp-types"))
            (hsPkgs."hie-bios" or (errorHandler.buildDepError "hie-bios"))
            (hsPkgs."ghcide" or (errorHandler.buildDepError "ghcide"))
            (hsPkgs."optparse-applicative" or (errorHandler.buildDepError "optparse-applicative"))
            (hsPkgs."safe-exceptions" or (errorHandler.buildDepError "safe-exceptions"))
            (hsPkgs."shake" or (errorHandler.buildDepError "shake"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
            (hsPkgs."unordered-containers" or (errorHandler.buildDepError "unordered-containers"))
            ];
          buildable = if flags.ghc-lib then false else true;
          modules = [ "Arguments" "Paths_ghcide" ];
          hsSourceDirs = [ "exe" ];
          mainPath = [ "Main.hs" ] ++ (pkgs.lib).optional (flags.ghc-lib) "";
          };
        "ghcide-bench" = {
          depends = [
            (hsPkgs."aeson" or (errorHandler.buildDepError "aeson"))
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
            (hsPkgs."directory" or (errorHandler.buildDepError "directory"))
            (hsPkgs."extra" or (errorHandler.buildDepError "extra"))
            (hsPkgs."filepath" or (errorHandler.buildDepError "filepath"))
            (hsPkgs."ghcide" or (errorHandler.buildDepError "ghcide"))
            (hsPkgs."lsp-test" or (errorHandler.buildDepError "lsp-test"))
            (hsPkgs."optparse-applicative" or (errorHandler.buildDepError "optparse-applicative"))
            (hsPkgs."process" or (errorHandler.buildDepError "process"))
            (hsPkgs."safe-exceptions" or (errorHandler.buildDepError "safe-exceptions"))
            ];
          build-tools = [
            (hsPkgs.buildPackages.ghcide or (pkgs.buildPackages.ghcide or (errorHandler.buildToolDepError "ghcide")))
            ];
          buildable = true;
          modules = [ "Experiments" ];
          hsSourceDirs = [ "bench/lib" "bench/exe" ];
          includeDirs = [ "include" ];
          mainPath = [ "Main.hs" ];
          };
        };
      tests = {
        "ghcide-tests" = {
          depends = [
            (hsPkgs."aeson" or (errorHandler.buildDepError "aeson"))
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
            (hsPkgs."directory" or (errorHandler.buildDepError "directory"))
            (hsPkgs."extra" or (errorHandler.buildDepError "extra"))
            (hsPkgs."filepath" or (errorHandler.buildDepError "filepath"))
            (hsPkgs."ghc" or (errorHandler.buildDepError "ghc"))
            (hsPkgs."ghcide" or (errorHandler.buildDepError "ghcide"))
            (hsPkgs."ghc-typelits-knownnat" or (errorHandler.buildDepError "ghc-typelits-knownnat"))
            (hsPkgs."haddock-library" or (errorHandler.buildDepError "haddock-library"))
            (hsPkgs."haskell-lsp" or (errorHandler.buildDepError "haskell-lsp"))
            (hsPkgs."haskell-lsp-types" or (errorHandler.buildDepError "haskell-lsp-types"))
            (hsPkgs."network-uri" or (errorHandler.buildDepError "network-uri"))
            (hsPkgs."lens" or (errorHandler.buildDepError "lens"))
            (hsPkgs."lsp-test" or (errorHandler.buildDepError "lsp-test"))
            (hsPkgs."optparse-applicative" or (errorHandler.buildDepError "optparse-applicative"))
            (hsPkgs."process" or (errorHandler.buildDepError "process"))
            (hsPkgs."QuickCheck" or (errorHandler.buildDepError "QuickCheck"))
            (hsPkgs."quickcheck-instances" or (errorHandler.buildDepError "quickcheck-instances"))
            (hsPkgs."rope-utf16-splay" or (errorHandler.buildDepError "rope-utf16-splay"))
            (hsPkgs."safe-exceptions" or (errorHandler.buildDepError "safe-exceptions"))
            (hsPkgs."shake" or (errorHandler.buildDepError "shake"))
            (hsPkgs."tasty" or (errorHandler.buildDepError "tasty"))
            (hsPkgs."tasty-expected-failure" or (errorHandler.buildDepError "tasty-expected-failure"))
            (hsPkgs."tasty-hunit" or (errorHandler.buildDepError "tasty-hunit"))
            (hsPkgs."tasty-quickcheck" or (errorHandler.buildDepError "tasty-quickcheck"))
            (hsPkgs."tasty-rerun" or (errorHandler.buildDepError "tasty-rerun"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
            ];
          build-tools = [
            (hsPkgs.buildPackages.ghcide or (pkgs.buildPackages.ghcide or (errorHandler.buildToolDepError "ghcide")))
            (hsPkgs.buildPackages.ghcide or (pkgs.buildPackages.ghcide or (errorHandler.buildToolDepError "ghcide")))
            ];
          buildable = if flags.ghc-lib then false else true;
          modules = [
            "Development/IDE/Test"
            "Development/IDE/Test/Runfiles"
            "Experiments"
            ];
          hsSourceDirs = [ "test/cabal" "test/exe" "test/src" "bench/lib" ];
          includeDirs = [ "include" ];
          mainPath = [ "Main.hs" ];
          };
        };
      benchmarks = {
        "benchHist" = {
          depends = [
            (hsPkgs."aeson" or (errorHandler.buildDepError "aeson"))
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."Chart" or (errorHandler.buildDepError "Chart"))
            (hsPkgs."Chart-diagrams" or (errorHandler.buildDepError "Chart-diagrams"))
            (hsPkgs."diagrams" or (errorHandler.buildDepError "diagrams"))
            (hsPkgs."diagrams-svg" or (errorHandler.buildDepError "diagrams-svg"))
            (hsPkgs."directory" or (errorHandler.buildDepError "directory"))
            (hsPkgs."extra" or (errorHandler.buildDepError "extra"))
            (hsPkgs."filepath" or (errorHandler.buildDepError "filepath"))
            (hsPkgs."shake" or (errorHandler.buildDepError "shake"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
            (hsPkgs."yaml" or (errorHandler.buildDepError "yaml"))
            ];
          build-tools = [
            (hsPkgs.buildPackages.ghcide or (pkgs.buildPackages.ghcide or (errorHandler.buildToolDepError "ghcide")))
            (hsPkgs.buildPackages.ghcide or (pkgs.buildPackages.ghcide or (errorHandler.buildToolDepError "ghcide")))
            ];
          buildable = true;
          };
        };
      };
    } // rec { src = (pkgs.lib).mkDefault ../.; }