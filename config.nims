--define:nimOldCaseObjects
when defined(release):
  --passC:"-target native-native-gnu.2.24"
  --cc:clang
  switch("clang.exe", "zigcc")
  switch("clang.linkerexe", "zigcc")
