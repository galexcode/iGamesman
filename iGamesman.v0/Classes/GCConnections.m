//
//  GCConnections.m
//  GamesmanMobile
//
//  Created by Kevin Jorgensen on 2/12/10.
//  Copyright 2010 GamesCrafters. All rights reserved.
//

#import "GCConnections.h"
#import "GCConnectionsViewController.h"
#import "GCConnectionsOptionMenu.h"
#import "IntegerQueue.h"

#define BLANK @"+"
#define X @"X"
#define XCON @"x"
#define O @"O"
#define OCON @"o"

@implementation GCConnections

@synthesize player1Name, player2Name;
@synthesize player1Type, player2Type;
@synthesize size;
@synthesize p1Turn;
@synthesize misere;
@synthesize predictions, moveValues;
@synthesize service;
@synthesize gameMode;
@synthesize circling;

- (id) init {
	if (self = [super init]) {
		player1Name = @"Player 1";
		player2Name = @"Player 2";
		
		size = 7;
		misere = NO;
		circling = NO;
		
		board = [[NSMutableArray alloc] initWithCapacity: size * size];
		for (int j = 0; j < size; j += 1) {
			for (int i = 0; i < size; i += 1) {
				if(i % 2 == j % 2){
					[board addObject:BLANK];
				}
				else if(i % 2 == 0){
					[board addObject: OCON];
				}
				else {
					[board addObject: XCON];
				}
			}
		}
	}
	
	return self;
}

- (NSString *) gameName {
	return @"Connections";
}

- (BOOL) supportsPlayMode:(PlayMode)mode {
	return mode == OFFLINE_UNSOLVED || mode == ONLINE_SOLVED;
}

- (PlayMode) playMode { return gameMode; }

- (UIViewController *) optionMenu {
	return [[GCConnectionsOptionMenu alloc] initWithGame: self];
}

- (UIViewController *) gameViewController {
	return conView;
}

- (void) startGameInMode: (PlayMode) mode {
	if (!conView)
		[conView release];
	conView = [[GCConnectionsViewController alloc] initWithGame: self];
	
	p1Turn = YES;
	
	[self resetBoard];
	
	if(mode == ONLINE_SOLVED){
		service = [[GCJSONService alloc] init];
		[self startFetch];
	}

	gameMode = mode;
}

- (NSArray *) getBoard {
	return board;
}

- (void) resetBoard {
	if(board){
		[board release];
	}
	
	board = [[NSMutableArray alloc] initWithCapacity: size * size];
	for (int j = 0; j < size; j += 1) {
		for (int i = 0; i < size; i += 1) {
			if(i % 2 == j % 2){
				[board addObject:BLANK];
			}
			else if(i % 2 == 0){
				[board addObject: OCON];
			}
			else {
				[board addObject: XCON];
			}
		}
	}
	
}

- (Player) currentPlayer {
	return p1Turn ? PLAYER1 : PLAYER2;
}

- (void) askUserForInput {
	[conView enableButtons];
}

- (void) stopUserInput {
	[conView disableButtons];
}

- (void) postHumanMove: (NSNumber *) num{
	humanMove = num;
	[[NSNotificationCenter defaultCenter] postNotificationName: @"HumanChoseMove" object: self];
}

- (NSNumber *) getHumanMove {
	return humanMove;
}

- (NSArray *) legalMoves {
	NSMutableArray *moves = [[NSMutableArray alloc] init];
	
	for (int j = 0; j < size; j += 1) {
		for (int i = 0; i < size; i += 1) {
			if ([[board objectAtIndex: i + j * size] isEqual: BLANK]) {
				if (i != 0 && i != size - 1 && j != 0 && j != size-1)
					[moves addObject: [NSNumber numberWithInt: i + j * size + 1]];
			}
		}
	}
	
	return moves;
}

// Return the value of the current board
- (NSString *) getValue { return [service getValue]; }

// Return the remoteness of the current board (or -1 if not available)
- (NSInteger) getRemoteness { return [service getRemoteness]; }

// Return the value of MOVE
- (NSString *) getValueOfMove: (NSNumber *) move {
	NSString *moveString = [NSString stringWithFormat: @"%d", [[[conView translateToServer: [NSArray arrayWithObject: move]] objectAtIndex: 0] intValue]];
	return [[service getValueAfterMove: moveString] uppercaseString];
}

// Return the remoteness of MOVE (or -1 if not available)
- (NSInteger) getRemotenessOfMove: (NSNumber *) move {
	NSString *moveString = [NSString stringWithFormat: @"%d", [[[conView translateToServer: [NSArray arrayWithObject: move]] objectAtIndex: 0] intValue]];
	return [service getRemotenessAfterMove: moveString];
}

