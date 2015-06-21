dofile "scripts/bootstrap.lua"
local toolchain = require "astro.toolchain"
local native = require "tundra.native"
local path = require "tundra.path"

local buildDir = path.join(native.getcwd(), ".build")
local projectsDir = path.join(buildDir, "projects")

native.mkdir(buildDir)
native.mkdir(projectsDir)

_G.ASTRO_ROOT = "../astro/"

Build {
  Units = {
    _G.ASTRO_ROOT .. "scripts/astro/library.lua",
    "scripts/units.lua",
  },
  ScriptsDirs = {
    _G.ASTRO_ROOT .. "scripts/astro"
  },
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
  ReplaceEnv = {
    OBJECTROOT = buildDir
  },
  Configs = toolchain.config,
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
    MsvcSolutionDir = path.join(buildDir, "projects", 'vs2015'),

    -- Override solutions to generate and what units to put where.
    MsvcSolutions = {
      ['AstroGraphics.sln'] = {},          -- receives all the units due to empty set
      -- ['ProgramOnly.sln'] = { Projects = { "prog" } },
      -- ['LibOnly.sln'] = { Projects = { "blahlib" } },
    },
  }
}
