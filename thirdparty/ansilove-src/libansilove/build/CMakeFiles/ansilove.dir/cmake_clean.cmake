file(REMOVE_RECURSE
  ".1"
  "libansilove.pdb"
  "libansilove.so"
  "libansilove.so.1"
  "libansilove.so.1.4.2"
)

# Per-language clean rules from dependency scanning.
foreach(lang C)
  include(CMakeFiles/ansilove.dir/cmake_clean_${lang}.cmake OPTIONAL)
endforeach()