- (void) doMove: (NSNumber *) move {
	[conView doMove: move];
	
	int slot = [move integerValue] - 1;
	[board replaceObjectAtIndex: slot withObject: (p1Turn ? X : O)];
	p1Turn = !p1Turn;
//	for (int j = 0; j < size; j += 1) {
//		NSString *row = @"";
//		for (int i = 0; i < size; i += 1) {
//			row = [row stringByAppendingString: [board objectAtIndex: i + j * size]];
//		}
//		NSLog(@"%@", row);
//	}
//	NSLog(@" ");
	
	//put here??
	if (gameMode != ONLINE_SOLVED)
		[conView updateLabels];
	
	if(gameMode == ONLINE_SOLVED){
		[self startFetch];
	}
}

- (void) undoMove: (NSNumber *) move {
	[conView undoMove: move];
	
	int slot = [move intValue] - 1;
	[board replaceObjectAtIndex: slot withObject: BLANK];
	p1Turn = !p1Turn;
	
	if (gameMode == OFFLINE_UNSOLVED)
		[conView updateLabels];
}

- (NSString *) primitive { 
	IntegerQueue * queue = [[IntegerQueue alloc] init];
	int position;
	int neighborPosition;
	
	if(circling){
		if([self encircled: board]){
			return misere ? @"WIN" : @"LOSE";
		}
	}
	if ([[self legalMoves] count] == 0){
		//return misere ? @"LOSE" : @"WIN";
		return misere ? @"WIN" : @"LOSE";
	}

	//////////////////p1 turn finished/////////////////////////
	if (!p1Turn){ 
		
		//add in initial positions, starting with the position directly below the top left connector
		for (int i = size + 1; i < size * 2 - 1; i += 2){
			if ([[board objectAtIndex: i] isEqual: X])
				[queue push: i];
		}
		
		while ([queue notEmpty]){
			position = [queue pop];
			
			//Check to see if we are at the end of our path
			if (position/size >= size - 2){
				[queue release];
				//return misere ? @"LOSE" : @"WIN";
				return misere ? @"WIN" : @"LOSE";
			}
			
			//add neighbors to the fringe
			//////////////odd case///////////////	In terms of column number from 0-size and position in terms of array (index at 0)
			if ((position % size) % 2){						
				//////left neighbor- only check if we are not in the leftmost column
				if ((position % size) > 1){
					neighborPosition = position + size - 1;
					
					if ([[board objectAtIndex: neighborPosition] isEqual: X])
						[queue push: neighborPosition];
				}
				
				/////right neighbor- only check if we are not in the rightmost column
				if ((position % size) < size - 2){
					neighborPosition = position + size + 1;
					
					if ([[board objectAtIndex: neighborPosition] isEqual: X])
						[queue push: neighborPosition];
				}
				
				/////bottom neighbor
				neighborPosition = position + size * 2;
				if ([[board objectAtIndex: neighborPosition] isEqual: X])
					[queue push: neighborPosition];
				
			}
			//////////////even case///////////////
			else{ 	
				
				/////left neighbor- only check if we are not in the leftmost column///////
				if ((position % size) > 3){
					neighborPosition = position - 2;
					
					//Check if The proper piece is in the neighboring position and that the position is not already in the fringe, then add it to the fringe
					if ([[board objectAtIndex: neighborPosition] isEqual: X])
						[queue push: neighborPosition];
					
				}
				
				/////bottom left neighbor///////
				neighborPosition = position + size - 1;
				if ([[board objectAtIndex: neighborPosition] isEqual: X])
					[queue push: neighborPosition];
				
				/////right neighbor- only check if we are not in the rightmost column///////
				if ((position % size) < size - 2){
					neighborPosition = position + 2;
					if ([[board objectAtIndex: neighborPosition] isEqual: X])
						[queue push: neighborPosition];
				}
				
				/////bottom right neighbor///////
				neighborPosition = position + size + 1;
				if ([[board objectAtIndex: neighborPosition] isEqual: X])
					[queue push: neighborPosition];
			}
		}
		
		//////////////////p2 turn/////////////////////////
	}else { 
		//add initial positions
		for (int i = size + 1; i < size * (size - 1); i += size){
			if ([[board objectAtIndex: i] isEqual: O])
				[queue push: i];
		}
		
		//check player
		while ([queue notEmpty]){
			position = [queue pop];
		    //NSLog(@"X queue not empty: %d", position);
			
			//Check to see if we are at the end of our path
			if (position % size >= size - 2){
				[queue release];
				//NSLog(@"Game Over");
				//return misere ? @"LOSE" : @"WIN";
				return misere ? @"WIN" : @"LOSE";
			}
			
			//////////////odd case///////////////
			if ((position % size) % 2){
				//up- only check if not in topmost row
				if(position > 2 * size){
					neighborPosition = position - size + 1;
					
					if([[board objectAtIndex: neighborPosition] isEqual: O])
						[queue push: neighborPosition];
				}
				
				//down- only check if not in bottommost row
				if(position < size * (size - 2)){
					neighborPosition = position + size + 1;
					
					if([[board objectAtIndex: neighborPosition] isEqual: O])
						[queue push: neighborPosition];
					
				}
				//right
				neighborPosition = position + 2;
				if ([[board objectAtIndex: neighborPosition] isEqual: O])
					[queue push: neighborPosition];
				
			}
			//////////////even case///////////////
			else{
				//up- only if not in the third row
				if (position > size * 3){
					neighborPosition = position - size * 2;
					if ([[board objectAtIndex: neighborPosition] isEqual: O])
						[queue push: neighborPosition];
				}
				
				//down- only if not in the third row from the bottom
				if (position < size * (size - 3)){
					neighborPosition = position + size * 2;
					if ([[board objectAtIndex: neighborPosition] isEqual: O])
						[queue push: neighborPosition];
				}
				//upper right
				neighborPosition = position - size + 1;
				if ([[board objectAtIndex: neighborPosition] isEqual: O])
					[queue push: neighborPosition];
				
				//lower right
				neighborPosition = position + size + 1;
				if ([[board objectAtIndex: neighborPosition] isEqual: O])
					[queue push: neighborPosition];
				
			}
		}
	}
	
	[queue release];
	return nil;
}

