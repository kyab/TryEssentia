//
//  AppController.m
//  TryEssentia
//
//  Created by koji on 2023/07/09.
//

#import "AppController.h"

#include <essentia/algorithmfactory.h>

using namespace std;
using namespace essentia;

@implementation AppController
-(void)awakeFromNib{
    NSLog(@"awakeFromNib");
}
- (IBAction)btnClicked:(id)sender {
    NSLog(@"btnClicked");
    essentia::init();
    NSLog(@"essentia initialized");
}

@end
