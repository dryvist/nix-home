# Skip kvazaar test suite on aarch64-darwin.
#
# kvazaar 2.x ships a CMake test suite (test_pu_depth_constraints, test_smp,
# test_intra, test_gop, test_owf_wpp_tiles, test_weird_shapes,
# test_invalid_input, test_interlace, test_mv_constraint, test_tools) that
# shells out to ffmpeg subprocesses. On aarch64-darwin those ffmpeg processes
# get SIGKILLed by the macOS Nix build sandbox (likely sandbox-syscall
# enforcement on jailed children) before they can produce frames, so every
# encoder test fails. The encoder library itself works correctly — the
# failures are purely in the test driver's use of out-of-tree binaries.
#
# kvazaar reaches the build via:
#   home.packages → markitdown (PPTX text extraction for Claude document-skills)
#     → speechrecognition / pydub → ffmpeg-headless → kvazaar (HEVC encoder)
#
# Revisit when nixpkgs ships a fix for kvazaar's macOS-sandbox-friendly tests
# or when markitdown drops the audio-processing dep chain.
_final: prev: {
  kvazaar = prev.kvazaar.overrideAttrs (_: {
    doCheck = false;
  });
}