- (BOOL) encircled: (NSArray *) theBoard {
	NSMutableArray * loop = [[NSMutableArray alloc] initWithCapacity: size*size];
	
	for(int i = 0; i < size*size; i += 1){
		[loop addObject: [NSNumber numberWithInt: -1]];
	}
	
	int row = 0, rowLimit = 0, col = 0, colLimit = 0;
	
	if(!p1Turn){
		row = 0;
		rowLimit = size - 1; 
		col = 1; 
		colLimit = size - 2;
	}
	else{
		row = 1;
		rowLimit = size - 2;
		col = 0;
		colLimit = size - 1;
	}
	for(; row <= rowLimit; row+=2 ){
		for(;col <= colLimit; col +=2 ){
			int connectorPos = row*size + col;
			int edge = 0;
			BOOL checkRight = NO;
			BOOL checkDown = NO;
			//don't do any checking;
			if(row = rowLimit && col == colLimit){}
			
			//in last row, only look right
			else if(row == rowLimit){
				checkRight = YES;
			}
			
			//in last col, only look down
			else if(col == colLimit){
				checkDown = YES;
			}
			
			//can look right and down
			else{
				checkRight = YES;
				checkDown = YES;
			}
			
			if(checkRight){
				edge = connectorPos + 1;
				if([[theBoard objectAtIndex: edge] isEqual: BLANK]){}
				else{
					int val = 0;
					int deg = [[loop objectAtIndex: connectorPos] intValue];
					//first connector
					if(deg > 0){
						val = deg;
					}
					val += 1;
					NSNumber * newDegree = [NSNumber numberWithInt: val];
					[loop replaceObjectAtIndex: connectorPos withObject: newDegree];
					
					//second connector
					val = 0;
					deg = [[loop objectAtIndex: connectorPos + 2] intValue];
					if(deg > 0){
						val = deg;
					}
					val += 1;
					NSNumber * newDegree2 = [NSNumber numberWithInt: val];
					[loop replaceObjectAtIndex: connectorPos + 2 withObject: newDegree2];
				}
			}
			
			if(checkDown){
				edge = connectorPos + size;
				if([[theBoard objectAtIndex: edge] isEqual: BLANK]){}
				else{
					//first connector
					int val = 0;
					int deg = [[loop objectAtIndex: connectorPos] intValue];
					if(deg > 0){
						val = deg;
					}
					val += 1;
					NSNumber * newDegree = [NSNumber numberWithInt: val];
					[loop replaceObjectAtIndex: connectorPos withObject: newDegree];
					
					//second connector
					val = 0;
					deg = [[loop objectAtIndex: connectorPos + 2*size] intValue];
					if(deg > 0){
						val = deg;
					}
					val += 1;
					NSNumber * newDegree2 = [NSNumber numberWithInt: val];
					[loop replaceObjectAtIndex: connectorPos + 2*size withObject: newDegree2];
				}
			}
			
		}
	}
	[self decrementVerticesIn: (NSMutableArray *) loop];
	
	int total = 0;
	for(int i = 1; i < size*size; i += 2){
		if([[loop objectAtIndex: i] intValue] > 0)
			total += 1;
		//NSLog(@"degrees of vertexes: %d", [[loop objectAtIndex: i] intValue]);
	}
	//NSLog(@"number of connections: %d", total);
	[loop release];
	if(total >= 4){
		//[loop dealloc];
		//[vertices dealloc];
		return YES;
	}
	else{
		//[loop dealloc];
		//[vertices dealloc];
		return NO;
	}
}

