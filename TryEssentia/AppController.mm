//
//  AppController.m
//  TryEssentia
//
//  Created by koji on 2023/07/09.
//

#import "AppController.h"

#include <essentia/algorithmfactory.h>
#include <essentia/pool.h>

using namespace std;
using namespace essentia;
using namespace standard;

@implementation AppController
-(void)awakeFromNib{
    NSLog(@"awakeFromNib");
}
- (IBAction)btnClicked:(id)sender {
    NSLog(@"btnClicked");
    essentia::init();
    NSLog(@"essentia initialized");
    
    Real sampleRate = 44100.0;
    AlgorithmFactory &factory = AlgorithmFactory::instance();
    
    Algorithm *audioLoader = factory.create("MonoLoader",
                                           "filename", "/Users/koji/Desktop/hibana.wav",
                                           "sampleRate", sampleRate);
    
    Algorithm *beatTracker = factory.create("BeatTrackerMultiFeature");
    
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
    
    for ( Real b : beats){
        NSLog(@"beat = %f[sec]",b);
    }
    
    delete audioLoader;
    delete beatTracker;
    essentia::shutdown();
}

@end
