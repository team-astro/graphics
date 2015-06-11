
Build {
  Units = "scripts/units.lua",
  Env = {
    CXXOPTS = {
      { "/W4"; Config = "*-vs2015-*" },
      { "/O2"; Config = "*-vs2015-release" },
    },
    GENERATE_PDB = {
      { "0"; Config = "*-vs2015-release" },
      { "1"; Config = { "*-vs2015-debug", "*-vs2015-production" } },
    }
  },
  Configs = {
    Config {
      Name = "macosx-clang",
      DefaultOnHost = "macosx",
      Tools = { "clang-osx" },
      Env = {
        CXXOPTS = {
          "-std=c++11 -stdlib=libc++"
        },
        PROGOPTS = {
          "-stdlib=libc++"
        },
        LIBOPTS = {
          -- "-stdlib=libc++",
          -- "-fobjc-arc",
          -- "-fobjc-link-runtime"
        },
        SHLIBOPTS = {
          "-stdlib=libc++"
        },
      },
      ReplaceEnv = {
        -- link with c++ compiler to get stdlib
        LD = "$(CXX)",
        --LIBCOM = "$(CXX) $(LIBOPTS) $(FRAMEWORKPATH:p-F)  $(FRAMEWORKS:p-framework ) -o $(@) $(<)",
      }
    },
    Config {
      Name = 'win64-vs2015',
      Tools = { { "msvc-vs2015"; TargetArch = "x64" }, },
      DefaultOnHost = "windows",
    },
    Config {
      Name = 'win32-vs2015',
      Tools = { { "msvc-vs2015"; TargetArch = "x32" }, },
      SupportedHosts = { "windows" },
    },
  },
  IdeGenerationHints = {
    Msvc = {
      -- Remap config names to MSVC platform names (affects things like header scanning & debugging)
      PlatformMappings = {
        ['win64-vs2015'] = 'x64',
        ['win32-vs2015'] = 'Win32',
      },
      -- Remap variant names to MSVC friendly names
      VariantMappings = {
        ['release']    = 'Release',
        ['debug']      = 'Debug',
        ['production'] = 'Production',
      },
    },

    -- Override output directory for sln/vcxproj files.
    MsvcSolutionDir = 'vs2015',

    -- Override solutions to generate and what units to put where.
    MsvcSolutions = {
      ['astro.graphics.sln'] = {},          -- receives all the units due to empty set
      -- ['ProgramOnly.sln'] = { Projects = { "prog" } },
      -- ['LibOnly.sln'] = { Projects = { "blahlib" } },
    },
  }
}