- (void) decrementVerticesIn: (NSMutableArray *) loop{
	NSMutableArray * decrementedVerts = [[NSMutableArray alloc] init];
	int secondConnectorPos = 0;
	int row = 0, rowLimit = 0, col = 0, colLimit = 0;
	if(!p1Turn){
		row = 0;
		rowLimit = size - 1; 
		col = 1; 
		colLimit = size - 2;
	}
	else{
		row = 1;
		rowLimit = size - 2;
		col = 0;
		colLimit = size - 1;
	}
	for(; row <= rowLimit; row+=2 ){
		for(;col <= colLimit; col +=2 ){
			int connectorPos = row*size + col;
			//find vertex with degree one and decrement it and its connecting vertex
			if([[loop objectAtIndex: connectorPos] intValue] == 1){
				[loop replaceObjectAtIndex: connectorPos withObject: [NSNumber numberWithInt: -1]];
				
				int val = 0;
				
				int left = connectorPos - 2;
				int right = connectorPos + 2;
				int above = connectorPos - 2*size;
				int below = connectorPos + 2*size;
				BOOL checkL = NO, checkR = NO, checkU = NO, checkD = NO;
				//if we are at the left most column for red or for blue, don't check left
				if(col > 1){
					checkL = YES;
				}
				//if we are at the right most column for red or for blue, don't check right
				if(col <= size - 3){
					checkR = YES;
				}
				//if we are at the top most row for red or for blue, don't check up
				if(row >= 2){
					checkU = YES;
				}
				//if we are at the bottom most row for red or for blue, don't check down
				if(row <= size - 3){
					checkD = YES;
				}
				
				if(checkL){
					if([[loop objectAtIndex: left] intValue] > 0){
						val = [[loop objectAtIndex: left] intValue] - 1;
						[loop replaceObjectAtIndex: left withObject: [NSNumber numberWithInt: val]];
						secondConnectorPos = left;
					}
				}
				if(checkR){
					if([[loop objectAtIndex: right] intValue] > 0){
						val = [[loop objectAtIndex: right] intValue] - 1;
						[loop replaceObjectAtIndex: right withObject: [NSNumber numberWithInt: val]];
						secondConnectorPos = right;
					}
				}
				if(checkU){
					if([[loop objectAtIndex: above] intValue] > 0){
						val = [[loop objectAtIndex: above] intValue] - 1;
						[loop replaceObjectAtIndex: above withObject: [NSNumber numberWithInt: val]];
						secondConnectorPos = above;
					}
				}
				if(checkD){
					if([[loop objectAtIndex: below] intValue] > 0){
						val = [[loop objectAtIndex: below] intValue] - 1;
						[loop replaceObjectAtIndex: below withObject: [NSNumber numberWithInt: val]];
						secondConnectorPos = below;
					}
				}
			
				[decrementedVerts addObject: [NSNumber numberWithInt: secondConnectorPos]];
			}
		}
	}
	[self chainDecrement: loop given: decrementedVerts];
	[decrementedVerts release];
}

