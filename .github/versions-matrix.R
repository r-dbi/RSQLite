# Extra entries for the versions matrix,
# appended by cynkra/cynkratemplate/.github/actions/versions-matrix.
# Windows with an older R uses an older Rtools,
# which once broke the build from source (#903).
data.frame(os = "windows-latest", r = "oldrel-4")
