#include "reDreamGameCore.h"
#include "OEhost.h"
#import <OpenEmuBase/OERingBuffer.h>

#import <mach-o/dyld.h>
#import <stdlib.h>
#import <string.h>

#include <stdio.h>
#include <stdlib.h>
#include "glad/glad.h"
#include "core/assert.h"
#include "core/filesystem.h"
#include "core/profiler.h"
#include "core/ringbuf.h"
#include "core/time.h"
#include "emulator.h"
#include "render/render_backend.h"

/*
 * OE host implementation
 */
#define BASE_HOST(h) ((struct host *)(h))
#define OE_HOST(h) ((struct OE_host *)(h))

/*
 * audio
 */
void audio_push(struct host *base, const int16_t *data, int frames) {
    GET_CURRENT_OR_RETURN();

     [[current ringBufferAtIndex:0] write:data maxLength:frames * AUDIO_FRAME_SIZE];
}

/*
 * video
 */
void renderFrame() {
    /* render emulator output first */
    emu_render_frame(oe_emu, VIDEO_DEFAULT_WIDTH, VIDEO_DEFAULT_HEIGHT);

    /* flip profiler at end of frame */
    prof_flip(time_nanoseconds());
}

/*
 * input
 */
void input_set( int port, int key, float value) {
        on_input_keydown(oe_host, port, key, value);
}

/*
 *  core
 */
struct OE_host* host_create(const char* supportPath) {
    oe_host = calloc(1, sizeof(struct OE_host));

    fs_set_appdir(supportPath);

    char userdir[PATH_MAX];
    int r = fs_userdir(userdir, sizeof(userdir));
    CHECK(r);

    /* load base options from config */
    char config[PATH_MAX] = {0};
    snprintf(config, sizeof(config), "%s" PATH_SEPARATOR "config", supportPath);
    options_read(config);

    int res = gladLoadGL();

    oe_host->video_rb = r_create();

    oe_emu = emu_create((struct host *)oe_host, oe_host->video_rb);
    
    return oe_host;
}

void load_game(const char *path) {
    emu_load_game(oe_emu, path);
}
