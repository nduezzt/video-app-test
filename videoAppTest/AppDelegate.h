//
//  AppDelegate.h
//  videoAppTest
//
//  Created by Ervina's MacBook on 10/13/17.
//  Copyright © 2017 HackXagonal. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (readonly, strong) NSPersistentContainer *persistentContainer;

- (void)saveContext;


@end

