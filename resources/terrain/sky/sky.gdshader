shader_type sky;

void sky() {
    if (AT_CUBEMAP_PASS) {
        // Sets the radiance cubemap to a nice shade of blue instead of doing
        // expensive sky calculations
        COLOR = vec3(1.0, 1.0, 1.0);
    } else {
        // Do expensive sky calculations for background sky only
        COLOR = vec3(0.0, 0.0, 0.0);
    }
}