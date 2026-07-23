file(REMOVE_RECURSE
  "libansilove-static.a"
  "libansilove-static.pdb"
)

# Per-language clean rules from dependency scanning.
foreach(lang C)
  include(CMakeFiles/ansilove-static.dir/cmake_clean_${lang}.cmake OPTIONAL)
endforeach()
