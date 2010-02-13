//
//  GCGameController.m
//  GamesmanMobile
//
//  Created by Kevin Jorgensen on 2/10/10.
//  Copyright 2010 GamesCrafters. All rights reserved.
//

#import "GCGameController.h"


@implementation GCGameController

- (id) initWithGame: (GCGame *) _game {
	if (self = [super init]) {
		game = _game;
		turn = NO;
		
		srand(time(NULL));
	}
	return self;
}

- (void) go {
	// Branch whether the current player is a human or a computer
	// If going to a computer move, make sure to thread it!
	if (![game isPrimitive: [game getBoard]]) {
		if ([game currentPlayerIsHuman])
			[self takeHumanTurn];
		else {
			runner = [[NSThread alloc] initWithTarget: self selector: @selector(takeComputerTurn) object: nil];
			[runner start];
		}
	}
}

- (void) takeHumanTurn {
	[[NSNotificationCenter defaultCenter] addObserver: self
											 selector: @selector(humanChoseMove:) 
												 name: @"HumanChoseMove" 
											   object: game];
	[game askUserForInput];
}

- (void) humanChoseMove: (NSNotification *) notification {
	[[NSNotificationCenter defaultCenter] removeObserver: self];
	
	[game doMove: [game getHumanMove]];
	
	[game stopUserInput];
	[self go];
}

- (void) takeComputerTurn {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	NSArray *legals = [game legalMoves];
	int choice = rand() % [legals count];
	
	sleep(1);
	[game doMove: [legals objectAtIndex: choice]];
	
	[runner cancel];
	[runner release];
	runner = nil;
	
	[self go];
	[pool drain];
}

@end
