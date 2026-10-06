cd ~

flutter create --platforms=linux wsl_gl_test

cd wsl_gl_test

LIBGL_ALWAYS_SOFTWARE=1 \
GALLIUM_DRIVER=llvmpipe \
GDK_BACKEND=x11 \
flutter run -d linux --no-enable-impeller