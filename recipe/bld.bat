@echo on
setlocal EnableDelayedExpansion

rem Keep the wheel version exactly the release version - suppress upstream's
rem "+cuXXX.git<sha>" local version label (see version_provider.py)
set "NO_VERSION_LABEL=1"

set "CMAKE_ARGS=%CMAKE_ARGS% -DCMAKE_BUILD_TYPE=Release"
set "CMAKE_ARGS=%CMAKE_ARGS% -DCMAKE_PREFIX_PATH=%LIBRARY_PREFIX%;%PREFIX%"
rem Use conda's libz3 (headers + Z3Config.cmake in %LIBRARY_PREFIX%) instead of the
rem pip z3-solver site-packages layout
set "CMAKE_ARGS=%CMAKE_ARGS% -DUSE_PYPI_Z3=OFF"

if "%gpu_variant%"=="cuda" (
    set "CMAKE_ARGS=!CMAKE_ARGS! -DUSE_CUDA=ON"
    rem Root the toolkit at the build env and select the nvcc wrapper explicitly
    rem (patch 0001 makes upstream respect it)
    set "CMAKE_ARGS=!CMAKE_ARGS! -DCUDAToolkit_ROOT=%BUILD_PREFIX%/Library"
    set "CMAKE_ARGS=!CMAKE_ARGS! -DCMAKE_CUDA_COMPILER=%BUILD_PREFIX%/Library/bin/nvcc.exe"
)

set "CMAKE_BUILD_PARALLEL_LEVEL=%CPU_COUNT%"

"%PYTHON%" -m pip install . -vv --no-deps --no-build-isolation
if errorlevel 1 exit /b 1

rem No rpath fixups needed on Windows: DLLs are found via the conda env's
rem Library\bin directory.

endlocal
exit /b 0
