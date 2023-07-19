//
//  AppController.m
//  TryEssentia
//
//  Created by koji on 2023/07/09.
//

#import "AppController.h"

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AudioToolbox/AudioFile.h>

#include <essentia/algorithmfactory.h>
#include <essentia/streaming/algorithms/poolstorage.h>
#include <essentia/scheduler/network.h>
#include <essentia/pool.h>

using namespace std;
using namespace essentia;
//using namespace standard;

@implementation AppController
-(void)awakeFromNib{
    NSLog(@"awakeFromNib");
}
- (IBAction)btnClicked:(id)sender {
    NSLog(@"btnClicked");
    essentia::init();
    NSLog(@"essentia initialized");
    
    Real sampleRate = 44100.0;
    standard::AlgorithmFactory &factory = standard::AlgorithmFactory::instance();
    
    standard::Algorithm *audioLoader = factory.create("MonoLoader",
                                            "filename", "/Users/koji/Desktop/moldover.wav",
                                            "sampleRate", sampleRate);
    
    standard::Algorithm *beatTracker = factory.create("BeatTrackerMultiFeature");
    
    vector<Real> audio;
    vector<Real> beats;
    Real confidence;
    
    audioLoader->output("audio").set(audio);
    audioLoader->compute();
    
    beatTracker->input("signal").set(audio);
    beatTracker->output("ticks").set(beats);
    beatTracker->output("confidence").set(confidence);
    beatTracker->compute();
    
    NSLog(@"audio size = %lu",audio.size());
    NSLog(@"beats size = %lu",beats.size());
    
    for (int i=0; i<beats.size(); i++) {
        Real delta = 0.0;
        if (i > 0) {
            delta = beats[i] - beats[i-1];
        }
        NSLog(@"beat = %f[sec] delta = %f[sec]" ,beats[i], delta);
    }
    
    standard::Algorithm *beatsMarker = factory.create("AudioOnsetsMarker",
                                            "onsets", beats,
                                            "type", "beep");
    
//    Algorithm *audioWriter = factory.create("MonoWriter",
//                                            "filename", "/Users/koji/Desktop/hibana_beat_es.aiff",
//                                            "format","aiff",
//                                            "sampleRate", sampleRate);
    
    vector<Real> audioOutput;
    beatsMarker->input("signal").set(audio);
    beatsMarker->output("signal").set(audioOutput);
    
//    audioWriter->input("audio").set(audioOutput);
    
    beatsMarker->compute();
//    audioWriter->compute();
    
    writeAudioDataToWAVFile(audioOutput, "/Users/koji/Desktop/moldover_beat.wav", sampleRate, 1);
    
    delete audioLoader;
    delete beatTracker;
    delete beatsMarker;
//    delete audioWriter;
    
    essentia::shutdown();
    
    //show me code to write vector<Real> to some wav file
    
    
    NSLog(@"done");
}

- (IBAction)btnClickedStreaming:(id)sender {
    NSLog(@"btnClickedStreaming");
    essentia::init();
    NSLog(@"essentia initialized : streaming");
    
    Pool pool;
    
    streaming::AlgorithmFactory &factory = streaming::AlgorithmFactory::instance();
    streaming::Algorithm *monoloader = factory.create("MonoLoader",
                                                      "filename", "/Users/koji/Desktop/moldover.wav");
    streaming::Algorithm *beattracker = factory.create("BeatTrackerMultiFeature");
    
    
    monoloader->configure("sampleRate", 44100.0);
    
    monoloader->output("audio") >> beattracker->input("signal");
    beattracker->output("ticks") >> PC(pool, "rhythm.ticks");
    beattracker->output("confidence") >> essentia::streaming::NOWHERE;
    
    scheduler::Network network(monoloader);
    network.run();
    
    std::vector<Real> ticks;
    if (pool.contains<vector<Real> > ("rhythm.ticks")){
        ticks = pool.value<vector<Real> > ("rhythm.ticks");
    }
    NSLog(@"ticks size = %lu", ticks.size());
    for (int i=0; i<ticks.size(); i++) {
        Real delta = 0.0;
        if (i > 0) {
            delta = ticks[i] - ticks[i-1];
        }
        NSLog(@"tick = %f[sec] delta = %f[sec]" ,ticks[i], delta);
    }
    
    {
        //use standard algo to mark onsets
    }
}



void writeAudioDataToWAVFile(std::vector<float>& audioData, const char* filePath, int sampleRate, int numChannels) {
    // Create the output file URL
    NSURL *fileURL = [NSURL fileURLWithPath:[NSString stringWithUTF8String:filePath]];

    // Set up the audio file format
    AudioStreamBasicDescription audioFormat;
    audioFormat.mSampleRate = sampleRate;
    audioFormat.mFormatID = kAudioFormatLinearPCM;
    audioFormat.mFormatFlags = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
    audioFormat.mChannelsPerFrame = numChannels;
    audioFormat.mBytesPerFrame = sizeof(SInt16) * numChannels;
    audioFormat.mFramesPerPacket = 1;
    audioFormat.mBytesPerPacket = audioFormat.mBytesPerFrame * audioFormat.mFramesPerPacket;
    audioFormat.mBitsPerChannel = sizeof(SInt16) * 8;

    // Create the audio file
    AudioFileID audioFile;
    OSStatus status = AudioFileCreateWithURL((__bridge CFURLRef)fileURL,
                                             kAudioFileWAVEType,
                                             &audioFormat,
                                             kAudioFileFlags_EraseFile,
                                             &audioFile);
    if (status != noErr) {
        NSLog(@"Error creating audio file.");
        return;
    }

    // Convert and write the audio data to the file
    SInt64 numFrames = audioData.size() / numChannels;
    std::vector<SInt16> convertedData(audioData.size());
    for (size_t i = 0; i < audioData.size(); i++) {
        convertedData[i] = static_cast<SInt16>(audioData[i] * SHRT_MAX);
    }
    UInt32 foo = (UInt32)numFrames;
    AudioFileWritePackets(audioFile,
                          NO,
                          (UInt32)(numFrames * audioFormat.mBytesPerFrame),
                          NULL,
                          0,
                          &foo,
                          convertedData.data());

    // Close the audio file
    AudioFileClose(audioFile);
}


@end
