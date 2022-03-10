//
//  SoundTouchConvert.h
//  soundTouch
//
//  Created by peterlee on 2022/3/10.
//

#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>

NS_ASSUME_NONNULL_BEGIN

@interface SoundTouchConvert : NSObject

-(CMSampleBufferRef)pitchSoundBuffer:(CMSampleBufferRef) ref;
-(CMSampleBufferRef)createAudioSample:(void *)audioData frames:(UInt32)len timing:(CMSampleTimingInfo)timing;
-(void)configSountTouch: (double)rate pitch: (double)pitch tempo:(double) tempo ;
-(void)changeSoundTouch: (double)rate pitchSemiTones: (double)semiTones pitchOctaves: (double)octaves tempo:(double) tempo;
@end

NS_ASSUME_NONNULL_END
