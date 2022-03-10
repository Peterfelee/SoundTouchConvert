//
//  SoundTouchConvert.m
//  soundTouch
//
//  Created by peterlee on 2022/3/10.
//

#import "SoundTouchConvert.h"
#import "SoundTouch.h"

@interface SoundTouchConvert()
{
    soundtouch::SoundTouch mSoundTouch;
}
@end

@implementation SoundTouchConvert

-(void)configSountTouch: (double)rate pitch: (double)pitch tempo:(double) tempo {
    mSoundTouch = soundtouch::SoundTouch();
    mSoundTouch.setRate(rate);
    mSoundTouch.setPitch(pitch);
    mSoundTouch.setTempo(tempo);
    mSoundTouch.setSetting(SETTING_SEQUENCE_MS, 40);
    mSoundTouch.setSetting(SETTING_SEEKWINDOW_MS, 16);
    mSoundTouch.setSetting(SETTING_OVERLAP_MS, 8);
}

-(void)changeSoundTouch: (double)rate pitchSemiTones: (double)semiTones pitchOctaves: (double)octaves tempo:(double) tempo {
    mSoundTouch.setRateChange(rate);
    mSoundTouch.setPitchSemiTones(semiTones);
    mSoundTouch.setPitchOctaves(octaves);
    mSoundTouch.setTempoChange(tempo);
}

- (CMSampleBufferRef)pitchSoundBuffer:(CMSampleBufferRef)ref {
    AudioBufferList audioBufferList;
    CMBlockBufferRef blockBuffer;
    CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(ref, NULL, &audioBufferList, sizeof(audioBufferList), NULL, NULL, 0, &blockBuffer);

    AudioBuffer audioBuffer = audioBufferList.mBuffers[0];
    Float32 *frame = (Float32*)audioBuffer.mData;
    NSMutableData *audioData=[[NSMutableData alloc] init];
    [audioData appendBytes:frame length:audioBuffer.mDataByteSize];

    char *pcmData = (char *)audioData.bytes;
    int pcmSize = (int)audioData.length;
    int nSamples = pcmSize / 4;
    soundtouch::SoundTouch mSoundTouch = soundtouch::SoundTouch();
    mSoundTouch.putSamples((short *)pcmData, nSamples);


    if (audioData.length == 0) {
        return ref;
    }

    NSMutableData *soundTouchDatas = [[NSMutableData alloc] init];

    short *samples = new short[pcmSize];
    int numSamples = 0;

    memset(samples, 0, pcmSize);
    numSamples = mSoundTouch.receiveSamples(samples,nSamples);
    [soundTouchDatas appendBytes:samples length:numSamples*4];

    delete [] samples;

    CMItemCount timingCount;
    CMSampleBufferGetSampleTimingInfoArray(ref, 0, nil, &timingCount);
    CMSampleTimingInfo* pInfo = (CMSampleTimingInfo *)malloc(sizeof(CMSampleTimingInfo) * timingCount);
    CMSampleBufferGetSampleTimingInfoArray(ref, timingCount, pInfo, &timingCount);

    if (soundTouchDatas.length == 0) {
        return ref;
    }

    void *touchData = (void *)[soundTouchDatas bytes];
    CMSampleBufferRef touchSampleBufferRef = [self createAudioSample:touchData frames:(int)[soundTouchDatas length] timing:*pInfo];
    return touchSampleBufferRef;
}

-(CMSampleBufferRef)createAudioSample:(void *)audioData frames:(UInt32)len timing:(CMSampleTimingInfo)timing {
    
    int channels = 1;
    AudioBufferList audioBufferList;
    audioBufferList.mNumberBuffers = 1;
    audioBufferList.mBuffers[0].mNumberChannels=channels;
    audioBufferList.mBuffers[0].mDataByteSize=len;
    audioBufferList.mBuffers[0].mData = audioData;

    AudioStreamBasicDescription asbd;
    asbd.mSampleRate = 44100;
    asbd.mFormatID = kAudioFormatLinearPCM;
    asbd.mFormatFlags = 0x29;
    asbd.mBytesPerPacket = 4;
    asbd.mFramesPerPacket = 1;
    asbd.mBytesPerFrame = 4;
    asbd.mChannelsPerFrame = 1;
    asbd.mBitsPerChannel = 32;
    asbd.mReserved = 0;

    CMSampleBufferRef buff = NULL;
    static CMFormatDescriptionRef format = NULL;

    OSStatus error = 0;
    error = CMAudioFormatDescriptionCreate(kCFAllocatorDefault, &asbd, 0, NULL, 0, NULL, NULL, &format);
    if (error) {
        return NULL;
    }

    error = CMSampleBufferCreate(kCFAllocatorDefault, NULL, false, NULL, NULL, format, len/4, 1, &timing, 0, NULL, &buff);
    if (error) {
        return NULL;
    }

    error = CMSampleBufferSetDataBufferFromAudioBufferList(buff, kCFAllocatorDefault, kCFAllocatorDefault, 0, &audioBufferList);
    if(error){
        return NULL;
    }

    return buff;
}



@end
