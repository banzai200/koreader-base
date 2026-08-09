list(APPEND PATCH_FILES
    cmake_tweaks.patch
    # Upstream dropped this in b3a28b2d ("tesseract: drop unnecessary patch"),
    # which is true for every upstream target but not for bookeen. It rewrites
    # std::round/std::fmax/std::log2 back to the global-namespace C functions.
    # libstdc++ only injects those into namespace std when
    # _GLIBCXX_USE_C99_MATH_TR1 is set, and that probe FAILS for this target:
    # glibc's bits/mathdef.h defines __NO_LONG_DOUBLE_MATH on ARM (long double
    # == double), so math.h never declares acoshl/roundl/fmaxl/..., the
    # configure probe that calls them does not compile, and libstdc++ gates away
    # *all* of the C99 math overloads -- including the plain double ones that do
    # exist. Forcing the macro on does not help; <cmath> then fails on
    # `using ::acoshl`. The symbols themselves are present in both the
    # toolchain's libm-2.12.1.so and the device's libm-2.11.1.so, so calling
    # them unqualified is correct and costs nothing.
    fix-old-tc-build.patch
    # 5.5.3 marked the FCOORD operators constexpr but left FCOORD() defaulted,
    # which pre-C++20 GCC (i.e. the bookeen GCC 8) rejects. Applied for every
    # target: it is a plain source fix, semantically identical on newer
    # compilers, so there is nothing to gate on BOOKEEN.
    gcc8_constexpr_fcoord.patch
    k2pdfopt.patch
    no_debug_fonts.patch
    trim_the_fat.patch
)

list(APPEND CMAKE_ARGS
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}
    # Project options.
    -DANDROID=${ANDROID}
    -DBUILD_TRAINING_TOOLS=FALSE
    -DDISABLE_ARCHIVE=TRUE
    -DDISABLE_CURL=TRUE
    -DDISABLE_TIFF=TRUE
    -DENABLE_CCACHE=FALSE
    -DENABLE_NINJA_POOL=FALSE
    -DENABLE_PRECOMPILED_HEADERS=FALSE
    -DGRAPHICS_DISABLED=TRUE
    -DINSTALL_CONFIGS=FALSE
)

list(APPEND BUILD_CMD COMMAND ninja)

list(APPEND INSTALL_CMD COMMAND ${CMAKE_COMMAND} --install .)

external_project(
    DOWNLOAD URL 561b6b104238fffa1d00362ac72ea397
    https://github.com/tesseract-ocr/tesseract/archive/refs/tags/5.5.3.tar.gz
    PATCH_FILES ${PATCH_FILES}
    CMAKE_ARGS ${CMAKE_ARGS}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
)