- (void) chainDecrement: (NSMutableArray*) loop
				  given: (NSMutableArray *) decrementedVerts{
	int num = 0;
	while (num < [decrementedVerts count]) {
		int connectorPos = [[decrementedVerts objectAtIndex: num] intValue];
		num += 1;
		if([[loop objectAtIndex: connectorPos] intValue] == 1){
			[loop replaceObjectAtIndex: connectorPos withObject: [NSNumber numberWithInt: -1]];
			int val = 0;
			int secondConnectorPos = 0;
			int left = connectorPos - 2;
			int right = connectorPos + 2;
			int above = connectorPos - 2*size;
			int below = connectorPos + 2*size;
			
			//decrement the connecting connector
			BOOL checkL = NO, checkR = NO, checkU = NO, checkD = NO;
			//if we are at the left most column for red or for blue, don't check left
			if(connectorPos % size > 1){
				checkL = YES;
			}
			//if we are at the right most column for red or for blue, don't check right
			if(connectorPos % size <= size - 3){
				checkR = YES;
			}
			//if we are at the top most row for red or for blue, don't check up
			if(connectorPos / size >= 2){
				checkU = YES;
			}
			//if we are at the bottom most row for red or for blue, don't check down
			if(connectorPos / size <= size - 3){
				checkD = YES;
			}
			
			if(checkL){
				if([[loop objectAtIndex: left] intValue] > 0){
					val = [[loop objectAtIndex: left] intValue] - 1;
					[loop replaceObjectAtIndex: left withObject: [NSNumber numberWithInt: val]];
					secondConnectorPos = left;
				}
			}
			if(checkR){
				if([[loop objectAtIndex: right] intValue] > 0){
					val = [[loop objectAtIndex: right] intValue] - 1;
					[loop replaceObjectAtIndex: right withObject: [NSNumber numberWithInt: val]];
					secondConnectorPos = right;
				}
			}
			if(checkU){
				if([[loop objectAtIndex: above] intValue] > 0){
					val = [[loop objectAtIndex: above] intValue] - 1;
					[loop replaceObjectAtIndex: above withObject: [NSNumber numberWithInt: val]];
					secondConnectorPos = above;
				}
			}
			if(checkD){
				if([[loop objectAtIndex: below] intValue] > 0){
					val = [[loop objectAtIndex: below] intValue] - 1;
					[loop replaceObjectAtIndex: below withObject: [NSNumber numberWithInt: val]];
					secondConnectorPos = below;
				}
			}
		
			[decrementedVerts addObject: [NSNumber numberWithInt: secondConnectorPos]];
		}
	}
	
}


//- (BOOL) playerHasContinuousPath{
//
//}
//						
	
- (NSString *) stringForBoard: (NSArray *) _board{
	NSString * result = @"";
	for(int row = size - 2; row > 0; row -= 2){
		for(int col = 1; col < size - 1; col += 2){
			NSString * piece = (NSString *) [_board objectAtIndex: row*size + col];
			if([piece isEqual: BLANK]){
				result = [result stringByAppendingString: @" "];
			}
			else
				result = [result stringByAppendingString: piece];
		}
	}
	
	for(int row = size - 3; row > 0; row -= 2){
		for(int col = 2; col < size - 1; col += 2){
			NSString * piece = (NSString *) [_board objectAtIndex: row*size + col];
			if([piece isEqual: BLANK]){
				result = [result stringByAppendingString: @" "];
			}
			else
				result = [result stringByAppendingString: piece];
		}
	}
	return result;
}
 
- (void) startFetch{
	waiter = [[NSThread alloc] initWithTarget: self selector: @selector (fetchNewData) object: nil];
	[waiter start];
}

- (void) fetchNewData{
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	NSString *boardString = [self stringForBoard: board];
	NSString *boardURL = [boardString stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding];
	NSString *boardVal = [[NSString stringWithFormat: @"http://nyc.cs.berkeley.edu:8080/gcweb/service/gamesman/puzzles/connections/getMoveValue;side=%d;board=%@", (size - 5)/2 +2, boardURL] retain];
	NSString *moveVals = [[NSString stringWithFormat: @"http://nyc.cs.berkeley.edu:8080/gcweb/service/gamesman/puzzles/connections/getNextMoveValues;side=%d;board=%@", (size - 5)/2 +2, boardURL] retain];
	[service retrieveDataForBoard: boardString URL: boardVal andNextMovesURL: moveVals];
	[self performSelectorOnMainThread: @selector (fetchFinished) withObject: nil waitUntilDone: NO];
	[pool release];
	
}

- (void) fetchFinished{
	if(waiter)	[waiter release];
	if(![service status] || ![service connected]){
		[[NSNotificationCenter defaultCenter] postNotificationName: @"GameEncounteredProblem" object: self ];
	}
	else{
		[conView updateLabels];
		[[NSNotificationCenter defaultCenter] postNotificationName: @"GameIsReady" object: self ];
	}
}

- (void) notifyWhenReady {
	if (gameMode == OFFLINE_UNSOLVED)
		[[NSNotificationCenter defaultCenter] postNotificationName: @"GameIsReady" object: self];
}

- (void) resume {
	if (gameMode == ONLINE_SOLVED)
		[self startFetch];
}

- (void) dealloc {
	[player1Name release];
	[player2Name release];
	[board release];
	[humanMove release];
	//[service release];
	[super dealloc];
}

@end
