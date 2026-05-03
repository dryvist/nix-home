# Skip flaky audio/video test suites on aarch64-darwin.
#
# Multiple packages in markitdown's transitive build graph run test suites
# that the macOS Nix sandbox kills with SIGKILL. The libraries themselves
# work correctly — only the in-sandbox test invocations fail.
#
# Affected packages and the test failure mode:
#
# - kvazaar (HEVC encoder)
#   CMake test suite shells out to ffmpeg to produce test frames; ffmpeg
#   subprocesses are SIGKILLed before they can write output.
#   Tests: test_pu_depth_constraints, test_smp, test_intra, test_gop,
#   test_owf_wpp_tiles, test_weird_shapes, test_invalid_input, test_interlace,
#   test_mv_constraint, test_tools.
#
# - chromaprint (audio fingerprinting / acoustid)
#   `tests/all_tests` (gtest binary) is SIGKILLed during
#   FFmpegAudioReaderTest.ReadRaw — same sandbox-syscall enforcement on the
#   ffmpeg subprocesses spawned by the test runner.
#
# Both packages reach the build via:
#   home.packages → markitdown (PPTX text extraction for Claude document-skills)
#     → speechrecognition / pydub → ffmpeg-headless → {kvazaar, chromaprint}
#
# Revisit when nixpkgs ships sandbox-friendly tests for these packages or
# when markitdown drops the audio-processing dep chain.
_final: prev: {
  kvazaar = prev.kvazaar.overrideAttrs (_: {
    doCheck = false;
  });
  chromaprint = prev.chromaprint.overrideAttrs (_: {
    doCheck = false;
  });
}
