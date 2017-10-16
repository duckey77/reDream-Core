#include "reDreamGameCore.h"
#include "OEhost.h"
#import <OpenEmuBase/OERingBuffer.h>

#include <stdio.h>
#include <stdlib.h>
#include "glad/glad.h"
#include "core/assert.h"
#include "core/filesystem.h"
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
    //emu_render_frame(oe_emu, VIDEO_DEFAULT_WIDTH, VIDEO_DEFAULT_HEIGHT);
    emu_render_frame(oe_emu);
}

/*
 * input
 */
void input_set( int port, int key, float value) {
   // input_keydown(oe_host, port, key, value);
     emu_keydown(oe_emu, port, key, value);
}

/*
 *  OE-Core
 */
struct OE_host* host_create(const char* supportPath) {
    oe_host = calloc(1, sizeof(struct OE_host));

    fs_set_appdir(supportPath);

    int res = gladLoadGL();

    oe_host->video_rb = r_create(VIDEO_DEFAULT_WIDTH, VIDEO_DEFAULT_HEIGHT);

    oe_emu = emu_create(BASE_HOST(oe_host));

    emu_vid_created(oe_emu, oe_host->video_rb);

    //, oe_host->video_rb
    return oe_host;
}

void load_game(const char *path) {
    emu_load(oe_emu, path);
}
