
/*
 Copyright (c) 2013, OpenEmu Team

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:
 * Redistributions of source code must retain the above copyright
 notice, this list of conditions and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright
 notice, this list of conditions and the following disclaimer in the
 documentation and/or other materials provided with the distribution.
 * Neither the name of the OpenEmu Team nor the
 names of its contributors may be used to endorse or promote products
 derived from this software without specific prior written permission.

 THIS SOFTWARE IS PROVIDED BY OpenEmu Team ''AS IS'' AND ANY
 EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL OpenEmu Team BE LIABLE FOR ANY
 DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "reDreamGameCore.h"
#import <OpenEmuBase/OERingBuffer.h>
#import <OpenGL/gl.h>

#import "OEhost.h"

#define SAMPLERATE 44100

__weak reDreamGameCore *_current;


@interface reDreamGameCore () <OEDCSystemResponderClient>
{
    uint16_t *_soundBuffer;
    int videoWidth, videoHeight;
    NSString *romPath;

    bool _isInitialized;
    struct OE_host* redream_host;

    GLint FBO;
}
@end

struct {
    OEDCButton button;
    int dckey;
} buttonToIdentifier[OEDCButtonCount] = {
    { OEDCButtonUp, K_CONT_DPAD_UP },
    { OEDCButtonDown, K_CONT_DPAD_DOWN },
    { OEDCButtonLeft, K_CONT_DPAD_LEFT },
    { OEDCButtonRight, K_CONT_DPAD_RIGHT },
    { OEDCButtonA, K_CONT_A },
    { OEDCButtonB, K_CONT_B },
    { OEDCButtonX, K_CONT_X },
    { OEDCButtonY, K_CONT_Y },
    { OEDCAnalogL, K_CONT_LTRIG },
    { OEDCAnalogR, K_CONT_RTRIG },
    { OEDCButtonStart, K_CONT_START },
    { OEDCAnalogUp, K_CONT_JOYY },
    { OEDCAnalogDown, K_CONT_JOYY },
    { OEDCAnalogLeft, K_CONT_JOYX },
    { OEDCAnalogRight,  K_CONT_JOYX },
};

@implementation reDreamGameCore

- (instancetype)init
{
    self = [super init];

    if(self)
    {
        videoHeight = 480;
        videoWidth = 640;
    }

    _current = self;
    return self;
}

- (void)dealloc
{
    free(_soundBuffer);
}
# pragma mark - Execution
- (BOOL)loadFileAtPath:(NSString *)path error:(NSError **)error
{
    romPath = path;
    return YES;
}

- (void)setupEmulation
{
}

- (void)stopEmulation
{
    [super stopEmulation];
}

- (void)resetEmulation
{
}

- (void)executeFrame
{
    if(_isInitialized)
    {
         glBindFramebuffer(GL_FRAMEBUFFER, FBO);

        renderFrame();

        //This will render the FBO frame
        [self.renderDelegate presentDoubleBufferedFBO];
    }
    else
    {
        const char *dataPath = [[self supportDirectoryPath] fileSystemRepresentation];
        redream_host = host_create(dataPath);

        FBO = (GLint)[[self.renderDelegate presentationFramebuffer] integerValue];

        load_game(romPath.fileSystemRepresentation);

        _isInitialized = true;
    }
}

# pragma mark - Video

- (OEGameCoreRendering)gameCoreRendering
{
    return OEGameCoreRenderingOpenGL3Video;
}

- (BOOL)needsDoubleBufferedFBO
{
    return YES;
}

- (OEIntSize)bufferSize
{
    return OEIntSizeMake(videoWidth, videoHeight);
}

- (NSTimeInterval)frameInterval
{
    return 60;
}

# pragma mark - Audio

void play_audio(int16_t *data, int frames) {

}

- (NSUInteger)channelCount
{
    return 2;
}

- (double)audioSampleRate
{
    return SAMPLERATE;
}

# pragma mark - Save States

// Save State is not implemented by ReDream at this time
- (BOOL)saveStateToFileAtPath: (NSString *) fileName
{
    return NO;
}

- (BOOL)loadStateFromFileAtPath: (NSString *) fileName
{
    return NO;
}

# pragma mark - Input

- (oneway void)didMoveDCJoystickDirection:(OEDCButton)button withValue:(CGFloat)value forPlayer:(NSUInteger)player
{
    if (button == OEDCAnalogUp || button == OEDCAnalogLeft)
        value *= -32767;
    else
        value *= 32767;

    input_set( player - 1, buttonToIdentifier[button].dckey, value );
}

-(oneway void)didPushDCButton:(OEDCButton)button forPlayer:(NSUInteger)player
{
    input_set( player - 1, buttonToIdentifier[button].dckey, 1);
}

- (oneway void)didReleaseDCButton:(OEDCButton)button forPlayer:(NSUInteger)player
{
    input_set( player - 1,  buttonToIdentifier[button].dckey, 0);
}

@end
